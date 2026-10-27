# AMP: Automated Mocap Processing pipeline

An automated pipeline for marker-based optical motion capture data, designed for kinematic trajectory label scrubbing and gap filling.

---

## Repository Structure

```text
AMP/
├── With_GUI/          # Interactive MATLAB application
└── No_GUI/            # Script-based batch processing
    ├── MATLAB/        # Headless MATLAB scripts
    └── Python/        # Python pipeline and environment setup
```

---

## Choosing a Version

* **Interactive GUI (MATLAB):**  
  If you want a graphical interface to visually inspect trajectories, review gap fills, or adjust settings, go to [With_GUI](With_GUI). See the README inside that directory for setup and launch instructions.

* **Batch Processing (No GUI):**  
  If you prefer running automated scripts over batches of files without a graphical interface:
  * **MATLAB:** Navigate to [No_GUI/Matlab](No_GUI/Matlab) to use the MATLAB pipeline.
  * **Python:** Navigate to [No_GUI/Python](No_GUI/Python) to use the Python environment.  

*Each subfolder contains its own README with specific dependencies and execution steps.*

---

## Citation

If you use AMP in your research, please cite:

```bibtex
@article{zhou2026amp,
  title     = {{AMP}: An Automated Marker-Based Motion Capture Processing Pipeline for Kinematic Trajectory Label Scrubbing and Gap Filling},
  author    = {Zhou, Sixu and Ryan, Casey and Walter, Joseph and Young, Aaron},
  journal   = {bioRxiv},
  year      = {2026},
  doi       = {10.64898/2026.09.25.754545}
}
```

---

## License

This project is licensed under the [MIT License](LICENSE).
