# scripts/main.jl
# main.jl - Sequential code, no functions

# Load Configuration 
file_name = "./data/config/indatpgp.yaml"  
result = load_simulation_config(file_name)

# --- Error Handling ---
if isa(result, Int)
    error_code_to_display = result
    if !haskey(AstroTLPlot.ERROR_MESSAGES_DICT, result)
        error_code_to_display = AstroTLPlot.ERROR_UNKNOWN 
    end
    println("ERROR loading configuration: ", AstroTLPlot.ERROR_MESSAGES_DICT[error_code_to_display])
    # exit(1)  
else
    config_data, pgp_data, runtime_data, modions_data = result
    println(AstroTLPlot.ERROR_MESSAGES_DICT[AstroTLPlot.STATUS_SUCCESS])
    println("Directory: ", config_data.directories.directory) 
end

# Configure & Allocate
_increments, _set_min_max_index, vol_local, vol_global, tr = configure(config_data, pgp_data, runtime_data)
simulations_data, time_files = allocate_vars(config_data, pgp_data, runtime_data)
filename = "./data/input/ref/ref.dat"

# setup config 
timescale = config_data.scales.timescale
nfiles =  config_data.number_of_plots.nfiles
timefile = read_ref_data_ds(filename, nfiles, timescale)

filenumber = config_data.number_of_plots.nfile_start
datafile = joinpath(config_data.directories.directory, "all00$(filenumber).h5")
read_result = readdata_hdf5!(datafile, simulations_data, config_data, runtime_data)

if isa(read_result, Int)
    error_code_to_display = read_result
    if !haskey(AstroTLPlot.ERROR_MESSAGES_DICT, read_result)
        error_code_to_display = AstroTLPlot.ERROR_UNKNOWN 
    end
    println("CRITICAL ERROR during HDF5 data reading: ",
            AstroTLPlot.ERROR_MESSAGES_DICT[error_code_to_display])
    # exit(1)  
else
    println(AstroTLPlot.ERROR_MESSAGES_DICT[AstroTLPlot.STATUS_SUCCESS])
    println("All simulation data is ready for processing.")
end

# Process Variables & Ions
variables!(simulations_data, config_data)
elem = count_ions(config_data)
abundances!(config_data, elem)
tps = ions_read(config_data, pgp_data, runtime_data, modions_data, elem)
ionp = create_ionproperties()
println("All simulation data is ready for plotting.")

#=function run_simulation(; file_name="./data/config/indatpgp.yaml")
    # Load Configuration 
    result = load_simulation_config(file_name)
    
    # --- Error Handling ---
    if isa(result, Int)
        error_code_to_display = result
        if !haskey(AstroTLPlot.ERROR_MESSAGES_DICT, result)
            error_code_to_display = AstroTLPlot.ERROR_UNKNOWN 
        end
        println("ERROR loading configuration: ", AstroTLPlot.ERROR_MESSAGES_DICT[error_code_to_display])
        return nothing
    else
        config_data, pgp_data, runtime_data, modions_data = result
        println(AstroTLPlot.ERROR_MESSAGES_DICT[AstroTLPlot.STATUS_SUCCESS])
        println("Directory: ", config_data.directories.directory) 
    end

    # Configure & Allocate
    _increments, _set_min_max_index, vol_local, vol_global, tr = configure(config_data, pgp_data, runtime_data)
    simulations_data, time_files = allocate_vars(config_data, pgp_data, runtime_data)
    filename = "./data/input/ref/ref.dat"
    
    # setup config 
    timescale = config_data.scales.timescale
    nfiles = config_data.number_of_plots.nfiles
    timefile = read_ref_data_ds(filename, nfiles, timescale)
    
    filenumber = config_data.number_of_plots.nfile_start
    datafile = joinpath(config_data.directories.directory, "all00$(filenumber).h5")
    read_result = readdata_hdf5!(datafile, simulations_data, config_data, runtime_data)
    
    if isa(read_result, Int)
        error_code_to_display = read_result
        if !haskey(AstroTLPlot.ERROR_MESSAGES_DICT, read_result)
            error_code_to_display = AstroTLPlot.ERROR_UNKNOWN 
        end
        println("CRITICAL ERROR during HDF5 data reading: ",
                AstroTLPlot.ERROR_MESSAGES_DICT[error_code_to_display])
        return nothing
    else
        println(AstroTLPlot.ERROR_MESSAGES_DICT[AstroTLPlot.STATUS_SUCCESS])
        println("All simulation data is ready for processing.")
    end

    # Process Variables & Ions
    variables!(simulations_data, config_data)
    elem = count_ions(config_data)
    abundances!(config_data, elem)
    tps = ions_read(config_data, pgp_data, runtime_data, modions_data, elem)
    ionp = create_ionproperties()
    
    println("All simulation data is ready for plotting.")
    
    # Retorna um NamedTuple com todas as variáveis
    return (;
        config_data, pgp_data, runtime_data, modions_data,
        _increments, _set_min_max_index, vol_local, vol_global, tr,
        simulations_data, time_files, timefile,
        elem, tps, ionp
    )
end

=#
