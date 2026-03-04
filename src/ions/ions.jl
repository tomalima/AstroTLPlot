# ==============================================================================
# Ion Species and Ionization Utilities Module
#
# This module defines data structures and utility functions related to chemical
# elements, charge states, and ionization bookkeeping used throughout the
# simulation and visualization pipeline. It includes:
#   • Element and ionization state metadata (IDs, symbols, kernel mappings)
#   • Conversions between (element, ion) indices and array dimensions
#   • Human-readable labeling utilities (e.g., ionstexto) for plots/reports
#   • Validation helpers for bounds and availability of ion states
#   • Convenience methods to query ranges, names, and display strings
#
# Notes:
#   - Keep physics/chemistry *models* (rates, collisional physics) elsewhere.
#   - This module focuses on *metadata*, *indexing*, and *presentation helpers*
#     for ion-related data (e.g., xionvar slices).
#
# Author: Tomás Lima
# Date: 2026-03-03
# ==============================================================================
``

using DelimitedFiles
using Printf


# ==============================================================================
# Function: create_ionproperties
# Purpose:  Initialize and configure IonProperties structure with default values
# ==============================================================================
"""
    create_ionproperties(;maxcoo::Int=5000) -> IonProperties

Initialize an IonProperties structure with default values and pre-allocated arrays.

This constructor function creates a properly initialized IonProperties object with
pre-allocated arrays for interpolation data and cooling function parameters. It sets up
the necessary data structures for temperature-dependent ionization calculations with
safe default values.

# Arguments
- `maxcoo::Int=5000`: Maximum number of interpolation points for cooling function data

# Returns
- `IonProperties`: Initialized structure containing:
  - `rlamba::Vector{Float64}`: Interpolated radiative loss function values
  - `beta::Vector{Float64}`: Slope coefficients for linear interpolation segments
  - `rlamb0::Vector{Float64}`: Base radiative loss values at interpolation nodes
  - `tcf::Vector{Float64}`: Temperature points for cooling function interpolation
  - `dtf::Float64`: Temperature step size for fine grid (initialized to 0.0)
  - `tcool::Vector{Float64}`: Coarse temperature grid points
  - `rlambc::Vector{Float64}`: Coarse grid radiative loss values

# Array Sizes
- All arrays (`rlamba`, `beta`, `rlamb0`, `tcf`, `tcool`, `rlambc`) are pre-allocated
  with length `maxcoo` for efficient memory management

# Default Values
- Numerical arrays are initialized with zeros for predictable behavior
- Scalar values like `dtf` are set to 0.0 to indicate uninitialized state
- The default `maxcoo=5000` provides sufficient capacity for most astrophysical applications

# Usage Example
```julia
# Create IonProperties with default size
ion_props = create_ionproperties()

# Create with custom size for high-resolution interpolation
ion_props_high_res = create_ionproperties(maxcoo=10000)
"""
function create_ionproperties(;maxcoo::Int=5000)
    # Initialize arrays for cooling function interpolation with maximum capacity MAXCOO
   rlamba = zeros(Float64, maxcoo) # Interpolated radiative loss values
   beta = zeros(Float64, maxcoo) # Linear interpolation slope coefficients
   rlamb0 = zeros(Float64, maxcoo) # Base radiative loss at interpolation nodes
   tcf = zeros(Float64, maxcoo) # Temperature points for cooling function
    
    # Valores padrão para outras variáveis
    dtf = 0.0                       # Temperature step size (to be calculated)
    tcool = zeros(Float64, maxcoo)  # Coarse temperature grid
    rlambc = zeros(Float64, maxcoo) # Coarse grid radiative loss values
    
    return IonProperties(rlamba, beta, rlamb0, tcf, dtf, tcool, rlambc)
end

# ==============================================================================
# Function: allocate_ions
# Purpose:  Allocate memory for ion- and electron-related properties based on the simulation
#           configuration (`cfg`) and the element configuration (`ele`).
# ==============================================================================

"""
    allocate_ions(cfg::ConfigData, ele::Element) -> TemperatureProperties

Allocate memory for ion- and electron-related properties based on the simulation
configuration (`cfg`) and the element configuration (`ele`).

# Arguments
- `cfg::ConfigData`: Configuration data, including grid sizes and variable parameters.
- `ele::Element`: Element configuration structure, containing number of elements (`nelem`)
  and maximum kernel index (`kernmax`).

# Returns
- `TemperatureProperties`: A structure containing allocated arrays for ion properties,
  ion variations, and optionally electron densities (depending on `cfg.variable_parameter.lele`).

# Notes
- The function follows the allocation logic of the Fortran subroutine `allocate_ions`.
- Grid sizes are read from `cfg.grid_size.grid_point` (x, y, z).
- If `cfg.variable_parameter.lele` is `true`, electron density arrays are also allocated.
"""
function allocate_ions(cfg::ConfigData, ele::Element)::TemperatureProperties
    # Extract grid sizes from the configuration
    in_ = cfg.grid_size.grid_point.x
    jn = cfg.grid_size.grid_point.y
    kn = cfg.grid_size.grid_point.z

    # Extract number of elements and kernel max from the element structure
    nelem = ele.nelem
    kernmax = ele.kernmax
    
    lele = cfg.variable_params.lele
    ncool = cfg.atomic_ionic_fraction.ncool

    # Allocate the main ion variation array:
    # dimensions: (in, jn, kn, nelem, kernmax+1)
    xionvar = Array{Float64}(undef, in_, jn, kn, nelem, kernmax)

    # Optional arrays for electrons (allocated only if lele == true)
    eleden  = lele ? Array{Float64}(undef, in_, jn, kn) : Array{Float64}(undef, 0, 0, 0)
    eledenz = lele ? Array{Float64}(undef, in_, jn, kn, nelem) : Array{Float64}(undef, 0, 0, 0, 0)

    # Placeholders for temperature-dependent arrays (allocated later in workflow)
          
    xion = zeros(Float64, nelem, kernmax, ncool) #ncool = 161
      
    xion_zs = zeros(Float64, nelem, kernmax, ncool)
    
    xionvar = Array{Float64}(undef, in_, jn, kn, nelem, kernmax)
    
    alogt = zeros(Float64, ncool)
       
    
    # Initialize the temperature range (to be filled later)
    temp = MinMaxRange(0.0, 0.0)

    # Return the populated structure
    return TemperatureProperties(
        xion,
        xion_zs,
        xionvar,
        eleden,
        eledenz,
        alogt,
        temp
    )
end

# ==============================================================================
# Function: allocate_ions_new
# Purpose:  Allocate memory for ion- and electron-related properties based on the simulation
#           configuration (`cfg`) and the element configuration (`ele`).
# ==============================================================================
function allocate_ions_new(cfg::ConfigData, ele::Element)::TemperatureProperties
    # Extract grid sizes from the configuration
    in_ = cfg.grid_size.grid_point.x
    jn = cfg.grid_size.grid_point.y
    kn = cfg.grid_size.grid_point.z
    
    lele_ = cfg.variable_params.lele
    ncool = cfg.atomic_ionic_fraction.ncool
    
    # Extract number of elements and kernel max from the element structure
    nelem = ele.nelem
    kernmax = ele.kernmax

    ntemp_spline = ncool

    # Allocate the main ion variation array:
    # dimensions: (in, jn, kn, nelem, kernmax+1)
        
    xion = zeros(Float64, nelem, kernmax, ncool) #ncool = 161
      
    xion_zs = zeros(Float64, nelem, kernmax, ncool)
    
    xionvar = Array{Float64}(undef, in_, jn, kn, nelem, kernmax)
    
    alogt = zeros(Float64, ncool)
   
     # Optional arrays for electrons (allocated only if lele == true)
    eleden = cfg.variable_params.lele ? Array{Float64}(undef, in_, jn, kn) : Array{Float64}(undef, 0, 0, 0)
    eledenz = cfg.variable_params.lele ? Array{Float64}(undef, in_, jn, kn, nelem) : Array{Float64}(undef, 0, 0, 0, 0)   
    
    # Initialize the temperature range (to be filled later)
    temp = MinMaxRange(0.0, 0.0)

    # Return the populated structure
    return TemperatureProperties(
        xion,
        xion_zs,
        xionvar,
        eleden,
        eledenz,
        alogt,
        temp
    )
end

