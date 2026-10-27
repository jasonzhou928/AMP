"""Marker relinking methods translated from ``RunMeCropped.m`` helpers."""

from __future__ import annotations

from collections import OrderedDict
from typing import Mapping, Sequence

import numpy as np

from ._utils import (clone_trial, cluster_expansion, cmarker_names, occupied,
                     runs, threshold_for_cluster, transform_point)
from .segmentation import segment_markers


def replace_current_marker_with_cmarker(trial, current_marker: str,
                                        cmarker: str, indices):
    """Copy C-marker coordinates into a labeled marker at ``indices``."""
    result = clone_trial(trial)
    idx = np.asarray(indices, dtype=int)
    if current_marker not in result.markers:
        result.markers[current_marker] = result.markers[cmarker].copy()
    result.markers[current_marker][idx] = result.markers[cmarker][idx]
    return result


def _merge_and_delete(trial, target: str, source: str, indices):
    result = replace_current_marker_with_cmarker(trial, target, source, indices)
    del result.markers[source]
    return result


def relink_marker_segments(trial, marker_set: Sequence[str], *,
                           jump_threshold: float = 10.0):
    """Directly join non-overlapping C segments adjacent to labeled segments.

    Marker arrays are edited in a plain dictionary and written back once, because
    cloning the whole trial per merge dominates runtime on full-length trials.
    """
    result = clone_trial(trial)
    markers = OrderedDict(
        (name, np.asarray(value, dtype=float))
        for name, value in result.markers.items()
    )
    occupancy = {name: occupied(value) for name, value in markers.items()}
    relinked: set[str] = set()
    n_frames = len(result.frame_numbers)
    for name in marker_set:
        if name not in markers:
            continue
        found = True
        while found:
            found = False
            target = markers[name]
            target_occ = occupancy[name]
            endpoints = runs(target_occ).reshape(-1)
            candidates = cmarker_names(markers)
            for endpoint_number, current in enumerate(endpoints):
                check = int(current) + (-1 if endpoint_number % 2 == 0 else 1)
                if check < 0 or check >= n_frames:
                    continue
                for candidate in candidates:
                    source_occ = occupancy[candidate]
                    if (not source_occ[check] or source_occ[int(current)] or
                            np.any(source_occ & target_occ)):
                        continue
                    source = markers[candidate]
                    distance = np.linalg.norm(target[int(current)] - source[check])
                    if distance < jump_threshold:
                        indices = np.flatnonzero(source_occ)
                        target[indices] = source[indices]
                        occupancy[name] = occupied(target)
                        del markers[candidate]
                        del occupancy[candidate]
                        relinked.add(name)
                        found = True
                        break
                if found:
                    break
    result.markers = markers
    return result, sorted(relinked), bool(relinked)


def relink_trimmed_rigid_body(
    trial,
    reference_trial,
    clusters: Sequence[Sequence[str]],
    marker_set: Sequence[str],
    good_frames: Sequence[int] = (),
    good_frames_by_marker: Mapping[str, Sequence[int]] | None = None,
    cluster_jump_thresholds=10.0,
):
    """Relink C segments using a rigid-body position prediction."""
    result = clone_trial(trial)
    good_by_marker = good_frames_by_marker or {}
    relinked: set[str] = set()
    for name in cluster_expansion(marker_set, clusters):
        if name not in result.markers:
            continue
        if len(good_frames):
            good_frame = int(np.asarray(good_frames).reshape(-1)[0])
        elif name in good_by_marker and len(good_by_marker[name]):
            good_frame = int(np.asarray(good_by_marker[name]).reshape(-1)[0])
        else:
            good_frame = None
        relevant = [(i, [d for d in cluster if d != name])
                    for i, cluster in enumerate(clusters) if name in cluster]
        missing = np.flatnonzero(~occupied(result.markers[name]))
        for order in (missing, missing[::-1]):
            for frame in order:
                if occupied(result.markers[name])[frame]:
                    continue
                matched = False
                for cluster_index, donors in relevant:
                    available = [d for d in donors if d in result.markers and
                                 not np.isnan(result.markers[d][frame]).any()]
                    if len(available) < 3:
                        continue
                    if good_frame is not None:
                        source = np.asarray([result.markers[d][good_frame]
                                             for d in available])
                        point = result.markers[name][good_frame]
                    else:
                        source = np.asarray([reference_trial.markers[d][0]
                                             for d in available])
                        point = reference_trial.markers[name][0]
                    if np.isnan(source).any() or np.isnan(point).any():
                        source = np.asarray([reference_trial.markers[d][0]
                                             for d in available])
                        point = reference_trial.markers[name][0]
                    try:
                        predicted = transform_point(
                            point, source,
                            np.asarray([result.markers[d][frame] for d in available]))
                    except (ValueError, np.linalg.LinAlgError):
                        continue
                    threshold = threshold_for_cluster(
                        cluster_jump_thresholds, cluster_index)
                    target_occ = occupied(result.markers[name])
                    for candidate in cmarker_names(result.markers):
                        candidate_occ = occupied(result.markers[candidate])
                        if (not candidate_occ[frame] or
                                np.any(candidate_occ & target_occ)):
                            continue
                        distance = np.linalg.norm(
                            predicted - result.markers[candidate][frame])
                        if distance < threshold:
                            valid = np.flatnonzero(candidate_occ)
                            extent = np.arange(valid[0], valid[-1] + 1)
                            result = _merge_and_delete(
                                result, name, candidate, extent)
                            relinked.add(name)
                            matched = True
                            break
                    if matched:
                        break
    return result, sorted(relinked), bool(relinked)


