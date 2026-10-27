"""Internal helpers shared by the preprocessing ports."""

from __future__ import annotations

from collections import OrderedDict
from copy import deepcopy
from typing import Iterable, Mapping, Sequence

import numpy as np


def clone_trial(trial, markers: Mapping[str, np.ndarray] | None = None, indices=None):
    """Copy a MarkerTrial without depending on a particular constructor."""
    out = trial.copy() if hasattr(trial, "copy") else deepcopy(trial)
    source = trial.markers if markers is None else markers
    out.markers = OrderedDict((name, np.array(value, dtype=float, copy=True))
                              for name, value in source.items())
    if indices is not None:
        idx = np.asarray(indices)
        out.markers = OrderedDict((name, value[idx].copy())
                                  for name, value in out.markers.items())
        out.frame_numbers = np.asarray(trial.frame_numbers)[idx].copy()
        if len(out.frame_numbers):
            out.first_frame = int(out.frame_numbers[0])
    else:
        out.frame_numbers = np.asarray(trial.frame_numbers).copy()
        if hasattr(trial, "metadata"):
            out.metadata = deepcopy(trial.metadata)
    return out


def occupied(data: np.ndarray) -> np.ndarray:
    """MATLAB parity: occupancy is determined from the second/x column."""
    return ~np.isnan(np.asarray(data)[:, 0])


def runs(mask: np.ndarray) -> np.ndarray:
    """Return inclusive, zero-based [start, end] runs."""
    padded = np.r_[False, np.asarray(mask, dtype=bool), False].astype(np.int8)
    transitions = np.diff(padded)
    return np.column_stack((np.flatnonzero(transitions == 1),
                            np.flatnonzero(transitions == -1) - 1))


def cmarker_names(markers: Mapping[str, np.ndarray]) -> list[str]:
    # MATLAB contains(..., 'C_'), not startsWith.
    return [name for name in markers if "C_" in name]


def next_cmarker_name(names: Iterable[str], next_id: int) -> tuple[str, int]:
    used = set(names)
    while f"C_{next_id}" in used:
        next_id += 1
    return f"C_{next_id}", next_id + 1


def threshold_for_cluster(thresholds, index: int) -> float:
    if np.isscalar(thresholds):
        return float(thresholds)
    return float(np.asarray(thresholds[index]).reshape(-1)[0])


def rigid_transform(source: np.ndarray, target: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Least-squares proper rigid transform, equivalent to absor."""
    source = np.asarray(source, dtype=float)
    target = np.asarray(target, dtype=float)
    if source.shape != target.shape or source.ndim != 2 or source.shape[1] != 3:
        raise ValueError("Rigid-body donor arrays must have shape (n, 3)")
    if source.shape[0] < 3 or np.isnan(source).any() or np.isnan(target).any():
        raise ValueError("At least three complete donors are required")
    source_center = source.mean(axis=0)
    target_center = target.mean(axis=0)
    u, _, vt = np.linalg.svd((source - source_center).T @
                             (target - target_center))
    rotation = vt.T @ u.T
    if np.linalg.det(rotation) < 0:
        vt[-1] *= -1
        rotation = vt.T @ u.T
    translation = target_center - source_center @ rotation.T
    return rotation, translation


def transform_point(point: np.ndarray, source: np.ndarray, target: np.ndarray) -> np.ndarray:
    rotation, translation = rigid_transform(source, target)
    return np.asarray(point) @ rotation.T + translation


def cluster_expansion(marker_set: Sequence[str],
                      clusters: Sequence[Sequence[str]]) -> list[str]:
    values: set[str] = set()
    requested = set(marker_set)
    for cluster in clusters:
        if requested.intersection(cluster):
            values.update(cluster)
    # MATLAB unique(cellstr) sorts.
    return sorted(values)