# ==============================================================================
# Function: count_ions
# Purpose:  Count active ions and set the element indices for ion calculations
# ==============================================================================
"""
    count_ions(cfg::ConfigData)

Count active ions and create an Element structure with the appropriate indices for ion calculations.
Follows the same logic as the original Fortran subroutine.

Arguments
---------
- `cfg::ConfigData` : Contains configuration flags for elements and plotting options.

Returns
-------
- `element::Element` : A new Element structure with all fields properly initialized.
"""
function count_ions(cfg::ConfigData)
    # Create a new Element instance with default values
    element = Element(
        falses(MAX_ATOMIC_NUMBER),      # zelem
        falses(MAX_ATOMIC_NUMBER),      # celem  
        falses(MAX_ATOMIC_NUMBER),      # plelem
        zeros(MAX_ATOMIC_NUMBER),       # abund
        0,                              # nelem
        0,                              # kernmax
        zeros(Int, MAX_ATOMIC_NUMBER),  # idk
        zeros(Int, MAX_ATOMIC_NUMBER),  # idkmin
        zeros(Int, MAX_ATOMIC_NUMBER)   # idkmax
    )
    
    # Set elements to plot images
    element.plelem[1]  = cfg.ions_plot.plhyd
    element.plelem[2]  = cfg.ions_plot.plhel
    element.plelem[6]  = cfg.ions_plot.plcar
    element.plelem[7]  = cfg.ions_plot.plnit
    element.plelem[8]  = cfg.ions_plot.ploxy
    element.plelem[10] = cfg.ions_plot.plne
    element.plelem[12] = cfg.ions_plot.plmg
    element.plelem[14] = cfg.ions_plot.plsil
    element.plelem[16] = cfg.ions_plot.plsul
    element.plelem[18] = cfg.ions_plot.plar
    element.plelem[26] = cfg.ions_plot.plfe

    # Update configuration flags (if needed)
    cfg.ions_type.lhyd |= cfg.ions_plot.plhyd
    cfg.ions_type.lhel |= cfg.ions_plot.plhel
    cfg.ions_type.lcar |= cfg.ions_plot.plcar
    cfg.ions_type.lnit |= cfg.ions_plot.plnit
    cfg.ions_type.loxy |= cfg.ions_plot.ploxy
    cfg.ions_type.lne  |= cfg.ions_plot.plne
    cfg.ions_type.lmg  |= cfg.ions_plot.plmg
    cfg.ions_type.lsil |= cfg.ions_plot.plsil  
    cfg.ions_type.lsul |= cfg.ions_plot.plsul  
    cfg.ions_type.lar  |= cfg.ions_plot.plar   
    cfg.ions_type.lfe  |= cfg.ions_plot.plfe  

    # Set active elements (zelem)
    element.zelem[1]  = cfg.ions_type.lhyd
    element.zelem[2]  = cfg.ions_type.lhel
    element.zelem[6]  = cfg.ions_type.lcar
    element.zelem[7]  = cfg.ions_type.lnit
    element.zelem[8]  = cfg.ions_type.loxy
    element.zelem[10] = cfg.ions_type.lne
    element.zelem[12] = cfg.ions_type.lmg
    element.zelem[14] = cfg.ions_type.lsil
    element.zelem[16] = cfg.ions_type.lsul
    element.zelem[18] = cfg.ions_type.lar
    element.zelem[26] = cfg.ions_type.lfe

    # Count elements and determine kernmax
    icount = 0
    kernmax = 0
    for kern in 1:min(MAX_ATOMIC_NUMBER, length(element.zelem))
        if element.zelem[kern]
            icount += 1
            kernmax = kern
        end
    end
    element.nelem = icount
    element.kernmax = kernmax
   
  if cfg.debug.ldebug    
     println("N_elements, Z_max: ", element.nelem, ", ", element.kernmax)
  end 

    # Set IDs and ion ranges
    icount = 0
    icount_ions = 0
    for kern in 1:min(element.kernmax, length(element.idk))
        if element.zelem[kern]
            icount += 1
            icount_ions += 1

            element.idk[kern] = icount
            element.idkmin[kern] = icount_ions
            element.idkmax[kern] = icount_ions + kern
            icount_ions += kern

            if cfg.debug.ldebug   
                println("Element ", kern, ": idk=", element.idk[kern],
                        " idkmin=", element.idkmin[kern],
                        " idkmax=", element.idkmax[kern])
            end   
        end
    end
    
    return element
end

# ==============================================================================
# Function: ions_read
# Purpose:  Reads and processes atomic ionic fraction data from files, performing spline interpolation if configured.
# ==============================================================================
"""
    ions_read(cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData, element::Element) -> TemperatureProperties

Reads and processes atomic ionic fraction data from files, performing spline interpolation if configured.

This function reads atomic ionic fraction data files for each element, processes the temperature
and ionization state data, and optionally calculates spline coefficients for interpolation.
It handles file existence checks, data validation, and error conditions.

# Arguments
- `cfg::ConfigData`: Configuration data containing grid sizes, directories, and interpolation settings
- `pgp::PGPData`: PGP data structure (currently unused in this implementation)
- `rt::RuntimeData`: Runtime data structure (currently unused in this implementation)
- `modions::ModionsData`: Modions data structure (currently unused in this implementation)
- `element::Element`: Element data containing atomic information and kernel parameters

# Returns
- `TemperatureProperties`: Structure containing processed temperature and ionization data including:
  - `xion`: 3D array of ionic fractions [element, ionization_state, temperature]
  - `xion_zs`: 3D array of spline coefficients (if interpolation enabled)
  - `xionvar`: 5D array for spatial variation of ionic fractions [x, y, z, element, ionization_state]
  - `eleden`: 4D array of electron density by element [x, y, z, element]
  - `eledenz`: 5D array of electron density by element and spatial location
  - `alogt`: Array of logarithmic temperature values
  - `temp_properties`: Temperature range information

# Exceptions
- `SystemError`: If file cannot be accessed due to permission issues
- `ArgumentError`: If file format is invalid or data dimensions don't match expectations
- `ErrorException`: For various error conditions with descriptive messages

# Example
```julia
config = ConfigData(...)
element_data = Element(...)
result = ions_read(config, pgp_data, rt_data, modions_data, element_data)

"""
function ions_read(cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData, element::Element)
    # Extract configuration parameters
    lele_ = cfg.variable_params.lele
    ncool = cfg.atomic_ionic_fraction.ncool 
    ntemp_spline = ncool

    kernmax = element.kernmax
    nelem = element.nelem

    in_ = cfg.grid_size.grid_point.x
    jn = cfg.grid_size.grid_point.y
    kn = cfg.grid_size.grid_point.z
    
    # Allocate data arrays 
    xion = zeros(Float64, nelem, kernmax+1, ncool) #ncool = 161
    xion_zs = zeros(Float64, nelem, kernmax+1, ncool)
    alogt = zeros(Float64, ncool)
    
    # Allocate spatial distribution arrays
    xionvar = zeros(Float64, in_, jn, kn, nelem, kernmax+1 )
    eleden = lele_ ? zeros(Float64, in_, jn, kn) : zeros(Float64, 0, 0, 0)
    eledenz = lele_ ? zeros(Float64, in_, jn, kn, nelem) : zeros(Float64, 0, 0, 0, 0)

    # Process each element 
    for kern in 1:kernmax
        if element.zelem[kern]
             # Construct filename using atomic data directory and element ID 
            id = cfg.atomic_ionic_fraction.id
            filefracs = joinpath(cfg.directories.diratomic,
                                 "$(lpad(id+1, 2, '0')).frac-Z=$(lpad(kern, 2, '0')).dat")

            if cfg.debug.ldebug
                println("Reading File: ", filefracs)
            end

            # Verify file existence
            if !isfile(filefracs)
                error("File not found: $filefracs")
            end

            # Read data from file
            rawdata = DelimitedFiles.readdlm(filefracs)
            
            # Validate data dimensions
            if (size(rawdata, 1)-1) != ncool
                error("Number of temperatures in file ($(size(rawdata, 1))) does not match ncool ($ncool)")
            end
            
            if size(rawdata, 2) < kern + 2
                error("File does not have enough columns for element kern=$kern")
            end

            # Process data in reverse order (matching Fortran convention)
            k = ncool
            for i in 1:ntemp_spline
                # Extract logarithmic temperature value
                # read k = ncool-1, ncool-2, ..., 0)
                alogt[k] = rawdata[i, 1]
                
                # Extract ion fractions for all ionization states
                for ionz in 0:kern
                    value = rawdata[i, ionz + 2] # +2 offset: column 1 is temperature
                    # Apply minimum value threshold for numerical stability
                    if(value<=0.0) 
                        xion[element.idk[kern], ionz+1, k]=1e-30
                     else
                     xion[element.idk[kern], ionz+1, k]=value
                    end
                    #xion[element.idk[kern], ionz+1, k] = value <= 0.0 ? 1e-30 : value
                end
               k -= 1 
            end

            # Compute spline interpolation coefficients if configured
            if cfg.interpolation.lspline
                for ionz in 0:kern
                    # Extract ionization data for current state
                    ion_data = xion[element.idk[kern], ionz+1 , :]
                    
                    # Calculate spline coefficients
                    spline_coeffs = spline3_coef(ntemp_spline, alogt, ion_data)
                    xion_zs[element.idk[kern], ionz+1, :] = spline_coeffs
                end
            end
            # Generate debug output if enabled
            if cfg.debug.ldebug
                debug_filename = "debug_Z$(lpad(kern, 2, '0')).dat"
                open(debug_filename, "w") do f
                    for i in 1:ntemp_spline
                        # Format output with scientific notation
                        @printf(f, "%14.7e", alogt[i]) # i+1 ==>i
                        for ionz in 0:kern
                            @printf(f, " %14.7e", xion[element.idk[kern], ionz+1, i]) # i+1 ==>i
                        end
                        @printf(f, "\n")
                 end
        end
        println("Debug output written to: $debug_filename")
      end
    end
 end

 temp_min = alogt[1]
 temp_max = alogt[end]
 temp_properties = MinMaxRange(temp_min, temp_max)

    # Return comprehensive temperature-dependent properties structure
 return TemperatureProperties(
        xion,
        xion_zs,
        xionvar,
        eleden,
        eledenz,
        alogt,
        temp_properties
    )
