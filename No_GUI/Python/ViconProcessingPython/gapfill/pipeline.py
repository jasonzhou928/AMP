"""RunMeCropped-compatible endpoint/internal gap-fill loop."""

from __future__ import annotations

from typing import Any, Iterable, Sequence

from .edge import fill_edges
from .internal import fill_all_gaps
from .status import FillReport, FillStatus


def fill_runme_gaps(
    trial: Any,
    reference: Any,
    clusters: Iterable[Iterable[str]],
    marker_names: Sequence[str] | None = None,
    *,
    max_passes: int = 100,
) -> tuple[Any, FillReport]:
    """Repeat edge and internal fills as done at RunMeCropped lines 497-500."""
    output = trial.copy()
    report = FillReport()
    cluster_lists = [list(cluster) for cluster in clusters]
    for _ in range(max_passes):
        output, edge_report = fill_edges(
            output,
            reference,
            cluster_lists,
            marker_names=marker_names,
        )
        report.extend(edge_report)
        output, internal_report = fill_all_gaps(
            output, cluster_lists, marker_names=marker_names
        )
        report.extend(internal_report)
        # MATLAB's loop flag is only set by an attempted internal fill.
        if not internal_report.changed:
            return output, report
    report.add(
        FillStatus(
            "",
            "pipeline",
            int(output.frame_numbers[0]),
            int(output.frame_numbers[-1]),
            0,
            0,
            "failed",
            f"Did not converge after {max_passes} passes",
        )
    )
    return output, report
