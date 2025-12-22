# AstroTLPlot

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://tomalima.github.io/AstroTLPlot.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tomalima.github.io/AstroTLPlot.jl/dev/)
[![Build Status](https://github.com/tomalima/AstroTLPlot.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/tomalima/AstroTLPlot.jl/actions/workflows/CI.yml?query=branch%3Amain)


AstroTLPlot is a Julia package for scientific visualization and data analysis in computational astrophysics.  
It modernizes a legacy Fortran/PGPLOT workflow by providing a modular, high-performance ecosystem built on top of Makie.jl, HDF5, and structured data-processing tools.

The package is designed to support the full workflow of reading simulation outputs, computing statistics on multi-dimensional grids, and generating high-quality scientific plots (maps, slices, contours, colour-scales, PDFs, and more).

---

## Features

- Reading and processing of astrophysical simulation data stored as HDF5.
- Extraction of 2D and 3D slices, XY/XZ cuts, and structured grid fields.
- Efficient calculation of global and local statistics for matrices.
- Plotting utilities based on Makie.jl:
  - Heatmaps, contour maps, density distributions.
  - Customizable colour scales (modern replacement of legacy Fortran `escala`).
  - Annotation tools (equivalent to the Fortran `escrever` routine).
- Modular and extensible architecture compatible with modern Julia workflows.
- Export of plots to PNG, SVG, and PDF.

---

## Installation

AstroTLPlot is not yet registered in the Julia General Registry.

To install directly from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/tomalima/AstroTLPlot.jl")