end

# ==============================================================================
# Function: abundances!
# Purpose:  Initialize the element abundances according to different literature sources
# ==============================================================================
"""
    abundances!(cfg::ConfigData, ele::Element)

Initialize the element abundances according to different literature sources.

Arguments
---------
- `cfg::ConfigData` : Contains flags for the abundance sources (`lallen`, `lag89`, `lasplund`, `lgas07`, `lagss09`) 
  and metallicity `zmetal`.
- `ele::Element`    : Element structure to be updated with `abund`.

Notes
-----
The abundances are normalized relative to hydrogen using the standard astronomical logarithmic scale.
After applying metallicity corrections, the final abundances are converted from log10 to linear scale.
"""
function abundances!(cfg::ConfigData, elem::Element)
    
    # Allocate abundances array
    kernmax = elem.kernmax
    elem.abund = zeros(Float64, kernmax)

    # Set abundances according to source
    if cfg.abundances.lallen
        elem.abund[1]  = 0.00
        elem.abund[2]  = -1.07
        elem.abund[6]  = -3.48
        elem.abund[7]  = -4.04
        elem.abund[8]  = -3.18
        elem.abund[10] = -4.08
        elem.abund[12] = -4.58
        elem.abund[14] = -4.48
        elem.abund[16] = -4.80
        elem.abund[26] = -4.40
    end

    if cfg.abundances.lag89
        elem.abund[1]  = 0.00
        elem.abund[2]  = -1.01
        elem.abund[6]  = -3.44
        elem.abund[7]  = -3.95
        elem.abund[8]  = -3.07
        elem.abund[10] = -3.91
        elem.abund[12] = -4.42
        elem.abund[14] = -4.45
        elem.abund[16] = -4.79
        elem.abund[26] = -4.33
    end

    if cfg.abundances.lasplund
        elem.abund[1]  = 0.00
        elem.abund[2]  = -1.07
        elem.abund[6]  = -3.61
        elem.abund[7]  = -4.22
        elem.abund[8]  = -3.34
        elem.abund[10] = -3.71  
        elem.abund[12] = -4.47
        elem.abund[14] = -4.49
        elem.abund[16] = -4.86
        elem.abund[26] = -4.55
    end

    if cfg.abundances.lgas07
        elem.abund[1]  = 0.00
        elem.abund[2]  = -1.07
        elem.abund[6]  = -3.61
        elem.abund[7]  = -4.22
        elem.abund[8]  = -3.34
        elem.abund[10] = -4.16
        elem.abund[12] = -4.47
        elem.abund[14] = -4.49
        elem.abund[16] = -4.86
        elem.abund[26] = -4.55
    end

    if cfg.abundances.lagss09
        elem.abund[1]  = 0.00
        elem.abund[2]  = -1.07
        elem.abund[6]  = -3.57
        elem.abund[7]  = -4.17
        elem.abund[8]  = -3.31
        elem.abund[10] = -4.07
        elem.abund[12] = -4.40
        elem.abund[14] = -4.49
        elem.abund[16] = -4.88
        elem.abund[26] = -4.50
    end

    # Apply metallicity correction
    if elem.kernmax >= 3
        elem.abund[3:end] .+= cfg.abundances.zmetal
    end

    # Convert from logarithmic to linear scale
    elem.abund .= 10 .^ elem.abund
end

# ==============================================================================
# Function: fractions_spline!
# Purpose:  writes into `ion_properties.xionvar[:,:,:, element.idk[kern], ionz+1]
# ==============================================================================
"""
    fractions_spline!(kern::Int, ionz::Int, tps::TemperatureProperties,
                      element::Element, sml::SimulationData, cfg::ConfigData)

Compute 3D ion fraction distributions using cubic spline interpolation of temperature-dependent ionization data.

This function calculates ion population fractions across the simulation grid by applying
cubic spline interpolation to pre-computed ionization tables. It provides higher accuracy
for temperature-dependent ionization calculations compared to linear interpolation methods.

# Arguments
- `kern::Int`: Element identifier (atomic number)
- `ionz::Int`: Ionization state (0-based)
- `tps::TemperatureProperties`: Temperature-dependent ionization data and spline coefficients
- `element::Element`: Element composition and abundance data
- `sml::SimulationData`: Simulation field data (temperature, density)
- `cfg::ConfigData`: Configuration parameters including grid boundaries

# Processing Workflow
1. **Grid Initialization**: Set up spatial boundaries and initialize output array
2. **Spline Evaluation**: Use pre-computed spline coefficients to interpolate ion fractions
3. **Physical Scaling**: Apply element abundance and local density scaling
4. **Normalization**: Convert to proper physical units using hydrogen mass

# Key Features
- Uses cubic spline interpolation for smooth temperature dependence
- Handles boundary conditions and invalid temperature values
- Applies element-specific abundance corrections
- Maintains numerical stability with minimum value enforcement

# Notes
- Modifies `tps.xionvar` in-place with calculated ion fractions
- Uses logarithmic temperature scale for interpolation
- Returns `nothing` as results are stored in `tps.xionvar`
- Includes comprehensive bounds checking and error handling
"""
function fractions_spline!(kern::Int, ionz::Int,
                          tps::TemperatureProperties,
                          element::Element, 
                          sml::SimulationData, 
                          cfg::ConfigData)

    # Extract element properties
    kernmax = element.kernmax
    nelem   = element.nelem
    zelem   = element.zelem
    plelem  = element.plelem
    idk     = element.idk
    idkmin  = element.idkmin
    idkmax  = element.idkmax
    
   # retrieve abundance for kern (element.abund indexed by atomic number)
    abund_k = element.abund[kern]
   # Get element identifier in internal indexing scheme
    eid = element.idk[kern]           # idk indexed by atomic number

    # Extract configuration flags
    lspline = cfg.interpolation.lspline
    lrloss  = cfg.interpolation.lrloss
    logs    = cfg.scales.logs
    lratios = cfg.variable_params.lratios

    # Extract grid dimensions
    in_dim = cfg.grid_size.grid_point.x
    jn_dim = cfg.grid_size.grid_point.y  
    kn_dim = cfg.grid_size.grid_point.z

    # Calculate processing boundaries with safety checks
    imin = max(Int(cfg.real_dims.min.x), 1)
    imax = min(Int(cfg.real_dims.max.x), in_dim)
    jmin = max(Int(cfg.real_dims.min.y), 1)
    jmax = min(Int(cfg.real_dims.max.y), jn_dim)
    kmin = max(Int(cfg.real_dims.min.z), 1)
    kmax = min(Int(cfg.real_dims.max.z), kn_dim)
   
    # Debug: print bounds to verify
    if cfg.debug.ldebug   
        println("Grid dimensions: $in_dim x $jn_dim x $kn_dim")
        println("Loop bounds: i=$imin:$imax, j=$jmin:$jmax, k=$kmin:$kmax")
    end
    # Additional configuration parameters     
    lele = cfg.variable_params.lele
    ntemp_spline = cfg.atomic_ionic_fraction.ncool - 1
    # Access simulation fields
    tem = sml.tem
    den = sml.den

    # spline nodes and precomputed coeffs
    alogt = tps.alogt
    nt = length(alogt)
    #ntemp_spline = max(nt - 1, 0)   #  equal ntemp_spline = cfg.atomic_ionic_fraction.ncool - 1

    # Get spline data for this element and ionization state
    xion_data = tps.xion[eid, ionz+1, :]  # +1 for 1-based indexing
    xion_zs_data = tps.xion_zs[eid, ionz+1, :]
   
    # Initialize output array with default low value
    frac = fill(1.0e-30, in_dim, jn_dim, kn_dim)

    # temperature valid window from alogt
    # If ion_properties.temp exists (MinMaxRange)
    tmin = tps.temp.min
    tmax = tps.temp.max

    # Main processing loops - iterate through specified grid domain
    @inbounds for kk in kmin:kmax
        for jj in jmin:jmax
            for ii in imin:imax
                tval = tem[ii, jj, kk]
                # protect against non-positive temperature values
                if !(isfinite(tval) && tval > 0.0)
                    continue
                end
                temper = log10(tval)
                if tmin <= temper <= tmax
                    # evaluate spline: returns fraction xi(T)
                    enloss = spline3_eval(ntemp_spline, alogt, xion_data, xion_zs_data, temper)

                    # Compute ion fraction: abundance × density × interpolated fraction
                    frac[ii, jj, kk] = element.abund[kern] * sml.den[ii, jj, kk] * enloss
              end
        end
    end
