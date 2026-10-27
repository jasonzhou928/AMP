"""Trial cropping, recombination, and unlabeled-marker compaction."""

from __future__ import annotations

from collections import OrderedDict
from typing import Mapping, Sequence

import numpy as np

from ._utils import clone_trial, cmarker_names, occupied


def combine_unlabeled_markers(trial):
    """Greedily pack non-overlapping C-marker trajectories."""
    result = clone_trial(trial)
    names = cmarker_names(result.markers)
    records = []
    for order, name in enumerate(names):
        valid = occupied(result.markers[name])
        indices = np.flatnonzero(valid)
        if len(indices):
            records.append((int(indices[0]), order, name))
        else:
            del result.markers[name]
    bins: list[str] = []
    for _, _, name in sorted(records):
        if name not in result.markers:
            continue
        source_occ = occupied(result.markers[name])
        placed = False
        for target_name in bins:
            target_occ = occupied(result.markers[target_name])
            if not np.any(source_occ & target_occ):
                result.markers[target_name][source_occ] = result.markers[name][source_occ]
                del result.markers[name]
                placed = True
                break
        if not placed:
            bins.append(name)
    return result


def crop_trial_segments(trial, marker_set: Sequence[str], crop_length: int):
    """Split a trial into consecutive segments and synthesize missing markers."""
    if crop_length <= 0:
        raise ValueError("crop_length must be positive")
    marker_names = list(trial.markers)
    marker_names.extend(name for name in marker_set if name not in trial.markers)
    segments = OrderedDict()
    n_frames = len(trial.frame_numbers)
    for number, start in enumerate(range(0, n_frames, crop_length), 1):
        stop = min(start + crop_length, n_frames)
        indices = np.arange(start, stop)
        markers = OrderedDict()
        for name in marker_names:
            if name in trial.markers:
                markers[name] = trial.markers[name][indices].copy()
            else:
                markers[name] = np.full((len(indices), 3), np.nan)
        segment = clone_trial(trial, markers=markers)
        segment.frame_numbers = np.asarray(trial.frame_numbers)[indices].copy()
        segment.first_frame = int(segment.frame_numbers[0])
        segments[f"Seg_{number}"] = segment
    return segments


def combine_trial_segments(segments: Mapping[str, object] | Sequence[object]):
    """Reassemble crops and pack segment-local C markers into full trajectories."""
    if isinstance(segments, Mapping):
        def segment_number(name: object) -> int:
            digits = "".join(character for character in str(name) if character.isdigit())
            return int(digits or 0)

        values = [
            value
            for _, value in sorted(
                segments.items(), key=lambda item: segment_number(item[0])
            )
        ]
    else:
        values = list(segments)
    if not values:
        raise ValueError("At least one segment is required")
    first = values[0]
    useful_names = [name for name in first.markers if "C_" not in name]
    frame_numbers = np.concatenate([np.asarray(segment.frame_numbers)
                                    for segment in values])
    markers = OrderedDict(
        (name, np.concatenate([segment.markers[name] for segment in values], axis=0))
        for name in useful_names
    )
    result = clone_trial(first, markers=markers)
    result.frame_numbers = frame_numbers
    result.first_frame = int(frame_numbers[0])

    row_by_frame = {int(frame): row for row, frame in enumerate(frame_numbers)}
    packed: list[tuple[np.ndarray, np.ndarray]] = []
    for segment in values:
        for name in cmarker_names(segment.markers):
            data = segment.markers[name]
            valid = occupied(data)
            if not valid.any():
                continue
            rows = np.asarray([row_by_frame.get(int(frame), -1)
                               for frame in np.asarray(segment.frame_numbers)[valid]])
            keep = rows >= 0
            rows = rows[keep]
            coordinates = data[valid][keep]
            placed = False
            for packed_data, packed_occ in packed:
                if not packed_occ[rows].any():
                    packed_data[rows] = coordinates
                    packed_occ[rows] = True
                    placed = True
                    break
            if not placed:
                packed_data = np.full((len(frame_numbers), 3), np.nan)
                packed_occ = np.zeros(len(frame_numbers), dtype=bool)
                packed_data[rows] = coordinates
                packed_occ[rows] = True
                packed.append((packed_data, packed_occ))
    next_id = len(useful_names)
    for data, _ in packed:
        name = f"C_{next_id}"
        while name in useful_names:
            next_id += 1
            name = f"C_{next_id}"
        result.markers[name] = data
        next_id += 1
    return result


CombineUnlabeledMarkers = combine_unlabeled_markers
cropTrialsSegments = crop_trial_segments
combineTrialsSegments = combine_trial_segments
