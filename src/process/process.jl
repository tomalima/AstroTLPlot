# ==============================================================================
# Simulation Processing and Visualization Routines
# 
# This module provides high-level routines to preprocess simulation variables,
# validate data types, manage output directories, and generate visualizations.
# It supports batch processing of selected variables, integrates with runtime,
# plotting, and ion-physics configurations, and produces 2D maps/heatmaps from
# 3D fields via `mapas!` after computing derived variables with `compute_variable`.
#
# Author: [Tomás Lima]
# Date: [2025-10-17]
# ==============================================================================


const VAR_LIST = [
    "den",
    "ene",
    "pre",
    "pok",
    "tem",
    "vxx",
    "vyy",
    "vzz",
    "vel2",
    "bxx",
    "byy",
    "bzz",
    "sentrop",
    "ramp",
    "rampok",
    "dentok",   # not implemented 
    "ent",      # not in datastruct
    "mach",     # not in datastruct
    "val",      # not in datastruct
    "bxz",      # return nothing
    "bxy",      # not in datastruct
    "Pmg",      # not in datastruct
    "SSS",      # return nothing
    "beta"      # not in datastruct
]

# ==============================================================================
#
# 
#
# ==============================================================================

"""
    load_data()

Load and configure simulation data from configuration files and input data sources.

This function serves as the main data loading and initialization routine for the simulation pipeline.
It reads configuration parameters, allocates data structures, loads reference data, and processes
simulation variables. The function orchestrates the entire data preparation workflow.

# Workflow Steps
1. **Configuration Loading**: Reads `indatpgp.yaml` configuration file
2. **System Configuration**: Computes increments, volumes, and other system parameters
3. **Memory Allocation**: Allocates data structures for simulation variables
4. **Reference Data Loading**: Reads time and file reference data from `ref.dat`
5. **Simulation Data Loading**: Loads HDF5 simulation data files
6. **Variable Processing**: Computes derived variables from loaded data

# Outputs
- Internal data structures are populated and ready for simulation processing
- Configuration data (`config_data`, `pgp_data`, `runtime_data`, `modions_data`)
- Allocated simulation variables (`simulations_data`)
- Time-file mapping (`timefile`)

# File Dependencies
- `./data/config/indatpgp.yaml`: Main configuration file
- `/home/tomaslima/julia_tlima/pkg/AstroTLPlot/data/input/ref/ref.dat`: Reference time data
- HDF5 data files: Simulation output data

# See Also
- [`read_indatpgp3`](@ref): Reads configuration from YAML file
- [`configure`](@ref): Configures system parameters and volumes
- [`allocate_vars`](@ref): Allocates memory for simulation variables
- [`read_ref_data_ds`](@ref): Reads reference time data
- [`readdata_hdf5!`](@ref): Loads HDF5 simulation data
- [`variables_v2!`](@ref): Processes derived variables

# Example
```julia
load_data()  # Loads and prepares all simulation data
"""

function load_data()

        # Read data from configuration file
        file_name = "./data/config/indatpgp.yaml"
        
        #data = YAML.load_file(file_name)
        config_data, pgp_data, runtime_data, modions_data = load_simulation_config(file_name)
        all_config=load_simulation_config_struct(file_name)

        # Additional processing
        # Calculate system parameters
        _increments, _set_min_max_index, vol_local, vol_global, tr = configure(config_data, pgp_data, runtime_data)

        # Allocate memory for simulation variables
        simulations_data, time_files = allocate_vars(config_data, pgp_data, runtime_data)

        # Load reference data
        # File name and number of entries to read
        filename="/home/tomaslima/julia_tlima/pkg/AstroTLPlot/data/input/ref/ref.dat"

        timescale = config_data.scales.timescale
        nfiles =  config_data.number_of_plots.nfiles

       # Read reference data from ref.dat - generates TimeFile with time::Vector{Float64} and files::Vector{Int} 
        timefile = read_ref_data_ds(filename, nfiles, timescale)
            
        # Load HDF5 simulation data (alternative version commented out)
        # readdata_hdf5_v4_alt!(simulations_data, config_data, runtime_data)
        readdata_hdf5!(simulations_data, config_data, runtime_data)

        # Process variables - reads and computes additional variables (tem, pre, vel2, etc.)
        variables_v2!( simulations_data,config_data)
 end
 

