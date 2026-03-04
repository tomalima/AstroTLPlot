
#---------------------------------------------------------------------------------
using PyCall
const SD = pyimport("pyhdf.SD")

#******************************************************************
# Function: read_dataset_field
# Purpose: Read and display metadata information for specific dataset in HDF5 file
#******************************************************************
"""
    read_dataset_field(file_name, dataset_name)

Read and display comprehensive metadata information for a specific dataset within an HDF5 file.

This function opens an HDF5 file and extracts detailed information about a specified dataset,
including dimensional properties, data type, memory usage, and relevant attributes. It provides
a structured overview of the dataset's characteristics without loading the actual data values.

# Arguments
- `file_name::String`: Path to the HDF5 file to be analyzed
- `dataset_name::String`: Name/path of the specific dataset within the HDF5 file

# Information Extracted
- **Basic Properties**: Dataset name, data type, dimensions, total elements
- **Dimensional Analysis**: Individual X, Y, Z dimensions and total element count
- **Memory Usage**: Total size in bytes based on dimensions and data type
- **Attributes**: Coordinate system information and long descriptive names
- **Shape Analysis**: Complete dimension tuple and rank information

# Output
Structured console output with the following sections:
- Dataset Information
- Dimensional Properties
- Attribute Analysis

# Notes
- Operates in read-only mode to prevent accidental file modification
- Handles missing attributes gracefully without throwing errors
- Provides memory footprint calculations for performance considerations
"""
function read_dataset_field(file_name, dataset_name)
    # Open HDF5 file in read-only mode and access specified dataset
    h5open(file_name, "r") do file
        dataset = file[dataset_name]

        # Extract dimensional properties
        dims = size(dataset)  # Complete dimension tuple
        dim_x = dims[1]  # First dimension (X-axis)
        dim_y = dims[2]  # Second dimension (Y-axis) 
        dim_z = dims[3]  # Third dimension (Z-axis)
        dim_total = dim_x * dim_y * dim_z  # Total number of elements

        # Calculate dataset properties
        rank = ndims(dataset)  # Number of dimensions
        dtype = eltype(dataset)  # Element data type
        total_size = prod(dims) * sizeof(dtype)  # Total memory usage in bytes

        # Display dataset information header
        println("=== Dataset Information ===")
        println("Name: ", dataset_name)
        println("Data Type: ", dtype)
        
        # Display dimensional properties
        println("X Dimension: ", dim_x)
        println("Y Dimension: ", dim_y) 
        println("Z Dimension: ", dim_z)
        println("Total Elements: ", dim_total)
        println("Shape: ", dims, " = ", total_size, " bytes")

        # Verify all dimension attributes were successfully extracted
        if dim_x !== nothing && dim_y !== nothing && dim_z !== nothing
            println("Dimensions: dim_x=", dim_x, ", dim_y=", dim_y, ", dim_z=", dim_z)
        else
            println("Dimension attributes (dim_x, dim_y, dim_z) not found.")
        end

        # Extract and display coordinate system information if available
        if haskey(attrs(dataset), "coordsys")
            coordsys = attrs(dataset)["coordsys"]
            println("Coordinate System: ", coordsys)
            println("Dimension List Size: ", size(attrs(dataset)["DIMENSION_LIST"]))
            println("Rank: ", rank)
        end

        # Extract and display long name attribute if available
        if haskey(attrs(dataset), "long_name")
            long_name = attrs(dataset)["long_name"]
            println("Long Name: ", long_name)
        end
    end
end

#******************************************************************
# Function: read_hdf5_file_
# Purpose: Recursively analyze and display metadata for all datasets in HDF5 file
#******************************************************************

"""
    read_hdf5_file_(file_name)

Recursively analyze and display metadata information for all datasets within an HDF5 file.

This function serves as a comprehensive HDF5 file inspector that iterates through all
top-level objects in the file and performs detailed metadata analysis on each dataset
it encounters. It provides a complete overview of the file's data structure without
loading the actual data values into memory.

# Arguments
- `file_name::String`: Path to the HDF5 file to be analyzed

# Workflow
1. Opens HDF5 file in read-only mode
2. Iterates through all top-level objects in the file
3. Identifies and filters for HDF5 Dataset objects (excluding groups and other types)
4. Applies `read_dataset_field_()` to each dataset for detailed metadata analysis
5. Automatically handles file closure using do-block syntax

# Output
Calls `read_dataset_field_()` for each dataset, producing:
- Dimensional information and data types
- Memory usage calculations
- Attribute listings
- Dataset classification

# Use Cases
- File structure exploration and validation
- Data inventory and metadata extraction
- Debugging and verification of HDF5 file contents
- Educational purposes for understanding HDF5 structure

# Notes
- Operates in read-only mode to prevent accidental file modification
- Only processes datasets (ignores groups, attributes, and other object types)
- Provides a complete hierarchical overview of the file's data content
"""
function read_hdf5_file_(file_name)
    # Open HDF5 file in read-only mode and process all top-level objects
    h5open(file_name, "r") do file
        println("Opening file: ", file_name)
        
        # Iterate through all top-level objects in the HDF5 file
        for dataset_name in keys(file)
            # Check if the object is a Dataset (not a Group or other type)
            if isa(file[dataset_name], HDF5.Dataset)
                # Apply detailed metadata analysis to each dataset
                read_dataset_field_(file[dataset_name])
            end
        end
    end
end

