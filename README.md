This package automates batch processing of motion capture trials using **MATLAB and Vicon Nexus**. It reconstructs trials, validates marker quality, attempts automatic relabeling of mislabeled clusters, fills gaps, filters trajectories, and exports finalized data.

Please share your opinions and feedback in this google form:
https://docs.google.com/forms/d/e/1FAIpQLSeFoyuN_JxNqxFMBNQTuTzEhFaveEHVCXbFz8rQkv4R-thgQQ/viewform

---

# System Requirements

* **Windows only**
* **MATLAB R2025a or later**
* **Vicon Nexus**
* MATLAB must be able to locate **Nexus.exe**

---

# Processing Workflow

## 1. Organize Your Data

Each workspace folder should contain:

* Motion trials (`.c3d`)
* A **Static trial**
* **Functional Joint Calibration (FJC)** trials (if used)
* The appropriate **markerset**

The pipeline must be able to identify **static trials** using either:

* A **naming keyword** (ex: `Static`), or
* A **manual list of static file paths**

---

# 2. Prepare Static Trial in Vicon

Open the **Static trial** in **Vicon Nexus**.

### Label All Markers

1. Open the **Labeling workspace** in Nexus.
2. Run **Reconstruct** if needed to generate trajectories.
3. Use **Autolabel** to automatically label markers.
4. Inspect the marker labels and correct any mistakes manually.

You should confirm that:

* All markers are correctly labeled.
* No markers are unlabeled or mislabeled.

---

### Set Region of Interest (ROI) to 2 Frames and clear events outside ROI

The static calibration must only use **two frames**.

1. Right-click on the **Timeline** bar in Vicon, and select **Set Region of Interest** then set inital frame to 1 and final fram to 2 and click 'OK'.
2. Right-click on the **Timeline** bar again and select **Clear Events** -> **Clear Events Outside Region of Interest**.

This ensures the static pose used for calibration is consistent.

---

### Run Static Calibration Pipelines

In the **Tools panel** on the right side of Nexus click on the **settings icon** and select the **Subject Calibration** drop down menu

Run the following pipelines in order:

1. **Static Skeleton Calibration**
2. **Set Autolabel Pose**

These pipelines:

* Generate the subject skeleton
* Define the reference pose used for automatic labeling

---

# 3. Run Functional Joint Calibration (Optional)

If your protocol uses **FJC trials**:

1. Open the FJC trial in Nexus.
2. Label all markers.
3. In the **Pipelines panel**, run:

```
Functional Joint Calibration
```

Repeat for each FJC trial.

---

# 4. Verify Nexus Setup (Recommended)

Before running MATLAB:

1. Open one of the motion trials.
2. Run the pipeline:

```
Reconstruct And Label
```

Confirm:

* Reconstruction completes without errors
* Autolabeling produces reasonable marker labels

If reconstruction fails here, the MATLAB pipeline will also fail.

---

# 5. Run MATLAB Setup

Open MATLAB and run:

```
Setup.m
```

This script:

* Adds required folders to the MATLAB path
* Checks dependencies
* Attempts to locate **Nexus.exe**

If Nexus cannot be found automatically, MATLAB will prompt you to provide the path.

---

# 6. Launch the GUI

Run:

```
GUI_Tool.mlapp
```

The GUI contains two tabs:

* **File Setup**
* **Configuration Parameters**

---

# File Setup Tab

## Processing Mode

Choose one option:

**Have a static file and have already run the reconstruct pipeline**

* Standard mode
* Uses Nexus to reconstruct and process trials

**Vicon Free Processing**

* Processes files without interacting with Nexus

---

## Selecting Trials to Process

Choose **one method**.

### Select Individual Files

Click **Select C3D Files** and choose trials.

All selected files must come from the **same folder**.

---

### Add Folder Paths

Paste a folder path into **Folder Path** and click **Add Folder Path**.

All `.c3d` files in that folder will be processed.

Multiple folders can be added.

You can remove entries by **right-clicking the table → Remove**.

---

## Skipping Trials

You can exclude trials from processing.

### Skip by File Selection

Use **Select C3D Files to Skip**.

### Skip by Keyword

Enter a keyword.

Any trial containing that substring will be skipped.

Example:

```
Static
Warmup
Calibration
```

---

## Static Trial Identification

The pipeline must know which trials are static.

Two options are available.

### Keyword Detection

Enter a keyword (for example `Static`).

The pipeline will automatically locate static trials in each folder.

---

### Manual Static File Path

Enter the full file path and press **Add File Path**.

Multiple static files can be added.

Entries can be removed with **right-click → Remove**.

---

## Auto Parameter Detection

**Auto Params**

* **True**
  Jump thresholds are automatically detected.

* **False**
  You must upload custom thresholds.

If set to **False**, upload a `.txt` file using:

```
Add Custom Thresholds
```

---

## Run Processing

Click:

```
Run Script
```

The GUI will display:

* **Currently Processing** trial name
* **Progress bar**
* **Error messages** if configuration problems occur

---

# Configuration Parameters Tab

These parameters control marker validation and filtering.

### Verbose

```
Verbose
```

Shows detailed processing logs.

---

### Collection Frequency

```
Collection Frequency (Hz)
```

Sampling frequency of the MoCap system.

Default: **200 Hz**

---

### Lowpass Filter Cutoff

```
Lowpass Filter Cutoff
```

Filtering frequency for marker trajectories.

Default: **6 Hz**

---

### Default Jump Threshold

```
Default Jump Threshold
```

Maximum distance a marker can move in one frame before being flagged.

Default: **50**

---

### Jump Speed Threshold

```
Jump Speed Threshold
```

Maximum allowed velocity between frames.

Default: **7.5**

---

### Gap Detection Threshold

```
Gap Detection Threshold
```

Maximum gap size before a trajectory is flagged.

Default: **15 frames**

---

### Pattern Check Threshold

```
Pattern Check Threshold
```

Used to detect abnormal cluster geometry.

Default: **5**

---

### Number of Times to Heavy Process

```
Number of Times to Heavy Process
```

Number of passes of the intensive relabeling algorithm.

Default: **2**

---

# 7. Processing Time

Processing speed depends on dataset size and computer performance.

A full subject dataset can take **several hours (up to ~24 hours)**.

---

# 8. Review Failed Trials

Trials that fail validation appear in:

```
/Failed/
```

Common issues:

* Marker drift
* Mislabeled markers
* Marker dropouts
* Large trajectory discontinuities

Open these trials in **Vicon Nexus** and correct any issues.

---

# 9. Reprocess Corrected Trials

After fixing failed trials, run:

```
Cleanup.m
```

Run once per workspace folder.

---

# 10. Final Output

Successful trials will be moved to:

```
/Finished/
```

Remaining problematic trials stay in:

```
/Failed/
```

The **Finished** folder contains finalized motion capture data ready for analysis.
