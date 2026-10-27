# Python Vicon processing orchestration

`ViconProcessingPython` is the Python orchestration equivalent of
`RunMeCropped.m`. It keeps that script's three phases, output naming, file
filters, crop growth, repeat conditions, fill-until-stable loop, and overall
progress printing. MATLAB GUI progress bars, plotting/debug branches, and
commented one-off trial fixes are intentionally omitted.

## Installation

Install Python 3.10 or newer, then run from this folder (`Python/`):

```powershell
cd Python
py -m pip install -e ".[test]"
```

If `python` fails with `No application is associated with the specified file`,
PowerShell is resolving a non-Windows shim (for example `C:\cygwin64\bin\python`)
instead of a real interpreter. Use the `py` launcher, or call an interpreter by
full path such as `C:\Python313\python.exe`. List what is installed with
`py -0p`.

## Quick start

1. Copy `config.example.yaml` to `config.yaml`, then set `paths.data_dir` and
   `paths.static_trial`.
2. Preview selection without loading a C3D:

   ```powershell
   py -m ViconProcessingPython --config config.yaml --dry-run
   ```

3. Run all enabled phases:

   ```powershell
   py -m ViconProcessingPython --config config.yaml
   ```

Any value can be overridden with a repeatable dotted key:

```powershell
py -m ViconProcessingPython -c config.yaml `
  --set iteration.workers=4 `
  --set flags.qualisys=false
```

Convenience options include `--data-dir`, `--workers`, `--quiet`, and
`--phase preprocess|gap-fill|final-check`. Progress messages go to stderr so
the JSON report on stdout remains pipeable. Use `--quiet` or
`flags.progress=false` to disable them. Segment-level overall progress is
controlled by `flags.parallel_progress` and matches MATLAB's
`ParallelProgress` line (`trial | iteration N | crop M | workers a/n processes
| segments k/n (p%)`).
Use `workers: 1` for sequential, debug-friendly segment processing. YAML
loading uses PyYAML; JSON configuration works without PyYAML.

## Processing flow

### 1. Preprocess

Raw `.c3d` files are sorted deterministically, then static trials, skip-list
matches, and trials already having `_preprocessed` or `_filled` outputs are
excluded. The static trial supplies the reference marker geometry.

Each trial gets the initial relink pass, then starts with 301-frame segments.
Segments execute through persistent `ProcessPoolExecutor` workers when
`workers` is greater than one. Separate processes bypass Python's GIL and are
the equivalent of MATLAB `parfor`; they are started once per trial and reused
across crop iterations. Results are always merged in original segment order.
Crop length increases by 150 each iteration. As in MATLAB, iteration one always
causes another pass; later passes continue when any segment reports more than
one relink/fill operation. Missing clusters are checked after the second pass
or when processing settles, and the safety cap is 15 iterations. Successful
outputs are named `<trial>_preprocessed.c3d`.

### 2. Gap fill

For each logical trial without a `_filled` result, the `_preprocessed` input is
preferred over raw input. Missing first/last frames are filled, followed by
rigid-body filling, repeatedly until the backend reports no new fills. Outputs
are named `<trial>_filled.c3d`.

### 3. Final check

Every `_filled.c3d` is checked for absent markers or remaining NaNs from the
configured marker set. Incomplete trials are reported for manual repair.

The inventory is refreshed between phases so outputs made during the same run
become inputs to the next phase.

## Integration contract

The orchestration imports `ViconProcessingPython.io`, `.preprocessing`,
`.gapfill`, and optionally `.model` only when real C3D work begins. Dry runs and
configuration/file-filter tests therefore do not require C3D dependencies.
`DefaultBackend` accepts a small set of snake-case function aliases and filters
unsupported keyword arguments. For API changes, adapt only `DefaultBackend`;
the `Pipeline` itself can also receive a test or application backend implementing
the `Backend` protocol.

Segment preprocessing must return either:

- `SegmentResult(data, operations)`;
- `(data, operations)`; or
- data alone (treated as zero operations).

Rigid gap filling must return `(data, filled_any)`. Loaders may return data or
`(data, original_names)`.

## Exit status

The CLI prints a JSON report. Exit status is `0` when no manual work is found
and `2` when preprocessing failures or incompletely filled trials are reported.
Backend/import/C3D failures propagate with a nonzero Python exit.
