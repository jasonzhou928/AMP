"""Command-line interface for the Vicon processing pipeline."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Sequence

from .config import load_config
from .pipeline import PipelineReport, run_pipeline


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python -m ViconProcessingPython",
        description="Preprocess, gap-fill, and validate Vicon C3D trials.",
    )
    parser.add_argument(
        "-c", "--config", type=Path, help="YAML or JSON configuration path"
    )
    parser.add_argument(
        "--set",
        dest="overrides",
        action="append",
        default=[],
        metavar="KEY=VALUE",
        help="override a dotted configuration key (repeatable)",
    )
    parser.add_argument("--data-dir", type=Path, help="override paths.data_dir")
    parser.add_argument("--workers", type=int, help="override iteration.workers")
    parser.add_argument(
        "--dry-run", action="store_true", help="list phase inputs without reading C3D"
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="disable progress messages (JSON report is still printed)",
    )
    parser.add_argument(
        "--phase",
        choices=("all", "preprocess", "gap-fill", "final-check"),
        default="all",
        help="run only one phase",
    )
    return parser


def _report_dict(report: PipelineReport) -> dict[str, object]:
    return {
        "dry_run": report.dry_run,
        "planned": {
            phase: [str(path) for path in paths]
            for phase, paths in report.planned.items()
        },
        "processed": {
            phase: [str(path) for path in paths]
            for phase, paths in report.processed.items()
        },
        "failed_preprocessing": report.failed_preprocessing,
        "incomplete_filled": report.incomplete_filled,
    }


def main(argv: Sequence[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    overrides = list(args.overrides)
    if args.data_dir is not None:
        overrides.append(f"paths.data_dir={json.dumps(str(args.data_dir))}")
    if args.workers is not None:
        overrides.append(f"iteration.workers={args.workers}")
    if args.dry_run:
        overrides.append("flags.dry_run=true")
    if args.quiet:
        overrides.append("flags.progress=false")
        overrides.append("flags.parallel_progress=false")
    if args.phase != "all":
        enabled = {
            "preprocess": args.phase == "preprocess",
            "gap_fill": args.phase == "gap-fill",
            "final_check": args.phase == "final-check",
        }
        overrides.extend(
            f"flags.{name}={'true' if value else 'false'}"
            for name, value in enabled.items()
        )

    config = load_config(args.config, overrides)
    report = run_pipeline(config)
    print(json.dumps(_report_dict(report), indent=2))
    return 2 if report.failed_preprocessing or report.incomplete_filled else 0
