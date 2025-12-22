
# ==============================================================================
# Runtime Configuration Module
# 
# This module defines a set of data structures for managing simulation runtime
# parameters, including plot configurations, execution state, data transformation
# settings, and visualization options. It provides a centralized approach for
# controlling simulation flow and customizing# controlling simulation flow and customizing output during execution.
#
# Author: [Tomás Lima]
# Date: [2025-10-17]
# ==============================================================================

"""
    RuntimeConfiguration

A module providing comprehensive runtime configuration structures for 
simulation execution, visualization, and data processing.

# Main Structures
- `MainRuntime`: Overall runtime configuration container
- `LoopGraphic`: Execution loop parameters
- `OutputPlot`: Plot type and output settings
- `ExecutionState`: Current simulation state
- `Transformation`: Data transformation parameters
- `Aspect`: Plot aspect ratio configuration
- `PlotSetting`: Visual appearance settings
- `Tracer`: Particle tracer configuration
- `Volume`: Volume calculation results
- `TimeFile`: Time and file indexing
- `Data`: Additional data storage

# Initialization
- `initialize_main_runtime()`: Creates and initializes a default runtime configuration

"""

# ==============================================================================

# Execution loop parameters
mutable struct LoopGraphic
    lmin::Int   # Minimum loop
    lmax::Int   # Maximum loop
    stepl::Int  # Loop step increment
end

# Plot type settings
mutable struct OutputPlot
    pdf::Bool    # Enable PDF output
    cont::Bool   # Enable contour plots
    grey::Bool   # Enable grayscale mode
    color::Bool  # Enable color mode
    nContours::Int            # Number of contours
end
    
# Execution state of the simulation
mutable struct ExecutionState
    variable::String          # Target variable (e.g., temperature, density)
    filenum::Int              # Current file number
    timeid::Float64           # Current simulation time
    #loop::LoopGraphics       # Loop execution parameters
end

# Transformation parameters for data manipulation
mutable struct Transformation
    tr::Vector{Float64}       # Transformation vector (6 elements)
    tr2::Float64              # Scale factor 2
    tr6::Float64              # Scale factor 6
    fac1::Float64             # Factor 1
    fac2::Float64             # Factor 2
end

mutable struct Aspect
    width::Float64  # Plot width in arbitrary units
    aspect::Float64 # Aspect ratio (height/width)
end

# Plot settings
mutable struct PlotSetting
    # aspect::Aspect # Aspect ratio
    palette::Int              # Color palette (e.g., 2 to 12)
    orientation::String       # Color scale orientation
    #output_plot::OutputPlot  # Plot type configuration
    #nContours::Int           # Number of contours
end

# Tracer settings
mutable struct Tracer
    nmin_tracers::Int          # Minimum number of tracers
    total_tracers::Int         # Total number of tracers
end

mutable struct Volume
   vol_local::Float64          # Local volume
   vol_global::Float64         # Global volume
end  

mutable struct TimeFile
   time::Vector{Float64}       # Time vector
   files::Vector{Int}          # File indices vector
end

mutable struct Data
   zk::Vector{Float64}         # Additional data vector (Zk)
   atom::Int                   # Atom identifier
end  
    
# ==============================================================================
  
# Main simulation runtime structure
mutable struct MainRuntime
    loop_graphics::LoopGraphic
    type_plot::OutputPlot
    execution_state::ExecutionState       # Current execution state
    transformation::Transformation        # Data transformation parameters
    aspect::Aspect                        # Aspect ratio
  
    time_files::TimeFile
    plot_setting::PlotSetting 
    
    # Plot settings
    tracer_settings::Tracer               # Tracer configuration
    
    vol_log::Volume
    
    zk::Vector{Float64}                   # Additional data vector (Zk)
    atom::Int                             # Atom identifier
end

# Function to initialize the SimulationRuntime structure
function initialize_main_runtime()::MainRuntime
    # Initialize LoopGraphics
    loop_graphics = LoopGraphic(
        lmin = 0,
        lmax = 100,
        stepl = 1
    )

    # Initialize OutputPlot
    type_plot = OutputPlot(
        pdf = true,
        cont = false,
        grey = false,
        color = true,
        nContours = 10
    )

    # Initialize ExecutionState
    execution_state = ExecutionState(
        variable = "temperature",
        filenum = 0,
        timeid = 0.0
    )

    # Initialize Transformation
    transformation = Transformation(
        tr = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        tr2 = 1.0,
        tr6 = 1.0,
        fac1 = 1.0,
        fac2 = 1.0
    )

    # Initialize Aspect
    aspect = Aspect(
        width = 10.0,
        aspect = 1.0
    )

    # Initialize PlotSettings
    plot_setting = PlotSetting(
        orientation = "horizontal",
        palette = 5
    )

    # Initialize Tracer
    tracerSettings = Tracer(
        nmin_tracers = 100,
        total_tracers = 1000
    )

   # time_files = TimeFile()=TimeFile(Vector{Float64}(undef, 0),Vector{Int}(undef, 0) )
    
    # Initialize other fields
    time = Float64[]
    files = Int[]
    
    vol_local = 1.0
    vol_global = 1.0
    
    zk = Float64[]
    atom = 1

    # Create and return SimulationRuntime instance
    return MainRuntime(
        loop_graphics,
        type_plot,
        execution_state,
        transformation,
        aspect,
        time,
        files,
        plot_setting,
        tracer_settings,
        vol_local,
        vol_global,
        zk,
        atom
    )
    end
