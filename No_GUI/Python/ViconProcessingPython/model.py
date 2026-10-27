"""In-memory representation of a marker-only motion-capture trial."""

from __future__ import annotations

from collections.abc import Iterator, MutableMapping
from copy import deepcopy
from dataclasses import dataclass, field, replace
from typing import Mapping

import numpy as np
import numpy.typing as npt


FloatArray = npt.NDArray[np.floating]


class _MarkerMap(MutableMapping[str, FloatArray]):
    """Live ``label -> (frames, 3)`` view used by preprocessing and gap-fill."""

    def __init__(self, trial: "MarkerTrial") -> None:
        self._trial = trial

    def __iter__(self) -> Iterator[str]:
        return iter(self._trial.labels)

    def __len__(self) -> int:
        return self._trial.n_markers

    def __getitem__(self, key: str) -> FloatArray:
        return self._trial.points[:, self._trial.index(key), :]

    def __setitem__(self, key: str, value: npt.ArrayLike) -> None:
        array = np.asarray(value, dtype=float)
        if array.ndim != 2 or array.shape[1] != 3:
            raise ValueError("each marker value must have shape (frames, 3)")
        trial = self._trial
        if key in trial.labels:
            if array.shape[0] != trial.n_frames:
                raise ValueError("replacement marker length must match the trial")
            trial.points[:, trial.index(key), :] = array
            return
        if trial.n_markers and array.shape[0] != trial.n_frames:
            raise ValueError("new markers must match the existing frame count")
        points = (
            array[:, None, :]
            if trial.n_markers == 0
            else np.concatenate([trial.points, array[:, None, :]], axis=1)
        )
        trial.points = points
        trial.labels = trial.labels + (str(key),)
        if trial.original_labels is not None:
            trial.original_labels = trial.original_labels + (str(key),)

    def __delitem__(self, key: str) -> None:
        trial = self._trial
        index = trial.index(key)
        trial.points = np.delete(trial.points, index, axis=1)
        trial.labels = trial.labels[:index] + trial.labels[index + 1 :]
        if trial.original_labels is not None:
            trial.original_labels = (
                trial.original_labels[:index] + trial.original_labels[index + 1 :]
            )


@dataclass(slots=True)
class MarkerTrial:
    """Marker coordinates and the C3D metadata needed by the processing pipeline.

    ``points`` has shape ``(frames, markers, 3)`` in the selected coordinate
    system. Missing observations are represented by three NaNs.
    """

    points: FloatArray
    labels: tuple[str, ...]
    rate: float
    first_frame: int = 1
    units: str = "mm"
    coordinate_system: str = "osim"
    original_labels: tuple[str, ...] | None = None
    metadata: dict[str, object] = field(default_factory=dict)

    def __post_init__(self) -> None:
        points = np.asarray(self.points, dtype=float)
        if points.ndim != 3 or points.shape[2] != 3:
            raise ValueError("points must have shape (frames, markers, 3)")
        self.labels = tuple(str(label) for label in self.labels)
        if points.shape[1] != len(self.labels):
            raise ValueError("the marker axis must match the number of labels")
        if len(set(self.labels)) != len(self.labels):
            raise ValueError("labels must be unique")
        if not np.isfinite(self.rate) or self.rate <= 0:
            raise ValueError("rate must be a positive finite number")
        if not isinstance(self.first_frame, (int, np.integer)):
            raise TypeError("first_frame must be an integer")
        if self.original_labels is not None:
            self.original_labels = tuple(str(label) for label in self.original_labels)
            if len(self.original_labels) != len(self.labels):
                raise ValueError("original_labels must align with labels")
        self.points = points
        self.rate = float(self.rate)
        self.first_frame = int(self.first_frame)
        self.units = str(self.units)
        self.coordinate_system = self.coordinate_system.lower()

    @property
    def n_frames(self) -> int:
        return self.points.shape[0]

    @property
    def n_markers(self) -> int:
        return self.points.shape[1]

    @property
    def last_frame(self) -> int:
        return self.first_frame + self.n_frames - 1

    @property
    def frames(self) -> npt.NDArray[np.int_]:
        return np.arange(self.first_frame, self.last_frame + 1, dtype=int)

    @property
    def frame_numbers(self) -> npt.NDArray[np.int_]:
        """Alias used by the MATLAB-oriented preprocessing/gap-fill APIs."""
        return self.frames

    @frame_numbers.setter
    def frame_numbers(self, value: npt.ArrayLike) -> None:
        numbers = np.asarray(value)
        if numbers.size:
            self.first_frame = int(numbers[0])

    @property
    def markers(self) -> MutableMapping[str, FloatArray]:
        """Mutable mapping expected by preprocessing and gap-fill."""
        return _MarkerMap(self)

    @markers.setter
    def markers(self, mapping: Mapping[str, npt.ArrayLike]) -> None:
        labels = tuple(str(label) for label in mapping)
        arrays = [np.asarray(mapping[label], dtype=float) for label in mapping]
        if any(array.ndim != 2 or array.shape[1] != 3 for array in arrays):
            raise ValueError("each marker value must have shape (frames, 3)")
        if arrays and len({array.shape[0] for array in arrays}) != 1:
            raise ValueError("all markers must have the same frame count")
        points = np.stack(arrays, axis=1) if arrays else np.empty((0, 0, 3))
        if self.original_labels is not None:
            by_label = dict(zip(self.labels, self.original_labels))
            self.original_labels = tuple(by_label.get(label, label) for label in labels)
        self.labels = labels
        self.points = points

    def copy(self) -> "MarkerTrial":
        """Deep-copy points and metadata so in-place edits stay local."""
        return replace(
            self,
            points=np.array(self.points, copy=True),
            original_labels=(
                None if self.original_labels is None else tuple(self.original_labels)
            ),
            metadata=deepcopy(self.metadata),
        )

    def index(self, label: str) -> int:
        try:
            return self.labels.index(label)
        except ValueError as exc:
            raise KeyError(label) from exc

    def with_points(self, points: FloatArray, **changes: object) -> "MarkerTrial":
        """Return a trial with new points while retaining its metadata."""
        return replace(self, points=np.asarray(points, dtype=float), **changes)

    @classmethod
    def from_marker_dict(
        cls,
        markers: Mapping[str, npt.ArrayLike],
        *,
        rate: float,
        first_frame: int = 1,
        units: str = "mm",
        coordinate_system: str = "osim",
    ) -> "MarkerTrial":
        """Build a trial from ``label -> (frames, 3)`` arrays."""
        labels = tuple(markers)
        arrays = [np.asarray(markers[label], dtype=float) for label in labels]
        if any(array.ndim != 2 or array.shape[1] != 3 for array in arrays):
            raise ValueError("each marker value must have shape (frames, 3)")
        if arrays and len({array.shape[0] for array in arrays}) != 1:
            raise ValueError("all markers must have the same frame count")
        points = np.stack(arrays, axis=1) if arrays else np.empty((0, 0, 3))
        return cls(points, labels, rate, first_frame, units, coordinate_system)
