# AMP: Headless MATLAB Processing Pipeline

This folder contains the headless, batch-processing MATLAB implementation of AMP (Automated Mocap Processing). It performs automated trajectory label scrubbing, mislabel detection, and kinematic gap filling across large optical motion capture datasets without requiring the graphical interface.

---

## Prerequisites

* **MATLAB Version:** R2023b or later (requires native `dictionary` support).
* **Required Toolboxes:**
  * **Parallel Computing Toolbox** (for multi-core trial batching in `RunMeCropped.m`)
  * **Signal Processing Toolbox** (required for underlying filter routines and [MoCapTools](https://github.com/JonathanCamargo/MoCapTools))
  * **Instrument Control Toolbox** (used for progress monitoring)

---

## Repository Structure

```text
No_GUI/Matlab/
├── MoCapTools/         # Core kinematic and gap-filling utilities
├── RunMe.m             # Sequential trial-by-trial pipeline runner
├── RunMeCropped.m      # Optimized parallel batch runner (recommended)
├── batchProcessing.m   # Batch execution helper routines
└── README.md           # Folder documentation