def predict_future_positions(positions: np.ndarray, delta_t: float,
                             num_steps: int,
                             process_noise: float = 0.01,
                             measurement_noise: float = 0.1) -> np.ndarray:
    """Nine-state constant-acceleration Kalman helper from the MATLAB file."""
    positions = np.asarray(positions, dtype=float)
    valid = np.flatnonzero(~np.isnan(positions).any(axis=1))
    if not len(valid):
        raise ValueError("All position data are NaN")
    eye3 = np.eye(3)
    state = np.r_[positions[valid[0]], np.zeros(6)]
    transition = np.block([
        [eye3, delta_t * eye3, 0.5 * delta_t ** 2 * eye3],
        [np.zeros((3, 3)), eye3, delta_t * eye3],
        [np.zeros((3, 3)), np.zeros((3, 3)), eye3],
    ])
    observation = np.c_[eye3, np.zeros((3, 6))]
    noise_gain = np.vstack((0.5 * delta_t ** 2 * eye3,
                            delta_t * eye3, eye3))
    process_cov = process_noise * noise_gain @ noise_gain.T
    measurement_cov = measurement_noise * eye3
    covariance = np.eye(9)
    for measurement in positions[1:]:
        state = transition @ state
        covariance = transition @ covariance @ transition.T + process_cov
        if np.isnan(measurement).any():
            continue
        innovation = measurement - observation @ state
        innovation_cov = observation @ covariance @ observation.T + measurement_cov
        gain = covariance @ observation.T @ np.linalg.inv(innovation_cov)
        state = state + gain @ innovation
        covariance = (np.eye(9) - gain @ observation) @ covariance
    predicted = np.empty((num_steps, 3))
    for index in range(num_steps):
        state = transition @ state
        predicted[index] = state[:3]
    return predicted


def relink_trimmed_neighbor(trial, marker_set: Sequence[str], *,
                            max_gap: int = 10,
                            prediction_threshold: float = 25.0,
                            process_noise: float = 0.01,
                            measurement_noise: float = 0.1):
    """Relink nearby C segments using the MATLAB Kalman prediction."""
    result = clone_trial(trial)
    initial_segments = segment_markers(result)
    relinked: set[str] = set()
    n_frames = len(result.frame_numbers)
    for name in marker_set:
        if name not in result.markers:
            continue
        endpoints = initial_segments[name].reshape(-1)
        for endpoint_number, initial_endpoint in enumerate(endpoints):
            endpoint = int(initial_endpoint)
            found = True
            while found:
                found = False
                target = result.markers[name]
                target_occ = occupied(target)
                for candidate in cmarker_names(result.markers):
                    source = result.markers[candidate]
                    source_occ = occupied(source)
                    if np.any(source_occ & target_occ):
                        continue
                    candidate_endpoints = set(
                        segment_markers(result)[candidate].reshape(-1).tolist())
                    for gap in range(1, max_gap + 1):
                        before = endpoint_number % 2 == 0
                        check = endpoint - gap if before else endpoint + gap
                        if check < 0 or check >= n_frames or target_occ[check]:
                            continue
                        if not source_occ[check] or check not in candidate_endpoints:
                            continue
                        if before:
                            window = np.arange(endpoint, min(n_frames, endpoint + max_gap + 1))
                            input_data = target[window][::-1]
                        else:
                            window = np.arange(max(0, endpoint - max_gap), endpoint + 1)
                            input_data = target[window]
                        predicted = predict_future_positions(
                            input_data, 1.0, gap, process_noise, measurement_noise)
                        distance = np.linalg.norm(predicted - source[check], axis=1)
                        if float(distance.mean()) <= prediction_threshold:
                            valid = np.flatnonzero(source_occ)
                            extent = np.arange(valid[0], valid[-1] + 1)
                            result = _merge_and_delete(
                                result, name, candidate, extent)
                            endpoint = int(extent[0] if before else extent[-1])
                            relinked.add(name)
                            found = True
                            break
                    if found:
                        break
    return result, sorted(relinked), bool(relinked)


