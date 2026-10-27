from __future__ import annotations

from collections import OrderedDict
from copy import deepcopy

import numpy as np

from ViconProcessingPython.gapfill import (
    fill_all_gaps,
    fill_edges,
    find_gaps,
    linear_fill,
    pattern_fill,
    rigid_body_fill,
)


class MarkerTrial:
    def __init__(self, markers, first_frame=101):
        self.markers = OrderedDict(
            (name, np.asarray(values, dtype=float).copy())
            for name, values in markers.items()
        )
        self.frame_numbers = np.arange(first_frame, first_frame + len(next(iter(markers.values()))))
        self.rate = 100.0
        self.first_frame = first_frame
        self.metadata = {"synthetic": True}

    def copy(self):
        return deepcopy(self)


def moving_rigid_trial(frames=12):
    local = {
        "target": np.array([0.2, 0.3, 0.7]),
        "d1": np.array([0.0, 0.0, 0.0]),
        "d2": np.array([1.0, 0.0, 0.0]),
        "d3": np.array([0.0, 1.0, 0.0]),
        "d4": np.array([0.0, 0.0, 1.0]),
    }
    trajectories = {name: [] for name in local}
    for frame in range(frames):
        angle = 0.08 * frame
        rotation = np.array(
            [
                [np.cos(angle), -np.sin(angle), 0.0],
                [np.sin(angle), np.cos(angle), 0.0],
                [0.0, 0.0, 1.0],
            ]
        )
        translation = np.array([0.3 * frame, -0.1 * frame, 0.05 * frame])
        for name, point in local.items():
            trajectories[name].append(rotation @ point + translation)
    return MarkerTrial(trajectories), MarkerTrial(
        {name: [point] for name, point in local.items()}, first_frame=1
    )


def test_find_gaps_returns_closed_frame_boundaries_and_ignores_edges():
    values = np.column_stack([np.arange(8.0)] * 3)
    values[0] = np.nan
    values[3:5] = np.nan
    values[-1] = np.nan
    trial = MarkerTrial({"m": values}, first_frame=20)

    assert find_gaps(trial) == {"m": [(22, 25)]}


def test_linear_fill_uses_frame_headers_and_does_not_mutate_input():
    values = np.column_stack([np.arange(6.0)] * 3)
    expected = values.copy()
    values[2:4] = np.nan
    trial = MarkerTrial({"m": values}, first_frame=50)

    result, status = linear_fill(trial, "m", 51, 54)

    np.testing.assert_allclose(result.markers["m"], expected)
    assert np.isnan(trial.markers["m"][2:4]).all()
    assert status.filled == status.requested == 2


def test_rigid_body_fill_reconstructs_rotating_body():
    trial, _ = moving_rigid_trial()
    expected = trial.markers["target"].copy()
    trial.markers["target"][3:8] = np.nan

    result, status = rigid_body_fill(
        trial, "target", ["d1", "d2", "d3", "d4"], 103, 109
    )

    np.testing.assert_allclose(result.markers["target"], expected, atol=1e-12)
    assert status.method == "rigid_body"
    assert status.state == "filled"
    assert status.filled == 5


def test_rigid_body_fill_reports_partial_donor_coverage():
    trial, _ = moving_rigid_trial()
    trial.markers["target"][3:8] = np.nan
    trial.markers["d1"][5] = np.nan
    trial.markers["d2"][5] = np.nan

    result, status = rigid_body_fill(
        trial, "target", ["d1", "d2", "d3", "d4"], 103, 109
    )

    assert np.isnan(result.markers["target"][5]).all()
    assert status.state == "partial"
    assert status.filled == 4


def test_pattern_fill_preserves_donor_deviation_from_endpoint_line():
    frames = np.arange(7.0)
    donor = np.column_stack([frames, frames**2, np.zeros(7)])
    target = donor + np.array([10.0, -3.0, 2.0])
    expected = target.copy()
    target[2:5] = np.nan
    trial = MarkerTrial({"target": target, "donor": donor})

    result, status = pattern_fill(trial, "target", "donor", 102, 106)

    np.testing.assert_allclose(result.markers["target"], expected)
    assert status.filled == 3


def test_edge_fill_uses_dynamic_complete_frame_transform():
    trial, reference = moving_rigid_trial()
    expected = trial.markers["target"].copy()
    trial.markers["target"][0] = np.nan

    result, report = fill_edges(
        trial,
        reference,
        [["target", "d1", "d2", "d3", "d4"]],
        which="first",
    )

    np.testing.assert_allclose(result.markers["target"][0], expected[0], atol=1e-12)
    assert report.filled_points == 1


def test_missing_marker_path_creates_static_anchors_for_internal_fill():
    trial, reference = moving_rigid_trial()
    expected = trial.markers["target"].copy()
    trial.markers["target"][:] = np.nan

    anchored, edge_report = fill_edges(
        trial, reference, [["target", "d1", "d2", "d3", "d4"]]
    )
    result, gap_report = fill_all_gaps(
        anchored, [["target", "d1", "d2", "d3", "d4"]]
    )

    np.testing.assert_allclose(result.markers["target"], expected, atol=1e-12)
    assert edge_report.filled_points == 2
    assert gap_report.filled_points == len(expected) - 2


def test_fill_all_gaps_falls_back_to_spline_when_rigid_donors_are_insufficient():
    frames = np.arange(12.0)
    values = np.column_stack([frames, 0.5 * frames, -frames])
    expected = values.copy()
    values[5:7] = np.nan
    trial = MarkerTrial({"target": values, "donor": expected + 1})

    result, report = fill_all_gaps(trial, [["target", "donor"]])

    np.testing.assert_allclose(result.markers["target"], expected, atol=1e-12)
    assert report.events[0].method == "spline"
    assert report.filled_points == 2
