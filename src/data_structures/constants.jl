# ==============================================================================
# Physical Constants and Configuration Module
# 
# This module defines physical constants, mathematical constants, precision types,
# simulation parameters, and status codes used throughout the simulation framework.
#
# Author: [Tomás Lima]
# Date: [2025-10-17]
# ==============================================================================

"""
    PhysicalConstants

A module providing comprehensive physical and mathematical constants, precision types,
simulation parameters, and error handling codes for plasma and MHD simulations.

# Categories
- Physical Constants (fundamental physics)
- Mathematical Constants
- Precision Types
- Simulation Parameters
- Plot Configuration
- Unit Identifiers
- Status Codes and Error Handling

# Usage
```julia
using .PhysicalConstants

# Use physical constants
thermal_energy = BOLTZ * temperature
proton_mass_ratio = MP / ELMA

# Use precision types
x::DP = 3.141592653589793

# Check status codes
if status == STATUS_SUCCESS
    println("Operation completed successfully")
end
"""

const GAMMA = 5.0 / 3.0            # Adiabatic index
const GAMMA1 = GAMMA - 1.0         # GAMMA minus one

const BOLTZ = 1.38065e-16          # Boltzmann constant (erg/K)
const CLIGHT = 2.99792458e+10      # Speed of light in vacuum (cm/s)
const HPL = 6.62606896e-27         # Planck's constant (erg·s)


# ===============================
# Particle Masses
# ===============================

const ELMA = 9.10938e-28           # Electron mass (g)
const MP = 1.67262e-24             # Proton mass (g)
const MH = 1.67353e-24             # Hydrogen atom mass (g)
const ME = 9.1093837015e-28     

# ===============================
# Other Constants
# ===============================

const SMALLP = 1.0e-30             # Minimum pressure (g/cm·s²)
const CMPC = 3.086e18              # Megaparsec to cm conversion factor
const EPSILON = 1e-10              # Small value to avoid log10(0)

# ===============================
# Mathematical Constants
# ===============================

#const PI    = 4.0 * atan(1.0)      # Value of π
const PI     = π                    # Using Julia's built-in constant
const TWOPI  = 2π
const FOURPI = 4π  #const FOURPI = 1.0
# ===============================
# Precision Types
# ===============================

const SP = Float32                 # Single precision floating-point type
const DP = Float64                 # Double precision floating-point type
const QP = BigFloat                # Quadruple precision floating-point type

# ===============================
# Simulation Constants
# ===============================

const MAXCOO = 5000                # Maximum number of ion elements for calculations
const MAX_ATOMIC_NUMBER = 26       # Maximum atomic number for chemical elements

# ===============================
# Plot Dimensions
# ===============================

const WIDTHPLOT::Float64 = 5.0     # Width of PDF plots
const ASPECTPLOT::Float64 = 0.9    # Aspect ratio of PDF plots

# ===============================
# Unit Identifiers
# ===============================

const GUNIT::Int = 13              # Gravity unit identifier
const LUNIT::Int = 14              # Length unit identifier
const TEMGUNIT::Int = 15           # Temperature gradient unit identifier
const TEMLUNIT::Int = 16           # Temperature length unit identifier
const PREGUNIT::Int = 17           # Pressure gradient unit identifier
const PRELUNIT::Int = 18           # Pressure length unit identifier
const RAMGUNIT::Int = 19           # RAM gradient unit identifier
const RAMLUNIT::Int = 20           # RAM length unit identifier

# ==============================================================================
# Status Codes for Configuration I/O (YAML/File Access)
# ==============================================================================

# Success Code
const STATUS_SUCCESS              = 0    # 0 = Success

const STATUS_SAVE_SUCCESS         = 30   # Successfully saved file(s)
const STATUS_LOAD_SUCCESS         = 31   # Successfully loaded file(s)
const STATUS_DISPLAY_SUCCESS      = 32   # Successfully displayed statistics

# Error Codes
const ERROR_UNKNOWN               = 1    # 1 = Unmapped/Generic Error (Fallback)

# ---------------------------------------------
# In-Progress / Informational Status
# ---------------------------------------------
const STATUS_PROCESSING           = 33   # Operation is currently in progress (informational)

# ---------------------------------------------
# Open / Read Errors (existing semantics)
# ---------------------------------------------
const ERROR_FILE_NOT_FOUND   = 2    # 2 = File Not Found
const ERROR_NO_PERMISSIONS   = 3    # 3 = No Permissions
const ERROR_YAML_PARSING     = 4    # 4 = YAML Parsing Error
const ERROR_WRONG_EXTENSION  = 5    # 5 = Wrong Extension
const ERROR_HDF5_READ_FAIL   = 6    # 6 = Failed to read/access data within an opened HDF5 file.
const ERROR_HDF4_READ_FAIL   = 7    # 7 = Failed to read/access data within an opened HDF4 file.
const ERROR_CSV_READ_FAIL    = 8    # 8 = Failed to parse the data structure within an opened CSV file.
const ERROR_UNSUPPORTED_TYPE = 9    # 9 = File extension is valid but the specific format/type is not supported by the function.

