"""Client-side progress output equivalent to MATLAB ParallelProgress."""

from __future__ import annotations

import sys
import threading
from typing import TextIO


def log(message: str, *, stream: TextIO | None = None) -> None:
    """Print a standalone status line. Progress bars use stderr so JSON stays on stdout."""
    print(message, file=stream or sys.stderr, flush=True)


class SegmentProgress:
    """Rewrite one overall-progress line, matching ParallelProgress.m."""

    def __init__(
        self,
        total: int,
        label: str,
        *,
        workers: int = 1,
        worker_kind: str = "sequential",
        stream: TextIO | None = None,
    ) -> None:
        self.total = max(int(total), 0)
        self.label = label
        self.workers = max(int(workers), 1)
        self.worker_kind = worker_kind
        self.completed = 0
        self._stream = stream or sys.stderr
        self._lock = threading.Lock()
        self._last_length = 0
        self._active = True
        self._render()

    def increment(self) -> None:
        with self._lock:
            if not self._active:
                return
            self.completed = min(self.completed + 1, self.total)
            self._render()

    def finish(self) -> None:
        with self._lock:
            if not self._active:
                return
            self.completed = self.total
            self._render()
            self._stream.write("\n")
            self._stream.flush()
            self._active = False
            self._last_length = 0

    def _render(self) -> None:
        percent = 100.0 if self.total == 0 else 100.0 * self.completed / self.total
        remaining = max(self.total - self.completed, 0)
        active = min(self.workers, remaining)
        message = (
            f"{self.label} | workers {active}/{self.workers} {self.worker_kind} | "
            f"segments {self.completed}/{self.total} ({percent:3.0f}%)"
        )
        padding = " " * max(0, self._last_length - len(message))
        self._stream.write(f"\r{message}{padding}")
        self._stream.flush()
        self._last_length = len(message)