def relink_trimmed_pattern(
    trial,
    clusters: Sequence[Sequence[str]],
    marker_set: Sequence[str],
    *,
    singleton_threshold: float = 5.0,
    trajectory_threshold: float = 10.0,
    singleton_max_gap: int = 150,
):
    """Relink C segments whose motion matches another cluster marker."""
    result = clone_trial(trial)
    initial_segments = segment_markers(result)
    relinked: set[str] = set()
    n_frames = len(result.frame_numbers)
    for name in cluster_expansion(marker_set, clusters):
        if name not in result.markers:
            continue
        endpoints = initial_segments[name].reshape(-1)
        donor_groups = [[d for d in cluster if d != name]
                        for cluster in clusters if name in cluster]
        for endpoint_number, initial_endpoint in enumerate(endpoints):
            endpoint = int(initial_endpoint)
            found = True
            while found:
                found = False
                target = result.markers[name]
                target_occ = occupied(target)
                check_location = endpoint
                before = endpoint_number % 2 == 0
                if before:
                    start = 0 if endpoint_number == 0 else int(endpoints[endpoint_number - 1]) + 1
                    end = endpoint - 1
                else:
                    start = endpoint + 1
                    end = (n_frames - 1 if endpoint_number == len(endpoints) - 1
                           else int(endpoints[endpoint_number + 1]) - 1)
                if end < start:
                    break
                for donors in donor_groups:
                    for donor in donors:
                        if donor not in result.markers:
                            continue
                        donor_data = result.markers[donor]
                        if (np.isnan(donor_data[:, 0]).all() or
                                np.isnan(donor_data[start:end + 1, 0]).all()):
                            continue
                        predicted = target.copy()
                        predicted[start:end + 1] = (
                            target[check_location] + donor_data[start:end + 1]
                            - donor_data[check_location])
                        for candidate in cmarker_names(result.markers):
                            source = result.markers[candidate]
                            source_occ = occupied(source)
                            if (not source_occ[start:end + 1].any() or
                                    np.any(source_occ & target_occ)):
                                continue
                            predicted_values = predicted[source_occ]
                            if np.isnan(predicted_values).any():
                                continue
                            distance = np.linalg.norm(
                                predicted_values - source[source_occ], axis=1)
                            matches = ((len(distance) == 1 and
                                        distance[0] < singleton_threshold and
                                        end - start <= singleton_max_gap) or
                                       np.all(distance <= trajectory_threshold))
                            if matches:
                                valid = np.flatnonzero(source_occ)
                                extent = np.arange(valid[0], valid[-1] + 1)
                                result = _merge_and_delete(
                                    result, name, candidate, extent)
                                endpoint = int(extent[0] if before else extent[-1])
                                relinked.add(name)
                                found = True
                                break
                    # MATLAB continues through the remaining donors/clusters
                    # after one C-marker match, allowing multiple pattern
                    # merges during the same endpoint sweep.
    return result, sorted(relinked), bool(relinked)


replaceCurrentMarkersWithCMarkers = replace_current_marker_with_cmarker
relinkMarkerSegmentation = relink_marker_segments
relinkTrimmedMarkerSegmentationRigidBody = relink_trimmed_rigid_body
relinkTrimmedMarkerSegmentationNeighbor = relink_trimmed_neighbor
relinkTrimmedMarkerSegmentationPattern2 = relink_trimmed_pattern
