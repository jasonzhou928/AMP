from collections import OrderedDict
from copy import deepcopy

import numpy as np

from ViconProcessingPython.preprocessing import (
    check_for_missing_clusters,
    combine_trial_segments,
    combine_unlabeled_markers,
    crop_trial_segments,
    find_a_good_frame,
    relink_marker_segments,
    relink_trimmed_pattern,
    relink_trimmed_rigid_body,
    segment_cmarker_jumps,
    segment_marker_jumps,
    segment_markers,
    segment_single_marker,
)


class MarkerTrial:
    def __init__(self, markers, frames=None, rate=100.0):
        self.markers = OrderedDict(
            (name, np.asarray(data, dtype=float).copy())
            for name, data in markers.items()
        )
        length = len(next(iter(self.markers.values()))) if self.markers else 0
        self.frame_numbers = np.arange(length) if frames is None else np.asarray(frames)
        self.rate = rate
        self.first_frame = int(self.frame_numbers[0]) if length else 0
        self.metadata = {"source": "synthetic"}

    def copy(self):
        return deepcopy(self)


def test_segment_markers_returns_inclusive_zero_based_runs():
    trial = MarkerTrial({"A": [[np.nan] * 3, [1, 2, 3], [2, 3, 4],
                                [np.nan] * 3, [5, 6, 7]]})
    np.testing.assert_array_equal(segment_markers(trial)["A"],
                                  [[1, 2], [4, 4]])
    missing = segment_single_marker(trial, ["A", "MISSING"])
    assert missing["MISSING"].shape == (0, 2)


def test_cmarker_jump_segmentation_splits_and_removes_source():
    trial = MarkerTrial({"C_0": [[0, 0, 0], [1, 0, 0], [2, 0, 0],
                                  [102, 0, 0], [103, 0, 0]]})
    result = segment_cmarker_jumps(trial)
    assert "C_0" not in result.markers
    assert len(result.markers) == 2
    assert [np.flatnonzero(~np.isnan(data[:, 0])).tolist()
            for data in result.markers.values()] == [[0, 1, 2], [3, 4]]


def test_marker_jump_keeps_fragments_containing_good_frame():
    points = np.array([[0, 0, 0], [1, 0, 0], [2, 0, 0]], float)
    trial = MarkerTrial({"A": points})
    result, changed = segment_marker_jumps(
        trial, ["A"], good_frames=[1], good_frames_by_marker={"A": [1]})
    assert not changed
    np.testing.assert_array_equal(result.markers["A"], points)


def test_marker_jump_removes_untrusted_fragment_from_packed_marker_trial():
    # Regression: adding C_* reallocates MarkerTrial.points. The labeled
    # marker must be written back after fragment creation, not mutated through
    # a detached pre-allocation view.
    from ViconProcessingPython.model import MarkerTrial as PackedMarkerTrial

    points = np.array(
        [[[0, 0, 0]], [[1, 0, 0]], [[2, 0, 0]],
         [[102, 0, 0]], [[103, 0, 0]]],
        dtype=float,
    )
    trial = PackedMarkerTrial(points, ("A",), 125.0)

    result, changed = segment_marker_jumps(
        trial,
        ["A"],
        good_frames=[],
        good_frames_by_marker={"A": [0]},
    )

    assert changed
    assert not np.isnan(result.markers["A"][:3]).any()
    assert np.isnan(result.markers["A"][3:]).all()
    c_names = [name for name in result.markers if "C_" in name]
    assert len(c_names) == 1
    np.testing.assert_allclose(result.markers[c_names[0]][3:, 0], [102, 103])


def test_direct_relink_joins_adjacent_nonoverlapping_cmarker():
    nan = [np.nan] * 3
    trial = MarkerTrial({
        "A": [[0, 0, 0], [1, 0, 0], nan, nan],
        "C_1": [nan, nan, [2, 0, 0], [3, 0, 0]],
    })
    result, names, changed = relink_marker_segments(
        trial, ["A"], jump_threshold=2)
    assert changed and names == ["A"] and "C_1" not in result.markers
    np.testing.assert_allclose(result.markers["A"][:, 0], [0, 1, 2, 3])