#******************************************************************
# Function: read_dataset_field_
# Purpose: Analyze and display comprehensive metadata information for HDF datasets
#******************************************************************
"""
    read_dataset_field_(dataset)

Comprehensive diagnostic function to analyze and display metadata information for HDF datasets.

This function extracts and prints detailed information about an HDF dataset including:
dimensionality, data type, memory usage, attributes, and coordinate system information.
It serves as a diagnostic tool for understanding dataset structure and properties.

# Arguments
- `dataset`: HDF dataset object to be analyzed

# Information Displayed
- Basic properties: data type, dimensions, memory usage
- Dimensionality: individual dimensions (X, Y, Z) and total element count
- Attributes: all available metadata attributes including long names
- Coordinate system: coordinate system information if available
- Classification: dataset type classification using `classify_dataset()`

# Output Format
Structured console output with sections:
- Dataset Information
- Dimensional Analysis  
- Attribute Listing
- Classification

# Notes
- Handles datasets with 1D, 2D, 3D, or higher dimensions gracefully
- Safely checks for optional attributes to avoid errors
- Provides memory usage calculations for performance analysis
"""
function read_dataset_field_(dataset)
    # Extract fundamental dataset properties
    dims = size(dataset)  # Dataset dimensions as tuple
    dtype = eltype(dataset)  # Element data type
    total_size = prod(dims) * sizeof(dtype)  # Total memory usage in bytes
    rank = ndims(dataset)  # Number of dimensions

    # Extract individual dimensions with safe indexing
    dim_x = length(dims) >= 1 ? dims[1] : 1
    dim_y = length(dims) >= 2 ? dims[2] : 1
    dim_z = length(dims) >= 3 ? dims[3] : 1
    dim_total = dim_x * dim_y * dim_z  # Total number of elements

    println("=== Dataset Information ===")

    # Display long name attribute if available
    if haskey(attrs(dataset), "long_name")
        long_name = attrs(dataset)["long_name"]
        println("Long Name: ", long_name)
    end
    
    # Print core dataset properties
    println("Data Type: ", dtype)
    println("X Dimension: ", dim_x)
    println("Y Dimension: ", dim_y)
    println("Z Dimension: ", dim_z)
    println("Total Elements: ", dim_total)
    println("Dimensions: ", dims, " = ", total_size, " bytes")

    # Display coordinate system information if available
    if haskey(attrs(dataset), "coordsys")
        coordsys = attrs(dataset)["coordsys"]
        println("Coordinate System: ", coordsys)
        println("Dimension List Size: ", size(attrs(dataset)["DIMENSION_LIST"]))
        println("Rank: ", rank)
    end

    # Classify dataset type (scalar, vector, matrix, etc.)
    println(classify_dataset(dims)) 
    
    # Display all available attributes
    println("=== Dataset Attributes ===")
    for attr in keys(attrs(dataset))
        println("  ", attr, ": ", attrs(dataset)[attr])
    end
end

#******************************************************************
# Function: classify_dataset
# Purpose: 
#******************************************************************
function classify_dataset(dims)
    rank = length(dims)
    dim_total = prod(dims)

    if rank == 0 || dim_total == 1
        return "Scalar (single value)"
    elseif rank == 1
        return "1D Vector"
    elseif rank == 2
        return "2D Matrix"
    elseif rank == 3
        return "Data Cube (3D)"
    else
        return "Multidimensional Dataset (4D+)"
    end
end

#******************************************************************
# Function: readdata_hdf5!
# Purpose: Reads simulation datasets from an HDF5 file.
#******************************************************************
    """
    Read simulation data from an HDF5 file and populate the SimulationData structure.
    
    This function reads grid dimensions, velocity fields, density, energy, and optionally
    magnetic field data from an HDF5 file, converting units as necessary and handling
    both MHD and hydrodynamic simulations.
    
    Parameters
    ----------
    simulations_data : SimulationData
        The data structure to be populated with simulation data
    config_data : ConfigData
        Configuration data containing grid sizes, file paths, and simulation type
    runtime_data : RuntimeData
        Runtime parameters (currently not used in this function)
    
    Side Effects
    ------------
    Modifies the simulations_data structure in-place with the read data
    Prints status messages or errors to the console
    
    Notes
    -----
    - Velocity data is converted from km/s to cm/s (multiplied by 1e5)
    - The function handles both MHD (with magnetic fields) and hydrodynamic simulations
    - File naming follows the pattern: directory/all00[filenum].h5
    - Grid dimensions are read from fakeDim0, fakeDim1, fakeDim2 datasets
    """
