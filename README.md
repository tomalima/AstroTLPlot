
# AstroTLPlot

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tomalima.github.io/AstroTLPlot.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tomalima.github.io/AstroTLPlot.jl/dev/)
[![Build Status](https://github.com/tomalima/AstroTLPlot.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/tomalima/AstroTLPlot.jl/actions/workflows/CI.yml?query=branch%3Amain)

**AstroTLPlot** is a Julia package for scientific visualization and data analysis in computational astrophysics.  
It modernizes the analysis and visualization software **AstroPGPLOT** (Avillez et al., 2009, 2020), originally implemented in FORTRAN and based on the PGPLOT graphics library, for the modern Julia ecosystem and the Makie graphics library.

The package provides a modular, high-performance replacement for the legacy Fortran/PGPLOT workflow by building on top of Makie.jl, HDF5, and structured data-processing tools. It supports the complete workflow from reading simulation outputs, computing statistics on multi-dimensional grids, to generating high-quality scientific plots (maps, slices, contours, colour-scales, PDFs, and more).

---

## Overview

This package reimagines the traditional astrophysical plotting workflow from Fortran/PGPLOT systems into a modern Julia environment. Inspired by the foundational work in **AstroPGPLOT** (originally developed by Miguel A. Vilela for IDL/PGPLOT and later by Avillez et al. for FORTRAN/PGPLOT), AstroTLPlot brings:

- **Familiar functionality** – 2D/3D slices, contours, maps, colour-scales, and statistical tools analogous to Fortran routines
- **Modern infrastructure** – HDF5 I/O, Makie-based plotting, and multi-threaded data processing
- **Full workflow support** – From reading simulation snapshots to generating publication-ready figures

The package is designed to serve the same use cases as the original AstroPGPLOT ecosystem but within a faster, more extensible, and interactive Julia environment.

---

## Features

- **Data I/O**
  - Reading astrophysical simulation data stored in **HDF5**
  - Optional support for legacy **HDF4** simulation data

- **Grid operations**
  - Extraction of 2D and 3D slices
  - XY/XZ cuts and structured grid fields

- **Statistics**
  - Efficient calculation of global and local statistics for multidimensional datasets

- **Plotting utilities** (Makie.jl backend)
  - Heatmaps and contour maps
  - Density distributions
  - Customizable colour scales
  - Annotation tools (modern replacement of legacy routines)
  - Multi-panel figures and layout customization

- **Export**
  - High-quality output to PNG, SVG, and PDF formats

- **Modular architecture**
  - Compatible with modern Julia workflows
  - Extensible for custom analysis and visualization pipelines

---

## Historical Context & Collaboration

This package builds upon the concepts and workflows originally developed for **AstroPGPLOT**, which was created by **Dr. Miguel Avillez in FORTRAN 2008 (Avillez et al., 2005, 2020)**. AstroPGPLOT provided a structured framework for visualization and analysis in astrophysical research.

The development of AstroTLPlot has been carried out in collaboration with **Prof. Francisco Coelho** and **Dr. Miguel Avillez**, whose invaluable insights into the original AstroPGPLOT system and its scientific applications significantly informed this work.

The primary objective of AstroTLPlot is to modernize AstroPGPLOT by reimplementing its core visualization and analysis capabilities in Julia. In doing so, it replaces PGPLOT with Makie.jl while preserving a similar logical structure and interface, thereby ensuring continuity for users familiar with the original system while leveraging modern language features and advanced visualization tools.

---

### Dependencies and Requirements

AstroTLPlot optionally relies on `PyCall.jl` and the Python library `pyhdf` **only when reading legacy HDF4 simulation outputs**.

**Important compatibility note:**

- `PyCall` + `pyhdf` are **not compatible with Python 3.13**, particularly when used inside Jupyter notebooks.
- This is a known limitation of the Python C-API interaction and is not specific to AstroTLPlot.

**Supported Python versions**
- Python 3.10
- Python 3.11
- Python 3.12

**Unsupported**
- Python 3.13 or newer

---

### Checking the Python version in Jupyter (before installing PyCall)

Before installing or building `PyCall`, you can check which Python version is available in your **Jupyter environment** by running the following cell in a **Julia notebook**:

```julia
run(`python --version`)
```

Example output:

```text
Python 3.11.14
```

If the reported version is **Python 3.13**, HDF4 support via `PyCall/pyhdf` will not work. In this case, configure Julia to use a compatible Python version **before** installing `PyCall`.

---

If you intend to read **HDF4** data, ensure that Julia is configured to use a compatible Python version **before installing or building `PyCall`**.

### Configuring PyCall with a compatible Python

```julia
ENV["PYTHON"] = "/usr/bin/python3.12"   # adjust path if needed
import Pkg
Pkg.build("PyCall")

```
You can verify the Python version used by PyCall with:

```julia
using PyCall
pyimport("sys").version
```

> **Note**  
> If you work exclusively with **HDF5** data, `PyCall` and `pyhdf` are **not required**.

---

## Installation

AstroTLPlot is not yet registered in the Julia General Registry.

To install directly from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/tomalima/AstroTLPlot.jl")

```

If you plan to use **HDF4** support, please read **Dependencies and Requirements** before installation.

---

## Documentation

For detailed usage instructions, examples, and API reference, see the [documentation](https://tomalima.github.io/AstroTLPlot.jl/stable/).

---

## Citation

If you use AstroTLPlot in your research, please consider citing:

- **Avillez et al. (2005, 2020)** for the original AstroPGPLOT framework
- This package (citation details forthcoming)

---

## Acknowledgements

Special thanks to **Prof. Dr. Francisco Coelho** and **Prof. Dr. Miguel Avillez** for their collaboration, expertise, and support in bridging the legacy AstroPGPLOT system with modern Julia workflows.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
