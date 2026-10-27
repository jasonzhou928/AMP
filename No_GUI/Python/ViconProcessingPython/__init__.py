"""Core Python translation of the marker dependencies in ``RunMeCropped.m``."""

from .io import markersto_c3d, read_c3d, trc_to_c3d, write_c3d
from .model import MarkerTrial
from .utils import (
    Registration,
    RegistrationErrors,
    absor,
    format_c3d_labels,
    get_marker_coordinates,
    marker_dict_to_trial,
    marker_trial_to_dict,
    parse_c3d_labels,
    rename_qualisys_unlabeled,
    restore_original_labels,
    restore_qualisys_unlabeled,
    transform_points,
)

__all__ = [
    "MarkerTrial",
    "Registration",
    "RegistrationErrors",
    "absor",
    "format_c3d_labels",
    "get_marker_coordinates",
    "marker_dict_to_trial",
    "marker_trial_to_dict",
    "markersto_c3d",
    "parse_c3d_labels",
    "read_c3d",
    "rename_qualisys_unlabeled",
    "restore_original_labels",
    "restore_qualisys_unlabeled",
    "transform_points",
    "trc_to_c3d",
    "write_c3d",
]