end
    # Normalize by hydrogen mass and store results
    # This converts to proper physical units (number density)
    @views tps.xionvar[:, :, :, eid, ionz+1] .= frac ./ AstroTLPlot.MH 
    return nothing
end

# ==============================================================================
# Function: get_element_name
# Purpose:  Convert atomic numbers to standard chemical element symbols
# ==============================================================================
"""
    get_element_name(atomic_number::Int)::String

Convert atomic numbers to standard chemical element symbols.

This utility function provides a mapping from atomic numbers (proton counts) to their
standard chemical symbols as defined by IUPAC. It supports common astrophysical elements
used in plasma simulations and ionization calculations.

# Arguments
- `atomic_number::Int`: Number of protons in the atomic nucleus (Z)

# Returns
- `String`: Standard chemical symbol for the element

# Supported Elements
- 1: "H"  (Hydrogen)
- 2: "He" (Helium)
- 6: "C"  (Carbon)
- 7: "N"  (Nitrogen)
- 8: "O"  (Oxygen)
- 10: "Ne" (Neon)
- 12: "Mg" (Magnesium)
- 14: "Si" (Silicon)
- 16: "S"  (Sulfur)
- 18: "Ar" (Argon)
- 26: "Fe" (Iron)

# Error Handling
- Returns "X" for unsupported atomic numbers as a fallback
- No error thrown for invalid inputs to maintain processing flow

# Example
```julia
get_element_name(8)   # Returns "O"
get_element_name(26)  # Returns "Fe"
get_element_name(99)  # Returns "X" (unsupported element)
"""
function get_element_name(atomic_number::Int)::String
    element_names = Dict(
        1 => "H",   # Hydrogen
        2 => "He",  # Helium
        6 => "C",   # Carbon
        7 => "N",   # Nitrogen
        8 => "O",   # Oxygen
        10 => "Ne", # Neon
        12 => "Mg", # Magnesium
        14 => "Si", # Silicon
        16 => "S",  # Sulfur
        18 => "Ar", # Argon
        26 => "Fe"  # Iron
    )
    return get(element_names, atomic_number, "X")
end

function get_element_fname(atomic_number::Int)::String
    element_names = Dict(
        1 => "Hydrogen",    # Hydrogen
        2 => "Helium",      # Helium
        6 => "Carbon",      # Carbon
        7 => "Nitrogen",    # Nitrogen
        8 => "Oxygen",      # Oxygen
        10 => "Neon",       # Neon
        12 => "Magnesium",  # Magnesium
        14 => "Silicon",    # Silicon
        16 => "Sulfur",     # Sulfur
        18 => "Argon",      # Argon
        26 => "Iron"        # Iron
    )
    return get(element_names, atomic_number, "X")
end
# ==============================================================================
# Function: ionstexto
# Purpose:  Generate standardized labels and identifiers for elements and ionization states
# ==============================================================================
"""
    ionstexto(kern::Int, ionlev::Int)::IonLabels

Generate standardized chemical notation, titles, and labels for elements and their ionization states.

This function provides a comprehensive mapping from atomic numbers and ionization levels
to human-readable chemical notation, plot titles, and axis labels. It supports common
astrophysical elements from hydrogen to iron with their complete ionization sequences.

# Arguments
- `kern::Int`: Atomic number of the element (1=H, 2=He, 6=C, 7=N, 8=O, etc.)
- `ionlev::Int`: Ionization level (0=neutral, 1=singly ionized, 2=doubly ionized, etc.)

# Returns
- `IonLabels`: Structure containing:
  - `ion::String`: Compact ion identifier (e.g., "C03+" for C IV)
  - `titleion::String`: Plot title format (e.g., "C IV")
  - `labelion::String`: Axis label format (e.g., "log n(C IV)")

# Supported Elements
- Hydrogen (H I, H II)
- Helium (He I-III)
- Carbon (C I-VII)
- Nitrogen (N I-VIII)
- Oxygen (O I-IX)
- Neon (Ne I-XI)
- Magnesium (Mg I-XIII)
- Silicon (Si I-XV)
- Sulfur (S I-XVII)
- Argon (Ar I-XIX)
- Iron (Fe I-XXVII)

# Notation System
- Uses Roman numerals for ionization states (I=neutral, II=singly ionized, etc.)
- Follows standard astrophysical notation conventions
- Provides both compact identifiers and human-readable labels

# Example
```julia
labels = ionstexto(6, 3)  # Returns labels for C IV (triply ionized carbon)
# labels.ion = "C03+"
# labels.titleion = "C IV"  
# labels.labelion = "log n(C IV)"
"""

