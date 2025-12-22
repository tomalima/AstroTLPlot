
# export load_simulation_config, allocate_vars, configure

# ==============================================================================

# ==============================================================================
# Function: open_file
# Purpose: Universal file opener with robust checks for various data formats.
# ==============================================================================

"""
    open_file(file_path::String)

Attempts to open a file based on its extension, applying strict checks for existence,
permissions, and format.

# Arguments
- `file_path::String`: The path to the file (supporting .hdf, .h5, .hdf5, .yaml, .csv, .vtk).

# Returns
- On success: The raw data or file handle (e.g., HDF5.File, Dict for YAML, DataFrame/CSV handle).
- On failure: An integer error code (e.g., ERROR_FILE_NOT_FOUND, ERROR_HDF5_READ_FAIL).
"""
function open_file(file_path::String)

    # 1. Check if the file exists (Maps to ERROR_FILE_NOT_FOUND = 2)
    if !isfile(file_path)
        return ERROR_FILE_NOT_FOUND
    end

    # 2. Check read permissions (Maps to ERROR_NO_PERMISSIONS = 3)
    # Using try/catch for stat() to handle complex I/O failures before HDF5/CSV tries
    file_stat = try
        stat(file_path)
    catch
        return ERROR_NO_PERMISSIONS
    end

    if !(file_stat.mode & 0o444 != 0) # Check if the file has read permissions
        return ERROR_NO_PERMISSIONS
    end

    # 3. Check file extension and determine format
    file_ext = splitext(file_path)[2]
    
    # --- Data Formats ---
    
    # Check for HDF4 file (.hdf)
    if file_ext == ".hdf"
        try
            raw_data = HDF4.hdfopen(file_path, "r")
            return raw_data
        catch
            return ERROR_HDF4_READ_FAIL # New Error Code 7
        end
        
    # Check for HDF5 file (.h5 or .hdf5)
    elseif file_ext == ".h5" || file_ext == ".hdf5"
        try
            raw_data = HDF5.h5open(file_path, "r")
            return raw_data
        catch
            return ERROR_HDF5_READ_FAIL # New Error Code 6
        end
        
    # Check for YAML file (.yaml or .yml)
    elseif file_ext == ".yaml" || file_ext == ".yml"
        try
            parsed_data = YAML.load_file(file_path)
            return parsed_data
        catch
            return ERROR_YAML_PARSING # Error Code 4
        end
        
    # Check for CSV file (.csv)
    elseif file_ext == ".csv"|| file_ext == ".dat"
        try
            # Assuming CSV.read returns a type like DataFrame (requires CSV.jl and DataFrames.jl)
            raw_data = CSV.read(file_path, DataFrames.DataFrame) 
            return raw_data
        catch
            return ERROR_CSV_READ_FAIL # New Error Code 8
        end
    
    # Check for VTK file (.vtk)
    elseif file_ext == ".vtk"
        # VTK file handling might require a specific library and logic, 
        # but for now, we can just return a placeholder or handle the error.
        return ERROR_UNSUPPORTED_TYPE # Or custom VTK failure code
        
    # Unsupported file type (Maps to ERROR_UNSUPPORTED_TYPE = 9)
    else
        return ERROR_UNSUPPORTED_TYPE 
    end
end

# ==============================================================================
# Function to open YAML files
# ==============================================================================

"""
    open_yaml_file_error_code(file_path::String)

Attempts to open and parse a YAML file, returning either the parsed data (Dict) or an 
appropriate integer error code based on the outcome.

# Arguments
- `file_path::String`: The path to the YAML file to be opened.

# Returns
- On success: The parsed YAML data (Dict).
- On failure: An integer representing the error code:
    - `1`: An unknown/unmapped error occurred (should not happen for expected failures).
    - `2`: The file does not exist.
    - `3`: No read permissions or file access issues.
    - `4`: Failed to parse the file due to an invalid format or syntax error.
    - `5`: The file is not recognized as a valid YAML file based on its extension.
 

# Error Codes Explanation (from constants):
1. ERROR_UNKNOWN: For any other unhandled internal exception.
2. ERROR_FILE_NOT_FOUND: Returned when the file specified by the `file_path` does not exist.
3. ERROR_NO_PERMISSIONS: Occurs when the file exists but cannot be accessed due to lack of read permissions.
4. ERROR_YAML_PARSING: Returned when the file is successfully opened but contains invalid YAML syntax.
5. ERROR_WRONG_EXTENSION: Returned when the file does not have a `.yaml` or `.yml` extension.


# Example Usage:
```julia
file_path = "data/config.yaml"
result = open_yaml_file_error_code(file_path)

# if isa(result, Int) && result == ERROR_FILE_NOT_FOUND ...
# else ...

"""

