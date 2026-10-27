from __future__ import annotations

import json
import time
from pathlib import Path
from types import SimpleNamespace

import numpy as np
import pytest

from ViconProcessingPython.config import (
    DEFAULT_CLUSTERS,
    PipelineConfig,
    load_config,
)
from ViconProcessingPython.model import MarkerTrial
from ViconProcessingPython.pipeline import (
    DefaultBackend,
    Pipeline,
    SegmentResult,
    discover_files,
    select_phase_files,
)


def touch_trials(directory: Path, *names: str) -> None:
    for name in names:
        (directory / name).touch()


def test_phase_file_filters_preserve_matlab_preferences(tmp_path: Path) -> None:
    touch_trials(
        tmp_path,
        "S2_Static.c3d",
        "A.c3d",
        "A_preprocessed.c3d",
        "B.c3d",
        "B_filled.c3d",
        "C.c3d",
        "skip_me.c3d",
        "walking_static_pose.c3d",
    )
    config = PipelineConfig()
    config.paths.data_dir = tmp_path
    config.skiplist = ["skip"]
    files = discover_files(config)

    assert [trial.path.name for trial in select_phase_files(files, "preprocess")] == [
        "C.c3d"
    ]
    assert [trial.path.name for trial in select_phase_files(files, "gap_fill")] == [
        "A_preprocessed.c3d",
        "C.c3d",
    ]
    assert [trial.path.name for trial in select_phase_files(files, "final_check")] == [
        "B_filled.c3d"
    ]


def test_dry_run_never_initializes_backend(tmp_path: Path) -> None:
    touch_trials(tmp_path, "trial.c3d", "S2_Static.c3d")
    config = PipelineConfig()
    config.paths.data_dir = tmp_path
    config.flags.dry_run = True

    class ExplodingBackend:
        def __getattribute__(self, name: str) -> object:
            raise AssertionError(f"dry-run touched backend attribute {name}")

    report = Pipeline(config, backend=ExplodingBackend()).run()  # type: ignore[arg-type]

    assert report.dry_run
    assert [path.name for path in report.planned["preprocess"]] == ["trial.c3d"]
    assert report.processed == {
        "preprocess": [],
        "gap_fill": [],
        "final_check": [],
    }


def test_config_defaults_file_and_overrides(tmp_path: Path) -> None:
    config_file = tmp_path / "config.json"
    config_file.write_text(
        json.dumps(
            {
                "paths": {"data_dir": str(tmp_path), "static_trial": "ref.c3d"},
                "iteration": {"workers": 3},
                "flags": {"qualisys": False},
            }
        ),
        encoding="utf-8",
    )

    config = load_config(
        config_file,
        ["iteration.workers=1", "thresholds.jump=22.5", "skiplist=[\"bad\"]"],
    )

    assert config.paths.data_dir == tmp_path
    assert config.paths.static_trial == "ref.c3d"
    assert config.iteration.workers == 1
    assert config.thresholds.jump == 22.5
    assert config.flags.qualisys is False
    assert config.skiplist == ["bad"]
    assert config.clusters == DEFAULT_CLUSTERS
    assert config.marker_set == sorted(set(sum(DEFAULT_CLUSTERS, [])))


def test_config_rejects_unknown_keys_and_mismatched_thresholds(
    tmp_path: Path,
) -> None:
    bad_key = tmp_path / "bad-key.json"
    bad_key.write_text('{"flags": {"not_a_flag": true}}', encoding="utf-8")
    with pytest.raises(ValueError, match="unknown configuration key"):
        load_config(bad_key)

    config = PipelineConfig()
    config.thresholds.cluster_jump = [1]
    with pytest.raises(ValueError, match="one value per cluster"):
        config.validate()


def test_parallel_segment_results_merge_in_input_order() -> None:
    config = PipelineConfig()
    config.iteration.workers = 3
    config.flags.progress = False
    config.flags.parallel_progress = False

    class OutOfOrderBackend:
        def preprocess_segment(
            self,
            segment: int,
            reference: object,
            iteration: int,
            config: PipelineConfig,
        ) -> SegmentResult:
            time.sleep((3 - segment) * 0.005)
            return SegmentResult(segment, operations=segment)

    pipeline = Pipeline(config, backend=OutOfOrderBackend())  # type: ignore[arg-type]
    results = pipeline._run_segments(
        [0, 1, 2], None, 1, trial_name="trial", crop_length=301
    )

    assert [result.data for result in results] == [0, 1, 2]


def test_default_backend_matches_matlab_multi_subject_processing_names() -> None:
    trial = MarkerTrial(
        points=np.ones((3, 2, 3)),
        labels=("Alice_RASI", "Alice_C_12"),
        original_labels=("Alice:RASI", "Alice:*12"),
        rate=100,
    )
    backend = DefaultBackend()
    backend.io = SimpleNamespace(read_c3d=lambda path, **kwargs: trial)
    config = PipelineConfig()
    config.flags.multi_subjects = True
    config.flags.qualisys = False

    loaded, originals = backend.load(Path("unused.c3d"), config)

    assert tuple(loaded.markers) == ("RASI", "C_12")
    assert originals == trial.original_labels
    exported = backend._to_model_trial(loaded, config)
    assert exported.original_labels == ("Alice:RASI", "Alice:*12")
    assert exported.labels == ("RASI", "C_12")


