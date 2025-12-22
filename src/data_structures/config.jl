
# ==============================================================================
# Simulation Configuration Module
# 
# This module defines data structures and initialization functions for managing
# simulation parameters, physical variables, grid definitions, file formats, and
# visualization settings in plasma and MHD simulations. It provides a centralized
## configuration system to ensure consistency and modularity across the simulation workflow.
#
# Author: [Tomás Lima]
# Date: [2025-10-17]
# ==============================================================================

"""
    SimulationConfiguration

A module providing comprehensive configuration structures for plasma and MHD simulations,
including physical parameters, grid definitions, file formats, and visualization settings.

# Main Structures
- `MainConfig`: Overall simulation configuration container
- `SimulationData`: 3D field data storage
- `VariableParams`: Physical variable activation flags
- `Element`: Chemical element configuration
- `Scales`: Physical quantity scaling factors

# Initialization
- `initialize_main_config()`: Creates and initializes a default configuration object

# Usage
```julia
config = initialize_main_config()
"""

# Debug configuration structure
mutable struct Debug
    ldebug::Bool # Enable debug output
end

# Directories configuration structure
mutable struct Directories
    directory::String  # Directory for data cubes
    diratomic::String  # Directory for atomic data
end

# File format configuration structure
mutable struct FileFormat
    lhdf::Bool   # HDF file format
    lascii::Bool # ASCII file format
    lvtk::Bool   # VTK file format
end

# Grid point configuration structure
mutable struct GridSize
    grid_point::Point3D  # Number of points along each axis (i, j, k) /grid_points
end

# Simulation type configuration structure
mutable struct SimulationType
    lhdrun::Bool  # Header simulation type
    lmhdrun::Bool # LMH method simulation type
end

# Real-space dimensions configuration structure
mutable struct RealDims
    min::Point3D   # Minimum spatial boundaries (xmin, ymin, zmin) /spatial_min_bound
    max::Point3D   # Maximum spatial boundaries (xmax, ymax, zmax) /spatial_max_bound
    units::String  # Unit system
end

# Map coordinates configuration structure
mutable struct MapsDims
    p1::Point3D # Initial coordinates (x1, y1, z1) /initial_coordinates
    p2::Point3D # Final coordinates (x2, y2, z2) /final_coordinates
end

# Plot configuration structure
mutable struct NumberOfPlots
    nfiles::Int       # Total number of files
    nfile_start::Int  # Start file index
    nfile_end::Int    # End file index
    jump::Int         # File increment
    nl::Int           # Number of plot rows
    numx::Int         # Resolution along X-axis
    numy::Int         # Resolution along Y-axis
end

# Grid index limits configuration structure
mutable struct SetMinMaxIndex
  min_index::Point3D  # Minimum indices for each axis (imin, jmin, kmin) /grid_min_index
  max_index::Point3D  # Maximum indices for each axis (imax, jmax, kmax) /grid_max_index
end

# Grid increments configuration structure
mutable struct Increments
    incs::Point3D   # Increments along each axis (dx, dy, dz) /increments
end

"""
VariableParams

Variable parameters activation configuration structure.

Fields
ldens::Bool: Density calculation flag
ltemp::Bool: Temperature calculation flag
lpres::Bool: Pressure calculation flag
lpram::Bool: Dynamic pressure calculation flag
lmagn::Bool: Magnetic field calculation flag
lentr::Bool: Entropy calculation flag
lmach::Bool: Mach number calculation flag
lions::Bool: Ions calculation flag
lele::Bool: Electrons calculation flag
lratios::Bool: Variable ratios calculation flag
lele_kern::Bool: Electron kernels calculation flag
"""
mutable struct VariableParams
    ldens::Bool  # Density
    ltemp::Bool  # Temperature
    lpres::Bool  # Pressure
    lpram::Bool  # Dynamic pressure
    lmagn::Bool  # Magnetic field
    lentr::Bool  # Entropy
    lmach::Bool  # Mach number
    lions::Bool  # Ions
    lele::Bool   # Electrons
    lratios::Bool # Variable ratios
    lele_kern::Bool # Electron kernels
end

# ===============================
# Simulation data structure (3D fields)
# ===============================

