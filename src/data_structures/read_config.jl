# ==============================================================================
# A central configuration structure that aggregates all simulation settings.
# 
# This module defines a mutable struct `ConfigData` that consolidates all
# high-level simulation parameters, including debugging options, file paths,
# simulation type, grid and map dimensions, interpolation settings, abundance
# data, scaling factors, ion plotting configurations, and atomic/ionic fractions.
# It serves as the main entry point for controlling and customizing simulations
# in a modular and extensible way.
#
# Author: [Tomás Lima]
# Date: [2025-10-17]
# ==============================================================================

"""
    ConfigData

A central configuration structure that aggregates all simulation settings.  
This structure is designed to hold parameters related to debugging, directories, 
simulation type, file formats, grid and map dimensions, interpolation options, 
abundance settings, scaling parameters, ion plotting, and atomic/ionic fractions.  

It serves as the main entry point for simulation control, encapsulating 
all high-level configuration options in a modular and extensible way.  

Fields:
- `debug` : Debugging settings and flags.  
- `directories` : File system paths for input/output data.  
- `simulation_type` : Type of simulation to be executed (e.g., HD, MHD, test modes).  
- `file_format` : File formats supported (e.g., HDF5, ASCII, VTK).  
- `grid_size` : Size and resolution of the computational grid.  
- `real_dims` : Real physical dimensions corresponding to the computational grid.  
- `maps_dims` : Dimensions for map generation and visualization.  
- `number_of_plots` : Configuration of the number of plots to be generated.  
- `variable_params` : Parameters controlling which variables are processed or analyzed.  
- `interpolation` : Interpolation settings for data transformations.  
- `abundances` : Atomic and molecular abundances used in the simulation.  
- `scales` : Scaling parameters (e.g., color scales, normalization ranges).  
- `ions_plot` : Configuration for plotting ion distributions.  
- `ions_type` : Types of ions considered in the simulation.  
- `atomic_ionic_fraction` : Fractions of atomic and ionic species for detailed analysis.  
"""

mutable struct ConfigData
    debug::Debug                               # Debugging configuration and runtime flags
    directories::Directories                   # Paths for simulation input and output data
    simulation_type::SimulationType            # Defines the type of simulation (HD, MHD, etc.)
    file_format::FileFormat                    # Selected file format(s) for data I/O
    grid_size::GridSize                        # Grid resolution and discretization details
    real_dims::RealDims                        # Physical dimensions mapped to the computational domain
    maps_dims::MapsDims                        # Dimensions used for map visualization and slicing
    number_of_plots::NumberOfPlots             # Number and configuration of plots to generate
    variable_params::VariableParams            # Variables to compute, store, or visualize
    interpolation::Interpolation               # Interpolation settings for post-processing
    abundances::Abundances                     # Elemental or molecular abundances considered
    scales::Scales                             # Scaling and normalization parameters
    ions_plot::IonsPlot                        # Ion-specific plotting configuration
    ions_type::IonsType                        # Types of ions involved in the simulation
    atomic_ionic_fraction::AtomicIonicFraction # Fractions of atomic and ionic species
end

# ==============================================================================
# Main Configuration Structure
# ==============================================================================
"""
MainConfig

Overall simulation configuration structure containing all sub-configurations.

Fields

ldebug::Bool: Debug output control
dir::Directories: Directory configuration
file_format::FileFormat: File format configuration
size_g::GridSize: Grid size configuration
real_dim::RealDims: Real-space dimensions
simulation_type::SimulationType: Simulation type configuration
min_max::RealDims: Spatial boundaries
p1p2::MapsDims: Map coordinates
nplots::NumberOfPlots: Plot configuration
min_max_index::SetMinMaxIndex: Grid index limits
inc::Increments: Grid increments
variable_params::VariableParams: Variable parameters activation
simulation_data::SimulationData: Simulation data storage
scaling_config::Scales: Physical quantity scaling
element_config::Element: Element configuration
ions_type::IonsType: Ion type configuration
ion_plot::IonsPlot: Ion plot configuration
abundance::Abundances: Abundance configuration
atom_ios_fraction::AtomicIonicFraction: Atomic/ionic fraction parameters
interpolation::Interpolation: Interpolation configuration
element::Element: Element configuration (alternative)
"""