def test_default_backend_write_keeps_qualisys_and_unlabeled_originals() -> None:
    trial = MarkerTrial(
        points=np.ones((2, 3, 3)),
        labels=("Alice_RASI", "Alice_C_12", "U3"),
        original_labels=("Alice:RASI", "Alice:*12", "U3"),
        rate=100,
    )
    backend = DefaultBackend()
    config = PipelineConfig()
    config.flags.multi_subjects = True
    config.flags.qualisys = True
    config.subject_name = "Alice"
    backend.io = SimpleNamespace(read_c3d=lambda path, **kwargs: trial)

    loaded, _ = backend.load(Path("unused.c3d"), config)
    loaded.markers["C_99"] = np.ones((2, 3))
    exported = backend._to_model_trial(loaded, config)

    assert tuple(loaded.markers) == ("RASI", "C_12", "C_3", "C_99")
    assert exported.original_labels == ("Alice:RASI", "Alice:*12", "U3", "U99")


def test_marker_trial_is_accepted_by_preprocessing_crop() -> None:
    from ViconProcessingPython.preprocessing import crop_trial_segments

    trial = MarkerTrial(
        points=np.arange(18, dtype=float).reshape(6, 1, 3),
        labels=("RASI",),
        rate=100,
        first_frame=10,
    )
    segments = crop_trial_segments(trial, ["RASI", "RKNE"], 4)

    assert list(segments) == ["Seg_1", "Seg_2"]
    assert segments["Seg_1"].first_frame == 10
    assert segments["Seg_2"].first_frame == 14
    assert "RKNE" in segments["Seg_1"].markers
    np.testing.assert_array_equal(trial.points[0, 0], [0.0, 1.0, 2.0])


def test_default_backend_resolves_missing_cluster_implementation() -> None:
    backend = DefaultBackend()
    config = PipelineConfig()
    config.clusters = [["RASI"]]
    trial = SimpleNamespace(markers={"RASI": np.ones((3, 3))})

    missing, clusters = backend.missing_clusters(trial, config)

    assert missing is False
    assert clusters == []


def test_segment_orchestration_matches_matlab_narrow_and_expand_order() -> None:
    calls: list[tuple[str, tuple[str, ...]]] = []

    class Preprocessing:
        direct_count = 0

        @staticmethod
        def find_a_good_frame(*args):
            return np.array([], dtype=int), np.array([])

        @staticmethod
        def find_a_good_frame_by_cluster(*args):
            assert args[-1] == "Seg_1"
            return {}, np.array([]), False

        @staticmethod
        def segment_cmarker_jumps(data):
            return data

        @staticmethod
        def segment_markers(data):
            return {}

        @staticmethod
        def segment_marker_jumps(data, *args):
            return data, False

        def relink_marker_segments(self, data, marker_set, **kwargs):
            calls.append(("D", tuple(marker_set)))
            self.direct_count += 1
            return (
                (data, ["A"], True)
                if self.direct_count == 1
                else (data, [], False)
            )

        @staticmethod
        def relink_trimmed_rigid_body(data, reference, clusters, marker_set, *args):
            calls.append(("R", tuple(marker_set)))
            first_rigid = sum(name == "R" for name, _ in calls) == 1
            return data, (["A"] if first_rigid else []), first_rigid

        @staticmethod
        def relink_trimmed_neighbor(data, marker_set):
            calls.append(("N", tuple(marker_set)))
            return data, [], False

        @staticmethod
        def relink_trimmed_pattern(data, clusters, marker_set, **kwargs):
            calls.append(("P", tuple(marker_set)))
            return data, [], False

        @staticmethod
        def combine_unlabeled_markers(data):
            calls.append(("C", ()))
            return data

    backend = DefaultBackend.__new__(DefaultBackend)
    backend.preprocessing = Preprocessing()
    config = PipelineConfig()
    config.clusters = [["A", "B"]]
    config.thresholds.cluster_jump = [35]
    config.iteration.heavy_iterations = 0

    result = backend._preprocess_segment_primitives(
        object(), object(), 1, config, "Seg_1"
    )

    assert result.operations == 3  # two direct calls + one trimmed outer pass
    assert calls == [
        ("D", ("A", "B")),
        ("D", ("A",)),
        ("R", ("A", "B")),
        ("N", ("A", "B")),
        ("P", ("A", "B")),
        ("R", ("A",)),
        ("N", ("A",)),
        ("P", ("A",)),
        ("P", ("A", "B")),
        ("R", ("A", "B")),
        ("N", ("A", "B")),
        ("C", ()),
    ]


def test_segment_progress_rewrites_one_line() -> None:
    from io import StringIO

    from ViconProcessingPython.progress import SegmentProgress

    stream = StringIO()
    progress = SegmentProgress(
        2,
        "trial | iteration 1 | crop 301",
        workers=2,
        worker_kind="processes",
        stream=stream,
    )
    progress.increment()
    progress.finish()

    output = stream.getvalue()
    assert "workers 2/2 processes | segments 0/2 (  0%)" in output
    assert "workers 1/2 processes | segments 1/2 ( 50%)" in output
    assert "workers 0/2 processes | segments 2/2 (100%)" in output
    assert output.endswith("\n")


def test_pipeline_progress_and_quiet_cli(capsys, tmp_path: Path) -> None:
    from ViconProcessingPython.cli import main

    touch_trials(tmp_path, "trial.c3d", "S2_Static.c3d")
    config_file = tmp_path / "config.json"
    config_file.write_text(
        json.dumps({"paths": {"data_dir": str(tmp_path)}}),
        encoding="utf-8",
    )

    assert main(["--config", str(config_file), "--dry-run"]) == 0
    noisy = capsys.readouterr()
    assert "%%%%DRY RUN%%%%" in noisy.err
    assert "trial.c3d" in noisy.err
    assert '"dry_run": true' in noisy.out

    assert main(["--config", str(config_file), "--dry-run", "--quiet"]) == 0
    quiet = capsys.readouterr()
    assert quiet.err == ""
    assert '"dry_run": true' in quiet.out