"""
SimulationData

Structure for storing three-dimensional matrices containing simulation data.

Fields
3D arrays for physical fields (density, energy, pressure, temperature, etc.)

Velocity components and magnetic field components

Entropy and damping fields

Grid coordinate vectors for X, Y, and Z axes
"""
mutable struct SimulationData
    den::Array{Float64, 3}    # Density field
    ene::Array{Float64, 3}    # Energy field
    pre::Array{Float64, 3}    # Pressure field
    pok::Array{Float64, 3}    # Plasma pressure field
    tem::Array{Float64, 3}    # Temperature field
    
    vxx::Array{Float64, 3}    # Velocity X-component
    vyy::Array{Float64, 3}    # Velocity Y-component
    vzz::Array{Float64, 3}    # Velocity Z-component
    vel2::Array{Float64, 3}   # Velocity squared
    
    bxx::Array{Float64, 3}    # Magnetic field X-component
    byy::Array{Float64, 3}    # Magnetic field Y-component
    bzz::Array{Float64, 3}    # Magnetic field Z-component
    
    sentrop::Array{Float64,3}  # Entropy field
    ramp::Array{Float64, 3}     # Damping field
    rampok::Array{Float64, 3}   # Corrected damping field
    dentot::Array{Float64, 2}   # Total density (2D projection)

    X_grid::Vector{Float64}     # Grid coordinates for X-axis
    Y_grid::Vector{Float64}     # Grid coordinates for Y-axis
    Z_grid::Vector{Float64}     # Grid coordinates for Z-axis
end


"""
Scales

Physical quantity scaling configuration structure.

Fields
timescale::Float64: Time scaling factor
bscale::Float64: Magnetic field scaling factor
denscale::Float64: Density scaling factor
temscale::Float64: Temperature scaling factor
velscale::Float64: Velocity scaling factor
elescale::Float64: Electron scaling factor
logs::Bool: Logarithmic scaling flag
"""
# Scaling configuration structure
mutable struct Scales
    timescale::Float64 # Time scaling factor
    bscale::Float64    # Magnetic scaling factor
    denscale::Float64  # Density scaling factor
    temscale::Float64  # Temperature scaling factor
    velscale::Float64  # Velocity scaling factor
    elescale::Float64  # Electron scaling factor
    logs::Bool         # Logarithmic scaling flag
end

# ===============================
# Ion and Element Configuration Structures
# ===============================

"""
IonsPlot

Ion plot activation configuration structure.

Fields
Individual flags for each ion species plot (plhyd, plhel, plcar, etc.)
"""
# Ion plot configuration structure
mutable struct IonsPlot
    plhyd::Bool  # Hydrogen ion plot
    plhel::Bool  # Helium ion plot
    plcar::Bool  # Carbon ion plot
    plnit::Bool  # Nitrogen ion plot
    ploxy::Bool  # Oxygen ion plot
    plne::Bool   # Neon ion plot
    plmg::Bool   # Magnesium ion plot
    plsil::Bool  # Silicon ion plot
    plsul::Bool  # Sulfur ion plot
    plar::Bool   # Argon ion plot
    plfe::Bool   # Iron ion plot
end

"""
IonsType

Ion type activation configuration structure.

Fields
Individual flags for each ion species calculation (lhyd, lhel, lcar, etc.)
"""
# Ions type configuration structure
mutable struct IonsType
    lhyd::Bool  # Hydrogen ion
    lhel::Bool  # Helium ion
    lcar::Bool  # Carbon ion
    lnit::Bool  # Nitrogen ion
    loxy::Bool  # Oxygen ion
    lne::Bool   # Neon ion
    lmg::Bool   # Magnesium ion
    lsil::Bool  # Silicon ion
    lsul::Bool  # Sulfur ion
    lar::Bool   # Argon ion
    lfe::Bool   # Iron ion
end

"""
Abundances

Chemical abundances configuration structure.

Fields
lallen::Bool: Allen-type abundance flag
lag89::Bool: AG89-type abundance flag
lasplund::Bool: Asplund-type abundance flag
lgas07::Bool: GAS07-type abundance flag
lagss09::Bool: AGSS09-type abundance flag
zmetal::Float64: Metallicity value
deplt::Float64: Depletion factor
"""
# Chemical abundances configuration structure
mutable struct Abundances
    lallen::Bool    # Allen-type abundance
    lag89::Bool     # AG89-type abundance
    lasplund::Bool  # Asplund-type abundance
    lgas07::Bool    # GAS07-type abundance
    lagss09::Bool   # AGSS09-type abundance
    zmetal::Float64  # Metallicity
    deplt::Float64   # Depletion
end