# ==============================================================================
#
# Compute and return a specific physical variable from simulation data.
#
# ============================================================================== 

"""
    compute_variable(var_name::String, simdata::SimulationData;
                     cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData)

Compute and return a specific physical variable from simulation data.

This function serves as a central dispatcher for calculating various physical quantities
from the raw simulation data. It handles both direct field access and computed derived variables
involving combinations of multiple fields and physical constants.

# Arguments
- `var_name::String`: Name of the variable to compute (see supported variables below)
- `simdata::SimulationData`: Simulation data structure containing all field variables
- `cfg::ConfigData`: Configuration data with grid sizes and scaling factors
- `pgp::PGPData`: Post-processing configuration data
- `rt::RuntimeData`: Runtime parameters and data
- `modions::ModionsData`: Ions and modifications data

# Returns
- `::AbstractArray{Float64,3}`: 3D array containing the computed variable data

# Supported Variables

## Basic Fields
- `"den"`: Density field  
- `"ene"`: Energy density field  
- `"pre"`: Pressure field  
- `"tem"`: Temperature field  
- `"vxx"`, `"vyy"`, `"vzz"`: Velocity components  
- `"bxx"`, `"byy"`, `"bzz"`: Magnetic field components  

## Derived Quantities
- `"vel2"`: Velocity magnitude squared (v² = vx² + vy² + vz²)  
- `"pok"`: Pressure normalized by Boltzmann constant (pre / BOLTZ)  
- `"sentrop"`: Entropy field  
- `"ram"`: Dynamic pressure (0.5 * den * vel²)  
- `"rok"`: Dynamic pressure normalized by Boltzmann constant  
- `"ent"`: Entropy (alternative formulation)  
- `"mach"`: Mach number (velocity / sound speed)  
- `"val"`: Alfvén velocity  
- `"bxy"`: Magnetic field magnitude (normalized)  
- `"Pmg"`: Magnetic pressure (B² / (8π))  
- `"beta"`: Plasma beta parameter (thermal pressure / magnetic pressure)  

# Precomputed Quantities
- Magnetic field squared: `b2 = bxx² + byy² + bzz²`  
- Velocity squared: `vel2 = vxx² + vyy² + vzz²`  
  (Both are recomputed in this function for clarity and safety.)

# Physical Constants Used
- `AstroTLPlot.BOLTZ`: Boltzmann constant  
- `AstroTLPlot.MH`: Hydrogen mass  
- `AstroTLPlot.GAMMA`: Adiabatic index  
- `AstroTLPlot.GAMMA1`: γ − 1  

# Error Handling
- Throws an error if an unknown variable name is provided.  
- Returns `nothing` for unsupported or placeholder variables (e.g. `"dentok"`).  
- Logs warnings for incomplete or placeholder implementations (`"SSS"`).

# Additional Notes
- Some derived quantities (entropy, Mach number, dynamic pressure) include protection against `log10(0)` or division by zero using small numerical floors (e.g., `1e-30`).
- The function currently recomputes `b2` and `vel2` even if preallocated—kept for clarity and functional isolation.
- The `"SSS"` branch appears to be an experimental or placeholder calculation for plasma beta; maintained unchanged.

# Example
```julia
# Compute Mach number from simulation data
mach_number = compute_variable("mach", simdata, cfg=cfg, pgp=pgp, rt=rt, modions=modions)

# Compute magnetic pressure
mag_pressure = compute_variable("Pmg", simdata, cfg=cfg, pgp=pgp, rt=rt, modions=modions)
"""