function open_yaml_file(file_path::String)
    # 1. Check if the file exists (Maps to ERROR_FILE_NOT_FOUND = 2)
    if !isfile(file_path)
        return ERROR_FILE_NOT_FOUND
    end

    # 2. Check read permissions (Maps to ERROR_NO_PERMISSIONS = 3)
    # Use a try/catch block to handle possible exceptions during stat (e.g., complex I/O failure)
    file_stat = try
        stat(file_path)
    catch
        return ERROR_NO_PERMISSIONS # Return code 3 for any access issue during stat
    end

    if !(file_stat.mode & 0o444 != 0) # Check if the file has read permissions (0o444 is read for user, group, and others)
        return ERROR_NO_PERMISSIONS # Return code 3: No read permissions
    end

    # 3. Check if the file has the correct YAML extension (Maps to ERROR_WRONG_EXTENSION = 5)
    file_ext = splitext(file_path)[2]
    if !(file_ext == ".yaml" || file_ext == ".yml")
        return ERROR_WRONG_EXTENSION # Return code 5: Not a YAML file
    end

    # 4. Try to open and parse the YAML file (Maps to ERROR_YAML_PARSING = 4)
    try
        parsed_data = YAML.load_file(file_path) # Parse the YAML file
        return parsed_data  # Return the parsed YAML data on success
    catch e
        # Catch any parsing exception
        return ERROR_YAML_PARSING # Return code 4: Failed to parse file
    end
end

# ==============================================================================
# Function: load_simulation_config
# Purpose: Reads simulation configuration and plotting parameters from a YAML file.
# Return the complete simulation setup in SimutationData
# ==============================================================================

"""
    load_simulation_config(filename::String) -> Tuple

Reads and parses the simulation configuration, plotting parameters, and runtime settings
from a specified YAML file. It populates several primary configuration structures
(ConfigData, PGPData, RuntimeData, ModionsData) from the file content.

# Arguments
- `filename::String`: The path to the input YAML file (e.g., "indatpgp3.yaml").

# Returns
- `Tuple`: A tuple containing the initialized data structures on success:
    (`config_data::ConfigData`, `pgp_data::PGPData`, `runtime_data::RuntimeData`, `modions_data::ModionsData`)
- `Int`: An integer error code (1, 2, 3, or 4) if file loading/parsing fails.
    (Error Codes: 1=File Not Found, 2=No Permissions, 3=YAML Parsing Error, 4=Wrong Extension)
"""

