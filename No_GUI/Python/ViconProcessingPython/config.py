"""Configuration loading and validation for the Vicon processing pipeline."""

from __future__ import annotations

import copy
import json
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Mapping, Sequence


DEFAULT_CLUSTERS = [
    ["R_IAS", "L_IAS", "R_IPS", "L_IPS", "RGTR", "LGTR"],
    ["R_TH1", "R_TH2", "R_TH3", "R_TH4", "R_FLE", "R_FME", "RGTR"],
    ["R_SK1", "R_SK2", "R_SK3", "R_SK4", "R_FAL", "R_TAM", "R_FLE"],
    ["R_FCC", "R_FM5", "R_FM2", "R_FM1", "R_FAL", "R_TAM"],
    ["L_TH1", "L_TH2", "L_TH3", "L_TH4", "L_FLE", "L_FME", "LGTR"],
    ["L_SK1", "L_SK2", "L_SK3", "L_SK4", "L_FAL", "L_TAM", "L_FLE"],
    ["L_FCC", "L_FM5", "L_FM2", "L_FM1", "L_FAL", "L_TAM"],
    ["RMW1", "RMW2", "RMW3", "R_FM1", "R_FM5", "R_FM2"],
    ["LMW1", "LMW2", "LMW3", "L_FM1", "L_FM5", "L_FM2"],
]
DEFAULT_CLUSTER_JUMP_THRESHOLDS = [40, 35, 35, 35, 35, 35, 35, 35, 35]


@dataclass
class PathsConfig:
    data_dir: Path = Path(".")
    static_trial: str = "S2_Static.c3d"


@dataclass
class FlagsConfig:
    preprocess: bool = True
    gap_fill: bool = True
    final_check: bool = True
    export_filled: bool = True
    qualisys: bool = True
    multi_subjects: bool = False
    worker_verbose: bool = False
    dry_run: bool = False
    fail_on_missing_clusters: bool = True
    progress: bool = True
    parallel_progress: bool = True


@dataclass
class ThresholdsConfig:
    collection_frequency: int = 125
    jump: float = 15
    jump_speed: float = 10
    gap: float = 18
    check: float = 1
    pattern_check: float = 5
    cluster_jump: list[float] = field(
        default_factory=lambda: list(DEFAULT_CLUSTER_JUMP_THRESHOLDS)
    )


@dataclass
class IterationConfig:
    initial_crop_length: int = 301
    crop_step: int = 150
    max_iterations: int = 15
    heavy_iterations: int = 2
    segment_timeout_minutes: float = 30
    workers: int = 1
    initial_relink_distance: float = 5
    segment_relink_distance: float = 10


@dataclass
class PipelineConfig:
    paths: PathsConfig = field(default_factory=PathsConfig)
    flags: FlagsConfig = field(default_factory=FlagsConfig)
    thresholds: ThresholdsConfig = field(default_factory=ThresholdsConfig)
    iteration: IterationConfig = field(default_factory=IterationConfig)
    clusters: list[list[str]] = field(
        default_factory=lambda: copy.deepcopy(DEFAULT_CLUSTERS)
    )
    skiplist: list[str] = field(default_factory=list)
    subject_name: str = "PK_L"
    directions: list[str] = field(default_factory=lambda: ["fw", "bw"])
    gap_lengths: list[int] = field(default_factory=lambda: [1, 2])
    pickup_gap_lengths: list[int] = field(default_factory=lambda: [3, 2, 1])
    coordinates: list[str] = field(default_factory=lambda: ["x", "y", "z"])

    @property
    def marker_set(self) -> list[str]:
        # MATLAB unique sorts its result; sorting also makes runs reproducible.
        return sorted({marker for cluster in self.clusters for marker in cluster})

    def validate(self) -> None:
        if not self.paths.static_trial:
            raise ValueError("paths.static_trial must not be empty")
        if not self.clusters or any(not cluster for cluster in self.clusters):
            raise ValueError("clusters must contain non-empty marker lists")
        if len(self.thresholds.cluster_jump) != len(self.clusters):
            raise ValueError(
                "thresholds.cluster_jump must have one value per cluster"
            )
        if self.iteration.workers < 1:
            raise ValueError("iteration.workers must be at least 1")
        if self.iteration.initial_crop_length < 1 or self.iteration.crop_step < 1:
            raise ValueError("crop lengths must be positive")
        if self.iteration.max_iterations < 1:
            raise ValueError("iteration.max_iterations must be at least 1")


def _read_mapping(path: Path) -> Mapping[str, Any]:
    text = path.read_text(encoding="utf-8")
    try:
        import yaml  # type: ignore
    except ImportError:
        try:
            value = json.loads(text)
        except json.JSONDecodeError as exc:
            raise RuntimeError(
                "PyYAML is required for YAML configuration (JSON also works)"
            ) from exc
    else:
        value = yaml.safe_load(text)
    if value is None:
        return {}
    if not isinstance(value, Mapping):
        raise ValueError("configuration root must be a mapping")
    return value


def _merge_known(target: dict[str, Any], source: Mapping[str, Any], prefix: str = "") -> None:
    for key, value in source.items():
        if key not in target:
            name = f"{prefix}.{key}" if prefix else key
            raise ValueError(f"unknown configuration key: {name}")
        if isinstance(target[key], dict) and isinstance(value, Mapping):
            _merge_known(target[key], value, f"{prefix}.{key}" if prefix else key)
        else:
            target[key] = value


def _parse_scalar(value: str) -> Any:
    try:
        import yaml  # type: ignore
    except ImportError:
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value
    return yaml.safe_load(value)


def _apply_override(data: dict[str, Any], expression: str) -> None:
    if "=" not in expression:
        raise ValueError(f"override must be KEY=VALUE: {expression!r}")
    dotted_key, raw_value = expression.split("=", 1)
    keys = dotted_key.split(".")
    current: dict[str, Any] = data
    for key in keys[:-1]:
        if key not in current or not isinstance(current[key], dict):
            raise ValueError(f"unknown configuration key: {dotted_key}")
        current = current[key]
    if keys[-1] not in current:
        raise ValueError(f"unknown configuration key: {dotted_key}")
    current[keys[-1]] = _parse_scalar(raw_value)


def load_config(
    path: str | Path | None = None, overrides: Sequence[str] = ()
) -> PipelineConfig:
    """Load defaults, merge a YAML/JSON file, then apply dotted CLI overrides."""
    defaults = asdict(PipelineConfig())
    if path is not None:
        _merge_known(defaults, _read_mapping(Path(path)))
    for override in overrides:
        _apply_override(defaults, override)

    paths = defaults.pop("paths")
    flags = defaults.pop("flags")
    thresholds = defaults.pop("thresholds")
    iteration = defaults.pop("iteration")
    paths["data_dir"] = Path(paths["data_dir"]).expanduser()
    config = PipelineConfig(
        paths=PathsConfig(**paths),
        flags=FlagsConfig(**flags),
        thresholds=ThresholdsConfig(**thresholds),
        iteration=IterationConfig(**iteration),
        **defaults,
    )
    config.validate()
    return config
