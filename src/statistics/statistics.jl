# =============================================================================
# File: statistics.jl
# Description:
#     This file contains a collection of functions for computing statistical
#     measures (sum, mean, variance, standard deviation, min/max values, and
#     axis limits) for 1D, 2D, and 3D data structures. It also includes
#     optional transformations applied to elements using user-defined functions.
#
# Contents:
#     - Public Functions:
#         * statistics_data1D: Compute statistics for a full 1D vector.
#         * statistics_data2D: Compute statistics for a full 2D matrix.
#         * statistics_data3D: Compute statistics for a full 3D array.
#         * statistics_data_windowed1D: Compute statistics for a specified window in a 1D vector.
#         * statistics_data_windowed2D: Compute statistics for a specified window in a 2D matrix.
#         * statistics_data_windowed3D: Compute statistics for a specified window in a 3D array.
#
#       These functions return structured results including:
#         - Sum, mean, variance, standard deviation
#         - Minimum and maximum values with coordinates
#         - Axis limits and ranges
#         - Transformed data arrays
#
#       Transformation Rules:
#         - If a function is provided (e.g., log10, sqrt), it is applied to each element.
#         - For log10:
#             * Negative values: sign(element) * log10(abs(element))
#             * Zero values: replaced with 0.0 to avoid -Inf
#             * Positive values: log10(element)
#         - For other functions:
#             * Negative values: sign(element) * func(abs(element))
#             * Zero or positive values: func(element)
#
#     - Private Helper Functions:
#         * variance_loops_1D: Compute variance for a full 1D vector.
#         * variance_loops_windowed_1D: Compute variance for a window in a 1D vector.
#         * variance_loops2D: Compute variance for a full 2D matrix.
#         * variance_loops_windowed2D: Compute variance for a window in a 2D matrix.
#         * variance_loops_3D: Compute variance for a full 3D array.
#         * variance_loops_windowed3D: Compute variance for a window in a 3D array.
#
# Notes:
#     - All helper functions are intended for internal use only (not exported).
#     - Variance calculations use (n - 1) in the denominator for unbiased sample variance.
#     - All functions ensure type conversion to Float64 for numerical stability.
#
# Author: [Tomás Lima]
# Date: [2025-10-17]
# =============================================================================

#******************************************************************
# Helper Function
#******************************************************************

"""
    find_axis_limits_data(matrix::AbstractMatrix)

Determine the minimum and maximum indices for rows (y) and columns (x) in a given matrix.

# Arguments
- `matrix::AbstractMatrix`: Input matrix.

# Returns
- `AxisLimits`: A structure containing:
    - `x_min`: Minimum column index.
    - `x_max`: Maximum column index.
    - `y_min`: Minimum row index.
    - `y_max`: Maximum row index.
"""
function find_axis_limits_data(matrix::AbstractMatrix)
    # Initialize axis limits with extreme values
    x_min = size(matrix, 2)
    x_max = 1
    y_min = size(matrix, 1)
    y_max = 1

    # Iterate through the matrix to find min and max indices
    for i in 1:size(matrix, 1)
        for j in 1:size(matrix, 2)
            x_min = min(x_min, j)
            x_max = max(x_max, j)
            y_min = min(y_min, i)
            y_max = max(y_max, i)
        end
    end

    # Create AxisLimits structure with computed values
    axis_limits = AxisLimits(x_min, x_max, y_min, y_max)

    return axis_limits
end

#******************************************************************
#  Variance_loops(vector::AbstractVector{T}, mean_val::T, n_elements::Int) where T<:Real
#******************************************************************

"""
    variance_loops(vector::AbstractVector{T}, mean_val::T, n_elements::Int) where T<:Real

Compute the sample variance for a 1D vector using a loop-based approach.

# Arguments
- `vector::AbstractVector{T}`: Input vector of real numbers.
- `mean_val::T`: Precomputed mean of the vector.
- `n_elements::Int`: Number of elements in the vector.

# Returns
- `Float64`: The sample variance of the vector.
"""
function variance_loops(vector::AbstractVector{T}, mean_val::T, n_elements::Int) where T<:Real
    # Initialize sum of squared differences
    sum_sq_diff = zero(T)

    # Iterate through all elements and accumulate squared differences
    for i in 1:n_elements
        diff = vector[i] - mean_val
        sum_sq_diff += diff * diff
    end

    # Return sample variance (n-1 denominator for unbiased estimate)
    return sum_sq_diff / (n_elements - 1)
end

#*****************************************
#   variance_loops_windowed_1D(vector::AbstractVector{T}, mean_val::T, n_elements::Int,
#                                wmin::Int, wmax::Int) where T<:Real
#*****************************************

"""
    variance_loops(vector::AbstractVector{T}, mean_val::T, n_elements::Int,
                                wmin::Int, wmax::Int) where T<:Real

Compute the sample variance for a specified window in a 1D vector using a loop-based approach.

# Arguments
- `vector::AbstractVector{T}`: Input vector of real numbers.
- `mean_val::T`: Precomputed mean of the window.
- `n_elements::Int`: Number of elements in the window.
- `wmin::Int, wmax::Int`: Start and end indices of the window.

# Returns
- `Float64`: The sample variance of the specified window.
"""
function variance_loops(vector::AbstractVector{T}, mean_val::T, n_elements::Int,
                                    wmin::Int, wmax::Int) where T<:Real
    # Initialize sum of squared differences
    sum_sq_diff = zero(T)

    # Iterate through the specified window and accumulate squared differences
    for i in wmin:wmax
        diff = vector[i] - mean_val
        sum_sq_diff += diff * diff
    end

    # Return sample variance (n-1 denominator for unbiased estimate)
    return sum_sq_diff / (n_elements - 1)
 end

#*****************************************
#  statistics_data
#*****************************************

"""
    statistics_data(vector::AbstractVector{T}, func::Union{Function, Nothing}=nothing) where T<:Real

Compute statistical data for a 1D vector and optionally apply a transformation function to each element.

# Arguments
- `vector::AbstractVector{T}`: Input vector of real numbers.
- `func::Union{Function, Nothing}`: Optional function to apply to each element. If `nothing`, no transformation is applied.

# Returns
- `Vector1DStatistics`: A structure containing:
    - Sum, mean, variance, standard deviation
    - Minimum and maximum values with indices
    - Axis limits and range
    - Transformed vector

# Notes
- If `func === log10`, negative values are transformed as `sign(element) * log10(abs(element))`.
- Zero values are replaced with `0.0` to avoid `-Inf`.
- For other functions, negative values are transformed using `sign(element) * func(abs(element))`.

# Examples
```julia
# Example 1: Compute statistics without transformation
vec = [1, 2, 3, 4, 5]
result = statistics_data(vec)
println(result.statistics_data.mean)  # Output: 3.0

# Example 2: Apply log10 transformation
vec = [-10, 0, 10, -100, 50]
result = statistics_data(vec, log10)
println(result.vector_result)  # Transformed vector with log10 applied

# Example 3: Apply sqrt transformation
vec = [1, 4, 9, 16, 25]
result = statistics_data(vec, sqrt)
println(result.vector_result)  # Each element transformed by sqrt

"""
function statistics_data(vector::AbstractVector{T}, func::Union{Function, Nothing}=nothing) where T<:Real
# Get vector length
n_elements = length(vector)
# Initialize statistical variables
sum_val = zero(Float64)
min_val = Float64(vector[1])
max_val = Float64(vector[1])
coord_min_idx = 1
coord_max_idx = 1

# Vector to store transformed values
vector_result = similar(vector, Float64, size(vector))

# Axis limits
x_min = n_elements
x_max = 1

#epsilon = 1e-10  # Small value to avoid log10(0)

