"""Coordinate transforms equivalent to ``Vicon.transform``."""

from __future__ import annotations

import numpy as np
import numpy.typing as npt


VICON_TO_OSIM = np.array(
    [[1.0, 0.0, 0.0], [0.0, 0.0, -1.0], [0.0, 1.0, 0.0]]
)


def transform_points(
    points: npt.ArrayLike, transform: str | npt.ArrayLike
) -> npt.NDArray[np.float64]:
    """Transform arrays ending in XYZ, preserving each NaN component.

    String transforms match MATLAB: ``"OsimXYZ"`` maps Vicon to OpenSim and
    ``"ViconXYZ"`` maps OpenSim back to Vicon. A 3x3 rotation or 4x4
    homogeneous transform may also be supplied.
    """
    values = np.asarray(points, dtype=float)
    if values.shape[-1] != 3:
        raise ValueError("points must have a final axis of length 3")

    translation = np.zeros(3)
    if isinstance(transform, str):
        name = transform.lower()
        if name == "osimxyz":
            rotation = VICON_TO_OSIM
        elif name == "viconxyz":
            rotation = VICON_TO_OSIM.T
        else:
            raise ValueError(f"unsupported coordinate system: {transform}")
    else:
        matrix = np.asarray(transform, dtype=float)
        if matrix.shape == (3, 3):
            rotation = matrix
        elif matrix.shape == (4, 4):
            rotation = matrix[:3, :3]
            translation = matrix[:3, 3]
        else:
            raise ValueError("transform must be a 3x3 or 4x4 matrix")

    missing = np.isnan(values)
    safe = np.where(missing, 0.0, values)
    result = safe @ rotation + translation
    result[missing] = np.nan
    return result


# Familiar name for callers migrating directly from MATLAB.
transform = transform_points
