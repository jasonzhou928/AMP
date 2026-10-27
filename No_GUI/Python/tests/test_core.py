from __future__ import annotations

import numpy as np
import pytest

from ViconProcessingPython import (
    MarkerTrial,
    absor,
    format_c3d_labels,
    get_marker_coordinates,
    marker_dict_to_trial,
    marker_trial_to_dict,
    parse_c3d_labels,
    rename_qualisys_unlabeled,
    read_c3d,
    restore_qualisys_unlabeled,
    transform_points,
    write_c3d,
)
from ViconProcessingPython.io.c3d import _point_labels


def test_marker_trial_and_dictionary_round_trip_preserve_frame_metadata() -> None:
    points = np.array(
        [
            [[1.0, 2.0, 3.0], [np.nan, np.nan, np.nan]],
            [[4.0, 5.0, 6.0], [7.0, 8.0, 9.0]],
        ]
    )
    trial = MarkerTrial(points, ("RASI", "C_1"), 125.0, 42, "mm", "osim")

    marker_dict = marker_trial_to_dict(trial, include_header=True)
    rebuilt = marker_dict_to_trial(marker_dict, rate=trial.rate, units=trial.units)

    assert rebuilt.labels == trial.labels
    assert rebuilt.first_frame == 42
    assert rebuilt.last_frame == 43
    np.testing.assert_equal(rebuilt.points, trial.points)
    np.testing.assert_equal(
        get_marker_coordinates(rebuilt, "RASI", [0, 1]),
        np.array([[1.0, 4.0], [2.0, 5.0], [3.0, 6.0]]),
    )
    assert np.isnan(get_marker_coordinates(rebuilt, "unknown", 0)).all()


def test_vicon_osim_transform_round_trip_preserves_nan_components() -> None:
    vicon = np.array([[[1.0, 2.0, 3.0], [np.nan, 5.0, 6.0]]])
    osim = transform_points(vicon, "OsimXYZ")

    np.testing.assert_equal(osim[0, 0], [1.0, 3.0, -2.0])
    assert np.isnan(osim[0, 1, 0])
    np.testing.assert_equal(transform_points(osim, "ViconXYZ"), vicon)


def test_homogeneous_transform_applies_translation_per_point() -> None:
    matrix = np.eye(4)
    matrix[:3, 3] = [10.0, 20.0, 30.0]
    result = transform_points([[1.0, 2.0, 3.0]], matrix)
    np.testing.assert_allclose(result, [[11.0, 22.0, 33.0]])


def test_unlabeled_and_multi_subject_label_round_trips() -> None:
    assert rename_qualisys_unlabeled(("U1", "U20x", "RASI")) == (
        "C_1",
        "U20x",
        "RASI",
    )
    assert restore_qualisys_unlabeled(("C_1", "C_x", "RASI")) == (
        "U1",
        "C_x",
        "RASI",
    )

    processing, originals = parse_c3d_labels(
        ("Alice:RASI", "Bob:RASI", "Alice:*12"), multi_subject=True
    )
    assert processing == ("Alice_RASI", "Bob_RASI", "Alice_C_12")
    assert originals == ("Alice:RASI", "Bob:RASI", "Alice:*12")
    assert format_c3d_labels(processing, multi_subject=True) == originals


def test_absor_recovers_rigid_transform_and_scale() -> None:
    source = np.array(
        [[0.0, 1.0, 0.0, 1.0], [0.0, 0.0, 1.0, 1.0], [0.0, 0.0, 0.0, 1.0]]
    )
    rotation = np.array([[0.0, -1.0, 0.0], [1.0, 0.0, 0.0], [0.0, 0.0, 1.0]])
    target = 2.5 * rotation @ source + np.array([[5.0], [-2.0], [3.0]])

    registration, fitted, errors = absor(source, target, scale=True)

    np.testing.assert_allclose(registration.rotation, rotation, atol=1e-12)
    np.testing.assert_allclose(registration.translation, [5.0, -2.0, 3.0])
    assert registration.scale == pytest.approx(2.5)
    np.testing.assert_allclose(fitted, target, atol=1e-12)
    assert errors.least_squares < 1e-12


def test_marker_trial_rejects_ambiguous_data() -> None:
    with pytest.raises(ValueError, match="shape"):
        MarkerTrial(np.zeros((2, 3)), ("A",), 100)
    with pytest.raises(ValueError, match="unique"):
        MarkerTrial(np.zeros((2, 2, 3)), ("A", "A"), 100)


def test_reconcile_labels_drops_stale_blocks_and_names_extra_points() -> None:
    from ViconProcessingPython.io.c3d import _reconcile_labels

    # MATLAB rewrote a smaller trial but left U213/U214 in POINT:LABELS2.
    assert _reconcile_labels(["A", "B", "U213", "U214"], 2) == ["A", "B"]
    assert _reconcile_labels(["A"], 1) == ["A"]

    padded = _reconcile_labels(["A", "*1"], 4)
    assert padded[:2] == ["A", "*1"]
    assert len(padded) == 4
    assert len(set(padded)) == 4


def test_point_labels_collects_numbered_c3d_parameters_in_order() -> None:
    c3d = {
        "parameters": {
            "POINT": {
                "LABELS2": {"value": ["C", "D"]},
                "LABELS": {"value": ["A", "B"]},
                "LABELS_TRANSLATIONS": {"value": ["ignored"]},
            }
        }
    }

    assert _point_labels(c3d) == ["A", "B", "C", "D"]


def test_write_shrinks_reference_label_blocks_and_residuals(tmp_path) -> None:
    pytest.importorskip("ezc3d")
    # A reference with >255 points splits labels into LABELS/LABELS2; writing a
    # smaller trial must not leave the reference's extra block behind.
    frames, wide = 3, 300
    reference = MarkerTrial(
        np.ones((frames, wide, 3)),
        tuple(f"M{index}" for index in range(wide)),
        125.0,
    )
    reference_path = write_c3d(
        reference, tmp_path / "reference", use_original_labels=False
    )

    points = np.ones((frames, 4, 3))
    points[1, 2] = np.nan
    subset = MarkerTrial(points, ("A", "B", "C", "D"), 125.0)

    output = write_c3d(
        subset,
        tmp_path / "subset",
        reference_path=reference_path,
        use_original_labels=False,
    )
    rebuilt = read_c3d(output)

    assert rebuilt.labels == subset.labels
    np.testing.assert_array_equal(
        np.isnan(rebuilt.points).any(axis=2), np.isnan(points).any(axis=2)
    )


def test_generated_c3d_round_trip_preserves_core_metadata(tmp_path) -> None:
    pytest.importorskip("ezc3d")
    points = np.array(
        [
            [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]],
            [[7.0, 8.0, 9.0], [np.nan, np.nan, np.nan]],
        ]
    )
    trial = MarkerTrial(
        points,
        ("Alice_RASI", "Alice_C_12"),
        125.0,
        42,
        "mm",
        "osim",
    )

    path = write_c3d(
        trial,
        tmp_path / "roundtrip",
        multi_subject=True,
        use_original_labels=False,
    )
    rebuilt = read_c3d(path, multi_subject=True)

    assert rebuilt.labels == trial.labels
    assert rebuilt.first_frame == trial.first_frame
    assert rebuilt.rate == trial.rate
    assert rebuilt.units == trial.units
    np.testing.assert_allclose(rebuilt.points, trial.points, equal_nan=True, atol=1e-5)
