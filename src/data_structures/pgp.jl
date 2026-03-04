# ==============================================================================
# Visualization and Plot Configuration Module
# 
# This module defines a set of data structures for managing visualization
# parameters in simulation outputs, including plot ranges, axis labels, titles,
# physical variable limits, contour settings, and device configurations. It
# provides a centralized approach for customizing graphical output and ensuring
# consistency across different visualization# consistency across different visualization contexts.
#
# Author: [Tomás Lima]
# Date: [2025-10-17]

# ==============================================================================

"""
    VisualizationConfig

A module providing comprehensive configuration structures for simulation 
visualization, plot generation, and graphical output settings.

# Main Structures
- `mainPGP`: Main visualization configuration container
- `SetMinMaxVar`: Physical variable range limits
- `ContourLimits`: Contour plot configuration
- `Views`: Viewport and projection settings
- `Labels`: Axis labels and text options
- `Title`: Plot titles and metadata
- `Device`: Output device configuration
- `AutomaticSetting`: Automated scaling settings
- `GLMinMax`: Global and local value ranges
- `GLobalMinMax`: Comprehensive range tracking

# Initialization
- `initialize_main_PGP()`: Creates and initializes default visualization settings

# Usage
```julia
viz_config = initialize_main_PGP()
viz_config.min_max_var.den = MinMaxRange(1e-3, 1e3)
viz_config.view.top = true
"""

# ==============================================================================

#Defines the minimum and maximum ranges for various physical variables
mutable struct SetMinMaxVar
    den::MinMaxRange        # Density MinMaxRange
    tem::MinMaxRange        # Temperature MinMaxRange
    pre::MinMaxRange        # Pressure MinMaxRange
    pok::MinMaxRange        # Dynamic pressure MinMaxRange
    b::MinMaxRange          # Beta MinMaxRange
    pmag::MinMaxRange       # Magnetic field strength MinMaxRange
    beta::MinMaxRange       # Magnitude of B MinMaxRange
    val::MinMaxRange        # Alfvén speed MinMaxRange
    mach::MinMaxRange       # Mach number MinMaxRange
    rot::MinMaxRange        # Rotation MinMaxRange
    vz::MinMaxRange         # Z velocity MinMaxRange
    
    #electron_value::MinMaxRange # Electron value MinMaxRange
    #overlap_value::MinMaxRange  # Overlap value MinMaxRange
end

# Data structure for contour limits
mutable struct ContourLimits
    density::MinMaxRange        # Density contour limits
    temperature::MinMaxRange    # Temperature contour limits
end

# Configuration flags and variables
mutable struct Views
    top::Bool            # Enable top view
    front::Bool          # Enable front view
    side::Bool           # Enable side view
    vertvar::Bool        # Enable vertical variables
    colden::Bool         # Enable column density
end

# Stores configuration for plot axis labels
mutable struct Labels 
    xlabel::String       # X-axis label
    ylabel::String       # Y-axis label
    writetime::Bool      # Enable time writing
    localizar::Bool      # Enable localization
end

# Contains descriptive metadata for the simulation
mutable struct Title     
    title::String        # Title of the simulation
    resolution::String   # Resolution of the output
    supernova::String    # Supernova identifier
    author::String       # Author of the simulation
    unitime::String      # Time unit
end

# Specifies the output device or display parameters,
mutable struct Device     
    device::String       # Device type
    dev::String          # Additional device information
end

# Manages various automatic or default settings
mutable struct AutomaticSetting
    escbet::String       # Beta scale
    automatic::String    # Automatic setting
    noautomatic::String  # Non-automatic setting
    unittime::String     # Unit of time
end

# Data structure for global and local maxima, minima, and averages
mutable struct GLMinMax
    global_min_max::MinMaxRange        # Global min/max values
    local_min_max::MinMaxRange         # Local min/max values
    aveg::Float64        # Global average value
    avel::Float64        # Local average value
end

# Data structure for global and local maxima, minima, and averages
mutable struct GLobalMinMax
    gl_den::GLMinMax           # Density
    gl_tem::GLMinMax           # Temperature
    gl_pre::GLMinMax           # Pressure
    gl_pram::GLMinMax          # Dynamic pressure
    gl_entr::GLMinMax          # Entropy
    gl_mach::GLMinMax          # Mach number
 end 
 # ==============================================================================
   
# Main structure for the PGP module
mutable struct mainPGP
    min_max_var::SetMinMaxVar  # Color scale parameters
    contourXYZ::ContourLimits  # Contour limit parameters
    view::Views
    labels::Labels
    title::Title
    device::Device
    flags::Bool                # General configuration flag
    global_min_max::GLobalMinMax
end


# Function to initialize the main PGP (Plasma/Physics/Graphics) configuration structure.
# This function creates a new instance of the main program configuration,
function initialize_main_PGP()
    min_max_var = SetMinMaxVar(
        MinMaxRange(-4.0, 1.5), MinMaxRange(1.0, 7.0), MinMaxRange(-15.0, -10.0),
        MinMaxRange(0.0, 5.0), MinMaxRange(-2.0, 1.0), MinMaxRange(-5.0, 0.0),
        MinMaxRange(-1.0, 5.0), MinMaxRange(-8.0, -4.0), MinMaxRange(-2.0, 2.0),
        MinMaxRange(-0.1, 1.0), MinMaxRange(-5.0e6, 1.2e7)
    )

    contourXYZ = ContourLimits(MinMaxRange(0.0, 1.0), MinMaxRange(0.0, 1.0))

    view = Views(true, false, false, true, false)
    labels = Labels("X-axis", "Y-axis", true, false)
    title = Title("Simulation Title", "High Resolution", "SN-01", "Author", "s")
    device = Device("GPU", "dev1", "1.0", "yes", "no", "s")

    global_min_max = GLobalMinMax(
        GLMinMax(MinMaxRange(0.0, 1.0), MinMaxRange(0.0, 1.0), 0.5, 0.5),
        GLMinMax(MinMaxRange(0.0, 1.0), MinMaxRange(0.0, 1.0), 0.5, 0.5),
        GLMinMax(MinMaxRange(0.0, 1.0), MinMaxRange(0.0, 1.0), 0.5, 0.5),
        GLMinMax(MinMaxRange(0.0, 1.0), MinMaxRange(0.0, 1.0), 0.5, 0.5),
        GLMinMax(MinMaxRange(0.0, 1.0), MinMaxRange(0.0, 1.0), 0.5, 0.5),
        GLMinMax(MinMaxRange(0.0, 1.0), MinMaxRange(0.0, 1.0), 0.5, 0.5)
    )
    
    return mainPGP(min_max_var, contourXYZ, view, labels, title, device, true, global_min_max)
end
