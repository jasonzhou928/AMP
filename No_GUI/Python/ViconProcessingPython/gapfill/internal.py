"""Internal-gap fills matching the MATLAB/Vicon routines used by RunMeCropped."""

from __future__ import annotations

from typing import Any, Iterable, Sequence

import numpy as np
from scipy.interpolate import PchipInterpolator

from ._utils import copied_trial, frame_index
from .status import FillReport, FillStatus


def find_gaps(trial: Any) -> dict[str, list[tuple[int, int]]]:
    """Return closed boundaries around each internal NaN run.

    Leading and trailing missing runs are intentionally omitted. MATLAB's
    ``Vicon.findGaps`` uses the x coordinate as the missing-data signal.
    """
    frames = np.asarray(trial.frame_numbers)
    result: dict[str, list[tuple[int, int]]] = {}
    for name, values in trial.markers.items():
        missing = np.isnan(np.asarray(values)[:, 0])
        changes = np.diff(np.r_[False, missing, False].astype(np.int8))
        starts = np.flatnonzero(changes == 1)
        ends = np.flatnonzero(changes == -1) - 1
        result[name] = [
            (int(frames[start - 1]), int(frames[end + 1]))
            for start, end in zip(starts, ends)
            if start > 0 and end + 1 < len(frames)
        ]
    return result


def _status(
    marker: str,
    method: str,
    start: int,
    end: int,
    requested: int,
    filled: int,
    message: str = "",
) -> FillStatus:
    state = "filled" if filled == requested else ("partial" if filled else "skipped")
    return FillStatus(marker, method, start, end, requested, filled, state, message)


def _indices(trial: Any, start_frame: int, end_frame: int) -> tuple[int, int]:
    start = frame_index(trial, start_frame)
    end = frame_index(trial, end_frame)
    if end <= start + 1:
        raise ValueError("Gap boundaries must enclose at least one frame")
    return start, end


def rigid_body_fill(
    trial: Any,
    marker: str,
    donors: Sequence[str],
    start_frame: int,
    end_frame: int,
) -> tuple[Any, FillStatus]:
    """Fill using Vicon's two-endpoint rigid-body interpolation algorithm."""
    output = copied_trial(trial)
    start, end = _indices(output, start_frame, end_frame)
    requested = end - start - 1
    target = output.markers[marker]
    if np.isnan(target[[start, end]]).any():
        raise ValueError("Fill trajectory has no data at a gap endpoint")
    if len(donors) < 3:
        raise ValueError("At least three donors are required")

    donor_data = np.stack([np.asarray(output.markers[name], dtype=float) for name in donors])
    endpoint_good = ~np.isnan(donor_data[:, [start, end], :]).any(axis=(1, 2))
    donor_data = donor_data[endpoint_good]
    if len(donor_data) < 3:
        raise ValueError("Fewer than three donors have both gap endpoints")

    filled = 0
    for index in range(start + 1, end):
        valid = ~np.isnan(donor_data[:, index, :]).any(axis=1)
        if valid.sum() < 3:
            continue
        current = donor_data[valid, index, :]
        current_center = current.mean(axis=0)
        estimates = []
        for endpoint in (end, start):
            endpoint_points = donor_data[valid, endpoint, :]
            endpoint_center = endpoint_points.mean(axis=0)
            covariance = (endpoint_points - endpoint_center).T @ (
                current - current_center
            )
            u, _, vt = np.linalg.svd(covariance)
            correction = np.eye(3)
            if np.linalg.det(u @ vt) < 0:
                correction[2, 2] = -1
            rotation = vt.T @ correction @ u.T
            estimates.append(
                rotation @ (target[endpoint] - endpoint_center) + current_center
            )
        weight = (index - start) / (end - start)
        target[index] = estimates[0] * weight + estimates[1] * (1.0 - weight)
        filled += 1
    return output, _status(
        marker,
        "rigid_body",
        start_frame,
        end_frame,
        requested,
        filled,
        "Fewer than three donors on some frames" if filled < requested else "",
    )


def pattern_fill(
    trial: Any,
    marker: str,
    donors: str | Sequence[str],
    start_frame: int,
    end_frame: int,
) -> tuple[Any, FillStatus]:
    output = copied_trial(trial)
    start, end = _indices(output, start_frame, end_frame)
    target = output.markers[marker]
    candidates = [donors] if isinstance(donors, str) else list(donors)
    candidates = [
        name
        for name in candidates
        if not np.isnan(output.markers[name][start + 1 : end]).all()
    ]
    if not candidates:
        raise ValueError("No donor has data inside the gap")
    distances = [
        (
            np.linalg.norm(output.markers[name][start] - target[start])
            + np.linalg.norm(output.markers[name][end] - target[end])
        )
        / 2
        for name in candidates
    ]
    donor = np.asarray(output.markers[candidates[int(np.nanargmin(distances))]])
    if np.isnan(donor[[start, end]]).any() or np.isnan(target[[start, end]]).any():
        raise ValueError("Pattern fill requires complete endpoints")

    weight = ((np.arange(start, end + 1) - start) / (end - start))[:, None]
    donor_line = donor[start] + weight * (donor[end] - donor[start])
    target_line = target[start] + weight * (target[end] - target[start])
    values = target_line + donor[start : end + 1] - donor_line
    valid = ~np.isnan(values).any(axis=1)
    target[start : end + 1][valid] = values[valid]
    requested = end - start - 1
    filled = int(valid[1:-1].sum())
    return output, _status(
        marker, "pattern", start_frame, end_frame, requested, filled
    )