function load_simulation_config(filename)
   # data = YAML.load_file(filename)
    
    # 1. Use the robust file opener to check for errors (I/O, permissions, extension) 
    #    and load the YAML data.
    #   'data' will be either the parsed dictionary (on success) or an Int error code.
    # data = open_yaml_file(filename)
     data =  open_file(filename)

    # 2. Check for error code return. If 'data' is an integer, it means an error occurred.
    if isa(data, Int)
        return data  # Return the error code directly (1, 2, 3, or 4)
    end
    # 3. If successful, 'data' is the parsed dictionary. Proceed with original struct construction.

    # Configuration Data (Settings related to simulation runs and basic I/O)
    config_data = ConfigData(
        Debug(data["Debug"]["ldebug"]),
        Directories(data["Directories"]["directory"], data["Directories"]["diratomic"]),
        SimulationType(data["SimulationType"]["lhdrun"], data["SimulationType"]["lmhdrun"]),
        FileFormat(data["FileFormat"]["lhdf"], data["FileFormat"]["lascii"], data["FileFormat"]["lvtk"]),
        GridSize(AstroTLPlot.Point3D(data["GridSize"]["in"], data["GridSize"]["jn"], data["GridSize"]["kn"])),
        RealDims(AstroTLPlot.Point3D(data["RealDims"]["xmin"], data["RealDims"]["ymin"], data["RealDims"]["zmin"]),
                 AstroTLPlot.Point3D(data["RealDims"]["xmax"], data["RealDims"]["ymax"], data["RealDims"]["zmax"]),
                 data["RealDims"]["units"]),
        MapsDims(AstroTLPlot.Point3D(data["MapsDims"]["x1"], data["MapsDims"]["y1"], data["MapsDims"]["z1"]),
                 AstroTLPlot.Point3D(data["MapsDims"]["x2"], data["MapsDims"]["y2"], data["MapsDims"]["z2"])),
        NumberOfPlots(data["NumberOfPlots"]["nfiles"], data["NumberOfPlots"]["nfile_start"], data["NumberOfPlots"]["nfile_end"],
                      data["NumberOfPlots"]["jump"], data["NumberOfPlots"]["nl"], data["NumberOfPlots"]["numx"], data["NumberOfPlots"]["numy"]),
        VariableParams(
            data["VariableParams"]["ldens"], data["VariableParams"]["ltemp"], data["VariableParams"]["lpres"], data["VariableParams"]["lpram"],
            data["VariableParams"]["lmagn"], data["VariableParams"]["lentr"], data["VariableParams"]["lmach"], data["VariableParams"]["lions"],
            data["VariableParams"]["lele"], data["VariableParams"]["lratios"], data["VariableParams"]["lele_kern"]
        ),
        Interpolation(data["Interpolation"]["lspline"], data["Interpolation"]["lrloss"]),
        Abundances(data["Abundances"]["lallen"], data["Abundances"]["lag89"], data["Abundances"]["lasplund"],
                   data["Abundances"]["lgas07"], data["Abundances"]["lagss09"], data["Abundances"]["zmetal"],
                   data["Abundances"]["deplt"]),
        Scales(
            data["Scales"]["timescale"], data["Scales"]["bscale"], data["Scales"]["denscale"],
            data["Scales"]["temscale"], data["Scales"]["velscale"], data["Scales"]["elescale"], data["Scales"]["logs"]
        ),
        IonsPlot(
            data["IonsPlot"]["plhyd"], data["IonsPlot"]["plhel"], data["IonsPlot"]["plcar"],
            data["IonsPlot"]["plnit"], data["IonsPlot"]["ploxy"], data["IonsPlot"]["plne"],
            data["IonsPlot"]["plmg"], data["IonsPlot"]["plsil"], data["IonsPlot"]["plsul"],
            data["IonsPlot"]["plar"], data["IonsPlot"]["plfe"]
        ),
        IonsType(
            data["IonsType"]["lhyd"], data["IonsType"]["lhel"], data["IonsType"]["lcar"],
            data["IonsType"]["lnit"], data["IonsType"]["loxy"], data["IonsType"]["lne"],
            data["IonsType"]["lmg"], data["IonsType"]["lsil"], data["IonsType"]["lsul"],
            data["IonsType"]["lar"], data["IonsType"]["lfe"]
        ),
        AtomicIonicFraction(data["AtomicIonicFraction"]["id"], data["AtomicIonicFraction"]["ncool"], 0, 0.0)
    )
   # PGP Data (Settings related to physics visualization ranges and metadata)
    pgp_data = PGPData(
        SetMinMaxVar(
            AstroTLPlot.MinMaxRange(data["setminmaxvar"]["dmin"], data["setminmaxvar"]["dmax"]),
            AstroTLPlot.MinMaxRange(data["setminmaxvar"]["tmin"], data["setminmaxvar"]["tmax"]),
            AstroTLPlot.MinMaxRange(data["setminmaxvar"]["pmin"], data["setminmaxvar"]["pmax"]),
            AstroTLPlot.MinMaxRange(data["setminmaxvar"]["pokmin"], data["setminmaxvar"]["pokmax"]),
            AstroTLPlot.MinMaxRange(data["setminmaxvar"]["bmin"], data["setminmaxvar"]["bmax"]),
            AstroTLPlot.MinMaxRange(data["setminmaxvar"]["pmagmin"], data["setminmaxvar"]["pmagmax"]),
            AstroTLPlot.MinMaxRange(data["setminmaxvar"]["betamin"], data["setminmaxvar"]["betamax"]),
            AstroTLPlot.MinMaxRange(data["setminmaxvar"]["valfmin"], data["setminmaxvar"]["valfmax"]),
            AstroTLPlot.MinMaxRange(data["setminmaxvar"]["machmin"], data["setminmaxvar"]["machmax"]),
            AstroTLPlot.MinMaxRange(data["setminmaxvar"]["rotmin"], data["setminmaxvar"]["rotmax"]),
            AstroTLPlot.MinMaxRange(data["setminmaxvar"]["vzmin"], data["setminmaxvar"]["vzmax"])
        ),
        ContourLimits(
            AstroTLPlot.MinMaxRange(data["mincontours"]["tmincont"], data["mincontours"]["tmaxcont"]),
            AstroTLPlot.MinMaxRange(data["mincontours"]["dmincont"], data["mincontours"]["dmaxcont"])
        ),
        Device(data["Device"]["device"], data["Device"]["dev"]),
        Views(data["Views"]["top"], data["Views"]["front"], data["Views"]["side"], data["Views"]["vertvar"], false),
        Title(data["Title"]["title"], data["Title"]["resolution"], data["Title"]["supernova"],
              data["Title"]["author"], data["Title"]["unittime"]),
        Labels(data["Labels"]["xlabel"], data["Labels"]["ylabel"], data["Labels"]["writetime"], data["Labels"]["localizar"])
    )
  # Runtime Data (Settings related to plot looping and rendering options)
    runtime_data = RuntimeData(
        LoopGraphic(data["Loopgraf"]["lmin"], data["Loopgraf"]["lmax"], data["Loopgraf"]["stepl"]),
        OutputPlot(data["OutputPlot"]["pdf"], data["OutputPlot"]["cont"], data["OutputPlot"]["grey"], data["OutputPlot"]["color"], data["OutputPlot"]["nconts"]),
        PlotSetting(data["PlotSetting"]["paleta"], data["PlotSetting"]["orientacao"]),
        Tracer(data["Tracer"]["nmintrace"], data["Tracer"]["ntraces"]),
        Aspect(data["Aspects"]["width"], data["Aspects"]["aspect"])
       # TimeFile(Vector{Float64}(undef, 0), Vector{Int}(undef, 0)),  # Inicial vazio
        )
    # Modions Data (Settings for ion-specific visualization ranges)
    modions_data = ModionsData(
        SetMinMaxIons(
            AstroTLPlot.MinMaxRange(data["setminmaxions"]["elemin"], data["setminmaxions"]["elemax"]),
            AstroTLPlot.MinMaxRange(data["setminmaxions"]["ovimin"], data["setminmaxions"]["ovimax"])
        )
    )

 # Return the aggregated data grouped into respective primary structs
    return (config_data, pgp_data, runtime_data, modions_data)