# Iterate through all elements
for i in 1:n_elements
    # Convert element to Float64 if necessary
    element = vector[i]
    if !(element isa Float64)
        element = Float64(element)
    end

    # Update sum
    sum_val += element

    # Update minimum
    if element < min_val
        min_val = element
        coord_min_idx = i
    end

    # Update maximum
    if element > max_val
        max_val = element
        coord_max_idx = i
    end

    # Update axis limits
    x_min = min(x_min, i)
    x_max = max(x_max, i)

    # Apply transformation if function is provided
    if func !== nothing
        if func === log10
            # Special handling for log10
            if element < 0
                vector_result[i] = sign(element) * func(max(abs(element), AstroTLPlot.EPSILON))
            elseif element == 0
                vector_result[i] = 0.0  # Avoid -Inf
            else
                vector_result[i] = func(max(element, AstroTLPlot.EPSILON))
            end
        else
            # Generic function handling
            if element < 0
                vector_result[i] = sign(element) * func(abs(element))
            else
                vector_result[i] = func(element)
            end
        end
    else
        # If no function, copy original element
        vector_result[i] = element
    end
end

    # Compute mean
    mean_val = sum_val / n_elements

    # Compute variance and standard deviation
    variance_val = variance_loops(vector, mean_val, n_elements)
    std_val = sqrt(variance_val)

    # Build result structures
    coord_min = Coordinate1DResult{T}(coord_min_idx, min_val)
    coord_max = Coordinate1DResult{T}(coord_max_idx, max_val)
    axis_limits = Axis1DLimits(x_min, x_max)
    range_struct = MinMaxRange(min_val, max_val)

    stats_struct = StatisticsData1D{T}(
        sum_val, mean_val, variance_val, std_val,
        coord_min, coord_max,
        range_struct, n_elements,
        axis_limits
    )

    return Vector1DStatistics{T}(stats_struct, vector_result)

end

#*****************************************
#  statistics_data
#*****************************************

"""
    statistics_data(vector::AbstractVector{T}, wmin::Int, wmax::Int,
                                func::Union{Function, Nothing}=nothing) where T<:Real

Compute statistical data for a specified window in a 1D vector and optionally apply a transformation function
to each element within the window.

# Arguments
- `vector::AbstractVector{T}`: Input vector of real numbers.
- `wmin::Int, wmax::Int`: Start and end indices of the window.
- `func::Union{Function, Nothing}`: Optional function to apply to each element. If `nothing`, no transformation is applied.

# Returns
- `Vector1DStatistics`: A structure containing:
    - Sum, mean, variance, standard deviation
    - Minimum and maximum values with indices
    - Axis limits and range
    - Transformed vector

# Notes
- If `func === log10`, negative values are transformed as `sign(element) * log10(abs(element))`.
- Zero values are replaced with `0.0` to avoid `-Inf`.
- For other functions, negative values are transformed using `sign(element) * func(abs(element))`.

# Examples
```julia
# Example 1: Compute statistics without transformation
vec = [1, 2, 3, 4, 5]
result = statistics_data(vec, 2, 4)
println(result.statistics_data.mean)  # Output: 3.0

# Example 2: Apply log10 transformation
vec2 = [-10, 0, 10, -100, 50]
result_log = statistics_data(vec2, 1, 5, log10)
println(result_log.vector_result)  # Transformed values in the window

# Example 3: Apply sqrt transformation
vec3 = [1, 4, 9, 16, 25]
result_sqrt = statistics_data(vec3, 1, 3, sqrt)
println(result_sqrt.vector_result)  # Each element transformed by sqrt

"""
function statistics_data(vector::AbstractVector{T}, wmin::Int, wmax::Int,
func::Union{Function, Nothing}=nothing) where T<:Real
# Initialize statistical variables
sum_val = zero(Float64)
min_val = Float64(vector[wmin])
max_val = Float64(vector[wmin])
coord_min_idx = wmin
coord_max_idx = wmin
n_elements = 0
mean_val::Float64 = 0.0
std_val::Float64 = 0.0

# Window analysis limits
n_total_elements = length(vector)
x_min = min(wmin, n_total_elements)
x_max = max(wmax, 1)

# Vector to store transformed values
vector_result = similar(vector, Float64, length(vector))
# epsilon = 1e-10  # Small value to avoid log10(0)

# Iterate through the window
for i in wmin:wmax
    # Convert element to Float64 if necessary
    element = vector[i]
    if !(element isa Float64)
        element = Float64(element)
    end

    # Update sum and count
    sum_val += element
    n_elements += 1

    # Update minimum
    if element < min_val
        min_val = element
        coord_min_idx = i
    end

    # Update maximum
    if element > max_val
        max_val = element
        coord_max_idx = i
    end

    # Apply transformation if function is provided
    if func !== nothing
        if func === log10
            # Special handling for log10
            if element < 0
                vector_result[i] = sign(element) * func(max(abs(element), AstroTLPlot.EPSILON))
            elseif element == 0
                vector_result[i] = 0.0  # Avoid -Inf
            else
                vector_result[i] = func(max(element, AstroTLPlot.EPSILON))
            end
        else
            # Generic function handling
            if element < 0
                vector_result[i] = sign(element) * func(abs(element))
            else
                vector_result[i] = func(element)
            end
        end
     else
        # If no function, copy original element
        vector_result[i] = element
     end
 end

    # Compute mean
    mean_val = sum_val / n_elements

    # Compute variance and standard deviation
    var_val = variance_loops(vector, mean_val, n_elements, wmin, wmax)
    std_val = sqrt(var_val)

    # Build result structures
    coordinate_min = Coordinate1DResult(coord_min_idx, min_val)
    coordinate_max = Coordinate1DResult(coord_max_idx, max_val)
    axis_limits = Axis1DLimits(x_min, x_max)
    min_max_range = MinMaxRange(min_val, max_val)

    statistics_data = StatisticsData1D(
        sum_val, mean_val, var_val, std_val,
        coordinate_min, coordinate_max,
        min_max_range, n_elements, axis_limits
    )

  return Vector1DStatistics(statistics_data, vector_result)
end

#*****************************************
#  variance_loops2D
#*****************************************


"""
    variance_loops(matrix::AbstractMatrix{T}, mean_val::Real, n_elements::Int,
                      n_rows::Int, n_columns::Int) where T<:Real

Compute the sample variance for a 2D matrix using a loop-based approach.

# Arguments
- `matrix::AbstractMatrix{T}`: Input matrix of real numbers.
- `mean_val::Real`: Precomputed mean of the matrix.
- `n_elements::Int`: Total number of elements in the matrix.
- `n_rows::Int, n_columns::Int`: Dimensions of the matrix.

# Returns
- `Float64`: The sample variance of the matrix.
"""
function variance_loops(matrix::AbstractMatrix{T}, mean_val::Real, n_elements::Int,
                          n_rows::Int, n_columns::Int) where T<:Real
    # Initialize variance accumulator
    var_val = 0.0

    # Iterate through all elements and accumulate squared differences
    for i in 1:n_rows
        for j in 1:n_columns
            var_val += (matrix[i, j] - mean_val)^2
        end
    end

    # Return sample variance (n-1 denominator for unbiased estimate)
    return var_val / (n_elements - 1)
end

#*****************************************
#  variance_loops_windowed2D
#*****************************************

"""
    variance_loops(matriz::AbstractMatrix{T}, mean_val::Float64, n_elements::Int,
                               xwmin::Int, xwmax::Int, ywmin::Int, ywmax::Int) where T<:Real

Compute the sample variance for a specified 2D window in a matrix using a loop-based approach.

# Arguments
- `matriz::AbstractMatrix{T}`: Input matrix of real numbers.
- `mean_val::Float64`: Precomputed mean of the window.
- `n_elements::Int`: Number of elements in the window.
- `xwmin::Int, xwmax::Int`: Column range for the window.
- `ywmin::Int, ywmax::Int`: Row range for the window.

# Returns
- `Float64`: The sample variance of the specified window.
"""
function variance_loops(matriz::AbstractMatrix{T}, mean_val::Float64, n_elements::Int,
                                   xwmin::Int, xwmax::Int, ywmin::Int, ywmax::Int) where T<:Real
    # Initialize variance accumulator
    var = 0.0

    # Iterate through the specified window and accumulate squared differences
    for i in ywmin:ywmax
        for j in xwmin:xwmax
            var += (matriz[i, j] - mean_val)^2
        end
    end

    # Return sample variance (n-1 denominator for unbiased estimate)
    return var / (n_elements - 1)
end

#*****************************************
#  statistics_data2D
#*****************************************