function ConfigData(; 
    debug::Debug = Debug(), 
    directories::Directories = Directories(), 
    simulation_type::SimulationType = SimulationType(), 
    file_format::FileFormat = FileFormat(), 
    grid_size::GridSize = GridSize(), 
    real_dims::RealDims = RealDims(), 
    maps_dims::MapsDims = MapsDims(), 
    number_of_plots::NumberOfPlots = NumberOfPlots(), 
    variable_params::VariableParams = VariableParams(), 
    interpolation::Interpolation = Interpolation(), 
    abundances::Abundances = Abundances(), 
    scales::Scales = Scales(), 
    ions_plot::IonsPlot = IonsPlot(), 
    ions_type::IonsType = IonsType(), 
    atomic_ionic_fraction::AtomicIonicFraction = AtomicIonicFraction(), )
    
    return ConfigData( 
        debug, 
        directories, 
        simulation_type, 
        file_format, 
        grid_size, 
        real_dims, 
        maps_dims, 
        number_of_plots, 
        variable_params, 
        interpolation, 
        abundances, 
        scales, 
        ions_plot, 
        ions_type, 
        atomic_ionic_fraction
    ) 
end

function Base.show(io::IO, config::ConfigData) 
    print(io, 
        """ 
           ConfigData: 
                Debug: $(config.debug) 
          Directories: $(config.directories) Simulation                     
                 Type: $(config.simulation_type) 
          File Format: $(config.file_format) 
            Grid Size: $(config.grid_size) 
            Real Dims: $(config.real_dims) 
            Maps Dims: $(config.maps_dims) 
      Number of Plots: $(config.number_of_plots)  
      Variable Params: $(config.variable_params) 
        Interpolation: $(config.interpolation) 
           Abundances: $(config.abundances) 
               Scales: $(config.scales) 
            Ions Plot: $(config.ions_plot) 
            Ions Type: $(config.ions_type) 
Atomic Ionic Fraction: $(config.atomic_ionic_fraction) 
""" 
) 
end

mutable struct PGPData
    set_min_max_var::SetMinMaxVar
    mincontours::ContourLimits
    device::Device
    view::Views
    title::Title
    labels::Labels
end

function PGPData(;
    set_min_max_var::SetMinMaxVar = SetMinMaxVar(),
    mincontours::ContourLimits = ContourLimits(),
    device::Device = Device(),
    view::Views = Views(),
    title::Title = Title(),
    labels::Labels = Labels(),
)
    return PGPData(
        set_min_max_var,
        mincontours,
        device,
        view,
        title,
        labels,
    )
end

function Base.show(io::IO, data::PGPData)
    print(io,
        """
                  PGPData:
             SetMinMaxVar: $(data.set_min_max_var)
            ContourLimits: $(data.mincontours)
                   Device: $(data.device)
                   Views : $(data.view)
                   Title : $(data.title)
                  Labels : $(data.labels)
        """
    )
end

# ==============================================================================

mutable struct RuntimeData
    loop_graphic::LoopGraphic
    output_plot::OutputPlot
    plot_setting::PlotSetting
    tracer::Tracer
    aspect::Aspect
  #  time_files::TimeFile #new to accomadate 
end

function RuntimeData(;
    loop_graphic::LoopGraphic = LoopGraphic(),
    output_plot::OutputPlot = OutputPlot(),
    plot_setting::PlotSetting = PlotSetting(),
    tracer::Tracer = Tracer(),
    aspect::Aspect = Aspect(),
    # time_files::TimeFile = TimeFile(Vector{Float64}(undef, 0), Vector{Int}(undef, 0)),
   # time_files::TimeFile=TimeFile(),
)
    return RuntimeData(
        loop_graphic,
        output_plot,
        plot_setting,
        tracer,
        aspect,
       # time_files,
    )
end

function Base.show(io::IO, data::RuntimeData) # TimeFile : $(data.time_files)
    print(io,
        """
            RuntimeData:
           Loop Graphic: $(data.loop_graphic)
            Output Plot: $(data.output_plot)
           Plot Setting: $(data.plot_setting)
                Tracer : $(data.tracer)
                Aspect : $(data.aspect)
        """
    )
