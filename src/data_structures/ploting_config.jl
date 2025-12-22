# ==============================================================================
## A configuration structure for plot settings and parameters.
# 
# This module defines a mutable struct `PlotConfig` that encapsulates common
# plotting options such as dimensions, axis labels, title, color map, and
# output path for saving or displaying plots.
#
# Author: [Tomás Lima]
# Date: [2025-10-17]
# ==============================================================================
"""
    PlotConfig

A configuration structure for plot settings and parameters.

# Fields
- `xsize::Int`: Width of the plot in pixels
- `ysize::Int`: Height of the plot in pixels  
- `xlabel::String`: Label for the x-axis
- `ylabel::String`: Label for the y-axis
- `title::String`: Title of the plot
- `colormap::Symbol`: Symbol representing the color map to use
- `savepath::Union{Nothing, String}`: File path to save the plot, or `nothing` to display only

# Examples
```julia
# Create a basic plot configuration
config = PlotConfig(800, 600, "Time", "Amplitude", "Signal Plot", :viridis, nothing)

# Create a configuration that saves to file
config = PlotConfig(1000, 800, "X", "Y", "Data Analysis", :plasma, "plot.png")
"""

mutable struct PlotConfig
    xsize::Int # Width of the plot in pixels
    ysize::Int # Height of the plot in pixels
    xlabel::String # Label for the x-axis
    ylabel::String # Label for the y-axis
    title::String # Title of the plot
    colormap::Symbol # Color map symbol (e.g., :viridis, :plasma, :hot)
    savepath::Union{Nothing, String} # File path for saving, or nothing for display only
end