function compute_variable(var_name::String, simdata::SimulationData;
                            cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData)
    # Extract grid dimensions from configuration
    in,jn,kn=cfg.grid_size.grid_point.x,cfg.grid_size.grid_point.y,cfg.grid_size.grid_point.z
     
    # Precompute magnetic field squared (used by multiple variables)
    b2 = zeros(in, jn, kn)
    b2 = simdata.bxx.^2 .+ simdata.byy.^2 .+ simdata.bzz.^2
    
    # Precompute velocity squared (used by multiple variables)
    vel2= zeros(in, jn, kn)
    vel2 = simdata.vxx.^2 .+ simdata.vyy.^2 .+ simdata.vzz.^2
    simdata.vel2 = vel2
    
    # Initialize density array (commented scaling operation)
    dens = zeros(in, jn, kn)
    # dens = simdata.den .*= cfg.scale.denscale
    
    # Recompute b2 (redundant but kept for clarity)
    b2 = simdata.bxx.^2 .+ simdata.byy.^2 .+ simdata.bzz.^2
    
    # Dispatch to appropriate variable calculation based on name
    if var_name == "den"
       #return simdata.den .*= cfg.scale.denscale 
        return simdata.den
    elseif var_name == "ene"
       return simdata.ene
    elseif var_name == "pre"
        return simdata.pre
    elseif var_name == "pok"
        # pok=pre/boltz
         simdata.pok .= simdata.pre ./ AstroTLPlot.BOLTZ
        return simdata.pok
    elseif var_name == "tem"
        return simdata.tem
     elseif var_name == "vxx"
        return simdata.vxx
    elseif var_name == "vyy"
        return simdata.vyy
     elseif var_name == "vzz"
        return simdata.vzz
    elseif var_name == "vel2"
        return simdata.vel2 # = simdata.vxx.^2 .+ simdata.vyy.^2 .+ simdata.vzz.^2
    elseif var_name == "bxx"
        return simdata.bxx
    elseif var_name == "byy"
        return simdata.byy
     elseif var_name == "bzz"
        return simdata.bzz
    elseif var_name == "sentrop"
        smallp = 1e-30  # Minimum value to avoid log10(0)
        simdata.sentrop .= 1.5 * AstroTLPlot.BOLTZ / AstroTLPlot.MH .* 
                   (log10.(max.(smallp, AstroTLPlot.GAMMA1 .* simdata.ene)) .- 
                    AstroTLPlot.GAMMA .* log10.(simdata.den))
        #return simdata.bzz 
    elseif var_name == "ram" #ramp
        # Dynamic pressure: p_ram = 0.5 * den * vel²
        simdata.ramp   .= 0.5 .* simdata.den .* simdata.vel2
        # Optional logarithmic scaling (commented out)
        # if configData.logs
        #    simdata.pram   .= log10.(max.(1e-30, simdata.pram))
        # end
        return simdata.ramp
     elseif var_name == "rok" # rampok # Normalized dynamic pressure
        # Dynamic pressure normalized by Boltzmann constant
        simdata.rampok .= simdata.ramp ./ AstroTLPlot.BOLTZ
        #if configData.logs
         #   simdata.pokram .= log10.(max.(1e-30, simdata.pokram)) no plot fazer isso
        #end
        return simdata.rampok 
    elseif var_name == "dentok"
        return nothing
    elseif var_name == "ent"
         # Alternative entropy calculation
        entr = zeros(in, jn, kn)
        entr = 1.5 * AstroTLPlot.BOLTZ  / AstroTLPlot.MH  * 
        (log10.(max.(smallp, AstroTLPlot.GAMMA1 .* simdata.ene)) .- AstroTLPlot.GAMMA .* log10.(simdata.den))
        return entr
    elseif var_name == "mach"
        # Mach number: velocity / sound speed
        cs2 = zeros(in, jn, kn)
        mach = zeros(in, jn, kn)
        cs2 .= AstroTLPlot.GAMMA * AstroTLPlot.GAMMA1 * simdata.ene ./ simdata.den
        mach .= sqrt.(vel2) ./ sqrt.(cs2)
        return mach
     elseif var_name == "val"
        # Alfvén velocity: v_alfvén = sqrt(B² / (ρ * 4π)) / velocity_scale
       # b2 = zeros(in, jn, kn)
        valf = zeros(in, jn, kn)
        # valf = sqrt(B² / (ρ*4π)) / velscale
        #b2 = simdata.bxx.^2 .+ simdata.byy.^2 .+ simdata.bzz.^2
        valf = b2 ./ (simdata.den .* cfg.fourpi)
        valf = sqrt.(valf) ./ cfg.scale.velscale
        return valf
    elseif var_name == "bxz"
        return simdata.bxz # ??? (needs clarification)
     elseif var_name == "bxy"
         # Magnetic field magnitude normalized by scale
        #b2 = zeros(in, jn, kn)
        bxy = zeros(in, jn, kn)
       # b2 = simdata.bxx.^2 .+ simdata.byy.^2 .+ simdata.bzz.^2
        bxy = sqrt.(b2) ./ cfg.scale.bscale
        return bxy
    elseif var_name == "Pmg"
        # Magnetic pressure: P_mag = B² / (8π) = B² / (2 * 4π)
       # b2 = zeros(in, jn, kn)
        pmag = zeros(in, jn, kn)
       # b2=simdata.bxx.^2 .+ simdata.byy.^2 .+ simdata.bzz.^2
        pmag = b2 ./ (2.0 * cfg.fourpi)
        return pmag
     elseif var_name == "SSS" # Appears to be plasma beta (needs verification)
     
     # b2 = zeros(in, jn, kn)
        pmag = zeros(in, jn, kn)
        beta = zeros(in, jn, kn)
       # b2 = simdata.bxx.^2 .+ simdata.byy.^2 .+ simdata.bzz.^2
        pmag = b2 ./ (2.0 * configData.fourpi)
        beta = AstroTLPlot.GAMMA1 .* simdata.ene ./ pmag
        return beta                    # ??? (needs clarification - appears to be plasma beta)                     
        # return nothing
     elseif var_name == "beta"
        # Plasma beta: β = thermal pressure / magnetic pressure
       # b2 = zeros(in, jn, kn)
        pmag = zeros(in, jn, kn)
        beta = zeros(in, jn, kn)
       # b2 = simdata.bxx.^2 .+ simdata.byy.^2 .+ simdata.bzz.^2
        pmag = b2 ./ (2.0 * configData.fourpi)
        beta = AstroTLPlot.GAMMA1 .* simdata.ene ./ pmag
        return beta
    else  
        error("Unknown variable: $var_name")
    end
