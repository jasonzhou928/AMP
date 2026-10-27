"""Trajectory segmentation ports used by ``RunMeCropped.m``."""

from __future__ import annotations

from collections import OrderedDict
from typing import Mapping, Sequence

import numpy as np

from ._utils import clone_trial, cmarker_names, next_cmarker_name, occupied, runs


def segment_single_marker(trial, marker_names: Sequence[str]) -> dict[str, np.ndarray]:
    """Find inclusive non-NaN runs for requested markers."""
    return {
        name: (
            runs(occupied(trial.markers[name]))
            if name in trial.markers
            else np.empty((0, 2), dtype=int)
        )
        for name in marker_names
    }


def segment_markers(trial) -> dict[str, np.ndarray]:
    """Find inclusive non-NaN runs for every marker, preserving order."""
    return OrderedDict(
        (name, runs(occupied(data))) for name, data in trial.markers.items()
    )


def _jump_fragments(data: np.ndarray, start: int, end: int,
                    speed_threshold: float, acceleration_threshold: float,
                    all_fast_threshold: float) -> list[tuple[int, int]]:
    if start == end:
        return [(start, end)]
    values = data[start:end + 1]
    axis_steps = np.diff(values, axis=0)
    speed = np.linalg.norm(axis_steps, axis=1)
    if (len(speed) > 1 and np.any(np.abs(np.diff(speed)) > acceleration_threshold)
            and np.any(speed > speed_threshold)):
        jumps: list[int] = []
        padded_steps = np.vstack((axis_steps[0], axis_steps, axis_steps[-1]))
        for loc in np.flatnonzero(speed > speed_threshold):
            # Direct translation of diff(speedcheck(loc:end,:)) in MATLAB.
            if np.any(np.abs(np.diff(padded_steps[loc:], axis=0))
                      > acceleration_threshold):
                jumps.append(start + int(loc) + 1)
        bounds = sorted([start, end] +
                        [value for jump in jumps for value in (jump - 1, jump)])
        return [(bounds[i], bounds[i + 1]) for i in range(0, len(bounds), 2)]
    if len(speed) and np.all(speed > all_fast_threshold):
        return [(index, index) for index in range(start, end + 1)]
    return [(start, end)]


def segment_cmarker_jumps(
    trial,
    *,
    speed_threshold: float = 20.0,
    acceleration_threshold: float = 10.0,
    all_fast_threshold: float = 25.0,
):
    """Replace each C marker with pseudo-markers split at trajectory jumps."""
    result = clone_trial(trial)
    original_names = list(result.markers)
    next_id = len(original_names)
    for name in [n for n in original_names if "C_" in n]:
        source = result.markers[name]
        fragments: list[tuple[int, int]] = []
        for start, end in runs(occupied(source)):
            fragments.extend(_jump_fragments(
                source, int(start), int(end), speed_threshold,
                acceleration_threshold, all_fast_threshold))
        for start, end in fragments:
            fake_name, next_id = next_cmarker_name(result.markers, next_id)
            fragment = np.full_like(source, np.nan, dtype=float)
            fragment[start:end + 1] = source[start:end + 1]
            result.markers[fake_name] = fragment
        del result.markers[name]
    return result


def segment_marker_jumps(
    trial,
    reference_marker_set: Sequence[str],
    marker_segments: Mapping[str, np.ndarray] | None = None,
    good_frames: Sequence[int] = (),
    good_frames_by_marker: Mapping[str, Sequence[int]] | None = None,
    *,
    speed_threshold: float = 20.0,
    acceleration_threshold: float = 10.0,
    all_fast_threshold: float = 25.0,
):
    """Move untrusted labeled trajectory fragments into C pseudo-markers.

    Frame locations are zero-based array indices. As in MATLAB, a marker absent
    from ``good_frames_by_marker`` has every segment treated as untrusted.
    """
    result = clone_trial(trial)
    segments = segment_markers(result) if marker_segments is None else marker_segments
    global_good = set(np.asarray(good_frames, dtype=int).tolist())
    marker_good = good_frames_by_marker or {}
    reference_names = set(reference_marker_set)
    next_id = len(result.markers)
    changed = False
    for name in [n for n in list(result.markers) if "C_" not in n]:
        # MarkerTrial exposes views into one packed points matrix. Adding a
        # C-marker reallocates that matrix, so retain an owned copy and write it
        # back after all fragments have been added.
        source = result.markers[name].copy()
        selected: list[tuple[int, int]] = []
        for start, end in np.asarray(segments.get(name, []), dtype=int).reshape(-1, 2):
            candidates = _jump_fragments(
                source, int(start), int(end), speed_threshold,
                acceleration_threshold, all_fast_threshold)
            for first, last in candidates:
                if name not in marker_good:
                    selected.append((first, last))
                    continue
                location = set(range(first, last + 1))
                trusted = (bool(global_good.intersection(location)) or
                           bool(set(np.asarray(marker_good[name], dtype=int).tolist())
                                .intersection(location)))
                if name not in reference_names or not trusted:
                    selected.append((first, last))
        for start, end in selected:
            fake_name, next_id = next_cmarker_name(result.markers, next_id)
            fragment = np.full_like(source, np.nan, dtype=float)
            fragment[start:end + 1] = source[start:end + 1]
            result.markers[fake_name] = fragment
            source[start:end + 1] = np.nan
            changed = True
        if name not in reference_names and not occupied(source).any():
            del result.markers[name]
        else:
            result.markers[name] = source
    return result, changed


# MATLAB-compatible spellings retained for migration.
segmentSingleMarker = segment_single_marker
segmentMarkers = segment_markers
CmarkerJumpSegmentation = segment_cmarker_jumps
markerJumpSegmentation = segment_marker_jumps
