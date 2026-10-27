"""Structured outcomes for gap-filling operations."""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Literal


FillState = Literal["filled", "partial", "skipped", "failed"]


@dataclass(frozen=True)
class FillStatus:
    marker: str
    method: str
    start_frame: int
    end_frame: int
    requested: int
    filled: int
    state: FillState
    message: str = ""


@dataclass
class FillReport:
    events: list[FillStatus] = field(default_factory=list)

    @property
    def filled_points(self) -> int:
        return sum(event.filled for event in self.events)

    @property
    def filled_gaps(self) -> int:
        return sum(event.state == "filled" for event in self.events)

    @property
    def changed(self) -> bool:
        return self.filled_points > 0

    def add(self, status: FillStatus) -> FillStatus:
        self.events.append(status)
        return status

    def extend(self, other: "FillReport") -> None:
        self.events.extend(other.events)