end

# ==============================================================================
# Function: load_simulation_config_struct
# Purpose:  Reads simulation configuration and plotting parameters from a YAML file.
# ==============================================================================
function load_simulation_config_struct(filename)

  # data = YAML.load_file(filename)
    
    # 1. Use the robust file opener to check for errors (I/O, permissions, extension) 
    #    and load the YAML data.
    #   'data' will be either the parsed dictionary (on success) or an Int error code.
    data = open_yaml_file(filename)

    # 2. Check for error code return. If 'data' is an integer, it means an error occurred.
    if isa(data, Int)
        return data  # Return the error code directly (1, 2, 3, or 4)
    end
    
    # 3. If successful, 'data' is the parsed dictionary. Proceed with original struct construction.

    # Configuration Data (Settings related to simulation runs and basic I/O)

    # data = YAML.load_file(filename)

    # Helper function to create Point3D from data
    point3d(prefix) = Point3D(
        data[prefix]["x"],
        data[prefix]["y"],
        data[prefix]["z"]
    )
    # Helper function to create MinMaxRange
    minmax(prefix, min_field, max_field) = MinMaxRange(data[prefix][min_field], data[prefix][max_field])

    # ConfigData construction
    config = ConfigData(
        debug = Debug(data["Debug"]["ldebug"]),
        directories = Directories(data["Directories"]["directory"], data["Directories"]["diratomic"]),
        simulation_type = SimulationType(data["SimulationType"]["lhdrun"], data["SimulationType"]["lmhdrun"]),
        file_format = FileFormat(data["FileFormat"]["lhdf"], data["FileFormat"]["lascii"], data["FileFormat"]["lvtk"]),
        grid_size = GridSize(Point3D(data["GridSize"]["in"], data["GridSize"]["jn"], data["GridSize"]["kn"])),
        real_dims = RealDims(
            Point3D(data["RealDims"]["xmin"], data["RealDims"]["ymin"], data["RealDims"]["zmin"]),
            Point3D(data["RealDims"]["xmax"], data["RealDims"]["ymax"], data["RealDims"]["zmax"]),
            data["RealDims"]["units"]
        ),
        maps_dims = MapsDims(
            Point3D(data["MapsDims"]["x1"], data["MapsDims"]["y1"], data["MapsDims"]["z1"]),
            Point3D(data["MapsDims"]["x2"], data["MapsDims"]["y2"], data["MapsDims"]["z2"])
        ),
        number_of_plots = NumberOfPlots(
            data["NumberOfPlots"]["nfiles"],
            data["NumberOfPlots"]["nfile_start"],
            data["NumberOfPlots"]["nfile_end"],
            data["NumberOfPlots"]["jump"],
            data["NumberOfPlots"]["nl"],
            data["NumberOfPlots"]["numx"],
            data["NumberOfPlots"]["numy"]
        ),
        variable_params = VariableParams(
            data["VariableParams"]["ldens"],
            data["VariableParams"]["ltemp"],
            data["VariableParams"]["lpres"],
            data["VariableParams"]["lpram"],
            data["VariableParams"]["lmagn"],
            data["VariableParams"]["lentr"],
            data["VariableParams"]["lmach"],
            data["VariableParams"]["lions"],
            data["VariableParams"]["lele"],
            data["VariableParams"]["lratios"],
            data["VariableParams"]["lele_kern"]
        ),
        interpolation = Interpolation(data["Interpolation"]["lspline"], data["Interpolation"]["lrloss"]),
        abundances = Abundances(
            data["Abundances"]["lallen"],
            data["Abundances"]["lag89"],
            data["Abundances"]["lasplund"],
            data["Abundances"]["lgas07"],
            data["Abundances"]["lagss09"],
            data["Abundances"]["zmetal"],
            data["Abundances"]["deplt"]
        ),
        scales = Scales(
            data["Scales"]["timescale"],
            data["Scales"]["bscale"],
            data["Scales"]["denscale"],
            data["Scales"]["temscale"],
            data["Scales"]["velscale"],
            data["Scales"]["elescale"],
            data["Scales"]["logs"]
        ),
        ions_plot = IonsPlot(
            data["IonsPlot"]["plhyd"],
            data["IonsPlot"]["plhel"],
            data["IonsPlot"]["plcar"],
            data["IonsPlot"]["plnit"],
            data["IonsPlot"]["ploxy"],
            data["IonsPlot"]["plne"],
            data["IonsPlot"]["plmg"],
            data["IonsPlot"]["plsil"],
            data["IonsPlot"]["plsul"],
            data["IonsPlot"]["plar"],
            data["IonsPlot"]["plfe"]
        ),
        ions_type = IonsType(
            data["IonsType"]["lhyd"],
            data["IonsType"]["lhel"],
            data["IonsType"]["lcar"],
            data["IonsType"]["lnit"],
            data["IonsType"]["loxy"],
            data["IonsType"]["lne"],
            data["IonsType"]["lmg"],
            data["IonsType"]["lsil"],
            data["IonsType"]["lsul"],
            data["IonsType"]["lar"],
            data["IonsType"]["lfe"]
        ),
        atomic_ionic_fraction = AtomicIonicFraction(
            data["AtomicIonicFraction"]["id"],
            data["AtomicIonicFraction"]["ncool"],
            0,  # nheat default
            0.0 # te default
        )
    )

    # PGPData construction
    pgp = PGPData(
        set_min_max_var = SetMinMaxVar(
            minmax("setminmaxvar", "dmin", "dmax"),  # density
            minmax("setminmaxvar", "tmin", "tmax"),  # temperature
            minmax("setminmaxvar", "pmin", "pmax"),  # pressure
            minmax("setminmaxvar", "pokmin", "pokmax"),  # pok
            minmax("setminmaxvar", "bmin", "bmax"),  # bfield
            minmax("setminmaxvar", "pmagmin", "pmagmax"),  # pmag
            minmax("setminmaxvar", "betamin", "betamax"),  # beta
            minmax("setminmaxvar", "valfmin", "valfmax"),  # valfven
            minmax("setminmaxvar", "machmin", "machmax"),  # mach
            minmax("setminmaxvar", "rotmin", "rotmax"),  # rotation
            minmax("setminmaxvar", "vzmin", "vzmax")   # vz
        ),
        mincontours = ContourLimits(
            minmax("mincontours", "tmincont", "tmaxcont"),
            minmax("mincontours", "dmincont", "dmaxcont")
        ),
        device = Device(data["Device"]["device"], data["Device"]["dev"]),
        view = Views(
            data["Views"]["top"],
            data["Views"]["front"],
            data["Views"]["side"],
            data["Views"]["vertvar"],
            false  # isometric default
        ),
        title = Title(
            data["Title"]["title"],
            data["Title"]["resolution"],
            data["Title"]["supernova"],
            data["Title"]["author"],
            data["Title"]["unittime"]
        ),
        labels = Labels(
            data["Labels"]["xlabel"],
            data["Labels"]["ylabel"],
            data["Labels"]["writetime"],
            data["Labels"]["localizar"]
        )
    )

    # RuntimeData construction
    runtime = RuntimeData(
        loop_graphic = LoopGraphic(
            data["Loopgraf"]["lmin"],
            data["Loopgraf"]["lmax"],
            data["Loopgraf"]["stepl"]
        ),
        output_plot = OutputPlot(
            data["OutputPlot"]["pdf"],
            data["OutputPlot"]["cont"],
            data["OutputPlot"]["grey"],
            data["OutputPlot"]["color"],
            data["OutputPlot"]["nconts"]
        ),
        plot_setting = PlotSetting(
            data["PlotSetting"]["paleta"],
            data["PlotSetting"]["orientacao"]
        ),
        tracer = Tracer(
            data["Tracer"]["nmintrace"],
            data["Tracer"]["ntraces"]
        ),
        aspect = Aspect(
            data["Aspects"]["width"],
            data["Aspects"]["aspect"]
        )
    )

    # ModionsData construction
   modions = ModionsData(
        SetMinMaxIons(
            MinMaxRange(data["setminmaxions"]["elemin"], data["setminmaxions"]["elemax"]),
            MinMaxRange(data["setminmaxions"]["ovimin"], data["setminmaxions"]["ovimax"])
        )
    )
    # Return the complete simulation setup
    return SimulationSetup(config, pgp, runtime, modions)
