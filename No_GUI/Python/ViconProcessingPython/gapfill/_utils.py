"""Shared numerical helpers."""

from __future__ import annotations

from typing import Any, Iterable

import numpy as np


def copied_trial(trial: Any) -> Any:
    """Use MarkerTrial.copy while tolerating copy implementations with kwargs."""
    return trial.copy()


def frame_index(trial: Any, frame: int) -> int:
    indices = np.flatnonzero(np.asarray(trial.frame_numbers) == frame)
    if indices.size == 0:
        raise ValueError(f"Frame {frame} is not in the trial")
    return int(indices[0])


def valid_rows(data: np.ndarray) -> np.ndarray:
    return ~np.isnan(data).any(axis=1)


def rigid_transform(source: np.ndarray, target: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """Horn/Kabsch rigid transform mapping source points onto target points."""
    source = np.asarray(source, dtype=float)
    target = np.asarray(target, dtype=float)
    if source.shape != target.shape or source.ndim != 2 or source.shape[1] != 3:
        raise ValueError("Rigid-transform point sets must have matching (n, 3) shapes")
    if source.shape[0] < 3:
        raise ValueError("At least three donor points are required")
    source_center = source.mean(axis=0)
    target_center = target.mean(axis=0)
    covariance = (source - source_center).T @ (target - target_center)
    u, _, vt = np.linalg.svd(covariance)
    rotation = vt.T @ u.T
    if np.linalg.det(rotation) < 0:
        vt[-1] *= -1
        rotation = vt.T @ u.T
    translation = target_center - rotation @ source_center
    return rotation, translation


def transform_point(point: np.ndarray, source: np.ndarray, target: np.ndarray) -> np.ndarray:
    rotation, translation = rigid_transform(source, target)
    return rotation @ np.asarray(point, dtype=float) + translation


def clusters_for(marker: str, clusters: Iterable[Iterable[str]]) -> list[list[str]]:
    return [list(cluster) for cluster in clusters if marker in cluster]