end

# ==============================================================================
#
# compute all variable return to data structures 
#
# ==============================================================================

"""
    setminmaxvar(variable::String, pgp::PGPData, modions::ModionsData)

Determines the minimum and maximum range values for a given simulation variable.

This function defines color scale limits (min/max) used for plotting or 
data normalization based on the variable name. Some variables have 
hard-coded limits, while others retrieve their limits dynamically 
from `PGPData` or `ModionsData` structures.

# Arguments
- `variable::String`: Name of the variable to set limits for.
- `pgp::PGPData`: Structure containing default min/max ranges for graphical variables.
- `modions::ModionsData`: Structure containing ion-related min/max ranges.

# Returns
- `(setmin, setmax)::Tuple{Float64, Float64}`: Minimum and maximum values for the variable.
- `nothing` if no predefined limits exist for the given variable.

# Notes
- This function ensures consistent color scaling across plots for the same variable.
- If the variable name is not recognized, `nothing` is returned and the caller 
  should handle default limits.
"""
function setminmaxvar(variable::String, pgp::PGPData, modions::ModionsData)
    # Access default PGP variable limits
    var_pgp = pgp.set_min_max_var

    # Determine variable-specific min/max limits
    setmin, setmax = begin
        if variable == "ent"
            (9.4, 9.6)
        elseif variable == "dto"
            (20.0, 22.0)
        elseif variable in ["CoO", "NoO", "AoO", "AoH"]
            (-2.0, 2.0)
        elseif variable in ["car", "nit", "oxy", "neo", "mgn", "sil", "sul", "arg", "iro"]
            (-12.00001, -1.00001)
        elseif variable == "hyd"
            (-4.00001, 1.500001)
        elseif variable == "hel"
            (-4.00001, 1.500001)
        elseif variable in ["ele", "elez"]
            (modions.set_min_max_ions.ele.min, modions.set_min_max_ions.ele.max)
        elseif variable == "den"
            (var_pgp.den.min, var_pgp.den.max)
        elseif variable == "tem"
            (var_pgp.tem.min, var_pgp.tem.max)
        elseif variable in ["pre", "ram"]
            (var_pgp.pre.min, var_pgp.pre.max)
        elseif variable in ["pok", "rok"]
            (var_pgp.pok.min, var_pgp.pok.max)
        elseif variable == "pmag"
            (var_pgp.pmag.min, var_pgp.pmag.max)
        elseif variable == "beta"
            (var_pgp.beta.min, var_pgp.beta.max)
        elseif variable in ["mach", "machb"]
            (var_pgp.mach.min, var_pgp.mach.max)
        elseif variable == "val"
            (var_pgp.val.min, var_pgp.val.max)
        elseif variable == "rot"
            (var_pgp.rot.min, var_pgp.rot.max)
        elseif variable in ["bxy", "bxz"]
            (var_pgp.b.min, var_pgp.b.max)
        elseif variable in ["co1", "co2", "co3"]
            (0.0, 1.000001)
        else
            # No predefined range found — return nothing so the caller can handle defaults
            return nothing
        end
    end

    return setmin, setmax