end

# ==============================================================================
# Function: configure
# Purpose: Calculate grid parameters, spatial increments, and view transformations for simulation data
# ==============================================================================

"""
    configure(config_data::ConfigData, pgp_data::PGPData, runtime_data::RuntimeData) -> Tuple{Increments, SetMinMaxIndex, Float64, Float64, Vector{Float64}}

Calculate grid configuration parameters, spatial increments, and visualization transformations.

This function computes essential grid parameters for simulation data processing including
spatial increments, index boundaries for sub-region selection, volume calculations, and
coordinate transformations for 2D projection views (front and top views).

# Arguments
- `config_data::ConfigData`: Configuration object containing grid dimensions, real space boundaries, and map dimensions
- `pgp_data::PGPData`: Post-processing parameters including view configuration (front, top)
- `runtime_data::RuntimeData`: Runtime data structure (currently not used in calculations)

# Returns
- `increments::Increments`: Spatial step sizes (dx, dy, dz) in each coordinate direction
- `set_min_max_index::SetMinMaxIndex`: Minimum and maximum indices for sub-region selection
- `vol_local::Float64`: Volume of the selected sub-region in grid cells
- `vol_global::Float64`: Total volume of the entire grid in grid cells
- `tr::Vector{Float64}`: Transformation vector for 2D view projections

# Calculations Performed
1. **Spatial Increments**: Computes dx, dy, dz from real space boundaries and grid resolution
2. **Index Boundaries**: Converts real-space map dimensions to grid indices with boundary checking
3. **Volume Calculations**: Computes local sub-region volume and total grid volume
4. **View Transformations**: Calculates transformation parameters for front and top view projections

# View Projections
- **Front View**: Projects X-Z plane with appropriate coordinate transformations
- **Top View**: Projects X-Y plane with appropriate coordinate transformations

# Notes
- Includes boundary safety checks to prevent invalid index values
- Handles edge cases where spatial dimensions may be zero
- Provides transformation parameters compatible with visualization libraries
"""
function configure(config_data::ConfigData, pgp_data::PGPData, runtime_data::RuntimeData)
    # Extract real space boundary coordinates
    xmin = config_data.real_dims.min.x
    xmax = config_data.real_dims.max.x
    ymin = config_data.real_dims.min.y
    ymax = config_data.real_dims.max.y
    zmin = config_data.real_dims.min.z
    zmax = config_data.real_dims.max.z
  
    # Extract grid dimensions and convert to integer
    in_grid = trunc(Int, config_data.grid_size.grid_point.x)
    jn_grid = trunc(Int, config_data.grid_size.grid_point.y)
    kn_grid = trunc(Int, config_data.grid_size.grid_point.z)
    
    # Extract map boundaries for sub-region selection
    x1 = config_data.maps_dims.p1.x
    x2 = config_data.maps_dims.p2.x
    y1 = config_data.maps_dims.p1.y
    y2 = config_data.maps_dims.p2.y
    z1 = config_data.maps_dims.p1.z
    z2 = config_data.maps_dims.p2.z
    
    # Extract view configuration flags
    front = pgp_data.view.front
    top = pgp_data.view.top

    # Calculate spatial increments with safety check for zero ranges
    dx = xmin == xmax ? 1.0 : (xmax - xmin) / in_grid
    dy = ymin == ymax ? 1.0 : (ymax - ymin) / jn_grid
    dz = zmin == zmax ? 1.0 : (zmax - zmin) / kn_grid

    # Convert real-space coordinates to grid indices
    imin = round(Int, x1 / dx)
    imax = round(Int, x2 / dx)
    jmin = round(Int, y1 / dy)
    jmax = round(Int, y2 / dy)
    kmin = round(Int, (z1 - zmin) / dz)
    kmax = round(Int, (z2 - zmin) / dz)

    # Apply boundary safety checks to prevent invalid indices
    imin = imin <= 0 ? 1 : imin
    jmin = jmin <= 0 ? 1 : jmin
    kmin = kmin <= 0 ? 1 : kmin
    imax = imax == 0 ? 1 : imax
    jmax = jmax == 0 ? 1 : jmax
    kmax = kmax == 0 ? 1 : kmax

    # Calculate local and global volumes in grid cells
    vol_local = Float64((imax - imin + 1) * (jmax - jmin + 1) * (kmax - kmin + 1))
    vol_global = Float64(in_grid * jn_grid * kn_grid)

    # Initialize transformation parameters
    tr2 = 0.0
    tr6 = 0.0
    fac1 = 0.0
    fac2 = 0.0

    # Calculate transformation parameters for view projections
    if front
        # Front view: X-Z plane projection
        tr2 = dx      # X-increment
        tr6 = dz      # Z-increment  
        fac1 = 0.0    # X-offset
        fac2 = abs(zmin)  # Z-offset (absolute value for coordinate adjustment)
    elseif top
        # Top view: X-Y plane projection
        tr2 = dx      # X-increment
        tr6 = dy      # Y-increment
        fac1 = 0.0    # X-offset
        fac2 = abs(ymin)  # Y-offset (absolute value for coordinate adjustment)
    end

    # Compose transformation vector for visualization
    tr = [0.0 - fac1, tr2, 0.0, 0.0 - fac2, 0.0, tr6]

    # Create return structures
    increments = Increments(AstroTLPlot.Point3D(dx, dy, dz))
    set_min_max_index = SetMinMaxIndex(AstroTLPlot.Point3D(imin, jmin, kmin), AstroTLPlot.Point3D(imax, jmax, kmax))

    return increments, set_min_max_index, vol_local, vol_global, tr
