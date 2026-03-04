# ==============================================================================
# Inspection and Debugging Utilities Module
#
# This module provides helper functions for inspecting data structures and arrays,
# including tools for printing selected regions of multi-dimensional arrays in
# scientific notation and reporting detailed information about the fields of
# composite types. These utilities are intended to support debugging, exploratory
# analysis, and introspection during development and testing.
#
# Author: Tomás Lima
# Date: 2026-01-12
# ==============================================================================
using Printf

"""
    parse_float_scientific_strict(str::AbstractString) -> Float64

Parses a string representing a floating-point number in scientific notation 
into a `Float64`.

This function supports both `E` and `D` notation (Fortran-style).
If parsing fails, it returns `NaN`.

# Arguments
- `str::AbstractString`: A string containing a number in scientific notation.

# Returns
- `Float64` value if parsing succeeds.
- `NaN` if parsing fails.

# Examples
```julia
julia> parse_float_scientific_strict("1.23E-04")
0.000123

julia> parse_float_scientific_strict("2.5D+03")
2500.0

julia> parse_float_scientific_strict("invalid")
NaN

"""
function parse_float_scientific_strict(str::AbstractString)::Float64
    try
        clean_str = replace(str, r"[dD]" => "E") # Fortran D → E
        return parse(Float64, clean_str)
    catch
        return NaN
    end
end

# ==============================================================================
# 
# 
#
# ==============================================================================

"""
Displays the first n values of a 1D array with indices and values in scientific notation.

Arguments:
- vetor: 1D array of Float64
- n: Number of elements to display
"""
function print_vect(vetor::Vector{Float64}, n::Int)
  
    total = length(vetor)
    println("=== First $n values of 1D array (length $total) ===")
    println(" i      Value")
    println("---  ---------------")

    for i in 1:min(n, total)
        value_str = @sprintf("%.6E", vetor[i])
        println(@sprintf("%3d  %15s", i, value_str))
    end

    if n > total
        println("\n⚠️  Warning: n ($n) is greater than the total size of the array ($total)")
    end
end

# ==============================================================================
# 
# 
#
# ==============================================================================
 """
    Displays the first n values of a 2D array with indices and values in scientific notation.

    Arguments:
    - vetor: 2D array of Float64
    - n: Number of elements to display
    """
function print_vect(vetor::Array{Float64,2}, n::Int)
   
    dims = size(vetor)
    count = 0

    println("=== First $n values of 2D array (dimensions $dims) ===")
    println(" i    j      Value")
    println("---  ---  ---------------")

    for j in 1:dims[2]
        for i in 1:dims[1]
            if count < n
                value_str = @sprintf("%.6E", vetor[i, j])
                println(@sprintf("%3d  %3d  %15s", i, j, value_str))
                count += 1
            else
                break
            end
        end
        count >= n && break
    end

    if n > prod(dims)
        println("\n⚠️  Warning: n ($n) is greater than the total size of the array ($(prod(dims)))")
    end
end

# ==============================================================================
# 
# 
#
# ==============================================================================

 """
    Displays the first n values of a 3D array with indices and values in scientific notation.

    Arguments:
    - vetor: 3D array of Float64
    - n: Number of elements to display
    """

function print_vect(vetor::Array{Float64,3}, n::Int)
   
    dims = size(vetor)
    count = 0

    println("=== First $n values of 3D array (dimensions $dims) ===")
    println(" i    j    k      Value")
    println("---  ---  ---  ---------------")

    for k in 1:dims[3]
        for j in 1:dims[2]
            for i in 1:dims[1]
                if count < n
                    value_str = @sprintf("%.6E", vetor[i, j, k])
                    println(@sprintf("%3d  %3d  %3d  %15s", i, j, k, value_str))
                    count += 1
                else
                    break
                end
            end
            count >= n && break
        end
        count >= n && break
    end

    if n > prod(dims)
        println("\n⚠️  Warning: n ($n) is greater than the total size of the array ($(prod(dims)))")
    end
