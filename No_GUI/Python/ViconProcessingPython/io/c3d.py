"""C3D marker I/O implemented with :mod:`ezc3d`."""

from __future__ import annotations

from pathlib import Path
import re
from typing import Any, Sequence

import numpy as np

from ..model import MarkerTrial
from ..utils.markers import format_c3d_labels, parse_c3d_labels
from ..utils.transform import transform_points


def _ezc3d() -> Any:
    try:
        import ezc3d
    except ImportError as exc:  # pragma: no cover - dependency supplies this path
        raise ImportError("C3D I/O requires the 'ezc3d' package") from exc
    return ezc3d


def _parameter_value(c3d: Any, group: str, name: str, default: Any) -> Any:
    try:
        value = c3d["parameters"][group][name]["value"]
    except KeyError:
        return default
    if isinstance(value, np.ndarray):
        value = value.tolist()
    return value


def _point_labels(c3d: Any) -> list[str]:
    """Collect C3D labels split across LABELS, LABELS2, ... parameters."""
    point_parameters = c3d["parameters"]["POINT"]
    label_parameters: list[tuple[int, str]] = []
    for name in point_parameters:
        match = re.fullmatch(r"LABELS(\d*)", name)
        if match:
            label_parameters.append((int(match.group(1) or 1), name))

    labels: list[str] = []
    for _, name in sorted(label_parameters):
        values = _parameter_value(c3d, "POINT", name, ())
        labels.extend(str(value) for value in values)
    return labels


def _reconcile_labels(labels: Sequence[str], point_count: int) -> list[str]:
    """Match the label list to the point count the way BTK does.

    MATLAB's writer shrinks POINT:LABELS but can leave entries behind in the
    later LABELS blocks, so trailing labels that describe no point are dropped.
    Points without a label become unlabeled markers.
    """
    if len(labels) >= point_count:
        return list(labels[:point_count])

    result = list(labels)
    used = set(result)
    next_id = 1
    while len(result) < point_count:
        while f"*{next_id}" in used or f"C_{next_id}" in used:
            next_id += 1
        result.append(f"*{next_id}")
        used.add(f"*{next_id}")
    return result


_LABEL_BLOCK = 255


def _set_point_string_parameter(c3d: Any, base: str, values: Sequence[str]) -> None:
    """Write a per-point string parameter across 255-entry C3D blocks.

    A reference file may already define more blocks than the new point count
    needs, so unused blocks are emptied instead of left stale.
    """
    point_parameters = c3d["parameters"]["POINT"]
    blocks = [
        list(values[start:start + _LABEL_BLOCK])
        for start in range(0, len(values), _LABEL_BLOCK)
    ] or [[]]

    existing = {
        int(match.group(1) or 1)
        for name in point_parameters
        if (match := re.fullmatch(rf"{base}(\d*)", name))
    }
    for number in sorted(existing | set(range(1, len(blocks) + 1))):
        name = base if number == 1 else f"{base}{number}"
        block = blocks[number - 1] if number <= len(blocks) else []
        if name in point_parameters:
            point_parameters[name]["value"] = block
        elif block:
            point_parameters[name] = {
                "type": _ezc3d().ezc3d.CHAR,
                "description": "",
                "is_locked": False,
                "value": block,
            }


def read_c3d(
    path: str | Path,
    *,
    multi_subject: bool = False,
    coordinate_system: str = "osim",
) -> MarkerTrial:
    """Read marker points, preserving labels, timing, units, and missing data."""
    c3d = _ezc3d().c3d(str(path))
    c3d_points = np.asarray(c3d["data"]["points"], dtype=float)
    if c3d_points.ndim != 3 or c3d_points.shape[0] < 4:
        raise ValueError("C3D point data must have shape (4, markers, frames)")

    labels_value = _reconcile_labels(_point_labels(c3d), c3d_points.shape[1])
    labels, originals = parse_c3d_labels(labels_value, multi_subject=multi_subject)
    xyz = c3d_points[:3].transpose(2, 1, 0)
    residuals = c3d_points[3].T
    xyz[residuals < 0] = np.nan
    # Match ExtractMarkers_multiSubs: BTK/ezc3d may return invalid samples as
    # zero coordinates even when the residual flag was not retained.
    xyz[xyz == 0] = np.nan

    target = coordinate_system.lower()
    if target == "osim":
        xyz = transform_points(xyz, "OsimXYZ")
    elif target != "vicon":
        raise ValueError("coordinate_system must be 'osim' or 'vicon'")

    rate_value = _parameter_value(c3d, "POINT", "RATE", [0.0])
    units_value = _parameter_value(c3d, "POINT", "UNITS", ["mm"])
    rate = float(rate_value[0])
    units = str(units_value[0])
    first_frame = int(c3d["header"]["points"].get("first_frame", 1))
    return MarkerTrial(
        xyz,
        labels,
        rate,
        first_frame,
        units,
        target,
        originals,
        metadata={"source": str(path)},
    )


