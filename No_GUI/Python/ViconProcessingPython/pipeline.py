"""Three-phase orchestration equivalent to ``RunMeCropped.m``."""

from __future__ import annotations

import importlib
import inspect
import itertools
import time
from collections import OrderedDict
from concurrent.futures import Executor, ProcessPoolExecutor, ThreadPoolExecutor, as_completed
from copy import deepcopy
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable, Iterable, Mapping, Protocol, Sequence

from .config import PipelineConfig
from .progress import SegmentProgress, log

PREPROCESSED_SUFFIX = "_preprocessed"
FILLED_SUFFIX = "_filled"


@dataclass(frozen=True)
class TrialFile:
    path: Path
    base: str
    kind: str


@dataclass
class SegmentResult:
    data: Any
    operations: int = 0


@dataclass
class PipelineReport:
    dry_run: bool
    planned: dict[str, list[Path]] = field(default_factory=dict)
    processed: dict[str, list[Path]] = field(default_factory=dict)
    failed_preprocessing: dict[str, list[str]] = field(default_factory=dict)
    incomplete_filled: dict[str, list[str]] = field(default_factory=dict)


class Backend(Protocol):
    """Small injectable boundary around model/io/preprocessing/gapfill APIs."""

    def load(self, path: Path, config: PipelineConfig) -> tuple[Any, Any]: ...
    def reference(self, data: Any, config: PipelineConfig) -> Any: ...
    def initial_relink(
        self,
        data: Any,
        reference: Any,
        config: PipelineConfig,
        on_pass: Callable[[int, Sequence[str]], None] | None = None,
    ) -> Any: ...
    def crop(self, data: Any, crop_length: int, config: PipelineConfig) -> Sequence[Any]: ...
    def preprocess_segment(
        self,
        segment: Any,
        reference: Any,
        iteration: int,
        config: PipelineConfig,
        segment_name: str = "",
    ) -> SegmentResult: ...
    def merge(self, segments: Sequence[Any], config: PipelineConfig) -> Any: ...
    def combine_unlabeled(self, data: Any, config: PipelineConfig) -> Any: ...
    def missing_clusters(self, data: Any, config: PipelineConfig) -> tuple[bool, list[str]]: ...
    def prepare_preprocessed_output(
        self, data: Any, original_names: Any, config: PipelineConfig
    ) -> Any: ...
    def fill_edges(
        self, data: Any, reference: Any, config: PipelineConfig
    ) -> Any: ...
    def rigid_fill(
        self, data: Any, config: PipelineConfig
    ) -> tuple[Any, bool]: ...
    def prepare_filled_output(
        self, data: Any, original_names: Any, config: PipelineConfig
    ) -> Any: ...
    def missing_markers(self, data: Any, config: PipelineConfig) -> list[str]: ...
    def write(
        self, data: Any, source: Path, destination: Path, config: PipelineConfig
    ) -> None: ...


@dataclass
class _TrialAdapter:
    """Mutable marker mapping expected by the translated MATLAB primitives."""

    markers: OrderedDict[str, Any]
    frame_numbers: Any
    rate: float
    first_frame: int
    units: str
    coordinate_system: str
    metadata: dict[str, Any]

    def copy(self) -> "_TrialAdapter":
        return deepcopy(self)


def classify_c3d(path: Path) -> TrialFile:
    stem = path.stem
    if stem.endswith(PREPROCESSED_SUFFIX):
        return TrialFile(path, stem[: -len(PREPROCESSED_SUFFIX)], "preprocessed")
    if stem.endswith(FILLED_SUFFIX):
        return TrialFile(path, stem[: -len(FILLED_SUFFIX)], "filled")
    return TrialFile(path, stem, "raw")


def discover_files(config: PipelineConfig) -> list[TrialFile]:
    """Return deterministic C3D inventory after RunMeCropped skip filtering."""
    skipped_names = {name.casefold() for name in config.skiplist}
    result = []
    for path in sorted(
        config.paths.data_dir.glob("*.c3d"), key=lambda item: item.name.casefold()
    ):
        trial = classify_c3d(path)
        if path.name.casefold() in skipped_names:
            continue
        if any(skip.casefold() in trial.base.casefold() for skip in config.skiplist):
            continue
        result.append(trial)
    return result