end


# ==============================================================================
# Function: allocate_vars
# Purpose: Allocate memory arrays for simulation data based on configuration parameters
# ==============================================================================

"""
    allocate_vars(config_data::ConfigData, pgp_data::PGPData, runtime_data::RuntimeData) -> Tuple{SimulationData, TimeFile}

Allocate memory for simulation data arrays based on configuration parameters and simulation type.

This function dynamically allocates multi-dimensional arrays for storing simulation data
including hydrodynamic variables, magnetic fields, and coordinate grids. The allocation
is optimized based on the simulation configuration, file format requirements, and
physical models being used (HD vs MHD).

# Arguments
- `config_data::ConfigData`: Configuration object containing grid dimensions, file formats, and variable flags
- `pgp_data::PGPData`: Post-processing parameters data structure
- `runtime_data::RuntimeData`: Runtime data and state information

# Returns
- `SimulationData`: Structure containing all allocated 3D/2D data arrays for simulation fields
- `TimeFile`: Structure containing time and file index arrays

# Array Allocation Strategy
- **Core Variables**: Always allocated (density, energy, temperature, pressure)
- **Velocity Fields**: Conditionally allocated based on file format and analysis requirements
- **Magnetic Fields**: Allocated only for MHD simulations (`lmhdrun = true`)
- **Auxiliary Arrays**: Pre-allocated with default dimensions for optional use

# Configuration Dependencies
- Grid dimensions (`in_grid`, `jn_grid`, `kn_grid`) determine array sizes
- File format flags (`lhdf`, `lascii`) control velocity field allocation
- Physics flags (`lmhdrun`, `lpram`, `lmach`) enable specialized arrays
- Number of plots (`nfiles`) sets time and file array sizes

# Memory Considerations
- Allocates 3D arrays of size (in_grid × jn_grid × kn_grid) for field variables
- Uses Float64 precision for all numerical data
- Initializes arrays as uninitialized memory for performance
- Conditionally allocates large arrays to conserve memory when not needed
"""
function allocate_vars(config_data::ConfigData, pgp_data::PGPData, runtime_data::RuntimeData)
    # Extract configuration parameters
    nfiles = config_data.number_of_plots.nfiles
    
    # Get grid dimensions and convert to integer
    in_grid = trunc(Int, config_data.grid_size.grid_point.x)
    jn_grid = trunc(Int, config_data.grid_size.grid_point.y)
    kn_grid = trunc(Int, config_data.grid_size.grid_point.z)
    
    # Extract format and physics flags
    lhdf = config_data.file_format.lhdf
    lascii = config_data.file_format.lascii
    lpram = config_data.variable_params.lpram
    lmach = config_data.variable_params.lmach
    lmhdrun = config_data.simulation_type.lmhdrun

    # Allocate time and file index arrays
    files = Vector{Int}(undef, nfiles)
    time = Vector{Float64}(undef, nfiles)

    # Allocate core hydrodynamic variables (always allocated)
    den = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    ene = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    tem = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    pre = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    pok = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)

    # Allocate velocity components for HDF format
    vxx = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    vyy = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    vzz = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)

    # Conditionally allocate velocity arrays for HDF format
    if lhdf
        vxx = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
        vyy = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
        vzz = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    end

    # Allocate velocity magnitude array
    vel2 = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)

    # Conditionally allocate velocity arrays for ASCII format with momentum/Mach analysis
    if lascii && (lpram || lmach)
        vxx = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
        vyy = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
        vzz = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
        vel2 = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    end

    # Allocate magnetic field components for MHD simulations
    bxx = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    byy = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    bzz = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)

    if lmhdrun
        bxx = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
        byy = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
        bzz = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    end

    # Allocate auxiliary arrays for specialized analysis
    sentrop = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    ramp = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    rampok = Array{Float64, 3}(undef, in_grid, jn_grid, kn_grid)
    dentot = Array{Float64, 2}(undef, in_grid, jn_grid)

    # Allocate coordinate grid arrays
    X_grid = Vector{Float64}(undef, in_grid)
    Y_grid = Vector{Float64}(undef, jn_grid)
    Z_grid = Vector{Float64}(undef, kn_grid)
    
    # Create SimulationData structure with all allocated arrays
    simulation_data = AstroTLPlot.SimulationData(den, ene, tem, pre, pok, vxx, vyy, vzz, vel2, bxx, 
        byy, bzz, sentrop, ramp, rampok, dentot, X_grid, Y_grid, Z_grid)

    # Create TimeFile structure for time and file tracking
    time_files = AstroTLPlot.TimeFile(time, files)

    return simulation_data, time_files
