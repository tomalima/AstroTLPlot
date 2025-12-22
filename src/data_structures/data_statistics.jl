
# ==============================================================================
# Statistical Data Structures Module
# 
# This module defines a collection of type-parameterized data structures for
# performing statistical analysis on 1D, 2D, and 3D datasets. It includes
# coordinate-aware results, axis limit tracking, and comprehensive descriptive
# statistics, enabling flexible and efficient# statistics, enabling flexible and efficient handling of multidimensional data.
#
# Author: [Tomás Lima]
# Date: [2025-10-17]
# ==============================================================================

"""
    StatisticalStructures

A module providing data structures for statistical analysis across different 
dimensionalities (1D, 2D, 3D) with coordinate tracking and comprehensive 
descriptive statistics.

# Main Structures
- 1D: `Coordinate1DResult`, `Axis1DLimits`, `StatisticsData1D`, `Vector1DStatistics`
- 2D: `Coordinate2DResult`, `Axis2DLimits`, `StatisticsData2D`, `Matrix2DStatistics`  
- 3D: `Coordinate3DResult`, `Axis3DLimits`, `StatisticsData3D`, `Matrix3DStatistics`

# Features
- Coordinate-aware statistical results
- Axis limits and dimensional metadata
- Comprehensive descriptive statistics
- Type-parameterized for numerical flexibility

# Usage
```julia
using .StatisticalStructures

# Analyze 1D data
stats_1d = StatisticsData1D(sum, mean, var, std, min_result, max_result, range, n, axis_limits)

# Analyze 2D matrix  
stats_2d = StatisticsData2D(sum, mean, var, std, min_result, max_result, range, n, rows, cols, axis_limits)

# Analyze 3D array
stats_3d = StatisticsData3D(sum, mean, var, std, min_result, max_result, range, n, rows, cols, slices, axis_limits)

"""

# ==============================================================================



"""
Represents a coordinate and its value in 1D space.
"""
mutable struct Coordinate1DResult{T}
    index1D::Int        # index of value
    value1D::T          # the value at index
end

"""
Represents axis limits in 1D space.
"""
mutable struct Axis1DLimits
    p1min::Int          # The minimum axis value (index)
    p1max::Int          # The maximum axis value (index)
end

"""
Represents statistical data from a 1D vector.
"""
mutable struct StatisticsData1D{T<:Real}
    sum::T              # The sum of all elements in the vector
    mean::T             # The average value of the elements
    variance::T         # The variance of the elements
    std_dev::T          # The standard deviation
    # median::T           # The median value
    # quantiles::Dict{Symbol, T} # Key quantiles (q25, q50, q75)

    min_value::Coordinate1DResult{T}      # The minimum value in the vector
    max_value::Coordinate1DResult{T}      # The maximum value in the vector

    range_value::MinMaxRange{T}   # The range of the elements
    n_elements::Int               # The total number of elements
    axis_limits::Axis1DLimits
end

"""
Combines statistical information, axis limits, and coordinate results for a 1D vector.
"""
mutable struct Vector1DStatistics{T<:Real}
    statistics_data::StatisticsData1D{T}  # Statistics including sum, min, max, mean, and count
    vector_result::Vector{T}              # Vector after applying a function
end

# ==============================================================================

"""
    Coordinate2DResult{T}

Represents a coordinate and its associated value in 2D space.  
This structure is useful for storing results that combine both position 
(index in a matrix) and the corresponding value.  

# Fields
- `index2D::Point2D{Int}` : The (x, y) index of the value in the matrix.  
- `value2D::T` : The value stored at the given coordinate.  
"""
mutable struct Coordinate2DResult{T}
    index2D::Point2D{Int}        # x,y index of value
    value2D::T                   # the value at index x,y
end