function readdata_hdf5!(simulations_data::SimulationData, config_data::ConfigData, runtime_data::RuntimeData)

    # Extract grid dimensions from configuration
    in_grid = trunc(Int, config_data.grid_size.grid_point.x)
    jn_grid = trunc(Int, config_data.grid_size.grid_point.y)
    kn_grid = trunc(Int, config_data.grid_size.grid_point.z)

    # Get file directory and starting file number
    directory = config_data.directories.directory
    filenum = config_data.number_of_plots.nfile_start
    lmhdrun = config_data.simulation_type.lmhdrun  # Flag for MHD simulation

    # Construct HDF5 filename
    datafile = "$(directory)all00$(filenum).h5"

    # Open HDF5 file in read mode
    # h5file = h5open(datafile, "r")
    
    # 1. Use the universal opener and check the result
    h5file = open_file(datafile)

    # 2. Check for error code return
    if isa(h5file, Int)
        # If an error code is returned (e.g., 2, 3, 6), return it to the caller.
        return h5file 
    end
    
    # 3. If successful, 'h5file' is the file handle. Proceed with reading.
    
    # Read grid scales
    try
        simulations_data.Z_grid = read(h5file["fakeDim0"])
        simulations_data.X_grid = read(h5file["fakeDim1"])
        simulations_data.Y_grid = read(h5file["fakeDim2"])

    catch e
       # println("Error reading grid scales from HDF5 file: ", e)
        close(h5file) 
        return ERROR_HDF5_READ_FAIL
    end

    # Read main simulation datasets with error handling
    try
        # Read and convert velocity components (km/s to cm/s)
        simulations_data.vxx = read(h5file["Data-Set-2"]) * 1e5
        simulations_data.vyy = read(h5file["Data-Set-3"]) * 1e5
        simulations_data.vzz = read(h5file["Data-Set-4"]) * 1e5
        
        # Read density and energy
        simulations_data.den = read(h5file["Data-Set-5"])
        simulations_data.ene = read(h5file["Data-Set-6"])

        # Read magnetic field components if this is an MHD simulation
        if lmhdrun
            simulations_data.bxx = read(h5file["Data-Set-7"])
            simulations_data.byy = read(h5file["Data-Set-8"])
            simulations_data.bzz = read(h5file["Data-Set-9"])
        end

        println("Datasets read successfully - HDF5.")
    catch e
       # println("Error reading datasets: ", e)
       # If reading the datasets fails, close and return the HDF5 read fail code
        close(h5file)
        return ERROR_HDF5_READ_FAIL
    end

    # Close the HDF5 file
    close(h5file)
    # Return nothing on complete success (typical for functions ending with '!')
    return nothing
end


#-------------------------------------

#******************************************************************
# Function: readdata_hdf5!
# Purpose: Reads simulation datasets from an HDF5 file.
#******************************************************************
"""
Read simulation data from an HDF5 file and populate the SimulationData structure.

This function reads grid dimensions, velocity fields, density, energy, and optionally
magnetic field data from an HDF5 file, converting units as necessary and handling
both MHD and hydrodynamic simulations.

Parameters
----------
datafile : AbstractString
    Full path to the HDF5 file to be read
simulations_data : SimulationData
    The data structure to be populated with simulation data
config_data : ConfigData
    Configuration data containing grid sizes, file paths, and simulation type
runtime_data : RuntimeData
    Runtime parameters (currently not used in this function)

Side Effects
------------
Modifies the simulations_data structure in-place with the read data
Prints status messages or errors to the console

Notes
-----
- Velocity data is converted from km/s to cm/s (multiplied by 1e5)
- The function handles both MHD (with magnetic fields) and hydrodynamic simulations
- Grid dimensions are read from fakeDim0, fakeDim1, fakeDim2 datasets
"""
function readdata_hdf5!(datafile::AbstractString,
                        simulations_data::SimulationData,
                        config_data::ConfigData,
                        runtime_data::RuntimeData)

    # Extract grid dimensions from configuration
    in_grid = trunc(Int, config_data.grid_size.grid_point.x)
    jn_grid = trunc(Int, config_data.grid_size.grid_point.y)
    kn_grid = trunc(Int, config_data.grid_size.grid_point.z)

    # Read simulation type (MHD or hydro)
    lmhdrun = config_data.simulation_type.lmhdrun  # Flag for MHD simulation

    # Open HDF5 file in read mode using the universal opener
    h5file = open_file(datafile)

    # Check for error code return
    if isa(h5file, Int)
        # If an error code is returned (e.g., 2, 3, 6), return it to the caller.
        return h5file
    end

    # If successful, 'h5file' is the file handle. Proceed with reading.

    # Read grid scales
    try
        simulations_data.Z_grid = read(h5file["fakeDim0"])
        simulations_data.X_grid = read(h5file["fakeDim1"])
        simulations_data.Y_grid = read(h5file["fakeDim2"])
    catch e
        close(h5file)
        return ERROR_HDF5_READ_FAIL
    end

    # Read main simulation datasets with error handling
    try
        # Read and convert velocity components (km/s to cm/s)
        simulations_data.vxx = read(h5file["Data-Set-2"]) * 1e5
        simulations_data.vyy = read(h5file["Data-Set-3"]) * 1e5
        simulations_data.vzz = read(h5file["Data-Set-4"]) * 1e5

        # Read density and energy
        simulations_data.den  = read(h5file["Data-Set-5"])
        simulations_data.ene  = read(h5file["Data-Set-6"])

        # Read magnetic field components if this is an MHD simulation
        if lmhdrun
            simulations_data.bxx = read(h5file["Data-Set-7"])
            simulations_data.byy = read(h5file["Data-Set-8"])
            simulations_data.bzz = read(h5file["Data-Set-9"])
        end

        println("Datasets read successfully - HDF5.")
    catch e
        close(h5file)
        return ERROR_HDF5_READ_FAIL
    end

    # Close the HDF5 file
    close(h5file)

    # Return nothing on complete success (typical for functions ending with '!')
    return nothing
end


