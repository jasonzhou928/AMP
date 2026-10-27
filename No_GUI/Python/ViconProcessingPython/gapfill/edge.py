"""First/last-frame rigid fills translated from the RunMeCropped helper."""

from __future__ import annotations

from typing import Any, Iterable, Literal, Sequence

import numpy as np

from ._utils import clusters_for, copied_trial, transform_point, valid_rows
from .status import FillReport, FillStatus


def _present(data: np.ndarray) -> np.ndarray:
    """MATLAB trajectory presence checks use x, then validate xyz for fitting."""
    return ~np.isnan(np.asarray(data)[:, 0])


def _static_point(reference: Any, marker: str) -> np.ndarray:
    values = np.asarray(reference.markers[marker])
    valid = np.flatnonzero(valid_rows(values))
    if not valid.size:
        raise ValueError(f"Reference marker {marker!r} has no complete sample")
    return values[valid[0]]


def _fill_existing_edge(
    trial: Any,
    reference: Any,
    marker: str,
    clusters: list[list[str]],
    edge: int,
) -> tuple[int, str]:
    for cluster in clusters:
        if len(cluster) < 4:
            continue
        available = [name for name in cluster if name in trial.markers]
        complete = np.ones(len(trial.frame_numbers), dtype=bool)
        for name in cluster:
            if name not in trial.markers:
                complete[:] = False
                break
            complete &= _present(trial.markers[name])
        full_frames = np.flatnonzero(complete)
        if full_frames.size:
            anchor = int(full_frames[0] if edge == 0 else full_frames[-1])
            donors = [name for name in available if name != marker]
            donors = [
                name
                for name in donors
                if valid_rows(trial.markers[name])[[anchor, edge]].all()
            ]
            source = np.stack([trial.markers[name][anchor] for name in donors])
            target = np.stack([trial.markers[name][edge] for name in donors])
            trial.markers[marker][edge] = transform_point(
                trial.markers[marker][anchor], source, target
            )
            return 1, ""

        # MATLAB's static fallback uses the earliest frame with >=3 cluster
        # markers for the first edge, and the literal last frame for the last.
        counts = np.zeros(len(trial.frame_numbers), dtype=int)
        for name in available:
            counts += _present(trial.markers[name])
        candidates = np.flatnonzero(counts >= 3)
        target_index = (
            int(candidates[0])
            if edge == 0 and candidates.size
            else len(trial.frame_numbers) - 1
        )
        donors = [
            name
            for name in available
            if valid_rows(trial.markers[name])[target_index]
            and name in reference.markers
        ]
        source = np.stack([_static_point(reference, name) for name in donors])
        target = np.stack([trial.markers[name][target_index] for name in donors])
        trial.markers[marker][edge] = transform_point(
            _static_point(reference, marker), source, target
        )
        return 1, "Used static-reference fallback"
    return 0, "No cluster with at least four markers"


def _fill_missing_marker_anchor(
    trial: Any,
    reference: Any,
    marker: str,
    clusters: list[list[str]],
    edge: int,
) -> tuple[int, int, str]:
    choices: list[tuple[int, list[str]]] = []
    for cluster in clusters:
        donors = [name for name in cluster if name != marker and name in trial.markers]
        counts = np.zeros(len(trial.frame_numbers), dtype=int)
        for name in donors:
            counts += _present(trial.markers[name])
        candidates = np.flatnonzero(counts >= 3)
        if not candidates.size:
            continue
        anchor = int(candidates[0] if edge == 0 else candidates[-1])
        valid_donors = [
            name
            for name in donors
            if _present(trial.markers[name])[anchor] and name in reference.markers
        ]
        choices.append((anchor, valid_donors))
    if not choices:
        return -1, 0, "No frame has three available donors"
    anchor, donors = (
        min(choices, key=lambda item: item[0])
        if edge == 0
        else max(choices, key=lambda item: item[0])
    )
    source = np.stack([_static_point(reference, name) for name in donors])
    target = np.stack([trial.markers[name][anchor] for name in donors])
    trial.markers[marker][anchor] = transform_point(
        _static_point(reference, marker), source, target
    )
    return anchor, 1, "Created an internal anchor from static reference"


def fill_edges(
    trial: Any,
    reference: Any,
    clusters: Iterable[Iterable[str]],
    *,
    which: Literal["both", "first", "last"] = "both",
    marker_names: Sequence[str] | None = None,
) -> tuple[Any, FillReport]:
    """Fill literal first/last samples, including MATLAB's missing-marker path."""
    if which not in {"both", "first", "last"}:
        raise ValueError("which must be 'both', 'first', or 'last'")
    output = copied_trial(trial)
    report = FillReport()
    names = list(marker_names) if marker_names is not None else list(output.markers)
    cluster_lists = [list(cluster) for cluster in clusters]
    edges = ([0] if which == "first" else [-1] if which == "last" else [0, -1])

    for edge in edges:
        for marker in names:
            marker_clusters = clusters_for(marker, cluster_lists)
            if marker not in output.markers:
                report.add(
                    FillStatus(
                        marker,
                        "edge_rigid",
                        int(output.frame_numbers[edge]),
                        int(output.frame_numbers[edge]),
                        1,
                        0,
                        "skipped",
                        "Marker is absent from MarkerTrial",
                    )
                )
                continue
            data = output.markers[marker]
            complete_count = int(_present(data).sum())
            if complete_count > 1:
                if _present(data)[edge]:
                    continue
                try:
                    filled, message = _fill_existing_edge(
                        output, reference, marker, marker_clusters, edge
                    )
                except (ValueError, KeyError, np.linalg.LinAlgError):
                    filled, message = 0, "Rigid transform could not be estimated"
                frame = int(output.frame_numbers[edge])
            else:
                try:
                    anchor, filled, message = _fill_missing_marker_anchor(
                        output, reference, marker, marker_clusters, edge
                    )
                except (ValueError, KeyError, np.linalg.LinAlgError):
                    anchor, filled, message = -1, 0, "Static transform could not be estimated"
                frame = int(output.frame_numbers[anchor if anchor >= 0 else edge])
            report.add(
                FillStatus(
                    marker,
                    "edge_rigid",
                    frame,
                    frame,
                    1,
                    filled,
                    "filled" if filled else "skipped",
                    message,
                )
            )
    return output, report