def select_phase_files(
    files: Iterable[TrialFile], phase: str
) -> list[TrialFile]:
    """Apply the MATLAB static/output de-duplication filters for one phase."""
    inventory = list(files)
    by_kind: dict[str, dict[str, TrialFile]] = {
        "raw": {},
        "preprocessed": {},
        "filled": {},
    }
    for trial in inventory:
        if "static" not in trial.base.casefold():
            by_kind[trial.kind].setdefault(trial.base.casefold(), trial)

    if phase == "preprocess":
        selected = [
            trial
            for key, trial in by_kind["raw"].items()
            if key not in by_kind["preprocessed"] and key not in by_kind["filled"]
        ]
    elif phase == "gap_fill":
        selected = []
        for key in sorted(set(by_kind["raw"]) | set(by_kind["preprocessed"])):
            if key in by_kind["filled"]:
                continue
            selected.append(
                by_kind["preprocessed"].get(key) or by_kind["raw"][key]
            )
    elif phase == "final_check":
        selected = list(by_kind["filled"].values())
    else:
        raise ValueError(f"unknown phase: {phase}")
    return sorted(selected, key=lambda trial: trial.path.name.casefold())


class DefaultBackend:
    """Adapter for evolving package APIs; imports are delayed until real work."""

    def __init__(self) -> None:
        package = __package__ or "ViconProcessingPython"
        self.io = importlib.import_module(f"{package}.io")
        self.preprocessing = importlib.import_module(f"{package}.preprocessing")
        self.gapfill = importlib.import_module(f"{package}.gapfill")
        self.utils = importlib.import_module(f"{package}.utils")
        self.np = importlib.import_module("numpy")
        try:
            self.model = importlib.import_module(f"{package}.model")
        except ImportError:
            self.model = None

    @staticmethod
    def _find(module: Any, names: Sequence[str]) -> Callable[..., Any]:
        for name in names:
            function = getattr(module, name, None)
            if callable(function):
                return function
        raise AttributeError(
            f"{module.__name__} must provide one of: {', '.join(names)}"
        )

    @staticmethod
    def _invoke(function: Callable[..., Any], *args: Any, **kwargs: Any) -> Any:
        """Pass only supported keywords, while allowing APIs with **kwargs."""
        signature = inspect.signature(function)
        supports_kwargs = any(
            parameter.kind == inspect.Parameter.VAR_KEYWORD
            for parameter in signature.parameters.values()
        )
        if not supports_kwargs:
            kwargs = {key: value for key, value in kwargs.items() if key in signature.parameters}
        return function(*args, **kwargs)

    def load(self, path: Path, config: PipelineConfig) -> tuple[Any, Any]:
        function = self._find(self.io, ["load_c3d", "read_c3d", "extract_markers"])
        result = self._invoke(
            function,
            path,
            multi_subject=config.flags.multi_subjects,
            multi_subjects=config.flags.multi_subjects,
        )
        data, original_names = result if isinstance(result, tuple) else (result, None)
        if hasattr(data, "points") and hasattr(data, "labels"):
            labels = tuple(data.labels)
            original_names = getattr(data, "original_labels", None) or original_names
            if config.flags.multi_subjects and original_names is not None:
                # ExtractMarkers_multiSubs.m removes the subject prefix while
                # processing so configured cluster names continue to match.
                labels = tuple(
                    str(label).rsplit(":", 1)[-1].replace("*", "C_")
                    for label in original_names
                )
                if len(set(labels)) != len(labels):
                    raise ValueError(
                        "multi-subject C3D contains duplicate marker names after "
                        "subject prefixes are removed"
                    )
            if config.flags.qualisys:
                labels = tuple(self.utils.rename_qualisys_unlabeled(labels))
            metadata = deepcopy(getattr(data, "metadata", {}))
            if original_names is not None:
                metadata["_original_by_processing_label"] = dict(
                    zip(labels, original_names)
                )
            if self.model is not None and isinstance(data, self.model.MarkerTrial):
                data = data.with_points(
                    self.np.asarray(data.points, dtype=float).copy(),
                    labels=labels,
                    original_labels=(
                        None if original_names is None else tuple(original_names)
                    ),
                    metadata=metadata,
                )
            else:
                markers = OrderedDict(
                    (
                        label,
                        self.np.asarray(data.points[:, index, :], dtype=float).copy(),
                    )
                    for index, label in enumerate(labels)
                )
                data = _TrialAdapter(
                    markers=markers,
                    frame_numbers=self.np.arange(
                        data.first_frame, data.first_frame + data.n_frames
                    ),
                    rate=data.rate,
                    first_frame=data.first_frame,
                    units=data.units,
                    coordinate_system=data.coordinate_system,
                    metadata=metadata,
                )
        return data, original_names

    def reference(self, data: Any, config: PipelineConfig) -> Any:
        function = getattr(self.preprocessing, "prepare_reference", None)
        return self._invoke(function, data, config=config) if function else data

    def initial_relink(
        self,
        data: Any,
        reference: Any,
        config: PipelineConfig,
        on_pass: Callable[[int, Sequence[str]], None] | None = None,
    ) -> Any:
        function = self._find(
            self.preprocessing,
            ["initial_relink", "relink_markers", "relink_marker_segments"],
        )
        marker_set: Sequence[str] = config.marker_set
        for pass_number in itertools.count(1):
            result = self._invoke(
                function,
                data,
                reference=reference,
                marker_set=marker_set,
                clusters=config.clusters,
                distance=config.iteration.initial_relink_distance,
                jump_threshold=config.iteration.initial_relink_distance,
                config=config,
            )
            if not isinstance(result, tuple):
                return result
            data = result[0]
            if on_pass is not None:
                on_pass(pass_number, result[1] if len(result) > 1 else ())
            if len(result) < 3 or not result[2]:
                return data
            # MATLAB narrows to markerSetToLink, so later passes stay cheap.
            if len(result) > 1 and result[1]:
                marker_set = list(result[1])

    def crop(self, data: Any, crop_length: int, config: PipelineConfig) -> Sequence[Any]:
        function = self._find(
            self.preprocessing, ["crop_segments", "crop_trial_segments", "crop_trial"]
        )
        result = self._invoke(
            function,
            data,
            crop_length=crop_length,
            marker_set=config.marker_set,
            config=config,
        )
        if isinstance(result, Mapping):
            def segment_number(item: tuple[Any, Any]) -> int:
                digits = "".join(char for char in str(item[0]) if char.isdigit())
                return int(digits or 0)
            return [value for _, value in sorted(result.items(), key=segment_number)]
        return list(result)

    def preprocess_segment(
        self,
        segment: Any,
        reference: Any,
        iteration: int,
        config: PipelineConfig,
        segment_name: str = "",
    ) -> SegmentResult:
        function = self._find(
            self.preprocessing, ["preprocess_segment", "process_segment"]
        ) if any(
            callable(getattr(self.preprocessing, name, None))
            for name in ("preprocess_segment", "process_segment")
        ) else None
        if function is not None:
            result = self._invoke(
                function,
                segment,
                reference,
                iteration=iteration,
                heavy=iteration <= config.iteration.heavy_iterations,
                marker_set=config.marker_set,
                clusters=config.clusters,
                cluster_jump_thresholds=config.thresholds.cluster_jump,
                relink_distance=config.iteration.segment_relink_distance,
                timeout_seconds=config.iteration.segment_timeout_minutes * 60,
                segment_name=segment_name,
                config=config,
            )
        else:
            result = self._preprocess_segment_primitives(
                segment, reference, iteration, config, segment_name
            )
        if isinstance(result, SegmentResult):
            return result
        if isinstance(result, tuple) and len(result) == 2:
            return SegmentResult(result[0], int(result[1]))
        return SegmentResult(result, 0)

    def _preprocess_segment_primitives(
        self,
        segment: Any,
        reference: Any,
        iteration: int,
        config: PipelineConfig,
        segment_name: str = "",
    ) -> SegmentResult:
        good_frames, _ = self.preprocessing.find_a_good_frame(
            segment,
            config.marker_set,
            reference,
            config.clusters,
            config.thresholds.cluster_jump,
        )
        good_by_marker, _, _ = self.preprocessing.find_a_good_frame_by_cluster(
            segment,
            config.marker_set,
            reference,
            config.clusters,
            config.thresholds.cluster_jump,
            good_frames,
            segment_name,
        )
        data = self.preprocessing.segment_cmarker_jumps(segment)
        marker_segments = self.preprocessing.segment_markers(data)
        if iteration <= config.iteration.heavy_iterations:
            data, _ = self.preprocessing.segment_marker_jumps(
                data,
                config.marker_set,
                marker_segments,
                good_frames,
                good_by_marker,
            )

        operations = 0
        relinked = True
        marker_set_to_link: Sequence[str] = config.marker_set
        while relinked:
            data, marker_set_to_link, relinked = (
                self.preprocessing.relink_marker_segments(
                data,
                marker_set_to_link,
                jump_threshold=config.iteration.segment_relink_distance,
            )
            )
            operations += 1

        deadline = time.monotonic() + config.iteration.segment_timeout_minutes * 60
        full_marker_set = config.marker_set

        # Initial full-set pass: MATLAB lines 268-270.
        data, rigid_names, rigid = self.preprocessing.relink_trimmed_rigid_body(
            data,
            reference,
            config.clusters,
            full_marker_set,
            good_frames,
            good_by_marker,
            config.thresholds.cluster_jump,
        )
        data, neighbor_names, neighbor = self.preprocessing.relink_trimmed_neighbor(
            data, full_marker_set
        )
        data, pattern_names, pattern = self.preprocessing.relink_trimmed_pattern(
            data,
            config.clusters,
            full_marker_set,
            singleton_threshold=config.thresholds.pattern_check,
        )

        # MATLAB has a narrow inner loop followed by a full-set expansion pass.
        while (rigid or neighbor or pattern) and time.monotonic() < deadline:
            operations += 1
            while (rigid or neighbor or pattern) and time.monotonic() < deadline:
                marker_set = sorted(
                    set(rigid_names) | set(neighbor_names) | set(pattern_names)
                )
                if not marker_set:
                    break
                data, rigid_names, rigid = (
                    self.preprocessing.relink_trimmed_rigid_body(
                        data,
                        reference,
                        config.clusters,
                        marker_set,
                        good_frames,
                        good_by_marker,
                        config.thresholds.cluster_jump,
                    )
                )
                data, neighbor_names, neighbor = (
                    self.preprocessing.relink_trimmed_neighbor(data, marker_set)
                )
                data, pattern_names, pattern = (
                    self.preprocessing.relink_trimmed_pattern(
                        data,
                        config.clusters,
                        marker_set,
                        singleton_threshold=config.thresholds.pattern_check,
                    )
                )

            # Expansion ordering is intentionally Pattern -> Rigid -> Neighbor,
            # matching RunMeCropped.m lines 282-284.
            data, pattern_names, pattern = self.preprocessing.relink_trimmed_pattern(
                data,
                config.clusters,
                full_marker_set,
                singleton_threshold=config.thresholds.pattern_check,
            )
            data, rigid_names, rigid = self.preprocessing.relink_trimmed_rigid_body(
                data,
                reference,
                config.clusters,
                full_marker_set,
                good_frames,
                good_by_marker,
                config.thresholds.cluster_jump,
            )
            data, neighbor_names, neighbor = self.preprocessing.relink_trimmed_neighbor(
                data, full_marker_set
            )
        data = self.preprocessing.combine_unlabeled_markers(data)
        return SegmentResult(data, operations)

    def merge(self, segments: Sequence[Any], config: PipelineConfig) -> Any:
        function = self._find(
            self.preprocessing, ["merge_segments", "combine_trial_segments"]
        )
        return self._invoke(function, segments, config=config)

    def combine_unlabeled(self, data: Any, config: PipelineConfig) -> Any:
        function = getattr(self.preprocessing, "combine_unlabeled_markers", None)
        return self._invoke(function, data, config=config) if function else data

    def missing_clusters(self, data: Any, config: PipelineConfig) -> tuple[bool, list[str]]:
        function = self._find(
            self.preprocessing,
            [
                "check_for_missing_clusters",
                "check_missing_clusters",
                "missing_clusters",
            ],
        )
        result = self._invoke(function, data, clusters=config.clusters, config=config)
        if isinstance(result, tuple):
            clusters = [
                ", ".join(value) if isinstance(value, (list, tuple)) else str(value)
                for value in result[1]
            ]
            return bool(result[0]), clusters
        missing = list(result)
        return bool(missing), missing

    def prepare_preprocessed_output(
        self, data: Any, original_names: Any, config: PipelineConfig
    ) -> Any:
        function = getattr(self.preprocessing, "prepare_preprocessed_output", None)
        return (
            self._invoke(
                function, data, original_names=original_names, config=config
            )
            if function
            else self.combine_unlabeled(data, config)
        )

    def fill_edges(self, data: Any, reference: Any, config: PipelineConfig) -> Any:
        function = self._find(
            self.gapfill,
            ["fill_missing_edges", "fill_first_last_frames", "fill_edges"],
        )
        result = self._invoke(
            function,
            data,
            reference,
            config.clusters,
            marker_names=config.marker_set,
            config=config,
        )
        return result[0] if isinstance(result, tuple) else result

    def rigid_fill(
        self, data: Any, config: PipelineConfig
    ) -> tuple[Any, bool]:
        function = self._find(
            self.gapfill,
            ["rigid_body_fill_all_gaps", "fill_all_gaps"],
        )
        result = self._invoke(
            function,
            data,
            config.clusters,
            marker_names=config.marker_set,
            config=config,
        )
        if not isinstance(result, tuple) or len(result) != 2:
            raise TypeError("rigid gap fill must return (data, filled_any)")
        changed = getattr(result[1], "changed", result[1])
        return result[0], bool(changed)

    def prepare_filled_output(
        self, data: Any, original_names: Any, config: PipelineConfig
    ) -> Any:
        function = getattr(self.gapfill, "prepare_filled_output", None)
        return (
            self._invoke(
                function, data, original_names=original_names, config=config
            )
            if function
            else data
        )

    def missing_markers(self, data: Any, config: PipelineConfig) -> list[str]:
        for name in ("find_missing_markers", "missing_markers"):
            function = getattr(self.gapfill, name, None)
            if callable(function):
                return list(
                    self._invoke(
                        function, data, marker_set=config.marker_set, config=config
                    )
                )
        return [
            name
            for name in config.marker_set
            if name not in data.markers
            or bool(self.np.isnan(data.markers[name]).any())
        ]

    def _export_labels(
        self, labels: Sequence[str], data: Any, config: PipelineConfig
    ) -> tuple[str, ...]:
        original_by_label: dict[str, str] = {}
        metadata = getattr(data, "metadata", {})
        if isinstance(metadata, Mapping):
            original_by_label = dict(metadata.get("_original_by_processing_label", {}))
        default_subject = config.subject_name if config.flags.multi_subjects else ""
        restored = []
        for label in labels:
            if label in original_by_label:
                output_label = original_by_label[label]
            elif label.startswith("C_"):
                output_label = label
            elif default_subject:
                output_label = f"{default_subject}_{label}"
            else:
                output_label = label
            if config.flags.qualisys:
                output_label = self.utils.restore_qualisys_unlabeled(
                    (output_label,)
                )[0]
            if label not in original_by_label:
                output_label = self.utils.format_c3d_labels(
                    (output_label,), multi_subject=config.flags.multi_subjects
                )[0]
            restored.append(output_label)
        return tuple(restored)

    def _to_model_trial(self, data: Any, config: PipelineConfig) -> Any:
        if self.model is not None and isinstance(data, self.model.MarkerTrial):
            data.original_labels = self._export_labels(data.labels, data, config)
            return data
        if not hasattr(data, "markers") or self.model is None:
            return data
        markers = OrderedDict(
            (name, self.np.asarray(value, dtype=float))
            for name, value in data.markers.items()
        )
        trial = self.model.MarkerTrial.from_marker_dict(
            markers,
            rate=data.rate,
            first_frame=data.first_frame,
            units=data.units,
            coordinate_system=data.coordinate_system,
        )
        trial.original_labels = self._export_labels(trial.labels, data, config)
        metadata = getattr(data, "metadata", {})
        if isinstance(metadata, Mapping):
            trial.metadata.update(
                {
                    key: value
                    for key, value in metadata.items()
                    if not str(key).startswith("_")
                }
            )
        return trial

    def write(
        self, data: Any, source: Path, destination: Path, config: PipelineConfig
    ) -> None:
        function = self._find(self.io, ["write_c3d", "save_c3d"])
        data = self._to_model_trial(data, config)
        self._invoke(
            function,
            data,
            destination,
            reference_path=source,
            source_path=source,
            multi_subject=config.flags.multi_subjects,
            multi_subjects=config.flags.multi_subjects,
        )