"""
    statistics_data(matriz::AbstractMatrix{T}, func::Union{Function, Nothing}=nothing) where T<:Real

Compute statistical data for an entire 2D matrix and optionally apply a transformation function
to each element.

# Arguments
- `matriz::AbstractMatrix{T}`: Input matrix of real numbers.
- `func::Union{Function, Nothing}`: Optional function to apply to each element. If `nothing`, no transformation is applied.

# Returns
- `Matrix2DStatistics`: A structure containing:
    - Sum, mean, variance, standard deviation
    - Minimum and maximum values with coordinates
    - Axis limits and range
    - Transformed matrix

# Notes
- If `func === log10`, negative values are transformed as `sign(element) * log10(abs(element))`.
- Zero values are replaced with `0.0` to avoid `-Inf`.
- For other functions, negative values are transformed using `sign(element) * func(abs(element))`.

# Examples
```julia
# Example 1: Compute statistics without transformation
mat = [1 2 3; 4 5 6; 7 8 9]
result = statistics_data2D(mat)
println(result.statistics_data.mean)  # Output: 5.0

# Example 2: Apply log10 transformation
mat = [-10 0 10; -100 50 100; -1 2 3]
result = statistics_data(mat, log10)
println(result.matrix_result)  # Transformed matrix with log10 applied

# Example 3: Apply sqrt transformation
mat = [1 4 9; 16 25 36; 49 64 81]
result = statistics_data(mat, sqrt)
println(result.matrix_result)  # Each element transformed by sqrt

"""

function statistics_data(matriz::AbstractMatrix{T}, func::Union{Function, Nothing}=nothing) where T<:Real
# Get matrix dimensions and element count
n_rows, n_columns = size(matriz)
n_elements = n_rows * n_columns
# Initialize statistical variables
sum_val = zero(Float64)
min_val = Float64(matriz[1, 1])
max_val = Float64(matriz[1, 1])
coord_minx = coord_miny = 1
coord_maxx = coord_maxy = 1

# Matrix to store transformed values
matrix_result = similar(matriz, Float64, size(matriz))

# Axis limits
x_min = n_columns
x_max = 1
y_min = n_rows
y_max = 1

# epsilon = 1e-10  # Small value to avoid log10(0)

# Iterate through all elements
for i in 1:n_rows
    for j in 1:n_columns
        # Convert element to Float64 if necessary
        element = matriz[i, j]
        if !(element isa Float64)
            element = Float64(element)
        end

        # Update sum
        sum_val += element

        # Update minimum
        if element < min_val
            min_val = element
            coord_minx, coord_miny = j, i
        end

        # Update maximum
        if element > max_val
            max_val = element
            coord_maxx, coord_maxy = j, i
        end

        # Update axis limits
        x_min = min(x_min, j)
        x_max = max(x_max, j)
        y_min = min(y_min, i)
        y_max = max(y_max, i)

        # Apply transformation if function is provided
        if func !== nothing
            if func === log10
                # Special handling for log10
                if element < 0
                    matrix_result[i, j] = sign(element) * func(abs(element)) # matrix_result[i, j] = sign(element) * func(max(abs(element), AstroTLPlot.EPSILON))

                elseif element == 0
                    matrix_result[i, j] = 0.0  # Avoid -Inf
                else
                    matrix_result[i, j] = func(element) # matrix_result[i, j] = func(max(element, AstroTLPlot.EPSILON))
                end
            else
                # Generic function handling
                if element < 0
                    matrix_result[i, j] = sign(element) * func(abs(element))
                else
                    matrix_result[i, j] = func(element)
                end
            end
        else
            # If no function, copy original element
            matrix_result[i, j] = element
        end
    end
end

# Compute mean
mean_val = sum_val / n_elements

    # Compute variance and standard deviation
    variance_val = variance_loops(matriz, mean_val, n_elements, n_rows, n_columns)
    std_val = sqrt(variance_val)

    # Build result structures
    coord_min = Coordinate2DResult{T}(Point2D(coord_minx, coord_miny), min_val)
    coord_max = Coordinate2DResult{T}(Point2D(coord_maxx, coord_maxy), max_val)
    axis_limits = Axis2DLimits(Point2D(x_min, y_min), Point2D(x_max, y_max))
    range_struct = MinMaxRange(min_val, max_val)

    stats_struct = StatisticsData2D{T}(
        sum_val, mean_val, variance_val, std_val,
        coord_min, coord_max,
        range_struct, n_elements, n_rows, n_columns,
        axis_limits
    )

    return Matrix2DStatistics{T}(stats_struct, matrix_result)

end

#*****************************************
#  statistics_data_windowed2D
#*****************************************

"""
    statistics_data(matriz::AbstractMatrix{T}, xwmin::Int, xwmax::Int,
                                ywmin::Int, ywmax::Int, func::Union{Function, Nothing}=nothing) where T<:Real

Compute statistical data for a specified 2D window in a matrix and optionally apply a transformation function
to each element within the window.

# Arguments
- `matriz::AbstractMatrix{T}`: Input matrix of real numbers.
- `xwmin::Int, xwmax::Int`: Column range for the window.
- `ywmin::Int, ywmax::Int`: Row range for the window.
- `func::Union{Function, Nothing}`: Optional function to apply to each element. If `nothing`, no transformation is applied.

# Returns
- `Matrix2DStatistics`: A structure containing:
    - Sum, mean, variance, standard deviation
    - Minimum and maximum values with coordinates
    - Axis limits and range
    - Transformed matrix

# Notes
- If `func === log10`, negative values are transformed as `sign(element) * log10(abs(element))`.
- Zero values are replaced with `0.0` to avoid `-Inf`.
- For other functions, negative values are transformed using `sign(element) * func(abs(element))`.

# Examples
```julia
# Example 1: Compute statistics without transformation
mat = [1 2 3; 4 5 6; 7 8 9]
result = statistics_data(mat, 1, 3, 1, 3)
println(result.statistics_data.mean)  # Output: 5.0

# Example 2: Apply log10 transformation
mat = [-10 0 10; -100 50 100; -1 2 3]
result = statistics_data(mat, 1, 3, 1, 3, log10)
println(result.matrix_result)  # Transformed matrix with log10 applied

# Example 3: Apply sqrt transformation
mat = [1 4 9; 16 25 36; 49 64 81]
result = statistics_data(mat, 1, 3, 1, 3, sqrt)
println(result.matrix_result)  # Each element transformed by sqrt

"""

function statistics_data(
        matriz::AbstractMatrix{T},
        xwmin::Int, xwmax::Int,
        ywmin::Int, ywmax::Int,
        func::Union{Function, Nothing} = nothing
    ) where T<:Real
# Initialize statistical variables
sum_val = zero(Float64)
min_val = Float64(matriz[ywmin, xwmin])
max_val = Float64(matriz[ywmin, xwmin])
coord_minx, coord_miny = xwmin, ywmin
coord_maxx, coord_maxy = xwmin, ywmin

n_elements = 0
mean_val::Float64 = 0.0
std_val::Float64 = 0.0

# Window limits
n_rows, n_columns = size(matriz)
x_min = min(xwmin, n_columns)
x_max = max(xwmax, 1)
y_min = min(ywmin, n_rows)
y_max = max(ywmax, 1)

# Matrix to store transformed values
matrix_result = similar(matriz, Float64, size(matriz))
# epsilon = 1e-10  # Small value to avoid log10(0)

# Iterate through the window
for i in ywmin:ywmax
    for j in xwmin:xwmax
        # Convert element to Float64 if necessary
        element = matriz[i, j]
        if !(element isa Float64)
            element = Float64(element)
        end

        # Update sum and element count
        sum_val += element
        n_elements += 1

        # Update minimum value and coordinates
        if element < min_val
            min_val = element
            coord_minx, coord_miny = j, i
        end

        # Update maximum value and coordinates
        if element > max_val
            max_val = element
            coord_maxx, coord_maxy = j, i
        end

        # Apply transformation if function is provided
        if func !== nothing
            if func === log10
                # Special handling for log10
                if element < 0
                    matrix_result[i, j] = sign(element) * func(max(abs(element), AstroTLPlot.EPSILON))
                elseif element == 0
                    matrix_result[i, j] = 0.0  # Avoid -Inf
                else
                    matrix_result[i, j] = func(max(element, AstroTLPlot.EPSILON))
                end
            else
                # Generic function handling
                if element < 0
                    matrix_result[i, j] = sign(element) * func(abs(element))
                else
                    matrix_result[i, j] = func(element)
                end
            end
        else
            # If no function, copy original element
            matrix_result[i, j] = element
        end
    end
