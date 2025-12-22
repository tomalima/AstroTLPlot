# ==============================================================================
# Ion Physics and Atomic Data Module
# 
# This module defines a set of data structures and utilities for handling ion
# properties, atomic data, temperature-dependent physics, and ionization state
# calculations in plasma and astrophysical simulations. It provides tools for
# managing ion fractions, statistical analysis, and multi-element support in a
# modular and extensible way.
#
# Author: [Tomás Lima]
# Date: [2025-10-17]
# =============================================================================

"""
    IonPhysics

A module providing comprehensive data structures for ion physics, atomic data,
temperature-dependent properties, and ionization state calculations in 
astrophysical and plasma simulations.

# Main Structures
- `MainModions`: Main ion physics configuration container
- `IonProperties`: Physical properties of ions
- `IonLabels`: Naming and labeling for ions
- `IonStatistics`: Statistical data for ion populations
- `IonFractions`: Ionization fraction arrays
- `TemperatureProperties`: Temperature-dependent arrays
- `SetMinMaxIons`: Ion value ranges

# Features
- Ionization state tracking
- Temperature-dependent physics
- Statistical analysis of ion populations
- Multi-element support (O, N, C, etc.)
- Flexible array allocation for different grid sizes

# Initialization
- `initialize_main_modions()`: Creates default ion physics configuration
- `TemperatureProperties(in, jn, kn, nelem, kernmax)`: Grid-aware constructor
- `IonProperties(max_coo)`: Pre-allocated constructor
- `reset!(ion_props)`: Reinitialization method

# Usage
```julia
using .IonPhysics

# Initialize with default values
ions_config = initialize_main_modions()

# Initialize with specific grid dimensions
temp_props = TemperatureProperties(100, 100, 50, 15, 200, lele=true)

# Initialize pre-allocated ion properties
ion_props = IonProperties(5000)
"""

# ==============================================================================

# Properties related to ions
mutable struct IonProperties
    rlamba::Vector{Float64}       # Ionization coefficient    ==> MAXCOO
    beta::Vector{Float64}         # Beta parameter for ions   ==> MAXCOO
    rlamb0::Vector{Float64}       # Initial lambda values     ==> MAXCOO
    tcf::Vector{Float64}          # Thermal transfer function ==> MAXCOO
    dtf::Float64                  # Associated time interval
    
    tcool::Vector{Float64}        # Cooling time
    rlambc::Vector{Float64}       # Cooling coefficient lambda
end

# Labels and identifiers for ions
mutable struct IonLabels
    ion::String                   # Name of the ion (e.g., "O2+", "H+")
    titleion::String              # Descriptive title of the ion
    labelion::String              # Short label for display
end

# =======================================================
# Ion statistics for various elements
# =======================================================

# Ion statistics for various elements
mutable struct IonStatistics
    mediaO::Vector{Float64}       # Average properties for oxygen  ==> 9 posi
    ionmaxO::Vector{Float64}      # Maximum values for oxygen
    ionminO::Vector{Float64}      # Minimum values for oxygen
    
    mediaN::Vector{Float64}       # Average properties for nitrogen ==> 8 posi
    ionmaxN::Vector{Float64}      # Maximum values for nitrogen
    ionminN::Vector{Float64}      # Minimum values for nitrogen
    
    mediaC::Vector{Float64}       # Average properties for carbon   ==> 7  
    ionmaxC::Vector{Float64}      # Maximum values for carbon
    ionminC::Vector{Float64}      # Minimum values for carbon
end

# Ion fractions for multiple elements
mutable struct IonFractions
    fracO::Array{Float64, 4}      # Fractions for oxygen            ==>dim Temp, 2 Den 3,tempo,ene 
    fracC::Array{Float64, 4}      # Fractions for carbon
    fracN::Array{Float64, 4}      # Fractions for nitrogen
end

# Properties associated with temperature
mutable struct TemperatureProperties
    xion::Array{Float64, 3}       # Ion properties associated with temperature [i,j,k]
    xion_zs::Array{Float64, 3}    # Ion properties adjusted using cubic spline [i,j,k]
    
    xionvar::Array{Float64, 5}    # Ion variations by temperature [i,j,k,element,kernel]
    eleden::Array{Float64, 3}     # Electron density [i,j,k]
    eledenz::Array{Float64, 4}    # Electron density in zones [i,j,k,element]
    alogt::Vector{Float64}        # Logarithm of temperatures
    
    temp::MinMaxRange             # Temperature range
    #temp_min::Float64            # Minimum temperature
    #temp_max::Float64            # Maximum temperature
end

 # Min/max ions
 mutable struct SetMinMaxIons
   #= elemin::Float64
    elemax::Float64
    ovimin::Float64
    ovimax::Float64=#
    
    ele::MinMaxRange # Electron density or related quantity range
    ovi::MinMaxRange # OVI ion fraction or related quantity range
end