_PROCESS_BACKEND: DefaultBackend | None = None
_PROCESS_REFERENCE: Any = None
_PROCESS_CONFIG: PipelineConfig | None = None


def _initialize_segment_process(reference: Any, config: PipelineConfig) -> None:
    """Initialize one persistent Windows worker process per trial."""
    global _PROCESS_BACKEND, _PROCESS_REFERENCE, _PROCESS_CONFIG
    _PROCESS_BACKEND = DefaultBackend()
    _PROCESS_REFERENCE = reference
    _PROCESS_CONFIG = config


def _preprocess_segment_in_process(
    segment: Any, iteration: int, segment_name: str
) -> SegmentResult:
    if _PROCESS_BACKEND is None or _PROCESS_CONFIG is None:
        raise RuntimeError("segment process was not initialized")
    return _PROCESS_BACKEND.preprocess_segment(
        segment,
        _PROCESS_REFERENCE,
        iteration,
        _PROCESS_CONFIG,
        segment_name,
    )


class Pipeline:
    def __init__(
        self, config: PipelineConfig, backend: Backend | None = None
    ) -> None:
        config.validate()
        self.config = config
        self._backend = backend

    @property
    def backend(self) -> Backend:
        if self._backend is None:
            self._backend = DefaultBackend()
        return self._backend

    def plan(self) -> dict[str, list[Path]]:
        inventory = discover_files(self.config)
        return {
            phase: [trial.path for trial in select_phase_files(inventory, phase)]
            for phase in ("preprocess", "gap_fill", "final_check")
        }

    def run(self) -> PipelineReport:
        planned = self.plan()
        report = PipelineReport(dry_run=self.config.flags.dry_run, planned=planned)
        report.processed = {phase: [] for phase in planned}
        if self.config.flags.dry_run:
            self._log("%%%%DRY RUN%%%%")
            for phase, paths in planned.items():
                self._log(f"{phase}: {len(paths)} file(s)")
                for path in paths:
                    self._log(f"  {path.name}")
            return report

        reference = None
        if (
            self.config.flags.preprocess
            or self.config.flags.gap_fill
        ):
            static_path = self.config.paths.data_dir / self.config.paths.static_trial
            self._log(f"%%%%%LOADING STATIC REFERENCE: {static_path.name}%%%%%")
            static_data, _ = self.backend.load(static_path, self.config)
            reference = self.backend.reference(static_data, self.config)

        if self.config.flags.preprocess:
            self._log("%%%%%GETTING FILE NAMES FROM DIR%%%%%")
            self._run_preprocess(planned["preprocess"], reference, report)
            if (
                report.failed_preprocessing
                and self.config.flags.fail_on_missing_clusters
            ):
                failures = ", ".join(sorted(report.failed_preprocessing))
                raise RuntimeError(
                    f"trials failed preprocessing and need manual check: {failures}"
                )

        # Refresh because preprocessing creates files consumed by phase two.
        if self.config.flags.gap_fill:
            inventory = discover_files(self.config)
            paths = [
                trial.path for trial in select_phase_files(inventory, "gap_fill")
            ]
            report.planned["gap_fill"] = paths
            self._log("%%%%%GAP FILLING AND EXPORTING%%%%%")
            self._run_gap_fill(paths, reference, report)

        # Refresh because gap filling creates files consumed by phase three.
        if self.config.flags.final_check:
            inventory = discover_files(self.config)
            paths = [
                trial.path for trial in select_phase_files(inventory, "final_check")
            ]
            report.planned["final_check"] = paths
            self._log("%%%%Final Check of all filled files%%%%")
            self._run_final_check(paths, report)
            if report.incomplete_filled:
                self._log(
                    "%%%% Trials not fully filled require manual fix. "
                    "Please use Vicon Nexus to fix these trials%%%%"
                )
            else:
                self._log("%%%%All Trials are Processed!%%%%")
        return report

    def _log(self, message: str) -> None:
        if self.config.flags.progress:
            log(message)

    def _run_segments(
        self,
        segments: Sequence[Any],
        reference: Any,
        iteration: int,
        *,
        trial_name: str,
        crop_length: int,
        process_executor: ProcessPoolExecutor | None = None,
    ) -> list[SegmentResult]:
        workers = min(self.config.iteration.workers, max(len(segments), 1))
        worker_kind = (
            "processes"
            if process_executor is not None
            else "threads" if workers > 1 else "sequential"
        )
        progress = None
        if self.config.flags.parallel_progress:
            progress = SegmentProgress(
                len(segments),
                f"{trial_name} | iteration {iteration} | crop {crop_length}",
                workers=workers,
                worker_kind=worker_kind,
            )
        try:
            if workers == 1:
                results = []
                for index, segment in enumerate(segments):
                    if isinstance(self.backend, DefaultBackend):
                        result = self.backend.preprocess_segment(
                            segment,
                            reference,
                            iteration,
                            self.config,
                            f"Seg_{index + 1}",
                        )
                    else:
                        result = self.backend.preprocess_segment(
                            segment, reference, iteration, self.config
                        )
                    results.append(result)
                    if progress is not None:
                        progress.increment()
                return results

            if process_executor is not None:
                executor: Executor = process_executor
                submit = lambda item: executor.submit(  # noqa: E731
                    _preprocess_segment_in_process,
                    item[1],
                    iteration,
                    f"Seg_{item[0] + 1}",
                )
            else:
                executor = ThreadPoolExecutor(max_workers=workers)
                submit = lambda item: executor.submit(  # noqa: E731
                    self.backend.preprocess_segment,
                    item[1],
                    reference,
                    iteration,
                    self.config,
                )

            ordered: list[SegmentResult | None] = [None] * len(segments)
            try:
                futures = {
                    submit((index, segment)): index
                    for index, segment in enumerate(segments)
                }
                for future in as_completed(futures):
                    ordered[futures[future]] = future.result()
                    if progress is not None:
                        progress.increment()
            finally:
                if process_executor is None:
                    executor.shutdown(wait=True)
            return [result for result in ordered if result is not None]
        finally:
            if progress is not None:
                progress.finish()

    def _run_preprocess(
        self, paths: Sequence[Path], reference: Any, report: PipelineReport
    ) -> None:
        total = len(paths)
        for index, source in enumerate(paths, start=1):
            self._log("==============")
            self._log(f"[{index}/{total}] {source.stem}")
            self._log("    Reading C3D...")
            data, original_names = self.backend.load(source, self.config)
            self._log("    Relinking markers...")
            data = self.backend.initial_relink(
                data,
                reference,
                self.config,
                on_pass=lambda number, markers: self._log(
                    f"    relink pass {number}: {len(markers)} marker(s) relinked"
                ),
            )
            crop_length = self.config.iteration.initial_crop_length
            missing: list[str] = []
            process_executor = None
            use_processes = (
                self.config.iteration.workers > 1
                and isinstance(self.backend, DefaultBackend)
            )
            if use_processes:
                self._log(
                    f"    Starting {self.config.iteration.workers} process workers "
                    "(MATLAB parfor equivalent)..."
                )
                process_executor = ProcessPoolExecutor(
                    max_workers=self.config.iteration.workers,
                    initializer=_initialize_segment_process,
                    initargs=(reference, self.config),
                )
            elif self.config.iteration.workers > 1:
                self._log(
                    f"    Starting {self.config.iteration.workers} thread workers "
                    "(custom backend)..."
                )
            else:
                self._log("    Segment workers: 1 (sequential)")

            try:
                for iteration in range(
                    1, self.config.iteration.max_iterations + 1
                ):
                    self._log(f"%%%%%Crop Length: {crop_length}%%%%%")
                    segments = self.backend.crop(data, crop_length, self.config)
                    results = self._run_segments(
                        segments,
                        reference,
                        iteration,
                        trial_name=source.stem,
                        crop_length=crop_length,
                        process_executor=process_executor,
                    )
                    data = self.backend.merge(
                        [result.data for result in results], self.config
                    )
                    data = self.backend.combine_unlabeled(data, self.config)
                    continue_processing = (
                        iteration == 1
                        or any(result.operations > 1 for result in results)
                    )
                    crop_length += self.config.iteration.crop_step
                    if iteration >= 2 or not continue_processing:
                        has_missing, missing = self.backend.missing_clusters(
                            data, self.config
                        )
                        if has_missing:
                            break
                    if not continue_processing:
                        break
            finally:
                if process_executor is not None:
                    self._log("    Stopping process workers...")
                    process_executor.shutdown(wait=True, cancel_futures=True)

            if missing:
                report.failed_preprocessing[source.stem] = missing
                self._log(
                    f"%%%Trial failed preprocessing. Need manual check: {source.stem}%%%"
                )
                continue
            data = self.backend.prepare_preprocessed_output(
                data, original_names, self.config
            )
            destination = source.with_name(source.stem + PREPROCESSED_SUFFIX + ".c3d")
            self._log("    Writing new C3D file...")
            self.backend.write(data, source, destination, self.config)
            report.processed["preprocess"].append(destination)
        if report.failed_preprocessing:
            self._log("%%%Trials Failed Preprocessing. Need Manual Check of Trials%%%")

    def _run_gap_fill(
        self, paths: Sequence[Path], reference: Any, report: PipelineReport
    ) -> None:
        total = len(paths)
        for index, source in enumerate(paths, start=1):
            self._log("==============")
            self._log(f"[{index}/{total}] {source.stem}")
            self._log("    Reading C3D...")
            data, original_names = self.backend.load(source, self.config)
            filled = True
            fill_pass = 0
            while filled:
                fill_pass += 1
                self._log(f"    Filling gaps (pass {fill_pass})...")
                data = self.backend.fill_edges(data, reference, self.config)
                data, filled = self.backend.rigid_fill(data, self.config)
            data = self.backend.prepare_filled_output(
                data, original_names, self.config
            )
            base = classify_c3d(source).base
            destination = source.with_name(base + FILLED_SUFFIX + ".c3d")
            if self.config.flags.export_filled:
                self._log("    Writing new C3D file...")
                self.backend.write(data, source, destination, self.config)
                report.processed["gap_fill"].append(destination)

    def _run_final_check(
        self, paths: Sequence[Path], report: PipelineReport
    ) -> None:
        total = len(paths)
        for index, source in enumerate(paths, start=1):
            self._log(f"[{index}/{total}] {source.stem}")
            data, _ = self.backend.load(source, self.config)
            missing = self.backend.missing_markers(data, self.config)
            if missing:
                report.incomplete_filled[classify_c3d(source).base] = missing
                self._log(f"Not Fully Filled Trial: {classify_c3d(source).base}")
            report.processed["final_check"].append(source)


def run_pipeline(
    config: PipelineConfig, backend: Backend | None = None
) -> PipelineReport:
    return Pipeline(config, backend=backend).run()