def spline_fill(
    trial: Any,
    marker: str,
    start_frame: int,
    end_frame: int,
    *,
    max_error: float = 30.0,
) -> tuple[Any, FillStatus]:
    """PCHIP fill with the MATLAB forward/backward jump safeguard."""
    output = copied_trial(trial)
    start, end = _indices(output, start_frame, end_frame)
    frames = np.asarray(output.frame_numbers, dtype=float)
    values = output.markers[marker]
    radius = 3
    if start - radius < 0:
        radius = start
    elif end + radius >= len(frames):
        radius = len(frames) - 1 - end
    refs = np.r_[np.arange(start - radius, start + 1), np.arange(end, end + radius + 1)]
    if len(np.unique(refs)) < 2 or np.isnan(values[refs]).any():
        raise ValueError("Spline reference frames contain missing data")
    estimate = PchipInterpolator(frames[refs], values[refs], axis=0)(
        frames[start : end + 1]
    )

    forward_error = np.inf
    backward_error = np.inf
    before = np.flatnonzero(frames < start_frame)
    if len(before) > radius:
        refs_forward = before[-radius:]
        line = np.polyfit(frames[refs_forward], values[refs_forward], 1)
        extrapolated = np.array(
            [np.polyval(line[:, coordinate], end_frame) for coordinate in range(3)]
        )
        forward_error = np.linalg.norm(estimate[-1] - extrapolated)
    else:
        after = np.flatnonzero(frames > end_frame)
        if len(after) > radius:
            refs_backward = after[:radius]
            line = np.polyfit(frames[refs_backward], values[refs_backward], 1)
            extrapolated = np.array(
                [np.polyval(line[:, coordinate], start_frame) for coordinate in range(3)]
            )
            # MATLAB compares a(end,:) here, including this historical quirk.
            backward_error = np.linalg.norm(estimate[-1] - extrapolated)
    requested = end - start - 1
    if min(forward_error, backward_error) >= max_error:
        return output, _status(
            marker,
            "spline",
            start_frame,
            end_frame,
            requested,
            0,
            "Jump safeguard rejected interpolation",
        )
    values[start : end + 1] = estimate
    return output, _status(
        marker, "spline", start_frame, end_frame, requested, requested
    )


def linear_fill(
    trial: Any,
    marker: str,
    start_frame: int,
    end_frame: int,
) -> tuple[Any, FillStatus]:
    output = copied_trial(trial)
    start, end = _indices(output, start_frame, end_frame)
    target = output.markers[marker]
    if np.isnan(target[[start, end]]).any():
        raise ValueError("Linear fill requires complete endpoints")
    weight = ((np.arange(start + 1, end) - start) / (end - start))[:, None]
    target[start + 1 : end] = target[start] + weight * (target[end] - target[start])
    requested = end - start - 1
    return output, _status(
        marker, "linear", start_frame, end_frame, requested, requested
    )


def fill_all_gaps(
    trial: Any,
    clusters: Iterable[Iterable[str]],
    marker_names: Sequence[str] | None = None,
) -> tuple[Any, FillReport]:
    """Perform one MATLAB ``Rigid_Body_Fill_All_Gaps`` pass."""
    output = copied_trial(trial)
    report = FillReport()
    names = list(marker_names) if marker_names is not None else list(output.markers)
    cluster_lists = [list(cluster) for cluster in clusters]

    for marker in names:
        for cluster in cluster_lists:
            if marker not in cluster:
                continue
            donors = [name for name in cluster if name != marker and name in output.markers]
            for start_frame, end_frame in list(find_gaps(output).get(marker, [])):
                span = end_frame - start_frame
                try:
                    candidate, status = rigid_body_fill(
                        output, marker, donors, start_frame, end_frame
                    )
                    output = candidate
                    report.add(status)
                    continue
                except (ValueError, KeyError, np.linalg.LinAlgError):
                    pass

                status = None
                if span <= 10:
                    try:
                        candidate, status = spline_fill(
                            output, marker, start_frame, end_frame, max_error=30
                        )
                        if status.filled:
                            output = candidate
                        elif span <= 3:
                            # MATLAB proceeds to LinearFill after a rejected
                            # spline only for these shortest gaps.
                            status = None
                    except (ValueError, np.linalg.LinAlgError):
                        status = None
                if status is None and 10 < span <= 30:
                    try:
                        candidate, status = pattern_fill(
                            output, marker, donors, start_frame, end_frame
                        )
                        output = candidate
                    except (ValueError, KeyError):
                        status = None
                if status is None and span <= 3:
                    try:
                        candidate, status = linear_fill(
                            output, marker, start_frame, end_frame
                        )
                        output = candidate
                    except ValueError:
                        status = None
                if status is None:
                    requested = frame_index(output, end_frame) - frame_index(
                        output, start_frame
                    ) - 1
                    status = FillStatus(
                        marker,
                        "none",
                        start_frame,
                        end_frame,
                        requested,
                        0,
                        "skipped",
                        "No MATLAB fallback could fill the gap",
                    )
                report.add(status)
            if not find_gaps(output).get(marker):
                break
    return output, report