#******************************************************************
# Function: readdata_hdf5
# Purpose: Reads simulation datasets from an HDF5 file and returns SimulationData.
#******************************************************************
"""
Read simulation data from an HDF5 file and populate the SimulationData structure.

This function reads grid dimensions, velocity fields, density, energy, and optionally
magnetic field data from an HDF5 file, converting units as necessary and handling
both MHD and hydrodynamic simulations.

Parameters
----------
datafile : AbstractString
    Full path to the HDF5 file to be read
config_data : ConfigData
    Configuration data containing grid sizes, file paths, and simulation type
runtime_data : RuntimeData
    Runtime parameters (currently not used in this function)

Side Effects
------------
Prints status messages or errors to the console

Notes
-----
- Velocity data is converted from km/s to cm/s (multiplied by 1e5)
- The function handles both MHD (with magnetic fields) and hydrodynamic simulations
- Grid dimensions are read from fakeDim0, fakeDim1, fakeDim2 datasets

Return
------
SimulationData
    Returns the (possibly partially populated) SimulationData structure.
"""
function readdata_hdf5(datafile::AbstractString,
                       config_data::ConfigData,
                       runtime_data::RuntimeData)::SimulationData

    # Extract grid dimensions from configuration
    in_grid = trunc(Int, config_data.grid_size.grid_point.x)
    jn_grid = trunc(Int, config_data.grid_size.grid_point.y)
    kn_grid = trunc(Int, config_data.grid_size.grid_point.z)

    # Read simulation type (MHD or hydro)
    lmhdrun = config_data.simulation_type.lmhdrun  # Flag for MHD simulation

    # Create an instance to populate
    simulations_data = SimulationData()

    # Open HDF5 file in read mode using the universal opener
    h5file = open_file(datafile)

    # Check for error code return
    if isa(h5file, Int)
        # If an error code is returned (e.g., 2, 3, 6), return the current structure.
        return simulations_data
    end

    # If successful, 'h5file' is the file handle. Proceed with reading.

    # Read grid scales
    try
        simulations_data.Z_grid = read(h5file["fakeDim0"])
        simulations_data.X_grid = read(h5file["fakeDim1"])
        simulations_data.Y_grid = read(h5file["fakeDim2"])
    catch e
        # println("Error reading grid scales from HDF5 file: ", e)
        close(h5file)
        return simulations_data
    end

    # Read main simulation datasets with error handling
    try
        # Read and convert velocity components (km/s to cm/s)
        simulations_data.vxx = read(h5file["Data-Set-2"]) * 1e5
        simulations_data.vyy = read(h5file["Data-Set-3"]) * 1e5
        simulations_data.vzz = read(h5file["Data-Set-4"]) * 1e5

        # Read density and energy
        simulations_data.den = read(h5file["Data-Set-5"])
        simulations_data.ene = read(h5file["Data-Set-6"])

        # Read magnetic field components if this is an MHD simulation
        if lmhdrun
            simulations_data.bxx = read(h5file["Data-Set-7"])
            simulations_data.byy = read(h5file["Data-Set-8"])
            simulations_data.bzz = read(h5file["Data-Set-9"])
        end

        println("Datasets read successfully - HDF5.")
    catch e
        # println("Error reading datasets: ", e)
        # If reading the datasets fails, close and return the structure as-is
        close(h5file)
        return simulations_data
    end

    # Close the HDF5 file
    close(h5file)

    # Return the populated structure on complete success
    return simulations_data
end

#******************************************************************
# Function: readdata_hdf4!
# Purpose: Read simulation data from HDF4 files and populate data structures
#******************************************************************    
"""
    readdata_hdf4!(simulations_data::SimulationData, config_data::ConfigData, runtime_data::RuntimeData)

Read hydrodynamic or magnetohydrodynamic simulation data from HDF4 files.

This function loads simulation data from HDF4 format files, including grid coordinates,
velocity fields, density, energy density, and optionally magnetic field components
for MHD simulations. The data is populated directly into the `simulations_data` structure.

# Arguments
- `simulations_data::SimulationData`: Data structure to be populated with simulation fields
- `config_data::ConfigData`: Configuration object containing:
  - `grid_size`: Grid dimensions in x, y, z directions
  - `directories`: Data directory path
  - `number_of_plots`: Starting file number for data reading
  - `simulation_type`: Flag indicating if simulation includes MHD fields (`lmhdrun`)
- `runtime_data::RuntimeData`: Runtime data structure (currently not used in this implementation)

# Data Processing
- Reads grid coordinates from "fakeDim0", "fakeDim1", "fakeDim2" datasets
- Reads velocity components from "Data-Set-2", "Data-Set-3", "Data-Set-4" (converted from cm/s to m/s)
- Reads density from "Data-Set-5" and energy density from "Data-Set-6"
- Conditionally reads magnetic field components from "Data-Set-7", "Data-Set-8", "Data-Set-9" for MHD runs

# Notes
- Uses Python's pyhdf library via PyCall for HDF4 file access
- Velocity components are scaled by 1e5 (conversion from cm/s to m/s)
- Includes comprehensive error handling and diagnostic output
"""
function readdata_hdf4!(simulations_data::SimulationData, config_data::ConfigData, runtime_data::RuntimeData)
 # Import Python HDF4 library
     SD = pyimport("pyhdf.SD")
    
    # Extract grid dimensions from configuration
    in_grid = trunc(Int, config_data.grid_size.grid_point.x)
    jn_grid = trunc(Int, config_data.grid_size.grid_point.y)
    kn_grid = trunc(Int, config_data.grid_size.grid_point.z)

    # Get file path and simulation parameters
    directory = config_data.directories.directory
    filenum = config_data.number_of_plots.nfile_start
    lmhdrun = config_data.simulation_type.lmhdrun

     # Construct full file path
    datafile = "$(directory)all00$(filenum).hdf"
    
    try
        # Abrir arquivo HDF4 com pyhdf
        #hdf_file = SD.SD(datafile, SD.SDC.READ) #original
        
        # Open HDF4 file and list available datasets
        println("Attempting to open: $datafile")
        if !isfile(datafile)
            error("File does not exist: $datafile")
        end
        # Open HDF4 file and list available datasets
        SD = pyimport("pyhdf.SD")
        hdf_file = SD.SD(datafile)
        datasets = hdf_file.datasets()
        println("Datasets: ", keys(datasets))

        # List all available dataset names for debugging
        datasets_info = hdf_file.datasets()
        dataset_names = collect(keys(datasets_info))
        println("Available datasets: ", dataset_names)

        # Read grid coordinates
        simulations_data.Z_grid = hdf_file.select("fakeDim0").get()
        simulations_data.X_grid = hdf_file.select("fakeDim1").get()
        simulations_data.Y_grid = hdf_file.select("fakeDim2").get()

        println("Grid size:")
        println("Z: ", length(simulations_data.Z_grid))
        println("X: ", length(simulations_data.X_grid))
        println("Y: ", length(simulations_data.Y_grid))

        # Read velocity components and convert from cm/s to m/s (scale factor 1e5)
        simulations_data.vxx = hdf_file.select("Data-Set-2").get() * 1e5
        simulations_data.vyy = hdf_file.select("Data-Set-3").get() * 1e5
        simulations_data.vzz = hdf_file.select("Data-Set-4").get() * 1e5
       
        # Read scalar fields (density and energy density)
        simulations_data.den = hdf_file.select("Data-Set-5").get()
        simulations_data.ene = hdf_file.select("Data-Set-6").get()

        # Read magnetic field components for MHD simulations
        if lmhdrun
            simulations_data.bxx = hdf_file.select("Data-Set-7").get()
            simulations_data.byy = hdf_file.select("Data-Set-8").get()
            simulations_data.bzz = hdf_file.select("Data-Set-9").get()
        end

        println("Dataset reading completed successfully - HDF4.")

    catch e
        # Comprehensive error handling with diagnostic information
        println("Error reading HDF4 file")
        @show e
    end