"""
AtomicIonicFraction

Atomic and ionic fraction parameters structure.

Fields
id::Int: Element ID or identifier
ncool::Int: Number of cooling levels
ntemp_spline::Int: Number of temperature points for spline interpolation
dlog_temp::Float64: Logarithmic temperature step
"""
# Atomic and ionic fraction parameters structure
mutable struct AtomicIonicFraction
    # ! Atomic and ionic fractions
    id::Int # Element ID or identifier
    ncool::Int # Number of cooling levels
    ntemp_spline::Int # Number of temperature points for spline interpolation
    dlog_temp::Float64 # Logarithmic temperature step
 end   
    
# Interpolation configuration structure   
mutable struct Interpolation
    #  ! Type of interpolation. Note, ntemp_spline=ncool-1 and starts in 0
    lspline::Bool # Spline interpolation flag
    lrloss::Bool # Radiative loss calculation flag
end

# ===============================
# Element configuration structure for chemical composition.
# ===============================

"""
Element

Element configuration structure for chemical composition.

Fields
zelem::Vector{Bool}: Flags for active elements
celem::Vector{Bool}: Flags for chemical elements
plelem::Vector{Bool}: Flags for physical elements
abund::Vector{Float64}: Element abundances
nelem::Int: Number of active elements
kernmax::Int: Maximum number of kernels used
idk::Vector{Int}: Element IDs
idkmin::Vector{Int}: Minimum IDs per range
idkmax::Vector{Int}: Maximum IDs per range
"""
# Element configuration structure
mutable struct Element
    zelem::Vector{Bool}   # Flags for active elements (e.g., hydrogen, helium)
    celem::Vector{Bool}   # Flags for chemical elements
    
    plelem::Vector{Bool}  # Flags for physical elements
    abund::Vector{Float64} # Element abundances
    
    nelem::Int             # Number of active elements
    kernmax::Int           # Maximum number of kernels used
 
    idk::Vector{Int}       # Element IDs
    idkmin::Vector{Int}    # Minimum IDs per range
    idkmax::Vector{Int}    # Maximum IDs per range
end

# Alternative constructor for Element with empty abundance vector (if truly necessary)
function Element(; n_flags::Int = 26)
    return Element(
        falses(n_flags),
        falses(n_flags),
        falses(n_flags),
        Float64[],  # abund vazio
        0,
        0,
        Int[],
        Int[],
        Int[]
    )
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

# Overall configuration structure
mutable struct MainConfig
    ldebug::Bool                      # Debug output control
    dir::Directories            # Directory configuration
    file_format::FileFormat             # File format configuration
    size_g::GridSize                       # Number of points along each axis (i, j, k) /grid_points
    real_dim::RealDims
    simulation_type::SimulationType     # Simulation type configuration
    min_max::RealDims
    p1p2::MapsDims
    nplots::NumberOfPlots         # Plot configuration
    min_max_index::SetMinMaxIndex
    inc::Increments
    variable_params::VariableParams     # Variable parameters
    simulation_data::SimulationData     # Simulation data
    scaling_config::Scales       # Scaling configuration
    element_config::Element       # Element configuration
    ions_type::IonsType    # Ions type configuration
    ion_plot::IonsPlot     # Ion plot configuration
    abundance::Abundances  # Abundance configuration
    atom_ios_fraction::AtomicIonicFraction # Metallicity and depletion configuration
    interpolation::Interpolation # Interpolation configuration
    element::Element
end 