# ---------------------------------------------
# Display / Save / Write Errors (new semantics)
# ---------------------------------------------
const STATUS_DISPLAY_FAIL            = 20   # 20 = Failed to display statistics (print_statistic)
const ERROR_PATH_CREATION_FAIL       = 22   # 22 = Failed to create output directory
const ERROR_NO_WRITE_PERMISSIONS     = 23   # 23 = Write permissions denied for output directory
const ERROR_EMPTY_FILE_LIST          = 24   # 24 = Saving requested but list_of_files is empty
const ERROR_UNSUPPORTED_OUTPUT_TYPE  = 25   # 25 = Unsupported output type (only .txt and .pdf supported)
const ERROR_TXT_WRITE_FAIL           = 26   # 26 = Failed to write TXT output file
const ERROR_PDF_WRITE_FAIL           = 27   # 27 = Failed to write PDF output file
const ERROR_GENERIC_SAVE_FAIL        = 28   # 28 = Generic saving failure (I/O or unexpected error)

# Dictionary of status messages (code => message)
const ERROR_MESSAGES_DICT = Dict{Int, String}(
    # --- Status Code ---
    STATUS_SUCCESS              => "Code 0: Operation completed successfully.",
    STATUS_SAVE_SUCCESS         => "Code 30: File saved successfully.",
    STATUS_LOAD_SUCCESS         => "Code 31: File loaded successfully.",
    STATUS_DISPLAY_SUCCESS      => "Code 32: Statistics displayed successfully.",
    
  # --- Informational ---
    STATUS_PROCESSING           => "Code 33: Processing simulation data ...",

   

    # --- Generic/Unmapped Errors ---
    ERROR_UNKNOWN           => "Code 1: Unknown or unexpected processing error.",
    
    # --- I/O and Initial Access Errors (Codes 2-3) ---
    ERROR_FILE_NOT_FOUND    => "Code 2: File not found.",
    ERROR_NO_PERMISSIONS    => "Code 3: Read permissions denied or file access issue.",
    
    # --- Parsing/Format Errors (Codes 4-5) ---
    ERROR_YAML_PARSING      => "Code 4: YAML syntax (parsing) error in file.",
    ERROR_WRONG_EXTENSION   => "Code 5: Incorrect file extension for expected format.",
    
    # --- Format-Specific Read Failures (Codes 6-8) ---
    ERROR_HDF5_READ_FAIL    => "Code 6: Failed to read data structure within the opened HDF5 file.",
    ERROR_HDF4_READ_FAIL    => "Code 7: Failed to read data structure within the opened HDF4 file.",
    ERROR_CSV_READ_FAIL     => "Code 8: Failed to parse data structure within the opened CSV/DAT file.",
    
    # --- Unsupported Type Error (Code 9) ---
    ERROR_UNSUPPORTED_TYPE  => "Code 9: File type is not supported by the universal open function.",
    
    # --- Display/Save/Write (new) ---
    STATUS_DISPLAY_FAIL            => "Code 20: Failed to display statistics (print_statistic).",
    ERROR_PATH_CREATION_FAIL       => "Code 22: Failed to create output directory.",
    ERROR_NO_WRITE_PERMISSIONS     => "Code 23: Write permissions denied for output directory.",
    ERROR_EMPTY_FILE_LIST          => "Code 24: Saving requested but list_of_files is empty.",
    ERROR_UNSUPPORTED_OUTPUT_TYPE  => "Code 25: Unsupported output file type (only .txt and .pdf are supported).",
    ERROR_TXT_WRITE_FAIL           => "Code 26: Failed to write TXT output file.",
    ERROR_PDF_WRITE_FAIL           => "Code 27: Failed to write PDF output file.",
    ERROR_GENERIC_SAVE_FAIL        => "Code 28: Generic saving failure (I/O or unexpected error)."
   
)

# ---------------------------------------------
# Optional: Helper to fetch messages safely
# ---------------------------------------------
"""
    error_message(code::Int) -> String

Return the human-readable message associated with `code`.
Falls back to the generic unknown error message if the code is unmapped.
"""
error_message(code::Int) = get(ERROR_MESSAGES_DICT, code, ERROR_MESSAGES_DICT[ERROR_UNKNOWN])