end

# ==============================================================================
#
# Automatically processes all 3D fields in a `SimulationData` object by generating maps/plots for each variable.
#
# ==============================================================================

"""
    process_simulation_files(simdata::SimulationData;
                            cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData)

Automatically processes all 3D fields in a `SimulationData` object by generating maps/plots for each variable.

This function iterates through all fields of the `SimulationData` structure, identifies 3D Float64 arrays,
and processes them using the `mapas!` function to generate visualizations. Each variable gets its own
subdirectory in the output folder for organized storage of generated figures.

# Arguments
- `simdata::SimulationData`: The simulation data containing all field variables to process
- `cfg::ConfigData`: Configuration data for the simulation
- `pgp::PGPData`: PGP (Post-Processing) configuration data
- `rt::RuntimeData`: Runtime data and parameters
- `modions::ModionsData`: Modifications/ions data for specialized processing

# Behavior
- Creates output directory `./figures/mavil` if it doesn't exist
- Iterates through all fields in `SimulationData`
- Filters for 3D Float64 arrays only
- Creates individual subdirectories for each variable
- Processes each valid variable using `compute_variable` and `mapas!` functions
- Prints progress messages for each variable being processed

# Example
```julia
process_simulation_files(simdata; 
                        cfg=config, pgp=pgp_data, rt=runtime_data, modions=modions_data)
See Also
compute_variable: Preprocesses individual variables

mapas!: Generates maps and plots for 3D data
"""

function process_simulation_files_old(simdata::SimulationData; # not files but simulatind da from file
                            cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData)

      save_path="./figures/mavil"
    # Create output directory if it doesn't exist 
    isdir(save_path) || mkdir(save_path)

    # Iterate over all fields in the struct
    for field in fieldnames(SimulationData)
        value = getfield(simdata, field)

        # # Only process 3D Float64 arrays
        if value isa AbstractArray{Float64,3}
            println(" Processing dataset: ", String(field))
                data_to_plot= compute_variable(String(field), simdata;cfg,pgp,rt,modions)
                    #compute_variable(String(field),simdata; cfg,pgp,rt,modions)

            # Create subdirectory for current variable
           subdir = joinpath(save_path, String(field))
           isdir(subdir) || mkdir(subdir)
            #=
            result=setminmaxvar(String(field),pgp,modions)
            # Optional: Set min/max values for color scaling
            smin, smax = result === nothing ? (0.0, 0.0) : result 
            =#
            
            mapas!(value, simdata.X_grid, simdata.Y_grid, simdata.Z_grid,String(field);
                   cfg=cfg, pgp=pgp, rt=rt, modions=modions)
        end
    end
end

# ==============================================================================
#
# Iterate over all fields in a `SimulationData` instance and generate plots/maps for each
# dataset that is a 3D `Float64` array.
#
# ==============================================================================