end

mutable struct ModionsData
    set_min_max_ions::SetMinMaxIons
end

function ModionsData(;
    set_min_max_ions::SetMinMaxIons = SetMinMaxIons()
)
    return ModionsData(
        set_min_max_ions
    )
end

function Base.show(io::IO, data::ModionsData)
    print(io,
        """
        ModionsData:
            Set Min/Max Ions: $(data.set_min_max_ions)
        """
    )
end

# ==============================================================================


# Configuration structure that aggregates all simulation settings
mutable struct SimulationSetup
    config::ConfigData
    pgp::PGPData
    runtime::RuntimeData
    modions::ModionsData
    
    # Basic Construtor
    function SimulationSetup(config::ConfigData, pgp::PGPData, 
                            runtime::RuntimeData, modions::ModionsData)
        new(config, pgp, runtime, modions)
    end
end

# Construtor conveniente
function SimulationSetup(;
    config::ConfigData = ConfigData(),
    pgp::PGPData = PGPData(),
    runtime::RuntimeData = RuntimeData(),
    modions::ModionsData = ModionsData()
)
    return SimulationSetup(config, pgp, runtime, modions)
end

# ==============================================================================

function Base.show(io::IO, setup::SimulationSetup)
    # Header 
    println(io, "SimulationSetup - Complete Configuration")
    println(io, "="^60)
    
    # CONFIG
    println(io, "\nCONFIGURATION PARAMETERS")
    println(io, "-"^60)
    println(io, "Debug Settings:")
    println(io, "  • Debug mode: ", setup.config.debug.ldebug ? "ENABLED" : "disabled")
    
    println(io, "\nDirectories:")
    println(io, "  • Main directory: ", setup.config.directories.directory)
    println(io, "  • Atomic data directory: ", setup.config.directories.directory)
    
    println(io, "\nSimulation Type:")
    println(io, "  • HD run: ", setup.config.simulation_type.lhdrun ? "YES" : "NO")
    println(io, "  • MHD run: ", setup.config.simulation_type.lmhdrun ? "YES" : "NO")
    
    println(io, "\nGrid Parameters:")
    println(io, "  • Grid points: (", setup.config.grid_size.grid_point.x, ", ", 
          setup.config.grid_size.grid_point.y, ", ", setup.config.grid_size.grid_point.z, ")")
    
    #  PGP
    println(io, "\n\nPGP VISUALIZATION SETTINGS")
    println(io, "-"^60)
    println(io, "View Settings:")
    println(io, "  • Top view: ", setup.pgp.view.top ? "ON" : "off")
    println(io, "  • Front view: ", setup.pgp.view.front ? "ON" : "off")
    println(io, "  • Side view: ", setup.pgp.view.side ? "ON" : "off")
    
    println(io, "\nTitle and Labels:")
    println(io, "  • Main title: ", setup.pgp.title.title)
    println(io, "  • X label: ", setup.pgp.labels.xlabel)
    println(io, "  • Y label: ", setup.pgp.labels.ylabel)
    
    #  RUNTIME
    println(io, "\n\nRUNTIME PARAMETERS")
    println(io, "-"^60)
    println(io, "Loop Graphics:")
    println(io, "  • Start: ", setup.runtime.loop_graphic.lmin)
    println(io, "  • End: ", setup.runtime.loop_graphic.lmax)
    println(io, "  • Step: ", setup.runtime.loop_graphic.stepl)
    
    println(io, "\nOutput Settings:")
    println(io, "  • PDF output: ", setup.runtime.output_plot.pdf ? "ENABLED" : "disabled")
    println(io, "  • Contour plots: ", setup.runtime.output_plot.cont ? "ENABLED" : "disabled")
    println(io, "  • Number of contours: ", setup.runtime.output_plot.nContours)
    
    #  MODIONS
    println(io, "\n\nMODIONS PARAMETERS")
    println(io, "-"^60)
    println(io, "Ions Settings:")
    println(io, "  • Min value: ", setup.modions.set_min_max_ions)
    println(io, "  • Max value: ", setup.modions.set_min_max_ions)
    
    # Footer
    println(io, "\n", "="^60)
    println(io, "End of SimulationSetup configuration")
end