def write_c3d(
    trial: MarkerTrial,
    output_path: str | Path,
    *,
    reference_path: str | Path | None = None,
    multi_subject: bool = False,
    use_original_labels: bool = True,
) -> Path:
    """Write a trial, optionally cloning non-point metadata from a reference C3D."""
    ezc3d = _ezc3d()
    c3d = ezc3d.c3d(str(reference_path)) if reference_path is not None else ezc3d.c3d()

    if trial.coordinate_system == "osim":
        xyz = transform_points(trial.points, "ViconXYZ")
    elif trial.coordinate_system == "vicon":
        xyz = trial.points.copy()
    else:
        raise ValueError("trial.coordinate_system must be 'osim' or 'vicon'")

    missing = np.isnan(xyz).any(axis=2)
    # C3D stores invalid coordinates as zero with a negative residual.
    xyz = np.where(missing[:, :, None], 0.0, xyz)
    points = np.empty((4, trial.n_markers, trial.n_frames), dtype=float)
    points[:3] = xyz.transpose(2, 1, 0)
    points[3] = np.where(missing.T, -1.0, 0.0)

    if use_original_labels and trial.original_labels is not None:
        labels = trial.original_labels
    else:
        labels = format_c3d_labels(trial.labels, multi_subject=multi_subject)

    c3d["data"]["points"] = points
    # Residuals/camera masks cloned from the reference still describe its own
    # point count, so they are rebuilt for this trial and keep the -1 residual
    # that marks a missing sample.
    c3d["data"]["meta_points"] = {
        "residuals": points[3][None, :, :].copy(),
        "camera_masks": np.zeros((7, trial.n_markers, trial.n_frames), dtype=bool),
    }
    _set_point_string_parameter(c3d, "LABELS", list(labels))
    _set_point_string_parameter(c3d, "DESCRIPTIONS", [""] * len(labels))
    c3d["parameters"]["POINT"]["RATE"]["value"] = [trial.rate]
    c3d["parameters"]["POINT"]["UNITS"]["value"] = [trial.units]
    c3d["parameters"]["POINT"]["FRAMES"]["value"] = [trial.n_frames]
    if "USED" in c3d["parameters"]["POINT"]:
        c3d["parameters"]["POINT"]["USED"]["value"] = [trial.n_markers]
    c3d["header"]["points"]["first_frame"] = trial.first_frame
    c3d["header"]["points"]["last_frame"] = trial.last_frame
    c3d["header"]["points"]["frame_rate"] = trial.rate

    output = Path(output_path)
    if output.suffix.lower() != ".c3d":
        output = output.with_suffix(".c3d")
    c3d.write(str(output))
    return output


def markersto_c3d(
    trial: MarkerTrial,
    reference_path: str | Path,
    output_path: str | Path,
    *,
    multi_subject: bool = False,
) -> Path:
    """Python equivalent of the two MATLAB ``markerstoC3D`` variants."""
    return write_c3d(
        trial,
        output_path,
        reference_path=reference_path,
        multi_subject=multi_subject,
    )


def trc_to_c3d(
    trial: MarkerTrial,
    reference_path: str | Path,
    output_path: str | Path,
    *,
    multi_subject: bool = False,
) -> Path:
    """Write MarkerTrial data as the MATLAB ``TRCtoC3D`` functions do."""
    return markersto_c3d(
        trial,
        reference_path,
        output_path,
        multi_subject=multi_subject,
    )


# Direct migration aliases.
ExtractMarkers_multiSubs = read_c3d
markerstoC3D = markersto_c3d
TRCtoC3D = trc_to_c3d