end

#******************************************************************
# Function: load_simulation_data!
# Purpose: Automatically detect and load simulation data from multiple file formats
#******************************************************************
"""
    load_simulation_data!(
        simulations_data::SimulationData,
        config_data::ConfigData, 
        runtime_data::RuntimeData
    )

Automatically detect and load simulation data from various file formats.

This function attempts to find and load simulation data by checking multiple file formats
in a prioritized manner. It supports HDF4, HDF5, and other common scientific data formats,
automatically detecting the correct format based on file extension and dispatching to the
appropriate reader function.

# Arguments
- `simulations_data::SimulationData`: Data structure to be populated with simulation data
- `config_data::ConfigData`: Configuration object containing directory and file number information
- `runtime_data::RuntimeData`: Runtime data structure for additional simulation parameters

# Supported Formats
- **HDF4/HDF**: Uses `readdata_hdf4!()` function
- **HDF5/NC**: Uses `readdata_hdf5!()` function  
- **VTK**: Visualization Toolkit format (to be implemented)
- **CSV**: Comma-separated values (to be implemented)
- **YAML/YML**: YAML configuration format (to be implemented)
- **TXT**: ASCII text format (to be implemented)

# Workflow
1. Constructs base filename from configuration parameters
2. Iterates through possible file extensions to find existing files
3. Automatically detects file format based on extension
4. Dispatches to appropriate format-specific reader function
5. Provides detailed feedback on file detection and format recognition

# Notes
- Returns immediately upon successful file loading
- Provides clear diagnostic messages for file detection and format recognition
- Gracefully handles missing files with informative error messages
"""
function load_simulation_data!(
    simulations_data::SimulationData,
    config_data::ConfigData,
    runtime_data::RuntimeData
)
    # Construct base file path from configuration parameters
    directory = config_data.directories.directory
    filenum = config_data.number_of_plots.nfile_start
    datafile_hdf = "$(directory)all00$(filenum)"

    # Prioritized list of supported file extensions
    possible_extensions = [".hdf", ".hdf4", ".hdf5", ".h5", ".vtk", ".csv", ".yaml", ".yml", ".txt"]

    # Iterate through extensions to find existing files
    for ext in possible_extensions
        fullpath = datafile_hdf * ext
        if isfile(fullpath)
            println("File found: $fullpath")

            # Dispatch to appropriate reader based on file extension
            if ext in [".hdf", ".hdf4"]
                println("→ HDF4 format detected.")
                return readdata_hdf4!(simulations_data, config_data, runtime_data)
            elseif ext in [".hdf5", ".nc"]
                println("→ HDF5 format detected.")
                return readdata_hdf5!(simulations_data, config_data, runtime_data)
            elseif ext == ".txt"
                println("→ ASCII format detected (pending implementation).")
                # return readdata_ascii!(simulations_data, config_data, runtime_data)
            elseif ext == ".vtk"
                println("→ VTK format detected (pending implementation).")
                # return readdata_vtk!(simulations_data, config_data, runtime_data)
            elseif ext == ".csv"
                println("→ CSV format detected (pending implementation).")
                # return readdata_csv!(simulations_data, config_data, runtime_data)
            elseif ext in [".yaml", ".yml"]
                println("→ YAML format detected (pending implementation).")
                # return readdata_yaml!(simulations_data, config_data, runtime_data)
            else
                println("→ Unrecognized format.")
            end
        end
    end

    # Error handling: no supported files found
    println("No data files found with known extensions in: $directory")