end


# ==============================================================================
# 
# 
#
# ==============================================================================
"""
Displays values of a 1D array within the specified range with indices and values in scientific notation.

Arguments:
- vetor: 1D array of Float64
- xmin: Minimum index in x direction (inclusive)
- xmax: Maximum index in x direction (inclusive)
"""
function print_vect(vetor::Vector{Float64}, xmin::Int, xmax::Int)
    total = length(vetor)
    
    # Validate ranges
    xmin = max(1, xmin)
    xmax = min(total, xmax)
    
    if xmin > xmax
        println("⚠️  Error: xmin ($xmin) is greater than xmax ($xmax)")
        return
    end
    
    n = xmax - xmin + 1
    
    println("=== Values of 1D array (indices $xmin:$xmax of $total) ===")
    println(" i      Value")
    println("---  ---------------")

    for i in xmin:xmax
        value_str = @sprintf("%.6E", vetor[i])
        println(@sprintf("%3d  %15s", i, value_str))
    end
end

# ==============================================================================
# 
# 
#
# ==============================================================================

"""
Displays values of a 2D array within the specified ranges with indices and values in scientific notation.

Arguments:
- vetor: 2D array of Float64
- xmin: Minimum index in x direction (inclusive)
- xmax: Maximum index in x direction (inclusive)
- ymin: Minimum index in y direction (inclusive)
- ymax: Maximum index in y direction (inclusive)
"""
function print_vect(vetor::Array{Float64,2}, xmin::Int, xmax::Int, ymin::Int, ymax::Int)
    dims = size(vetor)
    
    # Validate ranges
    xmin = max(1, xmin)
    xmax = min(dims[1], xmax)
    ymin = max(1, ymin)
    ymax = min(dims[2], ymax)
    
    if xmin > xmax || ymin > ymax
        println("⚠️  Error: Invalid range - x: [$xmin, $xmax], y: [$ymin, $ymax]")
        return
    end
    
    total_in_range = (xmax - xmin + 1) * (ymax - ymin + 1)
    
    println("=== Values of 2D array (dimensions $dims, range x[$xmin:$xmax], y[$ymin:$ymax]) ===")
    println(" i    j      Value")
    println("---  ---  ---------------")

    count = 0
    for j in ymin:ymax
        for i in xmin:xmax
            value_str = @sprintf("%.6E", vetor[i, j])
            println(@sprintf("%3d  %3d  %15s", i, j, value_str))
            count += 1
        end
    end
    
    println("\nTotal elements displayed: $count")
end

# ==============================================================================
# 
# 
#
# ==============================================================================
"""
Displays values of a 3D array within the specified ranges with indices and values in scientific notation.

Arguments:
- vetor: 3D array of Float64
- xmin: Minimum index in x direction (inclusive)
- xmax: Maximum index in x direction (inclusive)
- ymin: Minimum index in y direction (inclusive)
- ymax: Maximum index in y direction (inclusive)
- zmin: Minimum index in z direction (inclusive)
- zmax: Maximum index in z direction (inclusive)
"""
function print_vect(vetor::Array{Float64,3}, xmin::Int, xmax::Int, ymin::Int, ymax::Int, zmin::Int, zmax::Int)
    dims = size(vetor)
    
    # Validate ranges
    xmin = max(1, xmin)
    xmax = min(dims[1], xmax)
    ymin = max(1, ymin)
    ymax = min(dims[2], ymax)
    zmin = max(1, zmin)
    zmax = min(dims[3], zmax)
    
    if xmin > xmax || ymin > ymax || zmin > zmax
        println("⚠️  Error: Invalid range - x: [$xmin, $xmax], y: [$ymin, $ymax], z: [$zmin, $zmax]")
        return
    end
    
    total_in_range = (xmax - xmin + 1) * (ymax - ymin + 1) * (zmax - zmin + 1)
    
    println("=== Values of 3D array (dimensions $dims, range x[$xmin:$xmax], y[$ymin:$ymax], z[$zmin:$zmax]) ===")
    println(" i    j    k      Value")
    println("---  ---  ---  ---------------")

    count = 0
    for k in zmin:zmax
        for j in ymin:ymax
            for i in xmin:xmax
                value_str = @sprintf("%.6E", vetor[i, j, k])
                println(@sprintf("%3d  %3d  %3d  %15s", i, j, k, value_str))
                count += 1
            end
        end
    end
    
    println("\nTotal elements displayed: $count")