end

# ==============================================================================
# Function: new_allocate_vars!
# Purpose: Allocates and initializes the required arrays for simulation and runtime data **in-place**
# ==============================================================================

"""
    new_allocate_vars!(config_data::ConfigData, pgp_data::PGPData, runtime_data::RuntimeData)

Allocates and initializes the required arrays for simulation and runtime data **in-place**,  
modifying the existing `config_data.simulations_data` and `runtime_data.time_files` fields  
instead of creating new structs.

# Arguments
- `config_data::ConfigData`: Global configuration containing grid size, file format flags, and simulation parameters.
- `pgp_data::PGPData`: Plot configuration data (currently unused here but kept for consistency).
- `runtime_data::RuntimeData`: Runtime state containing file/time tracking structures.

# Notes
- No values are returned; the function updates the given mutable structs directly.
- This approach preserves existing references to `config_data` and `runtime_data`.
- All arrays are created uninitialized (`undef`), so they must be filled before use.

# Example
```julia
# Create configuration and runtime objects
config  = ConfigData(...)        # Must include a valid simulations_data field
pgp     = PGPData(...)
runtime = RuntimeData(...)       # Must include a valid time_files field

# Allocate arrays based on configuration
new_allocate_vars!(config, pgp, runtime)

# Now config.simulations_data and runtime.time_files have allocated arrays ready for data filling
println(size(config.simulations_data.den))   # -> (Nx, Ny, Nz)
println(length(runtime.time_files.time))     # -> number of files

"""
function new_allocate_vars!(
    config_data::ConfigData,
    pgp_data::PGPData,
    runtime_data::RuntimeData
)
    # Extract basic parameters from config
    nfiles  = config_data.number_of_plots.nfiles
    in_grid = trunc(Int, config_data.grid_size.grid_point.x)
    jn_grid = trunc(Int, config_data.grid_size.grid_point.y)
    kn_grid = trunc(Int, config_data.grid_size.grid_point.z)

    # Simulation flags for conditional allocations
    lhdf    = config_data.file_format.lhdf
    lascii  = config_data.file_format.lascii
    lpram   = config_data.variable_params.lpram
    lmach   = config_data.variable_params.lmach
    lmhdrun = config_data.simulation_type.lmhdrun

    # === Allocate runtime time/file tracking ===
    #runtime_data.time_files.time  = Vector{Float64}(undef, nfiles)
    #runtime_data.time_files.files = Vector{Int}(undef, nfiles)

    # Shortcut to simulation data for cleaner code
    sim_data = config_data.simulations_data

    # === Base 3D variables ===
    sim_data.den = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    sim_data.ene = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    sim_data.tem = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    sim_data.pre = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    sim_data.pok = Array{Float64}(undef, in_grid, jn_grid, kn_grid)

    # === Velocity fields ===
    sim_data.vxx = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    sim_data.vyy = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    sim_data.vzz = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    if lhdf
        # Allocate HDF-specific velocity arrays
        sim_data.vxx = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
        sim_data.vyy = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
        sim_data.vzz = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    end

    # Allocate velocity magnitude array
    sim_data.vel2 = Array{Float64}(undef, in_grid, jn_grid, kn_grid)

    if lascii && (lpram || lmach)
        # ASCII-specific velocity allocations
        sim_data.vxx  = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
        sim_data.vyy  = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
        sim_data.vzz  = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
        sim_data.vel2 = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    end

    # === Magnetic fields ===
    sim_data.bxx = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    sim_data.byy = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    sim_data.bzz = Array{Float64}(undef, in_grid, jn_grid, kn_grid)

    if lmhdrun
        # MHD-specific magnetic field allocations
        sim_data.bxx = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
        sim_data.byy = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
        sim_data.bzz = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    end

    # === Additional physical fields ===
    sim_data.sentrop = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    sim_data.ramp    = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    sim_data.rampok  = Array{Float64}(undef, in_grid, jn_grid, kn_grid)
    sim_data.dentot  = Array{Float64}(undef, in_grid, jn_grid)

    # === Grid coordinate vectors ===
    sim_data.X_grid = Vector{Float64}(undef, in_grid)
    sim_data.Y_grid = Vector{Float64}(undef, jn_grid)
    sim_data.Z_grid = Vector{Float64}(undef, kn_grid)

    return nothing
end

# ==============================================================================