end

    # Compute mean
    mean_val = sum_val / n_elements

    # Compute variance and standard deviation
    var_val = variance_loops(matriz, mean_val, n_elements, xwmin, xwmax, ywmin, ywmax)
    std_val = sqrt(var_val)

    # Build result structures
    coordinate_min = Coordinate2DResult(Point2D(coord_minx, coord_miny), min_val)
    coordinate_max = Coordinate2DResult(Point2D(coord_maxx, coord_maxy), max_val)
    axis_limits = Axis2DLimits(Point2D(x_min, y_min), Point2D(x_max, y_max))
    min_max_range = MinMaxRange(min_val, max_val)

    statistics_data = StatisticsData2D(sum_val, mean_val, var_val, std_val,
                                    coordinate_min, coordinate_max,
                                    min_max_range, n_elements, n_rows, n_columns, axis_limits)

    return Matrix2DStatistics(statistics_data, matrix_result)

end


#*****************************************
#  variance_loops_3D
#*****************************************

"""
    variance_loops(array::AbstractArray{T,3}, mean_val::T, n_elements::Int,
                       n_rows::Int, n_columns::Int, n_slices::Int) where T<:Real

Compute the sample variance for a 3D array using a loop-based approach.

# Arguments
- `array::AbstractArray{T,3}`: Input 3D array of real numbers.
- `mean_val::T`: Precomputed mean of the array.
- `n_elements::Int`: Total number of elements in the array.
- `n_rows::Int, n_columns::Int, n_slices::Int`: Dimensions of the array.

# Returns
- `Float64`: The sample variance of the 3D array.
"""
function variance_loops(array::AbstractArray{T,3}, mean_val::T, n_elements::Int,
                            n_rows::Int, n_columns::Int, n_slices::Int) where T<:Real
    # Initialize variance accumulator
    variance_val = zero(T)

    # Iterate through all elements and accumulate squared differences
    for k in 1:n_slices
        for i in 1:n_rows
            for j in 1:n_columns
                diff = array[i, j, k] - mean_val
                variance_val += diff * diff
            end
        end
    end

    # Return sample variance (n-1 denominator for unbiased estimate)
    return variance_val / (n_elements - 1)
end

#*****************************************
#  variance_loops_windowed3D(
#*****************************************

"""
    variance_loops(matriz::Array{T,3}, mean_val::Float64, n_elements::Int,
                               zmin::Int, zmax::Int, ymin::Int, ymax::Int,
                               xmin::Int, xmax::Int) where T<:Real

Compute the sample variance for a specified 3D window in an array using a loop-based approach.

# Arguments
- `matriz::Array{T,3}`: Input 3D array of real numbers.
- `mean_val::Float64`: Precomputed mean of the window.
- `n_elements::Int`: Number of elements in the window.
- `zmin::Int, zmax::Int`: Slice range for the window.
- `ymin::Int, ymax::Int`: Row range for the window.
- `xmin::Int, xmax::Int`: Column range for the window.

# Returns
- `Float64`: The sample variance of the specified window.
"""
function variance_loops(
    matriz::Array{T,3},
    mean_val::Float64,
    n_elements::Int,
    zmin::Int, zmax::Int,
    ymin::Int, ymax::Int,
    xmin::Int, xmax::Int
) where T<:Real
    # Handle edge case: variance undefined for 1 or fewer elements
    if n_elements <= 1
        return zero(Float64)
    end

    # Initialize variance accumulator
    var_val = 0.0

    # Iterate through the specified 3D window and accumulate squared differences
    for k in zmin:zmax
        for i in ymin:ymax
            for j in xmin:xmax
                var_val += (matriz[i, j, k] - mean_val)^2
            end
        end
    end

    # Return sample variance (n-1 denominator for unbiased estimate)
    return var_val / (n_elements - 1)
end

#*****************************************
#  statistics_data3D(array3D
#*****************************************


"""
    statistics_data(array3D::AbstractArray{T, 3}, func::Union{Function, Nothing}=nothing) where T<:Real

Compute statistical data for a 3D array and optionally apply a transformation function to each element.

# Arguments
- `array3D::AbstractArray{T, 3}`: Input 3D array of real numbers.
- `func::Union{Function, Nothing}`: Optional function to apply to each element. If `nothing`, no transformation is applied.

# Returns
- `Matrix3DStatistics`: A structure containing:
    - Sum, mean, variance, standard deviation
    - Minimum and maximum values with coordinates
    - Axis limits and range
    - Transformed 3D array

# Notes
- If `func === log10`, negative values are transformed as `sign(element) * log10(abs(element))`.
- Zero values are replaced with `0.0` to avoid `-Inf`.
- For other functions, negative values are transformed using `sign(element) * func(abs(element))`.

# Examples
```julia
# Example 1: Compute statistics without transformation
arr = reshape(1:27, (3, 3, 3))
result = statistics_data(arr)
println(result.statistics_data.mean)  # Output: 14.0

# Example 2: Apply log10 transformation
arr = [-10 0 10; -100 50 100; -1 2 3]
arr3D = reshape(arr, (3, 3, 1))
result = statistics_data(arr3D, log10)
println(result.matrix_result)  # Transformed 3D array with log10 applied

# Example 3: Apply sqrt transformation
arr3D = reshape([1, 4, 9, 16, 25, 36, 49, 64, 81], (3, 3, 1))
result = statistics_data(arr3D, sqrt)
println(result.matrix_result)  # Each element transformed by sqrt

"""

function statistics_data(array3D::AbstractArray{T, 3}, func::Union{Function, Nothing}=nothing) where T<:Real
# Get dimensions and element count
n_rows, n_columns, n_slices = size(array3D)
n_elements = n_rows * n_columns * n_slices
# Initialize statistical variables
sum_val = zero(Float64)
min_val = Float64(array3D[1, 1, 1])
max_val = Float64(array3D[1, 1, 1])
coord_min = (1, 1, 1)
coord_max = (1, 1, 1)

# Axis limits
x_min, x_max = n_columns, 1
y_min, y_max = n_rows, 1
z_min, z_max = n_slices, 1

# Matrix to store transformed values
matrix_result = similar(array3D, Float64, size(array3D))
# epsilon = 1e-10  # Small value to avoid log10(0)

# Iterate through all elements
for i in 1:n_rows, j in 1:n_columns, k in 1:n_slices
    # Convert element to Float64 if necessary
    val = array3D[i, j, k]
    if !(val isa Float64)
        val = Float64(val)
    end

    # Update sum
    sum_val += val

    # Update min and max
    if val < min_val
        min_val = val
        coord_min = (i, j, k)
    end
    if val > max_val
        max_val = val
        coord_max = (i, j, k)
    end

    # Update axis limits
    x_min = min(x_min, j)
    x_max = max(x_max, j)
    y_min = min(y_min, i)
    y_max = max(y_max, i)
    z_min = min(z_min, k)
    z_max = max(z_max, k)

    # Apply transformation if function is provided
    if func !== nothing
        if func === log10
            # Special handling for log10
            if val < 0
                matrix_result[i, j, k] = sign(val) * func(max(abs(val), AstroTLPlot.EPSILON))
            elseif val == 0
                matrix_result[i, j, k] = 0.0  # Avoid -Inf
            else
                matrix_result[i, j, k] = func(max(val, AstroTLPlot.EPSILON))
            end
        else
            # Generic function handling
            if val < 0
                matrix_result[i, j, k] = sign(val) * func(abs(val))
            else
                matrix_result[i, j, k] = func(val)
            end
        end
    else
        # If no function, copy original element
        matrix_result[i, j, k] = val
    end
end

# Compute mean
mean_val = sum_val / n_elements

# Compute variance and standard deviation
var_val = variance_loops(array3D, mean_val, n_elements, n_rows, n_columns, n_slices)
std_dev = sqrt(var_val)