function ionstexto(kern::Int, ionlev::Int)::IonLabels
    # Atomic number to element abbreviation mapping
    element_abbr_dict = Dict(
        1 => "hyd",
        2 => "hel", 
        6 => "car",
        7 => "nit",
        8 => "oxy",
        10 => "neo",
        12 => "mgn",
        14 => "sil",
        16 => "sul",
        18 => "arg",
        26 => "iro"
    )
    # Get element abbreviation or default to "unknown"
    element_abbr = get(element_abbr_dict, kern, "unk")
    
    # Initialize output variables
    ion_str = ""
    titleion_str = ""
    labelion_str = ""
    
    # Hydrogen ionization states
    if element_abbr == "hyd"
        if ionlev == 0
            ion_str = "H00+"
            titleion_str = "H I"
            labelion_str = "log n(H I)"
        elseif ionlev == 1
            ion_str = "H01+"
            titleion_str = "H II"
            labelion_str = "log n(H II)"
        end
        
    # Helium ionization states
    elseif element_abbr == "hel"
        if ionlev == 0
            ion_str = "He00+"
            titleion_str = "He I"
            labelion_str = "log n(He I)"
        elseif ionlev == 1
            ion_str = "He01+"
            titleion_str = "He II"
            labelion_str = "log n(He II)"
        elseif ionlev == 2
            ion_str = "He02+"
            titleion_str = "He III"
            labelion_str = "log n(He III)"
        end
        
    # Carbon ionization states (I through VII)
    elseif element_abbr == "car"
        ions = ["C00+", "C01+", "C02+", "C03+", "C04+", "C05+", "C06+"]
        titles = ["C I", "C II", "C III", "C IV", "C V", "C VI", "C VII"]
        if 0 <= ionlev <= 6
            ion_str = ions[ionlev+1]
            titleion_str = titles[ionlev+1]
            labelion_str = "log n($(titles[ionlev+1]))"
        end
        
    # Nitrogen ionization states (I through VIII)
    elseif element_abbr == "nit"
        ions = ["N00+", "N01+", "N02+", "N03+", "N04+", "N05+", "N06+", "N07+"]
        titles = ["N I", "N II", "N III", "N IV", "N V", "N VI", "N VII", "N VIII"]
        if 0 <= ionlev <= 7
            ion_str = ions[ionlev+1]
            titleion_str = titles[ionlev+1]
            labelion_str = "log n($(titles[ionlev+1]))"
        end
        
    # Nitrogen ionization states (I through VIII)
    elseif element_abbr == "oxy"
        ions = ["O00+", "O01+", "O02+", "O03+", "O04+", "O05+", "O06+", "O07+", "O08+"]
        titles = ["O I", "O II", "O III", "O IV", "O V", "O VI", "O VII", "O VIII", "O IX"]
        if 0 <= ionlev <= 8
            ion_str = ions[ionlev+1]
            titleion_str = titles[ionlev+1]
            labelion_str = "log n($(titles[ionlev+1]))"
        end
        
    # Neon ionization states (I through XI)
    elseif element_abbr == "neo"
        ions = ["Ne00+", "Ne01+", "Ne02+", "Ne03+", "Ne04+", "Ne05+", "Ne06+", "Ne07+", "Ne08+", "Ne09+", "Ne10+"]
        titles = ["Ne I", "Ne II", "Ne III", "Ne IV", "Ne V", "Ne VI", "Ne VII", "Ne VIII", "Ne IX", "Ne X", "Ne XI"]
        if 0 <= ionlev <= 10
            ion_str = ions[ionlev+1]
            titleion_str = titles[ionlev+1]
            labelion_str = "log n($(titles[ionlev+1]))"
        end
        
    # Magnesium ionization states (I through XIII)
    elseif element_abbr == "mgn"
        ions = ["Mg00+", "Mg01+", "Mg02+", "Mg03+", "Mg04+", "Mg05+", "Mg06+", "Mg07+", "Mg08+", "Mg09+", "Mg10+", "Mg11+", "Mg12+"]
        titles = ["Mg I", "Mg II", "Mg III", "Mg IV", "Mg V", "Mg VI", "Mg VII", "Mg VIII", "Mg IX", "Mg X", "Mg XI", "Mg XII", "Mg XIII"]
        if 0 <= ionlev <= 12
            ion_str = ions[ionlev+1]
            titleion_str = titles[ionlev+1]
            labelion_str = "log n($(titles[ionlev+1]))"
        end
        
    # Silicon ionization states (I through XV)
    elseif element_abbr == "sil"
        ions = ["Si00+", "Si01+", "Si02+", "Si03+", "Si04+", "Si05+", "Si06+", "Si07+", "Si08+", "Si09+", "Si10+", "Si11+", "Si12+", "Si13+", "Si14+"]
        titles = ["Si I", "Si II", "Si III", "Si IV", "Si V", "Si VI", "Si VII", "Si VIII", "Si IX", "Si X", "Si XI", "Si XII", "Si XIII", "Si XIV", "Si XV"]
        if 0 <= ionlev <= 14
            ion_str = ions[ionlev+1]
            titleion_str = titles[ionlev+1]
            labelion_str = "log n($(titles[ionlev+1]))"
        end
        
    # Sulfur ionization states (I through XVII)
    elseif element_abbr == "sul"
        ions = ["S00+", "S01+", "S02+", "S03+", "S04+", "S05+", "S06+", "S07+", "S08+", "S09+", "S10+", "S11+", "S12+", "S13+", "S14+", "S15+", "S16+"]
        titles = ["S I", "S II", "S III", "S IV", "S V", "S VI", "S VII", "S VIII", "S IX", "S X", "S XI", "S XII", "S XIII", "S XIV", "S XV", "S XVI", "S XVII"]
        if 0 <= ionlev <= 16
            ion_str = ions[ionlev+1]
            titleion_str = titles[ionlev+1]
            labelion_str = "log n($(titles[ionlev+1]))"
        end
        
    # Argon ionization states (I through XIX)
    elseif element_abbr == "arg"
        ions = ["Ar00+", "Ar01+", "Ar02+", "Ar03+", "Ar04+", "Ar05+", "Ar06+", "Ar07+", "Ar08+", "Ar09+", "Ar10+", "Ar11+", "Ar12+", "Ar13+", "Ar14+", "Ar15+", "Ar16+", "Ar17+", "Ar18+"]
        titles = ["Ar I", "Ar II", "Ar III", "Ar IV", "Ar V", "Ar VI", "Ar VII", "Ar VIII", "Ar IX", "Ar X", "Ar XI", "Ar XII", "Ar XIII", "Ar XIV", "Ar XV", "Ar XVI", "Ar XVII", "Ar XVIII", "Ar XIX"]
        if 0 <= ionlev <= 18
            ion_str = ions[ionlev+1]
            titleion_str = titles[ionlev+1]
            labelion_str = "log n($(titles[ionlev+1]))"
        end
        
    # Iron ionization states (I through XXVII)
    elseif element_abbr == "iro"
        ions = ["Fe00+", "Fe01+", "Fe02+", "Fe03+", "Fe04+", "Fe05+", "Fe06+", "Fe07+", "Fe08+", "Fe09+", "Fe10+", "Fe11+", "Fe12+", "Fe13+", "Fe14+", "Fe15+", "Fe16+", "Fe17+", "Fe18+", "Fe19+", "Fe20+", "Fe21+", "Fe22+", "Fe23+", "Fe24+", "Fe25+", "Fe26+"]
        titles = ["Fe I", "Fe II", "Fe III", "Fe IV", "Fe V", "Fe VI", "Fe VII", "Fe VIII", "Fe IX", "Fe X", "Fe XI", "Fe XII", "Fe XIII", "Fe XIV", "Fe XV", "Fe XVI", "Fe XVII", "Fe XVIII", "Fe XIX", "Fe XX", "Fe XXI", "Fe XXII", "Fe XXIII", "Fe XXIV", "Fe XXV", "Fe XXVI", "Fe XXVII"]
        if 0 <= ionlev <= 26
            ion_str = ions[ionlev+1]
            titleion_str = titles[ionlev+1]
            labelion_str = "log n($(titles[ionlev+1]))"
        end
    end
    
    # Fallback for unmapped elements or ionization states
    if ion_str == ""
        # Generate generic labels using atomic number and ionization level
        element_name = get_element_name(kern)  # Placeholder - could be enhanced with periodic table lookup
        ion_str = "$(element_name)$(lpad(ionlev, 2, '0'))+"
        titleion_str = "$(element_name) $(ionlev+1)"
        labelion_str = "log n($(element_name) $(ionlev+1))"
    end
    return IonLabels(ion_str, titleion_str, labelion_str)
end

# ==============================================================================
# Function: rloss!
# Purpose:  Given a coarse temperature grid `tcool` (in linear units, i.e. 10^alogt)
# ==============================================================================
"""
    rloss!(ionp::IonProperties, tcool::Vector{Float64}) -> ncoolf::Int

Given a coarse temperature grid `tcool` (in linear units, i.e. 10^alogt),
compute a fine, uniformly spaced temperature grid `tcf` and the corresponding
log-space loss function parameters `rlamba`, `beta`, `rlamb0`.

- `ionp.tcool` and `ionp.rlambc` must be prefilled before calling (rlambc = log10(xion...)).
- This function fills `ionp.tcf`, `ionp.rlamba`, `ionp.beta`, `ionp.rlamb0`, and `ionp.dtf`.
- Returns `ncoolf` (number of fine intervals; Fortran used indices 0..ncoolf).
"""
   #function rloss!(ionp::IonProperties, tcool::Vector{Float64})::Int
   function rloss!(ionp::IonProperties,ncool_::Int)::Int  
   #ncool = length(tcool) # ncool = cfg.atomic_ionic_fraction.ncool

   ncool = ncool_ #cfg.atomic_ionic_fraction.ncool

   tcool=ionp.tcool  
    # compute minimum log spacing dtmin = min(log10(tcool[i+1]) - log10(tcool[i]))
    dtmin = 1.e16
    for i in 2:ncool-1
        # println(tcool[i])
        dt = log10(tcool[i]) - log10(tcool[i-1])
        dtmin = min(dtmin, dt)
    end

    # fine spacing
    dtf = dtmin / 20.0   # matches Fortran dtf = dtmin/20.
    dtf100 = dtf / 100.0
    
    # compute ncoolf such that (log10(tcool[end]) - log10(tcool[1]))/dtf ≈ ncoolf
    ncoolf = Int(floor((log10(tcool[ncool]) - log10(tcool[1])) / dtf))
    # number of fine points (Fortran used indices 0..ncoolf inclusive)
    ionp.dtf     = dtf

    # initialize first point (Fortran used index 0 -> Julia index 1)
    ionp.tcf[1]    = ionp.tcool[1]
    ionp.rlamba[1] = ionp.rlambc[1]
    # beta[1] uses rlambc[2] and rlambc[1]
    ionp.beta[1]   = (ionp.rlambc[2] - ionp.rlambc[1]) / (log10(ionp.tcool[2]) - log10(ionp.tcool[1]))
    ionp.rlamb0[1] = ((ionp.rlambc[2] + ionp.rlambc[1]) - ionp.beta[1] * (log10(ionp.tcool[2]) + log10(ionp.tcool[1]))) / 2.0

    # prepare search window
    nn1 = 2    # Fortran nn1=1 (0-based) -> in Julia start at 2
    nn2 = ncoolf

    # Fill fine grid  # 5. Loop Principal de Interpolação
    for i in 2:ncoolf
        # compute next tcf in log-space
        ionp.tcf[i] = 10.0^(log10(ionp.tcf[i-1]) + dtf)

        # find n in coarse grid such that log10(tcf[i]) is close to log10(tcool[n])
        # loop n from nn1..nn2 (Julia indices correspond to Fortran +1)
        found = false
        for n in nn1:nn2
            # in Fortran the condition was (log10(tcf(i))-log10(tcool(n))).le.dtf100
            if (log10(ionp.tcf[i]) - log10(ionp.tcool[n])) <= dtf100
                # compute local slope beta
                ionp.beta[i] = (ionp.rlambc[n] - ionp.rlambc[n-1]) / (log10(ionp.tcool[n]) - log10(ionp.tcool[n-1]))
                # compute rlamb0
                ionp.rlamb0[i] = ((ionp.rlambc[n] + ionp.rlambc[n-1]) -
                                  ionp.beta[i] * (log10(ionp.tcool[n]) + log10(ionp.tcool[n]))) / 2.0
                # compute rlamba at point i
                ionp.rlamba[i] = ionp.rlambc[n-1] + ionp.beta[i] * (log10(ionp.tcf[i]) - log10(ionp.tcool[n-1]))

                # update nn1, nn2 like Fortran to narrow the search
                nn1 = n
                nn2 = n + 1
                if nn2 >= ncool
                    nn2 = ncool 
                end
                found = true
                break
            end
        end

        # If not found by the loop, fallback to nearest coarse interval:
       if !found
            # clamp n between 2..ncool-1
            n_clamped = clamp(nn1, 2, ncool-1)
            ionp.beta[i] = (ionp.rlambc[n_clamped] - ionp.rlambc[n_clamped-1]) /
                           (log10(ionp.tcool[n_clamped]) - log10(ionp.tcool[n_clamped-1]))
            ionp.rlamb0[i] = ((ionp.rlambc[n_clamped] + ionp.rlambc[n_clamped-1]) -
                              ionp.beta[i] * (log10(ionp.tcool[n_clamped]) + log10(ionp.tcool[n_clamped-1]))) / 2.0
            ionp.rlamba[i] = ionp.rlambc[n_clamped-1] + ionp.beta[i] * (log10(ionp.tcf[i]) - log10(ionp.tcool[n_clamped-1]))
        end
    end
    return ncoolf
