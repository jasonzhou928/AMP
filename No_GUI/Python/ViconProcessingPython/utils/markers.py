"""Marker dictionary and label helpers used by ``RunMeCropped.m``."""

from __future__ import annotations

import re
from collections.abc import Mapping, Sequence

import numpy as np
import numpy.typing as npt

from ..model import MarkerTrial


_QUALISYS_UNLABELED = re.compile(r"^U(\d+)$")
_INTERNAL_UNLABELED = re.compile(r"^C_(\d+)$")


def marker_trial_to_dict(
    trial: MarkerTrial, *, include_header: bool = False
) -> dict[str, npt.NDArray[np.float64]]:
    """Convert a trial to independent marker arrays.

    With ``include_header=True``, values are ``(frame, x, y, z)`` arrays,
    matching the dictionaries built by ``markerStruct2dict.m``.
    """
    result: dict[str, npt.NDArray[np.float64]] = {}
    for index, label in enumerate(trial.labels):
        coordinates = trial.points[:, index, :].copy()
        if include_header:
            coordinates = np.column_stack((trial.frames, coordinates))
        result[label] = coordinates
    return result


def marker_dict_to_trial(
    markers: Mapping[str, npt.ArrayLike],
    *,
    rate: float,
    first_frame: int | None = None,
    units: str = "mm",
    coordinate_system: str = "osim",
) -> MarkerTrial:
    """Convert marker arrays, optionally containing a MATLAB frame header."""
    converted: dict[str, npt.NDArray[np.float64]] = {}
    inferred_first = first_frame
    frame_columns: list[npt.NDArray[np.float64]] = []
    for label, value in markers.items():
        array = np.asarray(value, dtype=float)
        if array.ndim != 2 or array.shape[1] not in (3, 4):
            raise ValueError("marker arrays must have shape (frames, 3) or (frames, 4)")
        if array.shape[1] == 4:
            frame_columns.append(array[:, 0])
            if inferred_first is None and len(array):
                inferred_first = int(array[0, 0])
            array = array[:, 1:]
        converted[label] = array
    if frame_columns and any(
        not np.array_equal(column, frame_columns[0]) for column in frame_columns[1:]
    ):
        raise ValueError("marker frame headers do not match")
    return MarkerTrial.from_marker_dict(
        converted,
        rate=rate,
        first_frame=1 if inferred_first is None else inferred_first,
        units=units,
        coordinate_system=coordinate_system,
    )


def get_marker_coordinates(
    markers: MarkerTrial | Mapping[str, npt.ArrayLike],
    marker_name: str,
    frame_indices: int | Sequence[int] | npt.NDArray[np.integer],
) -> npt.NDArray[np.float64]:
    """Return coordinates as ``(3, n)``; unknown markers return ``(3, 1)`` NaNs.

    ``frame_indices`` are zero-based Python indices. Mapping values may be
    either XYZ arrays or MATLAB-style ``(frame, x, y, z)`` arrays.
    """
    if isinstance(markers, MarkerTrial):
        if marker_name not in markers.labels:
            return np.full((3, 1), np.nan)
        values = markers.points[:, markers.index(marker_name), :]
    else:
        if marker_name not in markers:
            return np.full((3, 1), np.nan)
        values = np.asarray(markers[marker_name], dtype=float)
        if values.ndim != 2 or values.shape[1] not in (3, 4):
            raise ValueError("marker array must have 3 or 4 columns")
        values = values[:, -3:]
    selected = np.asarray(values[np.atleast_1d(frame_indices)], dtype=float)
    return selected.T


def rename_qualisys_unlabeled(labels: Sequence[str]) -> tuple[str, ...]:
    """Map exact Qualisys unlabeled names ``U12`` to internal ``C_12``."""
    return tuple(_QUALISYS_UNLABELED.sub(r"C_\1", label) for label in labels)


def restore_qualisys_unlabeled(labels: Sequence[str]) -> tuple[str, ...]:
    """Map exact internal unlabeled names ``C_12`` back to ``U12``."""
    return tuple(_INTERNAL_UNLABELED.sub(r"U\1", label) for label in labels)


def parse_c3d_labels(
    labels: Sequence[str], *, multi_subject: bool = False
) -> tuple[tuple[str, ...], tuple[str, ...]]:
    """Return processing labels and unchanged originals from C3D labels."""
    originals = tuple(str(label) for label in labels)
    if multi_subject:
        # MATLAB removes the colon while processing and reconstructs it on
        # export. Retaining the subject avoids collisions between subjects
        # that use the same marker name.
        parsed = tuple(label.replace(":", "_").replace("*", "C_") for label in originals)
    else:
        parsed = tuple(label.replace("*", "C_") for label in originals)
    if len(set(parsed)) != len(parsed):
        raise ValueError(
            "subject-prefix removal produced duplicate labels; retain subject prefixes"
        )
    return parsed, originals


def restore_original_labels(
    labels: Sequence[str],
    original_by_processing_label: Mapping[str, str],
    *,
    default_subject: str = "",
) -> tuple[str, ...]:
    """Recreate the label restoration behavior used for multi-subject trials."""
    restored = []
    for label in labels:
        if label in original_by_processing_label:
            restored.append(original_by_processing_label[label])
        elif label.startswith("C_"):
            restored.append(label)
        else:
            restored.append(f"{default_subject}_{label}")
    return tuple(restored)


def format_c3d_labels(
    labels: Sequence[str], *, multi_subject: bool = False
) -> tuple[str, ...]:
    """Convert processing labels to the labels written by the MATLAB exporters."""
    formatted = []
    for label in labels:
        label = label.replace("C_", "*")
        if multi_subject and "_" in label:
            subject, marker = label.rsplit("_", 1)
            label = f"{subject}:{marker}"
        formatted.append(label)
    return tuple(formatted)


# Direct migration aliases.
markerStruct2dict = marker_trial_to_dict
markerdict2struct = marker_dict_to_trial
getMarkerCoordinates = get_marker_coordinates