# Build result structures
min_result = Coordinate3DResult{T}(Point3D{Int}(coord_min...), min_val)
max_result = Coordinate3DResult{T}(Point3D{Int}(coord_max...), max_val)
axis_limits = Axis3DLimits(Point3D{Int}(y_min, x_min, z_min), Point3D{Int}(y_max, x_max, z_max))
range = MinMaxRange{T}(min_val, max_val)

stats = StatisticsData3D{T}(
    sum_val, mean_val, var_val, std_dev,
    min_result, max_result,
    range, n_elements, n_rows, n_columns, n_slices,
    axis_limits
)

return Matrix3DStatistics{T}(stats, matrix_result)

end

#*****************************************
#  statistics_data_windowed3D
#*****************************************

"""
    statistics_data(matriz::AbstractArray{T,3}, xwmin::Int, xwmax::Int,
                                ywmin::Int, ywmax::Int, zwmin::Int, zwmax::Int,
                                func::Union{Function, Nothing}=nothing) where T<:Real

Compute statistical data for a specified 3D window in an array and optionally apply a transformation function
to each element within the window.

# Arguments
- `matriz::AbstractArray{T,3}`: Input 3D array of real numbers.
- `xwmin::Int, xwmax::Int`: Column range for the window.
- `ywmin::Int, ywmax::Int`: Row range for the window.
- `zwmin::Int, zwmax::Int`: Slice range for the window.
- `func::Union{Function, Nothing}`: Optional function to apply to each element. If `nothing`, no transformation is applied.

# Returns
- `Matrix3DStatistics`: A structure containing:
    - Sum, mean, variance, standard deviation
    - Minimum and maximum values with coordinates
    - Axis limits and range
    - Transformed 3D array

# Notes
- If `func === log10`, negative values are transformed as `sign(element) * log10(abs(element))`.
- Zero values are replaced with `0.0` to avoid `-Inf`.
- For other functions, negative values are transformed using `sign(element) * func(abs(element))`.

# Examples
```julia
# Example 1: Compute statistics without transformation
arr3D = reshape(1:27, (3, 3, 3))
result = statistics_data(arr3D, 1, 3, 1, 3, 1, 3)
println(result.statistics_data.mean)  # Output: 14.0

# Example 2: Apply log10 transformation
arr3D_log = reshape([-10, 0, 10, -100, 50, 100, -1, 2, 3], (3, 3, 1))
result_log = statistics_data(arr3D_log, 1, 3, 1, 3, 1, 1, log10)
println(result_log.matrix_result)  # Transformed 3D array with log10 applied

# Example 3: Apply sqrt transformation
arr3D_sqrt = reshape([1, 4, 9, 16, 25, 36, 49, 64, 81], (3, 3, 1))
result_sqrt = statistics_data(arr3D_sqrt, 1, 3, 1, 3, 1, 1, sqrt)
println(result_sqrt.matrix_result)  # Each element transformed by sqrt

"""

function statistics_data(matriz::AbstractArray{T,3}, xwmin::Int, xwmax::Int,
ywmin::Int, ywmax::Int, zwmin::Int, zwmax::Int,
func::Union{Function, Nothing}=nothing) where T<:Real

# Initialize statistical variables
sum_val = zero(Float64)
min_val = Float64(matriz[ywmin, xwmin, zwmin])
max_val = Float64(matriz[ywmin, xwmin, zwmin])
coord_minx, coord_miny, coord_minz = xwmin, ywmin, zwmin
coord_maxx, coord_maxy, coord_maxz = xwmax, ywmax, zwmax
n_elements = 0
mean_val::Float64 = 0.0
std_val::Float64 = 0.0

# Window analysis limits
n_rows, n_columns, n_slices = size(matriz)
x_min = min(xwmin, n_columns)
x_max = max(xwmax, 1)
y_min = min(ywmin, n_rows)
y_max = max(ywmax, 1)
z_min = min(zwmin, n_slices)
z_max = max(zwmax, 1)

# Array to store transformed values
matrix_result = similar(matriz, Float64, size(matriz))
# epsilon = 1e-10  # Small value to avoid log10(0)

# Iterate through the window
for k in zwmin:zwmax
    for i in ywmin:ywmax
        for j in xwmin:xwmax
            # Convert element to Float64 if necessary
            element = matriz[i, j, k]
            if !(element isa Float64)
                element = Float64(element)
            end

            # Update sum and count
            sum_val += element
            n_elements += 1

            # Update minimum
            if element < min_val
                min_val = element
                coord_minx, coord_miny, coord_minz = j, i, k
            end

            # Update maximum
            if element > max_val
                max_val = element
                coord_maxx, coord_maxy, coord_maxz = j, i, k
            end

            # Apply transformation if function is provided
            if func !== nothing
                if func === log10
                    # Special handling for log10
                    if element < 0
                        matrix_result[i, j, k] = sign(element) * func(max(abs(element), AstroTLPlot.EPSILON))
                    elseif element == 0
                        matrix_result[i, j, k] = 0.0  # Avoid -Inf
                    else
                        matrix_result[i, j, k] = func(max(element, AstroTLPlot.EPSILON))
                    end
                else
                    # Generic function handling
                    if element < 0
                        matrix_result[i, j, k] = sign(element) * func(abs(element))
                    else
                        matrix_result[i, j, k] = func(element)
                    end
                end
            else
                # If no function, copy original element
                matrix_result[i, j, k] = element
            end
        end
    end
end

    # Compute mean
    mean_val = sum_val / n_elements

    # Compute variance and standard deviation
    var_val = variance_loops(matriz, mean_val, n_elements, ywmin, ywmax, xwmin, xwmax, zwmin, zwmax)
    std_val = sqrt(var_val)

    # Build result structures
    coordinate_min = Coordinate3DResult(Point3D(coord_minx, coord_miny, coord_minz), min_val)
    coordinate_max = Coordinate3DResult(Point3D(coord_maxx, coord_maxy, coord_maxz), max_val)
    axis_limits = Axis3DLimits(Point3D(x_min, y_min, z_min), Point3D(x_max, y_max, z_max))
    min_max_range = MinMaxRange(min_val, max_val)

    statistics_data = StatisticsData3D(sum_val, mean_val, var_val, std_val,
                                    coordinate_min, coordinate_max,
                                    min_max_range, n_elements, n_rows, n_columns, n_slices, axis_limits)

    return Matrix3DStatistics(statistics_data, matrix_result)

end

#*****************************************
#  statistics_dic1D
#*****************************************

# 1D dictionary
function statistics_dic(vector::AbstractVector{T}, func::Union{Function, Nothing} = nothing) where T<:Real
    n_elements = length(vector)

    sum_val = zero(T)
    min_val = vector[1]
    max_val = vector[1]
    coord_min_idx = 1
    coord_max_idx = 1

    vector_result = similar(vector)

    x_min = n_elements
    x_max = 1
    
   # epsilon = 1e-10  # Small value to avoid log10(0)
    
    for i in 1:n_elements
        element = vector[i]
          # Convert element to Float64 if necessary
    element = vector[i]
    if !(element isa Float64)
        element = Float64(element)
    end

        sum_val += element

        if element < min_val
            min_val = element
            coord_min_idx = i
        end

        if element > max_val
            max_val = element
            coord_max_idx = i
        end

        x_min = min(x_min, i)
        x_max = max(x_max, i)
        
       # vector_result[i] = func !== nothing ? sign(element) * func(abs(element)) : element
       
         # Apply transformation if function is provided
            if func !== nothing
                if func === log10
                    # Special handling for log10
                    if element < 0
                        vector_result[i] = sign(element) * func(max(abs(element), AstroTLPlot.EPSILON))
                    elseif element == 0
                        vector_result[i] = 0.0  # Avoid -Inf
                    else
                        vector_result[i] = func(max(element, AstroTLPlot.EPSILON))
                    end
                else
                    # Generic function handling
                    if element < 0
                        vector_result[i] = sign(element) * func(abs(element))
                    else
                        vector_result[i] = func(element)
                    end
                end
            else
                # If no function, copy original element
                vector_result[i] = element
            end
    end
    mean_val = sum_val / n_elements
    # Compute variance and standard deviation
    variance_val = variance_loops(vetor, mean_val,n_elements)
    variance_val /= n_elements
    std_val = sqrt(variance_val)
  
    # Statistics
    statistics = Dict(
        "sum" => sum_val,
        "minimum" => min_val,
        "maximum" => max_val,
        "mean" => mean_val,
        "variance" => variance_val,
        "std_deviation" => std_val,
        "range" => max_val - min_val,
        "n_elements" => n_elements,
        "x_min" => x_min,
        "x_max" => x_max,
        "index_min" => coord_min_idx,
        "index_max" => coord_max_idx
    )
    # Vector results
    vector_results = Dict(
        "vector_result" => vector_result
    )
    
    return Dict(
        "statistics" => statistics,
        "vector_results" => vector_results
    )