end

# ==============================================================================
# Function: fractions_old!
# Purpose: Compute ion fractions using radiative-loss based interpolation (legacy method)
# ==============================================================================
"""
    fractions_old!(kern::Int, ionz::Int, ionps::IonProperties, tempr::TemperatureProperties,
                   elem::Element, sml::SimulationData, cfg::ConfigData, pgp::PGPData, 
                   rt::RuntimeData, modions::ModionsData)

Compute ion population fractions using the legacy radiative-loss based interpolation method.

This function implements the faster "old" method for calculating ion fractions by
interpolating pre-computed radiative loss data. It processes temperature-dependent
ionization data through multiple stages: coarse grid preparation, fine grid refinement
via `rloss!`, and 3D mapping via `mapfractions!`.

# Arguments
- `kern::Int`: Element identifier/kernel number
- `ionz::Int`: Ionization state (0-based)
- `ionps::IonProperties`: Ion property data structure (modified in-place)
- `tempr::TemperatureProperties`: Temperature-dependent properties including ion fractions
- `elem::Element`: Element composition and atomic data
- `sml::SimulationData`: Simulation field data (temperature, density)
- `cfg::ConfigData`: Configuration parameters including debug flags
- `pgp::PGPData`: Post-processing parameters
- `rt::RuntimeData`: Runtime data structure
- `modions::ModionsData`: Ionization module specific data

# Processing Pipeline
1. **Coarse Grid Preparation**: Convert logarithmic temperature points to linear scale
2. **Radiative Loss Calculation**: Call `rloss!` to create fine interpolation grid
3. **Debug Output**: Optionally save interpolation data to files
4. **3D Mapping**: Use `mapfractions!` to compute ion fractions across simulation grid
5. **Normalization**: Apply hydrogen mass normalization and minimum value clipping

# Key Features
- Uses pre-computed radiative loss tables for efficient interpolation
- Supports debug output for validation and analysis
- Applies physical normalization using hydrogen mass constant
- Maintains numerical stability with minimum value enforcement

# Notes
- Modifies `tempr.xionvar` in-place with calculated ion fractions
- Uses 1-based indexing for Julia compatibility (converts from 0-based Fortran)
- Includes comprehensive debug output capabilities
- Returns `nothing` as results are stored in `tempr.xionvar`
"""
function fractions_old!(kern::Int, ionz::Int,
                        ionps::IonProperties,
                        tempr::TemperatureProperties,
                        elem::Element,
                        sml::SimulationData,
                        cfg::ConfigData,
                        pgp::PGPData, rt::RuntimeData, modions::ModionsData)

    # Extract temperature grid parameters
    alogt = tempr.alogt
    ncool = cfg.atomic_ionic_fraction.ncool

    # Initialize interpolation arrays
    ionps.tcf .= 0.0
    ionps.rlamba .= 0.0
    ionps.rlamb0 .= 0.0
    ionps.beta .= 0.0 

    # Extract grid dimensions
    in_dim = cfg.grid_size.grid_point.x
    jn_dim = cfg.grid_size.grid_point.y  
    kn_dim = cfg.grid_size.grid_point.z

    # Get element identifier
    eid = elem.idk[kern]

    # === Prepare coarse temperature grid and radiative loss data ===
    for i in 1:ncool
        # Convert logarithmic temperature to linear scale
        ionps.tcool[i] = 10.0^(alogt[i])
        
        # Extract ion fraction and convert to logarithmic scale
        yval = tempr.xion[eid, ionz+1, i]
        ionps.rlambc[i] = log10(yval)
    end

    # === Generate fine interpolation grid using radiative loss method ===
    ncoolf = rloss!(ionps, ncool)

    # === Debug output: Save interpolation data to file ===
    if cfg.debug.ldebug
        # Create debug directory if it doesn't exist
        mkpath("./debug_tl")
        
        # Generate debug filename with zero-padded element and ionization state
        coolfile = "./debug_tl/Atom=$(lpad(kern, 2, '0'))_$(lpad(ionz, 2, '0')).DAT"
        
        open(coolfile, "w") do io
            for k in 1:ncoolf
                # Format debug output: log10(tcf), 10^rlamba, beta, rlamb0, index
                tcf_log = log10(ionps.tcf[k])
                rlamba_exp = 10.0^ionps.rlamba[k]
                beta_val = ionps.beta[k]
                rlamb0_val = ionps.rlamb0[k]
                
                Printf.@printf(io, " %14.7e  %14.7e  %14.7e  %14.7e %4i\n", 
                               tcf_log, rlamba_exp, beta_val, rlamb0_val, k)
            end
        end
    end

    # === Allocate 3D array for ion fraction mapping ===
    frac = Array{Float64}(undef, in_dim, jn_dim, kn_dim)

    # === Compute 3D ion fraction distribution ===
    mapfractions!(kern, ncoolf, frac, ionps, tempr, elem, sml, cfg, rt)

    # === Normalize and store results ===
    # Apply hydrogen mass normalization and enforce minimum value
    tempr.xionvar[:, :, :, eid, ionz+1] .= max.(frac ./ AstroTLPlot.MH, 1.0e-30)

    return nothing
end