end

# ==============================================================================
# 
# 
#
# ==============================================================================

"""
    print_struct_info(struct_data)

Prints the names, types, and dimensions of all fields in a given struct.

- If the field is an array, its dimensions are shown.
- For other fields, only the type is shown.
- If retrieving size or other info fails, the error is caught and reported.

# Example
```julia
print_struct_info(simulations_data)
"""
function print_struct_info(struct_data)
    println("Information about the fields in the struct:")
    for field_name in fieldnames(typeof(struct_data))
    field_value = getfield(struct_data, field_name)
        try
        dims = size(field_value) # might fail for non-arrays
        println("Name: ", field_name,
        " | Type: ", typeof(field_value),
        " | Dimensions: ", dims)
        catch
        # fallback if size() is not applicable
        println("Name: ", field_name,
        " | Type: ", typeof(field_value),
        " | Dimensions: not applicable")
        end
    end
end

# ==============================================================================
# Function: print_xionvar_table
# Purpose:  Generate formatted table output for 3D ion fraction data with file export capability
# ==============================================================================
"""
    print_xionvar_table(xionvar::Array{Float64,5}, eid::Int, ionz::Int; filename::Union{String,Nothing}=nothing)

Generate and display a formatted table of ion fraction values from 3D simulation data.

This function extracts a specific 3D ion fraction cube from the 5D `xionvar` array and
produces a human-readable table showing ion fraction values at each grid point. The output
includes grid coordinates and can be displayed in the console or saved to a file.

# Arguments
- `xionvar::Array{Float64,5}`: 5D array containing ion fraction data [i, j, k, element, ionization]
- `eid::Int`: Element identifier index in the 4th dimension
- `ionz::Int`: Ionization state index (0-based, converted to 1-based for array access)

# Keyword Arguments
- `filename::Union{String,Nothing}=nothing`: Optional filename for saving table output

# Features
- Formatted column alignment for easy readability
- Scientific notation for ion fraction values
- Console display with optional file export
- Comprehensive grid coordinate information

# Use Cases
- Debugging ion fraction calculations
- Data verification and quality control
- Exporting specific ion state data for external analysis
- Documentation of simulation results

# Notes
- Uses 1-based indexing for consistency with Julia conventions
- Automatically handles ionization state indexing conversion
- Efficient memory usage through buffered I/O operations
"""
function print_xionvar_table(xionvar::Array{Float64,5}, eid::Int, ionz::Int; filename::Union{String,Nothing}=nothing)
    cube = xionvar[:,:,:, eid, ionz+1]

      # Create table header with column descriptions
    header = "i   j   k   eid   ionz   value\n" *
             "----------------------------------------------\n"
    # Initialize output buffer for efficient string construction
    buffer = IOBuffer()
    print(buffer, header)

     # Iterate through all grid points and format table rows
    for i in axes(cube,1), j in axes(cube,2), k in axes(cube,3)
        val = cube[i,j,k]
        # Format row with fixed-width columns and scientific notation
        @printf(buffer, "%3d %3d %3d  %3d  %3d  %14.8e\n", i, j, k, eid, ionz, val)
    end

     # Convert buffer content to string
    output = String(take!(buffer))

    # Display table in console
    println(output)

    # Save to file if filename provided
    if filename !== nothing
        open(filename, "w") do f
            write(f, output)
        end
        println(">> Table saved to: $filename")
    end

    return nothing
end