end

#******************************************************************
# Function: verify_vector_content
# Purpose: Verify consistency of coordinate vector data across multiple HDF5 datasets
#******************************************************************

"""
    verify_vector_content(filename::String)

Verify the consistency and equality of coordinate vector data across multiple dimension datasets in an HDF5 file.

This function checks whether coordinate vectors (Z, X, Y dimensions) stored in multiple
dataset groups contain identical data. It is particularly useful for validating simulation
data where coordinate systems should be consistent across different physical variables
or time steps.

# Arguments
- `filename::String`: Path to the HDF5 file containing coordinate dimension datasets

# Verification Process
1. Reads coordinate data from multiple dimension datasets:
   - Z coordinates: "fakeDim0", "fakeDim3", "fakeDim6", "fakeDim9", "fakeDim12"
   - X coordinates: "fakeDim1", "fakeDim4", "fakeDim7", "fakeDim10", "fakeDim13"  
   - Y coordinates: "fakeDim2", "fakeDim5", "fakeDim8", "fakeDim11", "fakeDim14"
2. Compares all datasets within each coordinate group for equality
3. Reports consistency results for each coordinate axis

# Output
- Boolean results for Z, X, Y coordinate consistency
- Sample data from the first Z coordinate dataset for verification
- Error messages if file access or dataset reading fails

# Use Cases
- Data quality assurance for simulation outputs
- Validation of grid consistency across multiple variables
- Debugging coordinate system discrepancies
- Verification of HDF5 file structure integrity

# Notes
- Uses try-catch block for robust error handling
- Automatically closes HDF5 file to prevent resource leaks
- Provides clear diagnostic output for data validation
"""
function verify_vector_content(filename::String)
    try
        # Open HDF5 file for reading
        h5file = h5open(filename, "r")

        # Read coordinate data from multiple dimension datasets
        z_data = [read(h5file[name]) for name in ["fakeDim0", "fakeDim3", "fakeDim6", "fakeDim9", "fakeDim12"]]
        x_data = [read(h5file[name]) for name in ["fakeDim1", "fakeDim4", "fakeDim7", "fakeDim10", "fakeDim13"]]
        y_data = [read(h5file[name]) for name in ["fakeDim2", "fakeDim5", "fakeDim8", "fakeDim11", "fakeDim14"]]

        # Verify data consistency across all datasets for each coordinate axis
        z_equal = all(z_data[1] == data for data in z_data[2:end])
        x_equal = all(x_data[1] == data for data in x_data[2:end])
        y_equal = all(y_data[1] == data for data in y_data[2:end])

        # Report consistency verification results
        println("Z coordinate content consistent: ", z_equal)
        println("X coordinate content consistent: ", x_equal)
        println("Y coordinate content consistent: ", y_equal)

        # Display sample data from first Z coordinate dataset
        println("Sample Z coordinate data: ", z_data[1])
        
        # Close HDF5 file to release resources
        close(h5file)

    catch e
        # Handle file access or data reading errors
        println("Error processing HDF5 file: ", e)
    end
end

#******************************************************************
# Function: analyze_hdf5_datasets
# Purpose: Comprehensive analysis and classification of HDF5 datasets with metadata extraction
#******************************************************************

"""
    analyze_hdf5_datasets(filename)

Perform comprehensive analysis and classification of all datasets within an HDF5 file.

This function iterates through all datasets in an HDF5 file, extracting and displaying
key metadata information including dimensional properties, descriptive names, and
dimensionality classification. It provides a structured overview of the file's data
contents for inspection and validation purposes.

# Arguments
- `filename::String`: Path to the HDF5 file to be analyzed

# Analysis Output
For each dataset found in the file:
- Dataset name and path
- Dimensionality classification (1D, 2D, 3D, nD)
- Long descriptive name (if available via "long_name" attribute)
- Dimension count based on DIMENSION_LIST attribute or direct ndims() call

# Features
- Automatic dimensionality detection and classification
- Robust handling of missing attributes
- Clear, structured output formatting
- Support for both direct dimension counting and DIMENSION_LIST attribute parsing

# Use Cases
- Data inventory and cataloging
- File structure validation
- Dataset metadata inspection
- Data quality assessment

# Notes
- Operates in read-only mode to prevent file modification
- Gracefully handles datasets with missing metadata attributes
- Provides consistent output format for easy parsing and analysis
"""
function analyze_hdf5_datasets(filename)
    h5open(filename, "r") do file
        println("Analyzing datasets in file: *** ", filename)

        # Iterate through all datasets in the HDF5 file
        for dset_name in keys(file)
            dset = file[dset_name]

            println("DATASET: ", dset)
            
            # Initialize metadata variables
            dim_count = 0
            long_name = "N/A"

            # Check for dimension list attribute first, fall back to direct dimension count
            if haskey(attributes(dset), "DIMENSION_LIST")
                dim_list = attributes(dset)["DIMENSION_LIST"]
                dim_count = length(dim_list)  # Number of dimensions based on reference list
            else
                dim_count = ndims(dset)  # Fallback: get dimensions directly from dataset
            end

            # Extract long descriptive name if available
            if haskey(attributes(dset), "long_name")
                long_name = read(attributes(dset)["long_name"])
            end

            # Classify dataset based on dimensionality
            dim_label = if dim_count == 1
                "1D"
            elseif dim_count == 2
                "2D"
            elseif dim_count == 3
                "3D"
            else
                "$(dim_count)D"
            end

            # Display analysis results for current dataset
            println("  Dataset: ", dset_name)
            println("    Dimension: ", dim_label)
            println("    Long Name: ", long_name)
        end
    end