end

#*****************************************
#  2D dictionary
#*****************************************

function statistics_dic(matriz::AbstractMatrix{T}, func::Union{Function, Nothing} = nothing) where T<:Real
    n_rows, n_columns = size(matriz)
    n_elements = n_rows * n_columns

    sum_val = zero(T)
    min_val = matriz[1,1]
    max_val = matriz[1,1]
    coord_minx = coord_miny = 1
    coord_maxx = coord_maxy = 1

    # Matrix to store transformed values
    matrix_result = similar(matriz, Float64, size(matriz))
    
    # epsilon = 1e-10  # Small value to avoid log10(0)
    
    # Axis limits
    x_min = n_columns
    x_max = 1
    y_min = n_rows
    y_max = 1

    for i in 1:n_rows
        for j in 1:n_columns
            element = matriz[i, j]
            
            if !(element isa Float64)
                element = Float64(element)
            end

            sum_val += element

            if element < min_val
                min_val = element
                coord_minx = j
                coord_miny = i
            end

            if element > max_val
                max_val = element
                coord_maxx = j
                coord_maxy = i
            end

            x_min = min(x_min, j)
            x_max = max(x_max, j)
            y_min = min(y_min, i)
            y_max = max(y_max, i)

           # matrix_result[i, j] = func !== nothing ? sign(element) * func(abs(element)) : element
          # Apply transformation if function is provided
        if func !== nothing
            if func === log10
                # Special handling for log10
                if element < 0
                    matrix_result[i, j] = sign(element) * func(max(abs(element), AstroTLPlot.EPSILON))
                elseif element == 0
                    matrix_result[i, j] = 0.0  # Avoid -Inf
                else
                    matrix_result[i, j] = func(max(element, AstroTLPlot.EPSILON))
                end
            else
                # Generic function handling
                if element < 0
                    matrix_result[i, j] = sign(element) * func(abs(element))
                else
                    matrix_result[i, j] = func(element)
                end
            end
        else
            # If no function, copy original element
            matrix_result[i, j] = element
        end
    end
 end

    mean_val = sum_val / n_elements
    
   # Calcular variância e desvio padrão
   # var_val = variance_loops(matriz, mean_val, n_elements, n_rows, n_columns, n_depth)
    var_val = variance_loops(matriz, mean_val, n_elements, n_rows, n_columns)
    std_val = sqrt(var_val)
    
    #=
    variance_val = sum((matriz[i, j] - mean_val)^2 for i in 1:n_rows, j in 1:n_columns) / n_elements
    std_val = sqrt(variance_val)
    =#

      # Statistics
    statistics = Dict(
        "sum" => sum_val,
        "minimum" => min_val,
        "maximum" => max_val,
        "mean" => mean_val,
        "variance" => var_val,
        "std_deviation" => std_val,
        "range" => max_val - min_val,
        "n_elements" => n_elements,
        "x_min" => x_min,
        "x_max" => x_max,
        "y_min" => y_min,
        "y_max" => y_max,
        "indexx_min" => coord_minx,
        "indexy_min" => coord_miny,
        "indexx_max" => coord_maxx,
        "indexy_max" => coord_maxy,
    )

    # Matrix results
    matrix_results = Dict(
        "matrix_result" => matrix_result
    )
    
    return Dict(
        "statistics" => statistics,
        "matrix_results" => matrix_results
    )
end

#******************************************************************
#  Function to calculate statistics but restricted to a specific window 
#******************************************************************

"""
    statistics_data_dic(matriz::AbstractMatrix{T}, xwmin::Int, xwmax::Int, ywmin::Int, ywmax::Int, func::Union{Function, Nothing}=nothing) where T<:Real

This function calculates various statistical properties of the elements in a matrix, but restricted to a specific window defined by the coordinates (`xwmin`, `xwmax`, `ywmin`, `ywmax`). It also optionally applies a transformation function to each element of the matrix within the window.

### Arguments
- `matriz::AbstractMatrix{T}`: A matrix of real numbers on which the statistics are calculated.
- `xwmin::Int`: The minimum x-coordinate of the window.
- `xwmax::Int`: The maximum x-coordinate of the window.
- `ywmin::Int`: The minimum y-coordinate of the window.
- `ywmax::Int`: The maximum y-coordinate of the window.
- `func::Union{Function, Nothing}`: A function to apply to each element in the matrix. If `nothing`, the elements remain unchanged. Defaults to `nothing`.

### Returns
A `Dict` with the following keys:
- `"statistics"`: A dictionary with the following statistical values calculated over the window:
    - `"sum"`: The sum of all elements within the window.
    - `"minimum"`: The minimum value found within the window.
    - `"maximum"`: The maximum value found within the window.
    - `"mean"`: The mean (average) of the values within the window.
    - `"variance"`: The variance of the values within the window.
    - `"std_deviation"`: The standard deviation of the values within the window.
    - `"range"`: The range of the values (max - min) within the window.
    - `"n_elements"`: The number of elements within the window.
    - `"x_min"`, `"x_max"`, `"y_min"`, `"y_max"`: The coordinates defining the boundaries of the window.
    - `"indexx_min"`, `"indexy_min"`: The coordinates of the minimum value in the window.
    - `"indexx_max"`, `"indexy_max"`: The coordinates of the maximum value in the window.
    
- `"matrix_results"`: A dictionary containing the modified matrix results:
    - `"matrix_result"`: The matrix with the function `func` applied to each element within the window. If `func` is `nothing`, the original matrix values are returned.

### Example
```julia
mat = rand(5, 5)
windowed_stats = statistics_data_dic_super_windowed(mat, 2, 4, 1, 3)

"""
function statistics_dic(matriz::AbstractMatrix{T}, xwmin::Int, xwmax::Int, ywmin::Int, ywmax::Int, func::Union{Function, Nothing} = nothing) where T<:Real
    sum_val = zero(T)
    min_val = matriz[ywmin, xwmin]
    max_val = matriz[ywmin, xwmin]
    coord_minx = xwmin
    coord_miny = ywmin
    coord_maxx = xwmin
    coord_maxy = ywmin

    n_elements = 0
    std_val = 0
    mean_val::Float64 = 0.0

    matrix_result = similar(matriz, T, size(matriz))
    
    # Window analysis limits
    n_rows = size(matriz, 1)
    n_columns = size(matriz, 2)
    
    x_min = min(xwmin, n_columns)
    x_max = max(xwmax, 1)
    y_min = min(ywmin, n_rows)
    y_max = max(ywmax, 1)

    for i in ywmin:ywmax
        for j in xwmin:xwmax
            element = matriz[i, j]
            if !(element isa Float64)
               element = Float64(element)
            end
            sum_val += element
            n_elements += 1
            
            # Update the minimum
            if element < min_val
                min_val = element
                coord_minx = j
                coord_miny = i
            end
            
            # Update the maximum
            if element > max_val
                max_val = element
                coord_maxx = j
                coord_maxy = i
            end
            
       #=     # Apply the function, if provided
            if func !== nothing
                matrix_result[i, j] = func(element)
            else
                matrix_result[i, j] = element
            end =#
            
    # Apply transformation if function is provided
        if func !== nothing
            if func === log10
                # Special handling for log10
                if element < 0
                    matrix_result[i, j] = sign(element) * func(max(abs(element), AstroTLPlot.EPSILON))
                elseif element == 0
                    matrix_result[i, j] = 0.0  # Avoid -Inf
                else
                    matrix_result[i, j] = func(max(element, AstroTLPlot.EPSILON))
                end
            else
                # Generic function handling
                if element < 0
                    matrix_result[i, j] = sign(element) * func(abs(element))
                else
                    matrix_result[i, j] = func(element)
                end
            end
        else
            # If no function, copy original element
            matrix_result[i, j] = element
        end
     end
   end
    
    # Calculate the mean
    mean_val = sum_val / n_elements

    # Calculate the variance and standard deviation
    var_val = variance_loops(matriz, mean_val, n_elements, ywmin, ywmax, xwmin, xwmax)
    # var_val = sum((matriz[ywmin:ywmax, xwmin:xwmax] .- mean_val).^2) / n_elements
    std_val = sqrt(var_val)

    # Statistics
    statistics = Dict(
        "sum" => sum_val,
        "minimum" => min_val,
        "maximum" => max_val,
        "mean" => mean_val,
        "variance" => var_val,
        "std_deviation" => std_val,
        "range" => max_val - min_val,
        "n_elements" => n_elements,
        "x_min" => x_min,
        "x_max" => x_max,
        "y_min" => y_min,
        "y_max" => y_max,
        "indexx_min" => coord_minx,
        "indexy_min" => coord_miny,
        "indexx_max" => coord_maxx,
        "indexy_max" => coord_maxy,
    )

    # Matrix results
    matrix_results = Dict(
        "matrix_result" => matrix_result
    )
    
    return Dict(
        "statistics" => statistics,
        "matrix_results" => matrix_results
    )