"""
    process_simulation_files(
        simdata::SimulationData;
        cfg::ConfigData,
        pgp::PGPData,
        rt::RuntimeData,
        modions::ModionsData,
        formats::Vector{String} = ["png"],               
        save_path::AbstractString = "./figures/mavil",   
        include_computed::Bool = true                   
    ) -> Nothing

Iterate over all fields in a `SimulationData` instance and generate plots/maps for each
dataset that is a 3D `Float64` array.

For each such dataset:
1. Logs which dataset is being processed.
2. Optionally computes a processed variable via `compute_variable(fieldname, ...)` if `include_computed == true`.
3. Creates a per-variable subfolder under `save_path`.
4. Calls `mapas!` to generate the maps/plots using the simulation grids and configuration.

# Arguments
- `simdata::SimulationData`: Container holding raw simulation arrays and grids (e.g., `X_grid`, `Y_grid`, `Z_grid`).
- `cfg::ConfigData`: Global configuration (real-space limits, scaling factors, log flags).
- `pgp::PGPData`: Plot/graphics configuration (titles, labels, view toggles).
- `rt::RuntimeData`: Runtime loop configuration (`lmin`, `stepl`, `lmax`).
- `modions::ModionsData`: Ion-related configuration for helpers such as `setminmaxvar`.
- `formats::Vector{String}`: Output formats (e.g., `["png"]`, `["pdf","png"]`, `["svg"]`).
- `save_path::AbstractString`: Base folder; the function creates subfolders per dataset/variable.
- `include_computed::Bool`: If `true`, also compute a processed variable via `compute_variable`; if `false`, plot the raw field.

# Behavior
- Iterates over `fieldnames(SimulationData)` and selects those whose value in `simdata` is `AbstractArray{Float64,3}`.
- Creates `joinpath(save_path, fieldname)` and dispatches to `mapas!` to produce plots under that folder.

# Returns
- `Nothing`. Side effects include generating plots and saving files in the specified folder structure.

# Dependencies
Requires in scope: `compute_variable`, `mapas!`, and types `SimulationData`, `ConfigData`, `PGPData`, `RuntimeData`, `ModionsData`.

# Notes
- If `mapas!` does not yet accept `formats` or a base save path, extend it similarly to `mapas` to maintain consistency.
- Use structured logging (`@info`) in production for better traceability.
"""
function process_simulation_files(simdata::SimulationData;
    cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData,
    formats::Vector{String} = ["png"],               
    save_path::AbstractString = "./figures/mavil",   
    include_computed::Bool = true                    
)
    # Ensure base output directory exists
    isdir(save_path) || mkdir(save_path)

    # Iterate over all fields in the SimulationData struct
    for field in fieldnames(SimulationData)
        value = getfield(simdata, field)

        # Only process 3D Float64 arrays
        if value isa AbstractArray{Float64, 3}
            fname = String(field)
            println("Processing dataset: ", fname)

            # Optionally compute a processed version of this variable (depends on your implementation)
            data_to_plot = include_computed ? compute_variable(fname, simdata; cfg = cfg, pgp = pgp, rt = rt, modions = modions) : value

            # If compute_variable failed or returned nothing, fall back to raw value (or skip)
            if data_to_plot === nothing
                println("Variable '$fname' could not be computed. Falling back to raw dataset.")
                data_to_plot = value
            end

            # Create subdirectory for current variable under the base path
            subdir = joinpath(save_path, fname)
            isdir(subdir) || mkdir(subdir)

            # Dispatch to map generator (forward formats and base path)
            mapas(value, simdata.X_grid, simdata.Y_grid, simdata.Z_grid, fname;
                   cfg = cfg, pgp = pgp, rt = rt, modions = modions,
                   formats = formats,                    # ← forward formats for saving
                   base_save_path = subdir)              # ← per-variable base folder
        end
    end

    return nothing
end

