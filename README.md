# Wii Sports

Originally a Senior Capstone Project, _Wii Sports_ is now an on-going embedded systems solution utilizeing Computer Vision Technology, with Embedded System Design to create an inexpensive, accessible, and scalable sports monitoring solution.

## Project overview

This repository contains research and implementation artifacts for a multi-disciplinary project bringing together computer vision (MATLAB + Python), embedded system integration (FPGA/Vivado), and 3D scene assets (Blender). The codebase is organized into several top-level folders that target different parts of the system:

- `Application/` – MATLAB apps, camera calibration data, image assets, and client scripts used for demos and image-processing experiments.
- `Camera Calibration/`, `rev2 Cam Calibration/` – camera/ stereo calibration parameters and images used for calibration sessions.
- `TennisTracker/` – main tracking experiments, blender environment, Vivado/HDL/Simulink artifacts, and datasets used to validate the tracker and embedded pipeline.
- `ServeVollyDataFiles/` (inside `TennisTracker/`) – sample serve/volley datasets used by offline experiments.
- `SupportingRepos/` – helper repositories and example clients for virtual camera servers, Zynq server examples, and other integration utilities.

## Quick start

Prerequisites (high-level):

- Python 3.8+ (for Python scripts, clients, and utilities)
- MATLAB (R2020a or later recommended) for `.m` scripts, `.mlapp` apps and Simulink models
- Blender (for the `tennisCourt.blend` assets if you intend to open the 3D scenes)
- Vivado / HDL toolchain (if you will work with FPGA/bitstreams under `TennisTracker/`)

Basic Python setup (from project root):

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Notes:

- The `requirements.txt` contains Python dependencies for the small helper scripts and clients. It does not install MATLAB toolboxes or Vivado.
- Many core algorithms and user interfaces live in MATLAB files and apps (see `Application/` and `TennisTracker/`). Open `TennisProjectGUI.mlapp` in MATLAB App Designer to run the GUI.

## Recommended workflow by area

- Camera calibration: open the calibration scripts and data in `Camera Calibration/` or `rev2 Cam Calibration/` and run the included calibration sessions (`.m` files and `.mat` data are provided).
- Application: `Application/TennisProjectGUI.mlapp` is the main GUI demo. `CamParam2.m` and `calibrationSession_Final.mat` provide calibration parameters used by the app.
- TennisTracker: contains Blender scenes (for synthetic data / visualization), Simulink models, Vivado/HDL projects, and offline datasets. Use the `BlenderEnviornment/` Python scripts if you want to generate or replay virtual camera images.

## Files & folders at a glance

- `Application/` – MATLAB GUI, calibration session `.mat`, example clients in `Clients/`.
- `TennisTracker/BlenderEnviornment/` – Python scripts to initialize Blender scenes and the exported `.blend` file used for visual testing.
- `TennisTracker/Fusion2`, `+fusion2`, `hdl_prj` – HDL/Vivado project bits and IP used for FPGA prototyping. These artifacts are large; be careful modifying without the proper toolchain.
- `SupportingRepos/` – useful example servers and virtual camera helpers. See `matlab-zynq-server` and `python-zynq-server` for examples of host/server code interacting with Zynq targets.

## Running MATLAB pieces

1. Open MATLAB and add the repository root to the path (or cd into the folder).
2. Open `Application/TennisProjectGUI.mlapp` in App Designer to launch the GUI.
3. If you only need to run scripts, open the `.m` files (for example, `Application/CamParam2.m`) and run them in the MATLAB command window.

Important: MATLAB toolboxes used in the project may include the Computer Vision Toolbox and Simulink. If you see missing-function errors, install the corresponding toolbox or run those scripts with alternative Python implementations where available.

## Blender and Vivado notes

- Blender files are provided mainly as visualization assets. Use Blender v2.8+ to open `tennisCourt.blend` in `TennisTracker/BlenderEnviornment/`.
- The Vivado/HDL files and bitstreams under `TennisTracker/` are tied to a specific FPGA board and toolchain (check `TennisTracker/README.md` and Simulink model comments before opening or programming hardware).

## Contributing

If you want to contribute:

1. Fork and create a topic branch.
2. Keep MATLAB and Python changes separated where possible.
3. Add tests or example runs for any new Python code and list MATLAB requirements in a PR description.

Create issues for feature requests or bugs. Provide steps to reproduce and relevant artifacts (images, `.mat` files, or logs).

## Maintainers & contact

- Chris Zamopra (main contact): see the repository owner `caz1110`.

## Troubleshooting & FAQs

- Q: I get missing MATLAB functions when running scripts. A: Install required MATLAB toolboxes (Computer Vision Toolbox, Image Processing Toolbox, Simulink) or run equivalent Python code in `SupportingRepos/` where available.
- Q: Python scripts fail with dependency errors. A: Activate the virtual environment and run `pip install -r requirements.txt`.
- Q: I can't open the Vivado project or program the bitstream. A: Ensure you have the matching Vivado version for the provided bitstreams and access to the target hardware. You will need krtkl - snickerdoodle board packages to successfully compile the vivado design.