# Function to initialize the Config structure
"""
    initialize_config() -> Config

Creates and initializes a Config object with default or placeholder values.

# Returns
- A `Config` object with all fields initialized.
"""
function initialize_main_config()
    # Initialize Directories
    directories = Directories(
        directory = "",
        diratomic = ""
    )
    
    # Initialize FileFormat
    file_format = FileFormat(
        lhdf = false,
        lascii = false,
        lvtk = false
    )
    
    # Initialize GridSize
    grid_size = GridSize(
        gride_size = Point3D(0, 0, 0)
    )
    
    # Initialize SimulationType
    simulation_type = SimulationType(
        lhdrun = false,
        lmhdrun = false
    )
    
    # Initialize RealDims
    real_dim = RealDims(
        min = Point3D(0.0, 0.0, 0.0),
        max = Point3D(0.0, 0.0, 0.0),
        units = ""
    )
    
    # Initialize MapsDims
    p1p2 = MapsDims(
        p1 = Point3D(0.0, 0.0, 0.0),
        p2 = Point3D(0.0, 0.0, 0.0)
    )
    
    # Initialize NumberOfPlots
    nplots = NumberOfPlots(
        nfiles = 0,
        nfile_start = 0,
        nfile_end = 0,
        jump = 0,
        nl = 0,
        numx = 0,
        numy = 0
    )
    
    # Initialize SetMinMaxIndex
        min_max_index = SetMinMaxIndex(
        min_index = Point3D(0, 0, 0),
        max_index = Point3D(0, 0, 0)
    )
    
    # Initialize Increments
    inc = Increments(
        incs = Point3D(0.0, 0.0, 0.0)
    )
    
    # Initialize VariableParams
    variable_params = VariableParams(
        ldens = false,
        ltemp = false,
        lpres = false,
        lpram = false,
        lmagn = false,
        lentr = false,
        lmach = false,
        lions = false,
        lele = false,
        lratios = false,
        lele_kern = false
    )
    
    # Initialize SimulationData
    simulation_data = SimulationData(
        den = zeros(Float64, 0, 0, 0),
        ene = zeros(Float64, 0, 0, 0),
        pre = zeros(Float64, 0, 0, 0),
        pok = zeros(Float64, 0, 0, 0),
        tem = zeros(Float64, 0, 0, 0),
        vxx = zeros(Float64, 0, 0, 0),
        vyy = zeros(Float64, 0, 0, 0),
        vzz = zeros(Float64, 0, 0, 0),
        vel2 = zeros(Float64, 0, 0, 0),
        bxx = zeros(Float64, 0, 0, 0),
        byy = zeros(Float64, 0, 0, 0),
        bzz = zeros(Float64, 0, 0, 0),
        sentrop = zeros(Float64, 0, 0, 0),
        ramp = zeros(Float64, 0, 0, 0),
        rampok = zeros(Float64, 0, 0, 0),
        dentot = zeros(Float64, 0, 0),

        X_grid = Vector{Float64}(),
        Y_grid = Vector{Float64}(),
        Z_grid = Vector{Float64}()
    )
    
    # Initialize Scaling
    scaling_config = Scales(
        denscale = 0.0,
        temscale = 0.0,
        timescale = 0.0,
        bscale = 0.0,
        velscale = 0.0,
        elescale = 0.0,
        logs = false
    )
    
    # Initialize IonsType
    ions_type = IonsType(
        lhyd = false,
        lhel = false,
        lcar = false,
        lnit = false,
        loxy = false,
        lne = false,
        lmg = false,
        lsil = false,
        lsul = false,
        lar = false,
        lfe = false
    )
    
    # Initialize IonsPlot
    ion_plot = IonsPlot(
        plhyd = false,
        plhel = false,
        plcar = false,
        plnit = false,
        ploxy = false,
        plne = false,
        plmg = false,
        plsil = false,
        plsul = false,
        plar = false,
        plfe = false
    )
    
    # Initialize Abundances
    abundance = Abundances(
        lallen = false,
        lag89 = false,
        lasplund = false,
        lgas07 = false,
        lagss09 = false,
        zmetal = 0.0,
        deplt = 0.0
    )
    
    # Initialize AtomicIonicFraction
    atom_ios_fraction = AtomicIonicFraction(
        id = 0,
        ncool = 0,
        ntemp_spline = 0,
        dlog_temp = 0.0
    )
    
    # Initialize InterpolationType
    interpolation = InterpolationType(
        lspline = false,
        lrloss = false
    )
    
    # Initialize Element
    element = Element(
        zelem = Bool[],
        celem = Bool[],
        plelem = Bool[],
        abund = Float64[],
        nelem = 0,
        kernmax = 0,
        idk = Int[],
        idkmin = Int[],
        idkmax = Int[]
    )
    
    # Return the initialized Config structure
    return MainConfig(
        ldebug = false,
        dir = directories,
        file_format = file_format,
        size_g = grid_size,
        real_dim = real_dim,
        simulation_type = simulation_type,
        min_max = real_dim,
        p1p2 = p1p2,
        nplots = nplots,
        min_max_index = min_max_index,
        inc = inc,
        variable_params = variable_params,
        simulation_data = simulation_data,
        scaling_config = scaling_config,
        element_config = element,
        ions_type = ions_type,
        ion_plot = ion_plot,
        abundance = abundance,
        atom_ios_fraction = atom_ios_fraction,
        interpolation = interpolation,
        element = element
    )
end
