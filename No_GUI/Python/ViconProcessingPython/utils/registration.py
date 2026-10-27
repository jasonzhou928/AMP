"""Least-squares rigid/similarity registration translated from ``absor.m``."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
import numpy.typing as npt


@dataclass(frozen=True, slots=True)
class Registration:
    rotation: npt.NDArray[np.float64]
    translation: npt.NDArray[np.float64]
    scale: float
    matrix: npt.NDArray[np.float64]


@dataclass(frozen=True, slots=True)
class RegistrationErrors:
    least_squares: float
    maximum: float


def absor(
    source: npt.ArrayLike,
    target: npt.ArrayLike,
    *,
    scale: bool = False,
    translate: bool = True,
    weights: npt.ArrayLike | None = None,
) -> tuple[Registration, npt.NDArray[np.float64], RegistrationErrors]:
    """Fit ``scale * rotation @ source + translation`` to ``target``.

    Inputs follow MATLAB ``absor`` and have shape ``(2|3, n_points)``.
    """
    a = np.asarray(source, dtype=float)
    b = np.asarray(target, dtype=float)
    if a.shape != b.shape or a.ndim != 2 or a.shape[0] not in (2, 3):
        raise ValueError("source and target must have matching (2|3, n) shapes")
    if a.shape[1] == 0:
        raise ValueError("at least one point is required")
    if not np.isfinite(a).all() or not np.isfinite(b).all():
        raise ValueError("registration inputs must be finite")

    unweighted = weights is None
    if unweighted:
        normalized = np.full(a.shape[1], 1.0 / a.shape[1])
        original_sum = float(a.shape[1])
    else:
        raw = np.asarray(weights, dtype=float).reshape(-1)
        if raw.size != a.shape[1] or not np.isfinite(raw).all() or np.any(raw < 0):
            raise ValueError("weights must be finite, nonnegative, and match points")
        original_sum = float(raw.sum())
        if original_sum <= 0:
            raise ValueError("weights must have a positive sum")
        normalized = raw / original_sum

    if translate:
        source_center = a @ normalized
        target_center = b @ normalized
    else:
        source_center = np.zeros(a.shape[0])
        target_center = np.zeros(a.shape[0])
    left = (a - source_center[:, None]) * np.sqrt(normalized)[None, :]
    right = (b - target_center[:, None]) * np.sqrt(normalized)[None, :]

    # Orthogonal Procrustes with a proper (non-reflecting) rotation.
    covariance = right @ left.T
    u, _, vt = np.linalg.svd(covariance)
    correction = np.eye(a.shape[0])
    correction[-1, -1] = np.sign(np.linalg.det(u @ vt))
    rotation = u @ correction @ vt

    fitted_scale = 1.0
    if scale:
        denominator = float(np.sum(left * left))
        if denominator == 0:
            raise ValueError("cannot estimate scale from coincident source points")
        fitted_scale = float(np.sum(right * (rotation @ left)) / denominator)
    translation = (
        target_center - fitted_scale * rotation @ source_center
        if translate
        else np.zeros(a.shape[0])
    )
    fitted = fitted_scale * rotation @ a + translation[:, None]
    residual = np.linalg.norm(fitted - b, axis=0)
    weighted_residual = residual * np.sqrt(normalized)
    errors = RegistrationErrors(
        least_squares=float(np.linalg.norm(weighted_residual) * np.sqrt(original_sum)),
        maximum=float(np.max(residual if unweighted else weighted_residual)),
    )
    homogeneous = np.eye(a.shape[0] + 1)
    homogeneous[:-1, :-1] = fitted_scale * rotation
    homogeneous[:-1, -1] = translation
    registration = Registration(rotation, translation, fitted_scale, homogeneous)
    return registration, fitted, errors