def test_rigid_body_relink_uses_good_frame_geometry():
    static = {
        "A": [[0, 0, 0], [np.nan] * 3],
        "B": [[1, 0, 0], [11, 0, 0]],
        "C": [[0, 1, 0], [10, 1, 0]],
        "D": [[0, 0, 1], [10, 0, 1]],
        "C_4": [[np.nan] * 3, [10, 0, 0]],
    }
    trial = MarkerTrial(static)
    reference = MarkerTrial({name: [data[0]] for name, data in static.items()
                             if name != "C_4"})
    result, names, changed = relink_trimmed_rigid_body(
        trial, reference, [["A", "B", "C", "D"]], ["A"],
        good_frames=[0], cluster_jump_thresholds=[0.1])
    assert changed and names == ["A"] and "C_4" not in result.markers
    np.testing.assert_allclose(result.markers["A"][1], [10, 0, 0])


def test_pattern_relink_matches_donor_motion():
    nan = [np.nan] * 3
    trial = MarkerTrial({
        "A": [[0, 0, 0], nan, nan],
        "B": [[5, 0, 0], [6, 0, 0], [7, 0, 0]],
        "C_2": [nan, [1, 0, 0], [2, 0, 0]],
    })
    result, names, changed = relink_trimmed_pattern(
        trial, [["A", "B"]], ["A"])
    assert changed and names == ["A"]
    np.testing.assert_allclose(result.markers["A"][:, 0], [0, 1, 2])


def test_pattern_relink_checks_all_donors_in_one_endpoint_sweep():
    nan = [np.nan] * 3
    trial = MarkerTrial({
        "A": [[0, 0, 0], nan, nan],
        "B": [[0, 0, 0], [1, 0, 0], nan],
        "D": [[0, 0, 0], nan, [2, 0, 0]],
        "C_3": [nan, [1, 0, 0], nan],
        "C_4": [nan, nan, [2, 0, 0]],
    })

    result, names, changed = relink_trimmed_pattern(
        trial, [["A", "B", "D"]], ["A"]
    )

    assert changed and names == ["A"]
    np.testing.assert_allclose(result.markers["A"][:, 0], [0, 1, 2])
    assert "C_3" not in result.markers
    assert "C_4" not in result.markers


def test_good_frame_and_missing_cluster_rules():
    reference_points = OrderedDict([
        ("A", [[0, 0, 0]]), ("B", [[1, 0, 0]]),
        ("C", [[0, 1, 0]]), ("D", [[0, 0, 1]]),
    ])
    trial = MarkerTrial({
        name: np.asarray(value) + [10, 20, 30]
        for name, value in reference_points.items()
    })
    reference = MarkerTrial(reference_points)
    good, errors = find_a_good_frame(
        trial, list(reference_points), reference,
        [list(reference_points)], [0.01])
    np.testing.assert_array_equal(good, [0])
    assert np.max(errors) < 1e-10
    missing, clusters = check_for_missing_clusters(
        MarkerTrial({"A": [[np.nan] * 3]}), [["A", "B", "C", "D", "E"]])
    assert missing and clusters == [["A", "B", "C", "D", "E"]]


def test_crop_combine_and_unlabeled_compaction_preserve_frames():
    nan = [np.nan] * 3
    trial = MarkerTrial(
        {"A": [[0, 0, 0], [1, 0, 0], [2, 0, 0], [3, 0, 0]],
         "C_1": [[9, 0, 0], nan, [8, 0, 0], nan]},
        frames=[101, 102, 103, 104],
    )
    segments = crop_trial_segments(trial, ["A", "B"], 2)
    assert list(segments) == ["Seg_1", "Seg_2"]
    assert np.isnan(segments["Seg_1"].markers["B"]).all()
    combined = combine_trial_segments(segments)
    np.testing.assert_array_equal(combined.frame_numbers, trial.frame_numbers)
    assert combined.first_frame == 101
    c_names = [name for name in combined.markers if "C_" in name]
    assert len(c_names) == 1
    np.testing.assert_allclose(
        combined.markers[c_names[0]][[0, 2], 0], [9, 8]
    )

    reversed_segments = OrderedDict(reversed(list(segments.items())))
    reversed_combined = combine_trial_segments(reversed_segments)
    np.testing.assert_array_equal(
        reversed_combined.frame_numbers, trial.frame_numbers
    )
    np.testing.assert_allclose(reversed_combined.markers["A"], trial.markers["A"])

    packed = combine_unlabeled_markers(MarkerTrial({
        "C_0": [[1, 0, 0], nan, nan],
        "C_1": [nan, [2, 0, 0], nan],
        "C_2": [[3, 0, 0], nan, nan],
    }))
    assert list(packed.markers) == ["C_0", "C_2"]
    np.testing.assert_allclose(packed.markers["C_0"][:2, 0], [1, 2])