# ==============================================================================
# Function: fractions_old!
# Purpose: Compute ion fractions using radiative-loss based interpolation (legacy method)
# ==============================================================================
"""
    fractions_old!(kern::Int, ionz::Int, ionps::IonProperties, tempr::TemperatureProperties,
                   elem::Element, sml::SimulationData, cfg::ConfigData, pgp::PGPData, 
                   rt::RuntimeData, modions::ModionsData)

Compute ion population fractions using the legacy radiative-loss based interpolation method.

This function implements the faster "old" method for calculating ion fractions by
interpolating pre-computed radiative loss data. It processes temperature-dependent
ionization data through multiple stages: coarse grid preparation, fine grid refinement
via `rloss!`, and 3D mapping via `mapfractions!`.

# Arguments
- `kern::Int`: Element identifier/kernel number
- `ionz::Int`: Ionization state (0-based)
- `ionps::IonProperties`: Ion property data structure (modified in-place)
- `tempr::TemperatureProperties`: Temperature-dependent properties including ion fractions
- `elem::Element`: Element composition and atomic data
- `sml::SimulationData`: Simulation field data (temperature, density)
- `cfg::ConfigData`: Configuration parameters including debug flags
- `pgp::PGPData`: Post-processing parameters
- `rt::RuntimeData`: Runtime data structure
- `modions::ModionsData`: Ionization module specific data

# Processing Pipeline
1. **Coarse Grid Preparation**: Convert logarithmic temperature points to linear scale
2. **Radiative Loss Calculation**: Call `rloss!` to create fine interpolation grid
3. **Debug Output**: Optionally save interpolation data to files
4. **3D Mapping**: Use `mapfractions!` to compute ion fractions across simulation grid
5. **Normalization**: Apply hydrogen mass normalization and minimum value clipping

# Key Features
- Uses pre-computed radiative loss tables for efficient interpolation
- Supports debug output for validation and analysis
- Applies physical normalization using hydrogen mass constant
- Maintains numerical stability with minimum value enforcement

# Notes
- Modifies `tempr.xionvar` in-place with calculated ion fractions
- Uses 1-based indexing for Julia compatibility (converts from 0-based Fortran)
- Includes comprehensive debug output capabilities
- Returns `nothing` as results are stored in `tempr.xionvar`
"""
function _fractions_old!(kern::Int, ionz::Int,
                        ionps::IonProperties,
                        tempr::TemperatureProperties,
                        elem::Element,
                        sml::SimulationData,
                        cfg::ConfigData,
                        pgp::PGPData, rt::RuntimeData, modions::ModionsData)

    # Extract temperature grid parameters
    alogt = tempr.alogt
    ncool = cfg.atomic_ionic_fraction.ncool

    # Initialize interpolation arrays
    ionps.tcf .= 0.0
    ionps.rlamba .= 0.0
    ionps.rlamb0 .= 0.0
    ionps.beta .= 0.0 

    # Extract grid dimensions
    in_dim = cfg.grid_size.grid_point.x
    jn_dim = cfg.grid_size.grid_point.y  
    kn_dim = cfg.grid_size.grid_point.z

    # Get element identifier
    eid = elem.idk[kern]

    # === Prepare coarse temperature grid and radiative loss data ===
    for i in 1:ncool
        # Convert logarithmic temperature to linear scale
        ionps.tcool[i] = 10.0^(alogt[i])
        
        # Extract ion fraction and convert to logarithmic scale
        yval = tempr.xion[eid, ionz+1, i]
        ionps.rlambc[i] = log10(yval)
    end

    # === Generate fine interpolation grid using radiative loss method ===
    ncoolf = rloss!(ionps, ncool)

    # === Debug output: Save interpolation data to file ===
    if cfg.debug.ldebug
        # Create debug directory if it doesn't exist
        mkpath("./debug_tl")
        
        # Generate debug filename with zero-padded element and ionization state
        coolfile = "./debug_tl/Atom=$(lpad(kern, 2, '0'))_$(lpad(ionz, 2, '0')).DAT"
        
        open(coolfile, "w") do io
            for k in 1:ncoolf
                # Format debug output: log10(tcf), 10^rlamba, beta, rlamb0, index
                tcf_log = log10(ionps.tcf[k])
                rlamba_exp = 10.0^ionps.rlamba[k]
                beta_val = ionps.beta[k]
                rlamb0_val = ionps.rlamb0[k]
                
                Printf.@printf(io, " %14.7e  %14.7e  %14.7e  %14.7e %4i\n", 
                               tcf_log, rlamba_exp, beta_val, rlamb0_val, k)
            end
        end
    end

    # === Allocate 3D array for ion fraction mapping ===
    frac = Array{Float64}(undef, in_dim, jn_dim, kn_dim)

    # === Compute 3D ion fraction distribution ===
    mapfractions!(kern, ncoolf, frac, ionps, tempr, elem, sml, cfg, rt)

    # === Normalize and store results ===
    # Apply hydrogen mass normalization and enforce minimum value
    tempr.xionvar[:, :, :, eid, ionz+1] .= max.(frac ./ AstroTLPlot.MH, 1.0e-30)

    return nothing
end

# ==============================================================================
# Function: mapfractions!
# Purpose: Compute 3D ion fraction maps using temperature-dependent interpolation
# ==============================================================================
"""
    mapfractions!(kern::Int, ncoolf::Int, frac::Array{Float64,3},
                  ionp::IonProperties, ion_props::TemperatureProperties,
                  element::Element, sml::SimulationData, cfg::ConfigData, rt::RuntimeData)

Compute 3D ion fraction distributions using temperature-dependent interpolation of cooling function data.

This function populates a 3D array with ion fraction values by interpolating pre-computed
cooling function data onto the local temperature field of the simulation grid. It implements
the fine-grid mapping algorithm from the original Fortran code, handling temperature range
validation, logarithmic scaling, and physical unit conversions.

# Arguments
- `kern::Int`: Element identifier index
- `ncoolf::Int`: Number of cooling function interpolation points
- `frac::Array{Float64,3}`: Output array to be filled with ion fraction values (modified in-place)
- `ionp::IonProperties`: Ion property data containing cooling function tables
- `tepr::TemperatureProperties`: Temperature-dependent properties structure
- `elem::Element`: Element composition and abundance data
- `sml::SimulationData`: Simulation data containing temperature and density fields
- `cfg::ConfigData`: Configuration parameters for grid dimensions and processing boundaries
- `rt::RuntimeData`: Runtime data and state information

# Algorithm
1. **Initialization**: Set output array to default low values (1.0e-30)
2. **Temperature Scaling**: Convert cooling function temperatures to logarithmic scale
3. **Grid Processing**: Iterate through valid grid points within specified boundaries
4. **Index Calculation**: Compute temperature indices for interpolation
5. **Cooling Function Interpolation**: Use linear interpolation in log-space
6. **Ion Fraction Computation**: Apply abundance and density scaling

# Physical Model
- Uses cooling function data (`rlamba`, `beta`) from `rloss!` fine grid
- Applies element abundance corrections
- Converts between logarithmic and linear scales appropriately
- Handles edge cases with temperature range clamping

# Notes
- Modifies the `frac` array in-place for memory efficiency
- Returns the modified `frac` array (contrary to original Fortran version)
- Includes comprehensive boundary checking and warning messages
- Maintains compatibility with original Fortran algorithm structure
"""
function mapfractions!(kern::Int, ncoolf::Int, frac::Array{Float64,3},
                       ionp::IonProperties, tepr::TemperatureProperties,
                       elem::Element, sml::SimulationData, cfg::ConfigData, rt::RuntimeData)

   # println("MAP_FRACTION INSIDE!!!")

    # Extract grid dimensions from configuration
    in_dim = cfg.grid_size.grid_point.x
    jn_dim = cfg.grid_size.grid_point.y  
    kn_dim = cfg.grid_size.grid_point.z

    # Define processing boundaries with 1-based indexing
    imin = Int(cfg.real_dims.min.x + 1)
    imax = in_dim
    jmin = Int(cfg.real_dims.min.y + 1)
    jmax = jn_dim
    kmin = Int(cfg.real_dims.min.z + 1)
    kmax = kn_dim
       
    # Access simulation fields
    tem = sml.tem
    den = sml.den
    abund = elem.abund[kern]

    # Extract cooling function interpolation parameters
    tcf = ionp.tcf
    rlamba = ionp.rlamba
    beta = ionp.beta
    dtf = ionp.dtf   
    
    # Initialize temperature vector in logarithmic scale
    tempe = zeros(Float64, ncoolf)

    # Initialize output array with default low value
    fill!(frac, 1.0e-30) 

    # Convert cooling function temperatures to logarithmic scale
    for i in 1:ncoolf
        tempe[i] = log10(ionp.tcf[i])
    end

    # Determine valid temperature range for interpolation
    temin = tempe[1]
    temax = tempe[end]

    # Extract element abundance
    abund_k = elem.abund[kern]
    nmedia = 0.0  # Diagnostic counter for processed points

    # Process each grid point within specified boundaries
    for kk in kmin:kmax
        for jj in jmin:jmax
            for ii in imin:imax
                tval = tem[ii, jj, kk]
                temper = log10(tval)
                
                # Process only points within valid temperature range
                if temper <= temax && temper >= temin
                    # Calculate temperature index for interpolation
                    it = trunc(Int, (temper - tempe[1]) / dtf) + 1
                    
                    # Clamp index to valid range with warning
                    if it > ncoolf
                        it = ncoolf
                        @warn "mapfractions: temperature index > ncoolf, clamped to $it for kern=$kern"
                    end

                    # Interpolate cooling function value using linear interpolation in log-space
                    enloss = rlamba[it] + beta[it] * (temper - tempe[it])
                    enloss = 10.0^enloss  # Convert back to linear scale
                                        
                    # Compute ion fraction with abundance and density scaling
                    frac[ii, jj, kk] = abund_k * den[ii, jj, kk] * enloss
                    
                    nmedia += 1  # Diagnostic: count processed points
                else
                    # Point outside valid temperature range retains default value
                    println("Temperature outside valid range at ($ii, $jj, $kk)")
                end
            end
        end
    end

    return frac  # Return modified array (in-place modification)
end