end

#******************************************************************
# Function: read_ref_data_ds
# Purpose: Read and parse simulation file list with timing data
#******************************************************************
"""
    read_ref_data_ds(filename::String, nfiles::Int, timescale::Float64 = 1.0) -> TimeFile

Read reference data from a file containing simulation file numbers and their corresponding times.

This function parses a data file where each line contains a file identifier and its associated
time value. It processes up to `nfiles` lines and returns the data in a `TimeFile` structure.

# Arguments
- `filename::String`: Path to the input file containing file-time pairs
- `nfiles::Int`: Maximum number of files/lines to read from the file
- `timescale::Float64 = 1.0`: Scaling factor to normalize time values (default: 1.0)

# Returns
- `TimeFile`: A structure containing:
  - `times::Vector{Float64}`: Normalized time values (original time divided by timescale)
  - `files::Vector{Int}`: File identifiers

# File Format Expected
Each line should contain at least two whitespace-separated values:
- First column: File number (integer)
- Second column: Physical time (float)

# Error Handling
- Warns and skips lines with fewer than 2 columns
- Warns and skips lines with parsing errors (invalid numeric formats)
- Stops processing after reading `nfiles` lines

# Example
```julia
# Read first 100 files, converting times from microseconds to seconds
time_file_data = read_ref_data_ds("ref.dat", 100, 1e6)
"""

function read_ref_data_ds(filename::String, nfiles::Int, timescale::Float64 = 1.0)
    # Initialize containers for file numbers and normalized times
    files = Int[]
    times = Float64[]
    # Process each line in the input file
    for (i, line) in enumerate(eachline(filename))
    # Stop processing after reading the specified number of files
        if i > nfiles
            break
        end
    # Split line into fields and remove leading/trailing whitespace
        fields = split(strip(line))
        # Process only lines with at least two columns
        if length(fields) >= 2
            try 
                # Parse file number from first column
                push!(files, parse(Int, fields[1]))
                # Parse time from second column and apply normalization
                push!(times, parse(Float64, fields[2]) / timescale)
            catch e
                # Handle parsing errors (e.g., non-numeric values)
                @warn "Error processing line: $line" exception=(e, catch_backtrace())
            end
        else
         # Warn about lines with insufficient data
            @warn "Invalid line (fewer than 2 columns): $line"
        end
    end
    # Return structured data using TimeFile constructor
    return TimeFile(times,files) #TimeFile is define in runtime.jl
end

#******************************************************************
# Function: readlist!
# Purpose: Read and parse simulation file list with timing data
#******************************************************************
"""
    readlist!(filename::String, config_data::ConfigData, runtime_data::RuntimeData)

Read and parse a file list containing simulation snapshots and their corresponding times.

This function processes a reference file (typically `ref.dat`) that contains pairs of
file numbers and physical times for simulation outputs. It populates the runtime data
structure with file identifiers and normalized time values.

# Arguments
- `filename::String`: Path to the input file containing file-time pairs
- `config_data::ConfigData`: Configuration object containing:
  - `nfiles`: Number of files to read from the list
  - `timescale`: Scaling factor to normalize time values
- `runtime_data::RuntimeData`: Runtime data structure to be updated in-place with:
  - `files`: Vector of file identifiers (integers)
  - `time`: Vector of normalized time values (floats)

# File Format Expected
Each line should contain at least two space-separated values:
- First column: File number (integer)
- Second column: Physical time (float) that will be divided by `timescale`

# Example Input Line
"1050 1.5e6" → files_files[l] = 1050, time_files[l] = 1.5e6 / timescale

# Side Effects
- Prints each processed file number and normalized time to stdout
- Issues warnings for invalid lines that don't contain at least two values
"""

function readlist(filename::String, config_data::ConfigData, runtime_data::RuntimeData)
    # Reads file numbers to be used in the construction of the file name
    # Note that here nfiles is the number of files in ref.dat

    nfiles = config_data.file_flags.nfiles
    timescale = config_data.timescale

    try
        open(filename, "r") do io1
            open("2", "w") do io2
                for l in 1:nfiles
                    line = readline(io1)
                    if line === nothing
                        break # Handle end of file
                    end
                    parts = split(line)
                    if length(parts) >= 2
                        runtime_data.files[l] = parse(Int, parts[1])
                        runtime_data.time[l] = parse(Float64, parts[2]) / timescale
                        write(io2, "$(runtime_data.files[l]) $(runtime_data.time[l])\n")
                    else
                        println("Warning: Invalid line in ref.dat: $line")
                    end
                end
            end
        end
    catch e
        println("Error reading $filemname: ", e)
    end

    return runtime_data # return the modified runtime_data
end

#******************************************************************
# Function: readlist!
# Purpose: Read and parse simulation file list with timing data
#******************************************************************
"""
    readlist!(filename::String, config_data::ConfigData, runtime_data::RuntimeData)

Read and parse a file list containing simulation snapshots and their corresponding times.

This function processes a reference file (typically `ref.dat`) that contains pairs of
file numbers and physical times for simulation outputs. It populates the runtime data
structure with file identifiers and normalized time values.

# Arguments
- `filename::String`: Path to the input file containing file-time pairs
- `config_data::ConfigData`: Configuration object containing:
  - `nfiles`: Number of files to read from the list
  - `timescale`: Scaling factor to normalize time values
- `runtime_data::RuntimeData`: Runtime data structure to be updated in-place with:
  - `files`: Vector of file identifiers (integers)
  - `time`: Vector of normalized time values (floats)

# File Format Expected
Each line should contain at least two space-separated values:
- First column: File number (integer)
- Second column: Physical time (float) that will be divided by `timescale`

# Example Input Line
"1050 1.5e6" → files_files[l] = 1050, time_files[l] = 1.5e6 / timescale

# Side Effects
- Prints each processed file number and normalized time to stdout
- Issues warnings for invalid lines that don't contain at least two values
"""