end

#*****************************************
#  statistics 3D dic windowed /Dic windowed 3D dic
#*****************************************
"""
    statistics_data_windowed(matriz::Array{T,3}, xwmin::Int, xwmax::Int, ywmin::Int, ywmax::Int, zwmin::Int, zwmax::Int, func::Union{Function, Nothing} = nothing) where T<:Real

Calcula várias propriedades estatísticas dos elementos em um array 3D, restrito a uma janela específica definida pelas coordenadas (`xwmin`, `xwmax`, `ywmin`, `ywmax`, `zwmin`, `zwmax`). Também aplica opcionalmente uma função de transformação a cada elemento do array dentro da janela.

### Argumentos
- `matriz::Array{T,3}`: Um array 3D de números reais sobre o qual as estatísticas são calculadas.
- `xwmin::Int`: A coordenada x mínima da janela.
- `xwmax::Int`: A coordenada x máxima da janela.
- `ywmin::Int`: A coordenada y mínima da janela.
- `ywmax::Int`: A coordenada y máxima da janela.
- `zwmin::Int`: A coordenada z mínima da janela.
- `zwmax::Int`: A coordenada z máxima da janela.
- `func::Union{Function, Nothing}`: Uma função a ser aplicada a cada elemento no array. Se `nothing`, os elementos permanecem inalterados. O padrão é `nothing`.

### Retorna
Um `Dict` contendo os resultados dos cálculos estatísticos e o array transformado.
"""
function statistics_dic(matriz::AbstractArray{T,3}, xwmin::Int, xwmax::Int, ywmin::Int, ywmax::Int, zwmin::Int, zwmax::Int, func::Union{Function, Nothing} = nothing) where T<:Real
       
        # Initialize statistical variables
    sum_val = zero(Float64)
    min_val = Float64(matriz[ywmin, xwmin, zwmin])
    max_val = Float64(matriz[ywmin, xwmin, zwmin])
    coord_minx, coord_miny, coord_minz = xwmin, ywmin, zwmin
    coord_maxx, coord_maxy, coord_maxz = xwmax, ywmax, zwmax
    n_elements = 0
    mean_val::Float64 = 0.0
    std_val::Float64 = 0.0

    # Window analysis limits
    n_rows, n_columns, n_slices = size(matriz)
    x_min = min(xwmin, n_columns)
    x_max = max(xwmax, 1)
    y_min = min(ywmin, n_rows)
    y_max = max(ywmax, 1)
    z_min = min(zwmin, n_slices)
    z_max = max(zwmax, 1)

    # Array to store transformed values
    matrix_result = similar(matriz, Float64, size(matriz))
    #epsilon = 1e-10  # Small value to avoid log10(0)

   # Iterate through the window

    for k in zwmin:zwmax
        for i in ywmin:ywmax
            for j in xwmin:xwmax
                element = matriz[i, j, k]
                # Convert element to Float64 if necessary
                if !(element isa Float64)
                    element = Float64(element)
                end
                
                # Update sum and count
                sum_val += element
                n_elements += 1

                # Update the minimum
                if element < min_val
                    min_val = element
                    coord_minx = j
                    coord_miny = i
                    coord_minz = k
                end

                # Update the maximum
                if element > max_val
                    max_val = element
                    coord_maxx = j
                    coord_maxy = i
                    coord_maxz = k
                end
                
            # Apply transformation if function is provided
            if func !== nothing
                if func === log10
                    # Special handling for log10
                    if element < 0
                        matrix_result[i, j, k] = sign(element) * func(max(abs(element), AstroTLPlot.EPSILON))
                    elseif element == 0
                        matrix_result[i, j, k] = 0.0  # Avoid -Inf
                    else
                        matrix_result[i, j, k] = func(max(element, AstroTLPlot.EPSILON))
                    end
                else
                    # Generic function handling
                    if element < 0
                        matrix_result[i, j, k] = sign(element) * func(abs(element))
                    else
                        matrix_result[i, j, k] = func(element)
                    end
                end
            else
                # If no function, copy original element
                matrix_result[i, j, k] = element
            end
                
            end
        end
    end

    # Calculate the mean
    mean_val = sum_val / n_elements

    # Calculate the variance and standard deviation
    var_val = variance_loops(matriz, mean_val, n_elements, ywmin, ywmax, xwmin, xwmax,zwmin,zwmax)
   # var_val = sum((matriz[ywmin:ywmax, xwmin:xwmax, zwmin:zwmax] .- mean_val).^2) / n_elements
    std_val = sqrt(var_val)

    # Construct the result dictionary
    results = Dict(
        "statistics" => Dict(
            "sum" => sum_val,
            "minimum" => min_val,
            "maximum" => max_val,
            "mean" => mean_val,
            "variance" => var_val,
            "std_deviation" => std_val,
            "range" => max_val - min_val,
            "n_elements" => n_elements,
            "x_min" => x_min,
            "x_max" => x_max,
            "y_min" => y_min,
            "y_max" => y_max,
            "z_min" => z_min,
            "z_max" => z_max,
            "indexx_min" => coord_minx,
            "indexy_min" => coord_miny,
            "indexz_min" => coord_minz,
            "indexx_max" => coord_maxx,
            "indexy_max" => coord_maxy,
            "indexz_max" => coord_maxz,
        ),
        "matrix_result" => matrix_result,
    )
    return results
end

#*****************************************
#  statistics_data2D_native(matriz::AbstractMatrix{T}, func::Union{Function, Nothing}=nothing) where T<:Real
#*****************************************
"""
    statistics_data2D_native(matriz::AbstractMatrix{T}, func::Union{Function, Nothing}=nothing) where T<:Real

Compute statistical data for a 2D matrix using Julia's built-in functions and optionally apply a transformation function.

# Arguments
- `matriz::AbstractMatrix{T}`: Input matrix of real numbers.
- `func::Union{Function, Nothing}`: Optional function to apply to each element.

# Returns
- `Matrix2DStatistics`: A structure containing:
    - Sum, mean, variance, standard deviation
    - Minimum and maximum values with coordinates
    - Axis limits and range
    - Transformed matrix
"""
function statistics_data2D_native(matriz::AbstractMatrix{T}, func::Union{Function, Nothing}=nothing) where T<:Real
    # Convert matrix to Float64 for numerical stability
    matriz_f = Float64.(matriz)

    # Apply transformation if provided
    epsilon = 1e-10
    matrix_result = if func !== nothing
        if func === log10
            # Special handling for log10
            map(x -> x < 0 ? sign(x) * func(max(abs(x), epsilon)) :
                     x == 0 ? 0.0 : func(max(x, epsilon)), matriz_f)
        else
            # Generic function handling
            map(x -> x < 0 ? sign(x) * func(abs(x)) : func(x), matriz_f)
        end
    else
        copy(matriz_f)
    end

    # Compute statistics using built-in functions
    sum_val = sum(matriz_f)
    mean_val = mean(matriz_f)
    variance_val = var(matriz_f)  # Sample variance by default
    std_val = std(matriz_f)

    # Find min and max values and their coordinates
    min_val = minimum(matriz_f)
    max_val = maximum(matriz_f)
    coord_min = argmin(matriz_f)
    coord_max = argmax(matriz_f)

    # Axis limits
    x_min, x_max = first(axes(matriz, 2)), last(axes(matriz, 2))
    y_min, y_max = first(axes(matriz, 1)), last(axes(matriz, 1))

    # Build result structures
    coord_min_struct = Coordinate2DResult(Point2D(coord_min[2], coord_min[1]), min_val)
    coord_max_struct = Coordinate2DResult(Point2D(coord_max[2], coord_max[1]), max_val)
    axis_limits = Axis2DLimits(Point2D(x_min, y_min), Point2D(x_max, y_max))
    range_struct = MinMaxRange(min_val, max_val)

    stats_struct = StatisticsData2D(
        sum_val, mean_val, variance_val, std_val,
        coord_min_struct, coord_max_struct,
        range_struct, length(matriz_f), size(matriz, 1), size(matriz, 2),
        axis_limits
    )

    return Matrix2DStatistics(stats_struct, matrix_result)