# ==============================================================================
#
# Compute and plot a simulation variable by name.
#
# ==============================================================================
"""
    process_variable(
        var_name::String,
        simdata::SimulationData;
        kern::Int = 0,
        ionz::Int = 0,
        is_ions::Bool = false,
        cfg::ConfigData,
        pgp::PGPData,
        rt::RuntimeData,
        modions::ModionsData,
        formats::Vector{String} = ["png"],
        save_path::AbstractString = "./figures/mavil",
        id_string::AbstractString,                 
        root::AbstractString = "output_fair"       
    ) -> Bool



This function:
1) Computes the requested variable via `compute_variable(var_name, simdata; ...)`.
2) Validates that it is a 3D `Float64` array.
3) Creates a per-variable output subfolder under `save_path`.
4) Delegates to `mapas!` to generate and save plots, forwarding `formats` and `save_path`.

# Arguments
- `var_name::String`: Variable name (e.g., `"den"`, `"tem"`, `"beta"`, etc.).
- `simdata::SimulationData`: Simulation data container, including `X_grid`, `Y_grid`, `Z_grid`.
- `kern::Int`, `ionz::Int`, `is_ions::Bool`: Ion-related parameters forwarded to downstream plotting.
- `cfg::ConfigData`, `pgp::PGPData`, `rt::RuntimeData`, `modions::ModionsData`: Configuration, plotting, runtime, and ion model settings.
- `formats::Vector{String}`: Output formats to save (e.g., `["png"]`, `["pdf","png"]`, `["svg"]`).
- `save_path::AbstractString`: Base output directory; a subfolder per variable is created.

# Additional Keywords
- `id_string::AbstractString`: Snapshot identifier forwarded to the downstream plotting dispatcher (`maps!`)
  so that FAIR‑compliant folder structures can be created automatically
  (e.g. `<root>/snapshots/<id>/variables/<var_name>/...`) and included in filenames.
- `root::AbstractString = "output_fair"`: FAIR root directory for plot outputs.

# Returns
- `Bool`: `true` if plotting was dispatched; `false` if the variable could not be processed.

# Dependencies
Requires `compute_variable` and `mapas!` to be in scope. `mapas!` should accept `formats`
and FAIR-related keywords (`id_string`, `root`) or a `save_path`/`base_save_path` kwarg.
- FAIR pathing is handled downstream via `maps!` using `id_string` and `root`.

# Notes
- If `compute_variable` supports a precomputed cache, it can be passed here for efficiency.
- Consider replacing `println` with `@info` in production for structured logging.
"""
function process_variable(
    var_name::String,
    simdata::SimulationData;
    kern::Int = 0,
    ionz::Int = 0,
    is_ions::Bool = false,
    cfg::ConfigData,
    pgp::PGPData,
    rt::RuntimeData,
    modions::ModionsData,
    formats::Vector{String} = ["png"],
    id_string::AbstractString,                 
    root::AbstractString = "output_fair"      
) :: Bool

    # Compute the requested variable
    data_to_plot = compute_variable(var_name, simdata; cfg = cfg, pgp = pgp, rt = rt, modions = modions)

    # Skip if computation failed
    if data_to_plot === nothing
        println("Variable '$var_name' could not be processed, skipping.")
        return false
    end

    # Validate data type (must be 3D Float64 array)
    if !(data_to_plot isa AbstractArray{Float64, 3})
        println("Variable '$var_name' is not an AbstractArray{Float64,3}, skipping.")
        return false
    end

    # Generate maps/plots (forward formats and a variable-specific save path)
    maps!(data_to_plot, simdata.X_grid, simdata.Y_grid, simdata.Z_grid, var_name;
           kern = kern, ionz = ionz, is_ions = is_ions,
           cfg = cfg, pgp = pgp, rt = rt, modions = modions,
           formats = formats,
          id_string = id_string,      
          root = root)               

    return true
end