# ==============================================================================
#
# Compute ion fractions for all configured elements and ionization states
#
# ==============================================================================

"""
    ions!(
        ionp::IonProperties,
        temprops::TemperatureProperties,
        elem::Element,
        sml::SimulationData,
        cfg::ConfigData,
        pgp::PGPData,
        rt::RuntimeData,
        modions::ModionsData;
        method::Symbol = :auto,
        formats::Vector{String} = ["png"],                     
        base_save_path::AbstractString = "./data/output/ions" 
    ) -> Nothing

Compute ion fractions for all configured elements and ionization states, populate
`temprops.xionvar`, and generate ion fraction maps.

The function iterates over `kern` (element index) and `ionz` (ionization states 0..kern),
applies the selected interpolation method (legacy `fractions_old!` or `fractions_spline!`),
copies the 3D ion fraction block into a local array `fracion`, and dispatches plotting
via `mapas_ions!`.

# Arguments
- `ionp::IonProperties`: Ion-related properties used by the interpolation functions.
- `temprops::TemperatureProperties`: Holds `xionvar`, where ion fractions are stored as
  `xionvar[in_dim, jn_dim, kn_dim, elem_id, ion_index]`.
- `elem::Element`: Element metadata (e.g., `kernmax`, `zelem`, `plelem`, `idk`, bounds).
- `sml::SimulationData`: Simulation grids (`X_grid`, `Y_grid`, `Z_grid`) and fields if needed.
- `cfg::ConfigData`: Configuration (grid sizes, interpolation flags, scales, log flags).
- `pgp::PGPData`: Plot/graphics parameters (labels, titles, view toggles).
- `rt::RuntimeData`: Runtime loop configuration.
- `modions::ModionsData`: Ion modeling configuration.
- `method::Symbol`: `:auto` (default; uses `cfg.interpolation.lspline`), `:legacy` (uses `fractions_old!`),
  or `:spline` (uses `fractions_spline!`).
- `formats::Vector{String}`: Output formats forwarded to `mapas_ions!` (e.g., `["png"]`, `["pdf","png"]`).
- `base_save_path::AbstractString`: Base folder used by `mapas_ions!` to save outputs.

# Additional Keywords
- `id_string::AbstractString`: Snapshot identifier forwarded to downstream routines to create FAIR-compliant
  folder structures (e.g., `<root>/snapshots/<id>/species/ions/...`) and to derive a numeric `filenum` for filenames.
- `root::AbstractString = "output_fair"`: Root directory used by FAIR path helpers (e.g., `prepare_ion_paths`).

# Behavior
1. Reads element properties and configuration flags.
2. Zeros out `temprops.xionvar` before computation.
3. Chooses the interpolation method:
   - `:auto` → `:spline` if `cfg.interpolation.lspline == true`, otherwise `:legacy`.
   - `:legacy` → calls `fractions_old!`.
   - `:spline` → placeholder (enable `fractions_spline!` when available).
4. For each valid element `kern` (where `elem.zelem[kern] == true`) and ion state `ionz` in `0:kern`:
   - Calls the chosen interpolation to fill `temprops.xionvar[... , elem.idk[kern], ionz+1]`.
   - Copies the relevant 3D block into `fracion`.
   - If `elem.plelem[kern]` is `true`, dispatches to `mapas_ions!` to visualize the ion fraction volume,
     forwarding `formats`, `id_string`, and `root` to keep FAIR outputs consistent.
5. After looping ion states, if `elem.plelem[kern]` is `true`, generates an **element-level subplot panel**
   with `plot_element_subplot`, saving to a FAIR path under the element directory (e.g., `.../subplots/`).

# Returns
- `Nothing`. Side effects include populating `xionvar` and generating plots.

# Dependencies
Requires in scope:
- Interpolation: `fractions_old!` and/or `fractions_spline!` (if you enable spline mode).
- Plotting: `mapas_ions!` (accepting `formats`, FAIR paths via `id_string`/`root`) and `plot_element_subplot`.
- FAIR/paths & I/O: `prepare_ion_paths` (used inside downstream calls), `mkpath` for directory creation.
- Types: `IonProperties`, `TemperatureProperties`, `Element`, `SimulationData`, `ConfigData`, `PGPData`, `RuntimeData`, `ModionsData`.
- Labels: `ionstexto` (used to resolve element symbol and ion labels when building element subplot paths).

# Notes
- `method = :auto` respects `cfg.interpolation.lspline`; set `:legacy` to force the old method or `:spline` if available.
- `temprops.xionvar` is assumed preallocated with shape `(in_dim, jn_dim, kn_dim, nelements, nions_per_element)`.
- `mapas_ions!` is called with `fracion` and `var_name = "den"` in this pipeline; adjust if you prefer a different variable tag.
- The element-level subplot export uses FAIR-style directories based on `id_string`, element symbol, and `root`.
"""

function ions!(ionp::IonProperties, temprops::TemperatureProperties,
               elem::Element,
               sml::SimulationData,
               cfg::ConfigData,
               pgp::PGPData, rt::RuntimeData, modions::ModionsData;
               method::Symbol = :auto,
               formats::Vector{String} = ["pdf"],
               id_string::AbstractString,                 
               root::AbstractString = "output_fair"      
)
    # --- Element properties and atomic data ---
    kernmax = elem.kernmax         # Maximum element index to process
    nelem   = elem.nelem           # Number of elements (not used directly here)
    zelem   = elem.zelem           # Validity flags per element
    plelem  = elem.plelem          # Plot flags per element
    idk     = elem.idk             # Element IDs (mapping index -> eid)
    idkmin  = elem.idkmin          # Min ID bound (for reference)
    idkmax  = elem.idkmax          # Max ID bound (for reference)

    # --- Configuration flags ---
    lspline = cfg.interpolation.lspline      # Spline interpolation flag
    logs    = cfg.scales.logs                # Log scaling flag (not applied here)
    lratios = cfg.variable_params.lratios    # Whether to compute ion ratios (post-step)

    # --- Grid dimensions ---
    in_dim = cfg.grid_size.grid_point.x
    jn_dim = cfg.grid_size.grid_point.y
    kn_dim = cfg.grid_size.grid_point.z

    # --- Initialize output storage ---
    temprops.xionvar .= 0.0

    println("Starting IONS processing")

    # --- Decide interpolation method ---
    chosen_method = method == :auto ? (lspline ? :spline : :legacy) : method

    # --- Iterate through all elements and ionization states ---
    for kern in 1:kernmax
        # Process only valid elements
        if zelem[kern]
            eid = idk[kern]

            for ionz in 0:kern
               # println("Calling fractions for kern=$(kern), ionz=$(ionz+1)")

                # Compute ion fractions using the chosen interpolation method
                if chosen_method == :spline
                    # Spline interpolation method (enable when implemented)
                    fractions_spline!(kern, ionz + 1, temprops, cfg, pgp, rt, modions, elem)
                   # println("  fractions_spline! executed (placeholder)")
                else
                    # Legacy interpolation method
                    fractions_old!(kern, ionz, ionp, temprops, elem, sml, cfg, pgp, rt, modions)
                    #println("  fractions_old! executed for element $kern and ionization state $(ionz+1)")
                end

                # Extract the computed ion fraction block for this (kern, ionz)
                fracion = zeros(in_dim, jn_dim, kn_dim)
                fracion .= temprops.xionvar[1:in_dim, 1:jn_dim, 1:kn_dim, eid, ionz + 1]

                # Generate visualization maps for selected elements
                if plelem[kern]
                    # Forward formats and base_save_path to keep the pipeline consistent
                                                                            
                    maps_ions!(fracion, sml.X_grid, sml.Y_grid, sml.Z_grid, "den";
                                kern = kern, ionz = ionz, is_ions = true,
                                cfg = cfg, pgp = pgp, rt = rt, modions = modions,
                                formats = formats,             
                                id_string=id_string,
                                root=root)
                end
            end 
           # generate subplot element
           if plelem[kern]
                # Obtain labels for this ionization state
                ion_labels = ionstexto(kern, 0)
                elem_sym = first(split(ion_labels.titleion))
                elem_dir = joinpath(root, "snapshots", id_string, "species", "ions", elem_sym)
                mkpath(elem_dir)
                # Create subplots/ and save
                subplots_dir = joinpath(elem_dir, "subplots")
                mkpath(subplots_dir)
                                
                plot_element_subplot(temprops, sml, elem, kern;
                    ncols=4, save_dir= subplots_dir, formats=["pdf"])
           end
        end
    end

    println("Ion maps completed, proceeding to electron calculations")

    # --- Optional: ion ratios post-processing ---
    if lratios
        # maps_ratios(temprops, elem, sml, cfg)  # To be implemented
    end

    return nothing
end