end


#*****************************************
#  statistics_data2D_optimized(matriz::AbstractMatrix{T}, func::Union{Function, Nothing}=nothing) where T<:Real
#*****************************************

"""
    statistics_data2D_optimized(matriz::AbstractMatrix{T}, func::Union{Function, Nothing}=nothing) where T<:Real

Compute statistical metrics and apply an optional transformation to a 2D matrix of real numbers, returning both the computed statistics and the transformed matrix.

# Arguments
- `matriz::AbstractMatrix{T}`: A 2D matrix of real numbers (`T<:Real`) to analyze.
- `func::Union{Function, Nothing}`: An optional function to apply element-wise to the matrix values.
    - If `func === log10`, special handling is applied to avoid issues with zero or negative values.
    - If `func` is `nothing`, no transformation is applied.

# Behavior
- Converts the input matrix to `Float64` for numerical stability.
- Applies the transformation using broadcasting:
    - For `log10`, negative values are handled by applying `sign(x) * log10(max(abs(x), ε))`.
    - For other functions, negative values are transformed as `sign(x) * func(abs(x))`.
- Computes the following statistics on the original matrix:
    - Sum, mean, variance, standard deviation.
    - Minimum and maximum values and their coordinates.
- Determines axis limits based on matrix dimensions.
- Constructs structured results:
    - `Coordinate2DResult` for min and max positions.
    - `Axis2DLimits` for axis boundaries.
    - `MinMaxRange` for value range.
    - `StatisticsData2D` for all computed statistics.
- Returns a `Matrix2DStatistics` object containing:
    - The statistics structure.
    - The transformed matrix.

# Returns
- `Matrix2DStatistics`: A composite structure with statistical data and the transformed matrix.

# Notes
- Uses `@.` macro for efficient broadcasting.
- `epsilon = 1e-10` is used to avoid logarithm of zero or negative values.

# Example
```julia
mat = [1.0 2.0; -3.0 4.0]
result = statistics_data2D_optimized(mat, log10)
println(result.stats.mean)  # Access mean value
"""

function statistics_data2D_optimized(matriz::AbstractMatrix{T}, func::Union{Function, Nothing}=nothing) where T<:Real
   # Conversão para Float64
    matriz_f = Float64.(matriz)
    epsilon = 1e-10

    # Aplicar transformação com broadcasting
    matrix_result = if func !== nothing
        if func === log10
            @. matriz_f < 0 ? sign(matriz_f) * log10(max(abs(matriz_f), epsilon)) :
               matriz_f == 0 ? 0.0 : log10(max(matriz_f, epsilon))
        else
            @. matriz_f < 0 ? sign(matriz_f) * func(abs(matriz_f)) : func(matriz_f)
        end
    else
        copy(matriz_f)
    end

    # Estatísticas
    sum_val = sum(matriz_f)
    mean_val = mean(matriz_f)
    variance_val = var(matriz_f)
    std_val = std(matriz_f)
    min_val, max_val = minimum(matriz_f), maximum(matriz_f)
    coord_min, coord_max = argmin(matriz_f), argmax(matriz_f)

    # Limites dos eixos
    x_min, x_max = first(axes(matriz, 2)), last(axes(matriz, 2))
    y_min, y_max = first(axes(matriz, 1)), last(axes(matriz, 1))


    # Construção das estruturas
    coord_min_struct = Coordinate2DResult(Point2D(coord_min[2], coord_min[1]), min_val)
    coord_max_struct = Coordinate2DResult(Point2D(coord_max[2], coord_max[1]), max_val)
    axis_limits = Axis2DLimits(Point2D(x_min, y_min), Point2D(x_max, y_max))
    range_struct = MinMaxRange(min_val, max_val)

    stats_struct = StatisticsData2D(
        sum_val, mean_val, variance_val, std_val,
        coord_min_struct, coord_max_struct,
        range_struct, length(matriz_f), size(matriz, 1), size(matriz, 2),
        axis_limits
    )

    return Matrix2DStatistics(stats_struct, matrix_result)
end

#----------


function statistics_data2D_new(matriz::AbstractMatrix{T}, func::Union{Function, Nothing}=nothing) where T<:Real
    # Get matrix dimensions and element count
    n_rows, n_columns = size(matriz)
    n_elements = n_rows * n_columns

    # Initialize statistical variables
    sum_val = zero(Float64)
    min_val = Float64(matriz[1, 1])
    max_val = Float64(matriz[1, 1])
    coord_minx = coord_miny = 1
    coord_maxx = coord_maxy = 1

    # Matrix to store transformed values
    matrix_result = similar(matriz, Float64, size(matriz))

    # Axis limits
    x_min = n_columns
    x_max = 1
    y_min = n_rows
    y_max = 1

    # Define epsilon to avoid log10(0)
    epsilon = AstroTLPlot.EPSILON  # or 1e-10 if not defined globally

    # Iterate through all elements
    for i in 1:n_rows
        for j in 1:n_columns
            # Convert element to Float64 if necessary
            element = matriz[i, j]
            if !(element isa Float64)
                element = Float64(element)
            end

            # Update sum
            sum_val += element

            # Update minimum
            if element < min_val
                min_val = element
                coord_minx, coord_miny = j, i
            end

            # Update maximum
            if element > max_val
                max_val = element
                coord_maxx, coord_maxy = j, i
            end

            # Update axis limits
            x_min = min(x_min, j)
            x_max = max(x_max, j)
            y_min = min(y_min, i)
            y_max = max(y_max, i)

            # Apply transformation if function is provided
            if func !== nothing
                if func === log10
                    # Hybrid handling for log10
                    if element < 0
                        matrix_result[i, j] = sign(element) * func(max(abs(element), epsilon))
                    elseif element == 0
                        matrix_result[i, j] = func(epsilon)  # Use epsilon instead of 0
                    else
                        matrix_result[i, j] = func(max(element, epsilon))
                    end
                else
                    # Generic function handling
                    if element < 0
                        matrix_result[i, j] = sign(element) * func(abs(element))
                    else
                        matrix_result[i, j] = func(element)
                    end
                end
            else
                # If no function, copy original element
                matrix_result[i, j] = element
            end
        end
    end

    # Compute mean
    mean_val = sum_val / n_elements

    # Compute variance and standard deviation
    variance_val = variance_loops2D(matriz, mean_val, n_elements, n_rows, n_columns)
    std_val = sqrt(variance_val)

    # Build result structures
    coord_min = Coordinate2DResult{T}(Point2D(coord_minx, coord_miny), min_val)
    coord_max = Coordinate2DResult{T}(Point2D(coord_maxx, coord_maxy), max_val)
    axis_limits = Axis2DLimits(Point2D(x_min, y_min), Point2D(x_max, y_max))
    range_struct = MinMaxRange(min_val, max_val)

    stats_struct = StatisticsData2D{T}(
        sum_val, mean_val, variance_val, std_val,
        coord_min, coord_max,
        range_struct, n_elements, n_rows, n_columns,
        axis_limits
    )

    return Matrix2DStatistics{T}(stats_struct, matrix_result)
end