# ==============================================================================
#
# Process a list of variable names for a given simulation dataset and generate plots/maps for each.
#
# ==============================================================================
"""
    process_simulation_list(
        simdata::SimulationData;
        kern::Int = 0,
        ionz::Int = 0,
        is_ions::Bool = false,
        cfg::ConfigData,
        pgp::PGPData,
        rt::RuntimeData,
        modions::ModionsData,
        variable_names::Vector{String},
        formats::Vector{String} = ["png"],                   
        save_path::AbstractString = "./figures/mavil",       
        filenum::Union{Int,String},                          
        root::AbstractString = "output_fair"                 
    ) -> Nothing

Process a list of variable names for a given simulation dataset and generate plots/maps for each.

For each entry in `variable_names`, this function:
1. Logs which variable is being processed.
2. Calls `process_variable(...)` to compute the variable data, validate it, create per-variable folders,
   and delegate plotting via `mapas!`.
3. Forwards `formats` and `save_path` so that all outputs can be organized under the same base path
   (each variable goes into `joinpath(save_path, var_name)`).

# Arguments
- `simdata::SimulationData`: Simulation data container with grids (`X_grid`, `Y_grid`, `Z_grid`) and raw arrays.
- `kern::Int`, `ionz::Int`, `is_ions::Bool`: Ion parameters forwarded to downstream plotting routines.
- `cfg::ConfigData`: Configuration (real-space limits, scaling, log flags).
- `pgp::PGPData`: Plot/graphics parameters (titles, labels, view toggles).
- `rt::RuntimeData`: Runtime loop configuration.
- `modions::ModionsData`: Ion configuration (used by helpers like `setminmaxvar`).
- `variable_names::Vector{String}`: List of variable names to process (e.g., `["den","tem"]`).
- `formats::Vector{String}`: Output formats to save (e.g., `["png"]`, `["pdf","png"]`, `["svg"]`).
- `save_path::AbstractString`: Base folder under which per-variable subfolders are created.

# Additional Keywords
- `filenum::Union{Int,String}`: Snapshot index/identifier used to construct a canonical `id_string`
  (e.g., `"all003000"`) via `build_id_string(filenum)`. This `id_string` é passado a jusante para naming
  consistente dos ficheiros e construção de diretórios FAIR.
- `root::AbstractString = "output_fair"`: Diretório raiz FAIR. É encaminhado a jusante para que as funções
  de mapeamento (`maps!` e wrappers) criem a árvore de output FAIR-compliant.

# Returns
- `Nothing`. Side effects include generating plots and saving files to disk.

# Dependencies
Requires `process_variable` in scope, and types: `SimulationData`, `ConfigData`, `PGPData`, `RuntimeData`, `ModionsData`.

# Notes
- `process_variable` é chamado com `id_string` (derivado de `filenum`) e `root`, garantindo naming consistente
  e organização FAIR nas funções de plot a jusante.
- Use `@info`/`@warn` para *structured logging* em produção em vez de `println`.
"""
function process_simulation_list(
    simdata::SimulationData;
    kern::Int = 0,
    ionz::Int = 0,
    is_ions::Bool = false,  # ion mode flag
    cfg::ConfigData,
    pgp::PGPData,
    rt::RuntimeData,
    modions::ModionsData,
    variable_names::Vector{String},
    formats::Vector{String} = ["png"],           
    filenum::Union{Int,String},                  
    root::AbstractString = "output_fair"         
  )
    # Build snapshot id_string like "all003000" from the provided filenum
    id_string = build_id_string(filenum)

    # === Loop over validated variable names ===
    for var_name in variable_names
        println("Processing variable: ", var_name)
        # Preprocess and plot each variable
        # Delegate per-variable work, forwarding id_string/root
        process_variable(var_name, simdata;
                             kern = kern, ionz = ionz, is_ions = is_ions,
                             cfg = cfg, pgp = pgp, rt = rt, modions = modions,
                             formats = formats,          # forward formats
                             #save_path = save_path)     # save_path = save_path)     # forward base output path
                            id_string = id_string,     
                            root = root                
            ) 
    end
 return nothing
end

# ==============================================================================
#
# 
#
# ==============================================================================

function index_to_coord(ix::Int, iy::Int, nx, ny, xrange, yrange)
    x_real = xrange[1] + (ix-1)/(nx-1) * (xrange[2]-xrange[1])
    y_real = yrange[1] + (iy-1)/(ny-1) * (yrange[2]-yrange[1])
    return (x_real, y_real)
end
