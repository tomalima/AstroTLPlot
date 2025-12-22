# ==============================================================================
# Geometry and Range Structures Module
# 
# This module defines basic geometric structures and range representations
# used throughout the simulation framework.
# ==============================================================================

"""
    GeometryStructures

A module providing fundamental geometric structures for 2D/3D coordinates
and numerical ranges used in simulation configurations and data processing.

# Main Structures
- `Point3D`: 3D point in Cartesian space
- `Point2D`: 2D point in Cartesian space  
- `MinMaxRange`: Numerical range with min/max bounds

# Type Parameters
- `T<:Real`: All structures are parameterized by real number types

# Usage
```julia
point3d = Point3D(1.0, 2.0, 3.0)
point2d = Point2D(1.0, 2.0)
range = MinMaxRange(0.0, 10.0)
"""

    """
    Represents a point in 2D space.
    """
    # 2D Point structure
    mutable struct Point2D{T<:Real}
        x::T # x-coordinate
        y::T # y-coordinate
    end

    """
    Represents a point in 3D space.
    """
    mutable struct Point3D{T<:Real}
        x::T # x-coordinate
        y::T # y-coordinate
        z::T # z-coordinate
    end
    
   """
    Represents a range with minimum and maximum values.
    """
mutable struct MinMaxRange{T<:Real}
        min::T # Minimum value of the range
        max::T # Maximum value of the range
end