function readlist!(filename::String,config_data::ConfigData, runtime_data::RuntimeData)
    # Extract configuration parameters
    nfiles = config_data.number_of_plots.nfiles
    timescale = config_data.timescale
    # Access runtime data arrays for in-place modification
    time_files = runtime_data.time_files.time #Accessing the time vector
    files_files = runtime_data.time_files.files #Accessing the files vector

    # Open and process the reference file
    open(filename, "r") do file
     # Read exactly nfiles lines from the input file
        for l in 1:nfiles
            line = readline(file)
            parts = split(line)
            # Process line only if it contains at least two values
            if length(parts) >= 2
            # Parse file number (first column) as integer
                files_files[l] = parse(Int, parts[1])
                # Parse physical time (second column) and normalize by timescale
                time_files[l] = parse(Float64, parts[2]) / timescale
                # Output verification: display processed file number and normalized time
                println(files_files[l], " ", time_files[l]) # Simula a escrita para o arquivo 2
            else
                @warn "Invalid line in $filename: $line"
            end
        end
    end
end

#******************************************************************
# Function: variables!
# Purpose: Calculate derived physical variables for simulation data based on configuration flags.
#******************************************************************
"""
    variables!(simulations_data::SimulationData, config_data::ConfigData)

Calculate derived physical variables for simulation data based on configuration flags.

This function computes temperature and velocity magnitude fields from basic hydrodynamic
quantities according to the specified configuration parameters. It performs in-place
modifications of the `simulations_data` structure.

# Arguments
- `simulations_data::SimulationData`: Container holding simulation field data (energy density, 
  mass density, velocity components, etc.). Modified in-place.
- `config_data::ConfigData`: Configuration object containing boolean flags that control 
  which variables to calculate.

# Physical Quantities Calculated

## Temperature Calculation (if `lions`, `lele`, or `ltemp` are true)
- Pressure: `pre = γ₁ * ene` (with lower limit `smallp`)
- Temperature: `tem = (pre * mh) / (den * boltz)`

## Velocity Magnitude Calculation (if `lpram` or `lmach` are true)  
- Velocity squared: `vel2 = vxx² + vyy² + vzz²`

# Notes
- Uses physical constants from `AstroTLPlot` module (γ₁, mh, boltz, smallp)
- Applies numerical safeguards against small pressure values
- All operations are element-wise and broadcasted over arrays
"""
function variables!(simulations_data::SimulationData, config_data::ConfigData)
    # Extract required field data from simulations_data
    ene = simulations_data.ene
    den = simulations_data.den
    vxx = simulations_data.vxx
    vyy = simulations_data.vyy
    vzz = simulations_data.vzz
    pre = simulations_data.pre
    tem = simulations_data.tem
    vel2 = simulations_data.vel2
    # Extract configuration flags for variable calculation
    lions = config_data.variable_params.lions
    lele = config_data.variable_params.lele
    ltemp = config_data.variable_params.ltemp
    lpram = config_data.variable_params.lpram
    lmach = config_data.variable_params.lmach
    # Physical constants
    gamma1 = AstroTLPlot.GAMMA1
    mh = AstroTLPlot.MH
    boltz = AstroTLPlot.BOLTZ
    smallp = AstroTLPlot.SMALLP

    # Calculate temperature-related quantities if any temperature flag is active
    if lions || lele || ltemp
    # Compute pressure from energy density: P = γ₁ * energy_density
        simulations_data.pre .= gamma1 .* ene
    # Apply lower bound to prevent unphysical small pressure values
        simulations_data.pre .= max.(smallp, pre)
    # Compute temperature: T = (P * mh) / (ρ * kₙ)
        simulations_data.tem .= pre .* mh ./ den ./ boltz
    end

    # Calculate velocity magnitude squared if required for momentum or Mach number
    if lpram || lmach
        simulations_data.vel2 .= vxx.^2 .+ vyy.^2 .+ vzz.^2
    end
end

#******************************************************************
# Function: variables_v0!
# Purpose: calculate_temperature_pressure_velocity!
#******************************************************************

function variables!(config_data::ConfigData)
    # Calculate the 3D variables: tem and denh
    # Tem is needed for the ions.

    if config_data.ion_flags.lions || config_data.electron_flags.lele || config_data.temperature_flags.ltemp
        pre = config_data.eos_flags.gamm1 * config_data.simulation_data.ene
        pre = max(config_data.eos_flags.smallp, pre) # Avoid zeros or negative pressure
        config_data.simulation_data.tem .= pre .* MH ./ config_data.simulation_data.den ./ BOLTZ
    end

    if config_data.pressure_flags.lpram || config_data.mach_flags.lmach
        config_data.simulation_data.vel2 .= config_data.simulation_data.vxx .^ 2 .+ config_data.simulation_data.vyy .^ 2 .+ config_data.simulation_data.vzz .^ 2
    end

    return config_data # Return the modified config_data
end