# Main structure encapsulating all data
mutable struct MainModions
    ionproperties::IonProperties          # Properties related to ions
    ionlabels::IonLabels                  # Labels for ions
    ionstatistics::IonStatistics          # Statistical data for ions
    ionfractions::IonFractions            # Fractions of different ions
    temperature::TemperatureProperties    # Properties related to temperature
end

# =======================================================
# Initialization Function
# =======================================================

"""
    initialize_main_modions()

Initializes the `MainModions` structure with default values.

# Returns:
- A `MainModions` instance with all substructures initialized with default or empty values.
"""
function initialize_main_modions()::MainModions
    # Initialize IonProperties with empty vectors and default values
    ionproperties = IonProperties(
        Float64[], Float64[], Float64[], Float64[], 
        0.0, Float64[], Float64[]
    )

    # Initialize IonLabels with placeholder strings
    ionlabels = IonLabels("Unknown", "Unknown Ion", "Unknown Label")

    # Initialize IonStatistics with empty vectors
    ionstatistics = IonStatistics(
        Float64[], Float64[], Float64[], 
        Float64[], Float64[], Float64[], 
        Float64[], Float64[], Float64[]
    )

    # Initialize IonFractions with empty arrays
    ionfractions = IonFractions(
        zeros(Float64, 1, 1, 1, 1),  # Placeholder 4D array for oxygen
        zeros(Float64, 1, 1, 1, 1),  # Placeholder 4D array for carbon
        zeros(Float64, 1, 1, 1, 1)   # Placeholder 4D array for nitrogen
    )

    # Initialize TemperatureProperties with empty arrays and default values
    temperature = TemperatureProperties(
        zeros(Float64, 1, 1, 1),  # Placeholder 3D array for xion
        zeros(Float64, 1, 1, 1),  # Placeholder 3D array for xion_zs
        zeros(Float64, 1, 1, 1, 1),  # Placeholder 5D array for xionvar
        zeros(Float64, 1, 1, 1),  # Placeholder 3D array for eleden
        zeros(Float64, 1, 1, 1, 1),  # Placeholder 4D array for eledenz
        Float64[],  # Empty vector for logarithm of temperatures
        MinMaxRange(0.0, 0.0)  # Initialize Range from DataStructure
        #0.0,        # Default minimum temperature
        #0.0         # Default maximum temperature
    )

    # Return the MainModions structure
    return MainModions(ionproperties, ionlabels, ionstatistics, ionfractions, temperature)
end

# ----


"""
    TemperatureProperties(in, jn, kn, nelem, kernmax; lele::Bool=false)

Outer constructor for `TemperatureProperties`.

Allocates all necessary arrays based on the provided grid sizes (`in`, `jn`, `kn`),
the number of elements (`nelem`), and the kernel maximum (`kernmax`).

Arguments
---------
- `in::Int` : Grid size in x-direction.
- `jn::Int` : Grid size in y-direction.
- `kn::Int` : Grid size in z-direction.
- `nelem::Int` : Number of elements.
- `kernmax::Int` : Maximum kernel index.
- `lele::Bool=false` : If true, allocate electron density arrays; otherwise leave them empty.

Returns
-------
A fully initialized `TemperatureProperties` instance.
"""
function TemperatureProperties(in::Int, jn::Int, kn::Int, nelem::Int, kernmax::Int; lele::Bool=false)
    xion     = zeros(Float64, in, jn, kn)
    xion_zs  = zeros(Float64, in, jn, kn)
    xionvar  = zeros(Float64, in, jn, kn, nelem, kernmax+1)
    eleden   = lele ? zeros(Float64, in, jn, kn) : Array{Float64,3}(undef, 0,0,0)
    eledenz  = lele ? zeros(Float64, in, jn, kn, nelem) : Array{Float64,4}(undef, 0,0,0,0)
    alogt    = Float64[]                # empty vector, fill later
    temp     = MinMaxRange(0.0, 0.0)    # placeholder

    return TemperatureProperties(xion, xion_zs, xionvar, eleden, eledenz, alogt, temp)
end


#----


# Constructor for initializing IonProperties with pre-allocated arrays of specified size.
function init_ion_properties(max_coo::Int)
    return IonProperties(
        zeros(Float64, max_coo),
        zeros(Float64, max_coo), 
        zeros(Float64, max_coo),
        zeros(Float64, max_coo),
        0.0,
        zeros(Float64, max_coo),
        zeros(Float64, max_coo)
    )
end

# Alternative constructor for IonProperties with pre-allocation
function IonProperties(max_coo::Int)
    return init_ion_properties(max_coo)
end

# Resets all arrays in an IonProperties instance to zero values.
function reset!(ion_props::IonProperties)
    fill!(ion_props.rlamba, 0.0)
    fill!(ion_props.beta, 0.0)
    fill!(ion_props.rlamb0, 0.0)
    fill!(ion_props.tcf, 0.0)
    ion_props.dtf = 0.0
    fill!(ion_props.tcool, 0.0)
    fill!(ion_props.rlambc, 0.0)
    return ion_props
end
