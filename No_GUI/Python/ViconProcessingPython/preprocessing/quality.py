"""Good-frame and missing-cluster checks."""

from __future__ import annotations

from collections import OrderedDict, Counter
from typing import Sequence

import numpy as np

from ._utils import occupied, threshold_for_cluster, transform_point


def _cluster_errors(trial, reference, cluster: Sequence[str], frame: int):
    errors: dict[str, float] = {}
    present = [name for name in cluster
               if name in trial.markers and
               not np.isnan(trial.markers[name][frame]).any()]
    if len(present) < 4:
        return errors
    for name in present:
        donors = [other for other in present if other != name]
        try:
            predicted = transform_point(
                reference.markers[name][0],
                np.asarray([reference.markers[d][0] for d in donors]),
                np.asarray([trial.markers[d][frame] for d in donors]),
            )
        except (KeyError, ValueError, np.linalg.LinAlgError):
            continue
        errors[name] = float(np.linalg.norm(predicted - trial.markers[name][frame]))
    return errors


def find_a_good_frame(
    trial,
    marker_set: Sequence[str],
    reference_trial,
    clusters: Sequence[Sequence[str]],
    cluster_jump_thresholds,
):
    """Return frames where all requested markers and rigid bodies are valid."""
    good: list[int] = []
    all_errors: list[float] = []
    for frame in range(len(trial.frame_numbers)):
        if any(name not in trial.markers or
               np.isnan(trial.markers[name][frame]).any()
               for name in marker_set):
            continue
        jumped: list[bool] = []
        for index, cluster in enumerate(clusters):
            if len(cluster) < 4:
                continue
            errors = _cluster_errors(trial, reference_trial, cluster, frame)
            threshold = threshold_for_cluster(cluster_jump_thresholds, index)
            all_errors.extend(errors.values())
            jumped.extend(error >= threshold for error in errors.values())
        if jumped and not any(jumped):
            good.append(frame)
    return np.asarray(good, dtype=int), np.asarray(all_errors, dtype=float)


def find_a_good_frame_by_cluster(
    trial,
    marker_set: Sequence[str],
    reference_trial,
    clusters: Sequence[Sequence[str]],
    cluster_jump_thresholds,
    good_frame_reference: Sequence[int] = (),
    segment_name: str = "",
):
    """Return valid frame indices per marker using rigid-body consensus."""
    modified = [list(cluster) for cluster in clusters if len(cluster) >= 4]
    frequency = Counter(name for cluster in modified for name in cluster)
    good: OrderedDict[str, list[int]] = OrderedDict()
    all_errors: list[float] = []
    for frame in range(len(trial.frame_numbers)):
        frame_counts: Counter[str] = Counter()
        for index, cluster in enumerate(clusters):
            if len(cluster) < 4 and len(good_frame_reference) == 0:
                for name in cluster:
                    good.setdefault(name, [])
                continue
            errors = _cluster_errors(trial, reference_trial, cluster, frame)
            threshold = threshold_for_cluster(cluster_jump_thresholds, index)
            all_errors.extend(errors.values())
            passing = [name for name, error in errors.items() if error < threshold]
            if len(passing) >= 3:
                frame_counts.update(passing)
        for name, count in frame_counts.items():
            if count == frequency[name] or count >= 2:
                good.setdefault(name, []).append(frame)

    clustered = {name for cluster in modified for name in cluster}
    missing = False
    for name in marker_set:
        if name not in trial.markers:
            good.setdefault(name, [])
            missing = True
            continue
        indices = np.flatnonzero(occupied(trial.markers[name]))
        if len(indices) == 0:
            missing = True
        elif segment_name == "Seg_1" and name not in clustered:
            good.setdefault(name, [int(indices[0])])
    output = OrderedDict((name, np.asarray(values, dtype=int))
                         for name, values in good.items())
    return output, np.asarray(all_errors, dtype=float), missing


def check_for_missing_clusters(trial, clusters: Sequence[Sequence[str]]):
    """Match MATLAB's fatal missing-cluster rule."""
    missing_clusters: list[list[str]] = []
    for cluster in clusters:
        missing_count = sum(
            name not in trial.markers or not occupied(trial.markers[name]).any()
            for name in cluster
        )
        if (missing_count == len(cluster) or
                (len(cluster) > 4 and len(cluster) - missing_count <= 2)):
            missing_clusters.append(list(cluster))
    return bool(missing_clusters), missing_clusters


FindAGoodFrame = find_a_good_frame
FindAGoodFrameByCluster = find_a_good_frame_by_cluster
checkForMissingClusters = check_for_missing_clusters
