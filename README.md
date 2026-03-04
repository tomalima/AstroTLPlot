
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

- **Data I/O**: Reading astrophysical simulation data stored in HDF5 format
- **Grid operations**: Extraction of 2D and 3D slices, XY/XZ cuts, and structured grid fields
- **Statistics**: Efficient calculation of global and local statistics for multi-dimensional datasets
- **Plotting utilities** (Makie.jl backend):
  - Heatmaps, contour maps, and density distributions
  - Customizable colour scales (modern replacement of legacy)
  - Annotation tools (equivalent to the Fortran routine)
  - Multi-panel figures and layout customization
- **Export**: High-quality output to PNG, SVG, and PDF formats
- **Modular architecture**: Compatible with modern Julia workflows and extensible for custom pipelines

---

## Historical Context & Collaboration

This package builds upon the concepts and workflows originally developed for **AstroPGPLOT**, which was created by **Dr. Miguel Avillez in FORTRAN 2008 (Avillez et al., 2005, 2020)**. AstroPGPLOT provided a structured framework for visualization and analysis in astrophysical research.

The development of AstroTLPlot has been carried out in collaboration with **Prof. Francisco Coelho** and **Dr. Miguel Avillez**, whose invaluable insights into the original AstroPGPLOT system and its scientific applications significantly informed this work.

The primary objective of AstroTLPlot is to modernize AstroPGPLOT by reimplementing its core visualization and analysis capabilities in Julia. In doing so, it replaces PGPLOT with Makie.jl while preserving a similar logical structure and interface, thereby ensuring continuity for users familiar with the original system while leveraging modern language features and advanced visualization tools.

---

## Installation

AstroTLPlot is not yet registered in the Julia General Registry.

To install directly from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/tomalima/AstroTLPlot.jl")

```

## Documentation

For detailed usage, examples, and API reference, see the [documentation](https://tomalima.github.io/AstroTLPlot.jl/stable/).

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