"""
    Axis2DLimits

Represents axis limits in 2D space, defined by minimum and maximum coordinates.  
This structure is typically used to define the bounding box of a matrix, plot, 
or region of interest.  

# Fields
- `p2min::Point2D{Int}` : Minimum index for x- and y-axes.  
- `p2max::Point2D{Int}` : Maximum index for x- and y-axes.  
"""
mutable struct Axis2DLimits
    p2min::Point2D{Int}   # Lower bound (min x, min y) index
    p2max::Point2D{Int}   # Upper bound (max x, max y) index
end

"""
    StatisticsData2D{T<:Real}

Stores statistical data computed from a 2D matrix.  
Encapsulates descriptive statistics, extrema values with coordinates, 
and metadata about matrix dimensions.  

# Fields
- `sum::T` : Sum of all matrix elements.  
- `mean::T` : Arithmetic mean of the elements.  
- `variance::T` : Variance of the elements.  
- `std_dev::T` : Standard deviation.  
- `min_value::Coordinate2DResult{T}` : Minimum value and its coordinate.  
- `max_value::Coordinate2DResult{T}` : Maximum value and its coordinate.  
- `range_value::MinMaxRange{T}` : Range between minimum and maximum values.  
- `n_elements::Int` : Total number of elements.  
- `n_rows::Int` : Number of rows.  
- `n_columns::Int` : Number of columns.  
- `axis_limits::Axis2DLimits` : Axis limits covering the matrix.  
"""
mutable struct StatisticsData2D{T<:Real}
    sum::T           # The sum of all elements in the matrix
    mean::T          # The average value of the elements
    variance::T      # The variance of the elements
    std_dev::T       # The standard deviation

    min_value::Coordinate2DResult{T}      # Minimum value with its position
    max_value::Coordinate2DResult{T}      # Maximum value with its position

    range_value::MinMaxRange{T} #  Range (min, max) of values
    n_elements::Int        # The total number of elements
    n_rows::Int            # The number of rows
    n_columns::Int         # The number of columns
    axis_limits::Axis2DLimits # Axis boundaries for the matrix
end


"""
    Matrix2DStatistics{T<:Real}

Combines numerical statistics with the resulting transformed matrix.  
This structure links raw statistical results with processed data, 
enabling both quantitative analysis and matrix-level transformations.  

# Fields
- `statistics_data::StatisticsData2D{T}` : Statistical descriptors of the matrix.  
- `matrix_result::Matrix{T}` : Resulting matrix after transformations or computations.  
"""
mutable struct Matrix2DStatistics{T<:Real}
    statistics_data::StatisticsData2D{T}  # Statistical descriptorst
    matrix_result::Matrix{T}              # Matrix after applying a function
end

# ==============================================================================

"""
Represents a coordinate and its value in 3D space.
"""
mutable struct Coordinate3DResult{T}
    index3D::Point3D{Int}        # x index of value
    value3D::T                   # the value at index x,y,z
end

"""
Represents axis limits in 3D space.
"""
mutable struct Axis3DLimits
    p3min::Point3D{Int}    # The minimum x,y,z-axis value (index)
    p3max::Point3D{Int}    # The maximum x,y,z-axis value (index)
end

"""
Represents statistical data from a 3D matrix.
"""
mutable struct StatisticsData3D{T<:Real}
    sum::T          # The sum of all elements in the matrix
    mean::T         # The average value of the elements
    variance::T     # The variance of the elements
    std_dev::T      # The standard deviation

    min_value::Coordinate3DResult{T}      # The minimum value in the matrix
    max_value::Coordinate3DResult{T}      # The maximum value in the matrix

    range_value::MinMaxRange{T} # The range of the elements
    n_elements::Int        # The total number of elements
    n_rows::Int            # The number of rows
    n_columns::Int         # The number of columns
    n_slices::Int          #The number of slices
    axis_limits::Axis3DLimits
end

"""
Combines statistical information, axis limits, and coordinate results for a 3D matrix.
"""
mutable struct Matrix3DStatistics{T<:Real}
    statistics_data::StatisticsData3D{T}  # Statistics including sum, min, max, mean, and count
    matrix_result::Array{T, 3}            # Matrix after applying a function
end

# ==============================================================================

