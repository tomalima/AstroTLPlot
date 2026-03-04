# ==============================================================================
# Cubic Spline Interpolation Module
#
# This module provides a collection of functions for computing and evaluating
# natural cubic splines, including:
#   • Second-derivative computation for spline coefficients
#   • Spline evaluation routines using different numerical formulations
#   • Full piecewise cubic coefficient generation (a, b, c, d)
#   • Alternative solver implementations for tridiagonal systems
#
# These utilities support interpolation, smoothing, and numerical analysis of
# tabulated datasets, and are designed for clarity, robustness, and testing
# of different spline formulations.
#
# Author: Tomás Lima
# Date: 2026-03-03
# ==============================================================================

# ==============================================================================
# Cubic Spline Interpolation Functions
# ==============================================================================

"""
    spline3_coef(n::Int, t::Vector{Float64}, y::Vector{Float64}) -> Vector{Float64}

Compute second derivatives for natural cubic spline interpolation.

This function calculates the second derivatives (z coefficients) required for
natural cubic spline interpolation using the tridiagonal matrix algorithm.

# Arguments
- `n::Int`: Number of data points (length of `t` and `y`)
- `t::Vector{Float64}`: Vector of strictly increasing x-coordinates (knot positions)
- `y::Vector{Float64}`: Vector of y-values corresponding to `t`

# Returns
- `z::Vector{Float64}`: Vector of second derivatives at each knot point, with 
  `z[1] = z[n] = 0.0` for natural spline boundary conditions

# Algorithm
1. Computes step sizes `h[i] = t[i+1] - t[i]`
2. Calculates finite differences `b[i] = (y[i+1] - y[i]) / h[i]`
3. Solves tridiagonal system for second derivatives using Thomas algorithm
4. Applies natural spline boundary conditions (zero second derivatives at endpoints)

# Example
```julia
t = [0.0, 1.0, 2.0, 3.0]
y = [0.0, 1.0, 0.0, 1.0]
z = spline3_coef(length(t), t, y)
Notes
Requires at least 3 data points

Input t must be strictly increasing

Natural spline: second derivatives zero at endpoints
"""

function spline3_coef(n::Int, t::Vector{Float64}, y::Vector{Float64})
    h = Vector{Float64}(undef, n)
    b = Vector{Float64}(undef, n)
    u = Vector{Float64}(undef, n-1)
    v = Vector{Float64}(undef, n-1)
    z = Vector{Float64}(undef, n+1)

    for i in 1:n-1
        h[i] = t[i+1] - t[i]
        b[i] = (y[i+1] - y[i]) / h[i]
    end

    u[1] = 2.0 * (h[1] + h[2])
    v[1] = 6.0 * (b[2] - b[1])

    for i in 2:n-1
        u[i] = 2.0 * (h[i] + h[i-1]) - h[i-1]^2 / u[i-1]
        v[i] = 6.0 * (b[i] - b[i-1]) - h[i-1] * v[i-1] / u[i-1]
    end

    z[n] = 0.0
    for i in n-1:-1:1
        z[i] = (v[i] - h[i] * z[i+1]) / u[i]
    end
    z[1] = 0.0
    z[n + 1] = 0.0 # Guarantee the final element remains zero

    return z
end

# ==============================================================================
# 
# 
#
# ==============================================================================
"""
spline3_eval(n::Int, t::Vector{Float64}, y::Vector{Float64}, z::Vector{Float64}, x::Float64) -> Float64

Evaluate cubic spline at a specific point using precomputed coefficients.

This function evaluates the cubic spline interpolation at point x using
the precomputed second derivatives from spline3_coef.

Arguments
n::Int: Number of data points

t::Vector{Float64}: Knot positions (x-coordinates)

y::Vector{Float64}: Function values at knots

z::Vector{Float64}: Second derivatives from spline3_coef

x::Float64: Point at which to evaluate the spline

Returns
Float64: Interpolated value at x

Algorithm
Locates the interval containing x using linear search

Computes cubic polynomial coefficients for the interval

Evaluates the cubic polynomial at x

Example
julia
# After computing z with spline3_coef
interpolated_value = spline3_eval(n, t, y, z, 1.5)
Notes
Assumes x is within the range of t (no extrapolation handling)

Uses linear search which is efficient for small datasets
"""
function spline3_eval(n::Int, t::Vector{Float64}, y::Vector{Float64}, z::Vector{Float64}, x::Float64)
    h = 0.0
    temp = 0.0
    i = n

    while i > 1
        if x - t[i] >= 0.0
            break
        end
        i -= 1
    end

    h = t[i+1] - t[i]
    temp = 0.5 * z[i] + (x - t[i]) * (z[i+1] - z[i]) / (6.0 * h)
    temp = (y[i+1] - y[i]) / h - h * (z[i+1] + 2.0 * z[i]) / 6.0 + (x - t[i]) * temp
    spline3_eval = y[i] + (x - t[i]) * temp

    return spline3_eval
end

# ==============================================================================
# 
# 
#
# ==============================================================================
"""
natural_cubic_spline(t::Vector{Float64}, y::Vector{Float64}) -> Tuple

Compute complete natural cubic spline coefficients.

This function computes all coefficients (a, b, c, d) for piecewise cubic polynomial
representation of the natural cubic spline.

Arguments
t::Vector{Float64}: Knot positions (must be strictly increasing)

y::Vector{Float64}: Function values at knots

Returns
a::Vector{Float64}: Constant coefficients (function values at left endpoints)

b::Vector{Float64}: Linear coefficients

c::Vector{Float64}: Quadratic coefficients

d::Vector{Float64}: Cubic coefficients

t_segments::Vector{Float64}: Segment boundaries (t[1:n-1])

z::Vector{Float64}: Second derivatives

Representation
For x in [t[i], t[i+1]], the spline is:
S_i(x) = a[i] + b[i](x-t[i]) + c[i](x-t[i])² + d[i]*(x-t[i])³

Example
julia
t = [0.0, 1.0, 2.0, 3.0]
y = [0.0, 1.0, 0.0, 1.0]
a, b, c, d, t_seg, z = natural_cubic_spline(t, y)
Notes
Returns coefficients for n-1 segments

Natural boundary conditions: second derivatives zero at endpoints
"""

function natural_cubic_spline(t::Vector{Float64}, y::Vector{Float64})
    n = length(t)
    if n != length(y)
        error("Vectors t and y must have the same length.")
    end
    if n < 3
        error("At least 3 points are required for the cubic spline.")
    end

    h = diff(t)
    a = copy(y)
    l = zeros(n)
    mu = zeros(n - 1)
    z = zeros(n)
    b = zeros(n)
    d = zeros(n)

    l[1] = 1
    for i in 1:n-2
        l[i+1] = 2 * (t[i+2] - t[i]) - h[i] * mu[i]
        mu[i+1] = h[i+1] / l[i+1]
        z[i+1] = (3 * ((a[i+2] - a[i+1]) / h[i+1] - (a[i+1] - a[i]) / h[i]) - h[i] * z[i]) / l[i+1]
    end
    l[n] = 1

    c = zeros(n)
    for j in n-1:-1:1
        c[j] = z[j] - mu[j] * c[j+1]
        b[j] = (a[j+1] - a[j]) / h[j] - h[j] * (c[j+1] + 2 * c[j]) / 3
        d[j] = (c[j+1] - c[j]) / (3 * h[j])
    end

    return a[1:n-1], b[1:n-1], c[1:n-1], d[1:n-1], t[1:n-1], z
end

# ==============================================================================
# 
# 
#
# ==============================================================================
"""
spline3_coef_v1(n::Int, x::Vector{Float64}, y::Vector{Float64}) -> Matrix{Float64}

Alternative implementation of cubic spline coefficient calculation.

This function provides a different algorithmic approach to computing
cubic spline coefficients, returning them in a consolidated matrix format.

Arguments
n::Int: Number of data points

x::Vector{Float64}: Knot positions

y::Vector{Float64}: Function values

Returns
Matrix{Float64}: 4×n matrix where columns are [a, b, c, d] coefficients
for each segment

Differences from spline3_coef
Different numerical approach to solving the tridiagonal system

Returns coefficients in matrix format for easier segment access

Uses alternative formulation of the continuity equations

Notes
Compatible with the same interpolation formula

May have different numerical properties for certain datasets
"""

function spline3_coef_v1(n::Int, x::Vector{Float64}, y::Vector{Float64})
    h = diff(x)
    α = zeros(Float64, n)
    for i in 2:n
        α[i] = (3/h[i]) * (y[i+1] - y[i]) - (3/h[i-1]) * (y[i] - y[i-1])
    end
    
    l = zeros(Float64, n+1)
    μ = zeros(Float64, n+1)
    z = zeros(Float64, n+1)
    c = zeros(Float64, n+1)
    b = zeros(Float64, n+1)
    d = zeros(Float64, n+1)
    
    l[1] = 1.0
    μ[1] = 0.0
    z[1] = 0.0
    
    for i in 2:n
        l[i] = 2*(x[i+1] - x[i-1]) - h[i-1]*μ[i-1]
        μ[i] = h[i]/l[i]
        z[i] = (α[i] - h[i-1]*z[i-1])/l[i]
    end
    
    l[n+1] = 1.0
    z[n+1] = 0.0
    c[n+1] = 0.0
    
    for j in n:-1:1
        c[j] = z[j] - μ[j]*c[j+1]
        b[j] = (y[j+1] - y[j])/h[j] - h[j]*(c[j+1] + 2*c[j])/3
        d[j] = (c[j+1] - c[j])/(3*h[j])
    end
    
    return [y[1:n] b[1:n] c[1:n] d[1:n]]
end

# ==============================================================================
# 
# 
#
# ==============================================================================

function evaluate_spline(x::Float64, a::Vector{Float64}, b::Vector{Float64}, c::Vector{Float64}, d::Vector{Float64}, t_segments::Vector{Float64})
    n = length(a)
    if n == 0
        error("Nenhum segmento de spline disponível.")
    end

    i = 0
    for j in 1:n
        if t_segments[j] <= x
            if j == n || x < t_segments[j+1]
                i = j
                break
            end
        end
    end

    if i == 0
        if x <= t_segments[1]
            i = 1
        elseif x >= t_segments[end]
            i = n
        else
            error("Ponto x fora do intervalo dos dados.")
        end
    end

    dx = x - t_segments[i]
    return a[i] + b[i] * dx + c[i] * dx^2 + d[i] * dx^3
end

# ==============================================================================
# 
# 
#
# ==============================================================================
"""
    spline3_coef_v2(n::Int, t::Vector{Float64}, y::Vector{Float64}) -> Vector{Float64}

Compute the second derivatives (z coefficients) for a natural cubic spline
interpolation of the function defined by the nodes `t` and values `y`.

# Arguments
- `n`: number of data points (length of `t` and `y`).
- `t`: vector of x-coordinates, strictly increasing.
- `y`: vector of y-values corresponding to `t`.

# Returns
- `z`: vector of second derivatives at each point.

# Example
```julia
t = [0.0, 1.0, 2.0, 3.0]
y = [0.0, 1.0, 0.0, 1.0]
z = spline3_coef(length(t), t, y)


"""
# ==============================================================================
# 
# 
#
# ==============================================================================

function spline3_coef_v2(n::Int, t::Vector{Float64}, y::Vector{Float64})
        if n < 3
            error("Need at least 3 points for cubic spline.")
        end
        
        h = diff(t)
        α = zeros(n)
        for i in 2:n-1
            α[i] = (3/h[i]) * (y[i+1] - y[i]) - (3/h[i-1]) * (y[i] - y[i-1])
        end
        
        l = ones(n)
        μ = zeros(n)
        z = zeros(n)
        
        for i in 2:n-1
            l[i] = 2*(t[i+1] - t[i-1]) - h[i-1]*μ[i-1]
            μ[i] = h[i] / l[i]
            z[i] = (α[i] - h[i-1]*z[i-1]) / l[i]
        end
        
        # Back substitution
        for j in n-1:-1:1
            z[j] -= μ[j]*z[j+1]
        end
        
        return z
end
# ==============================================================================
# 
# 
#
# ==============================================================================
# (original transposta)
function spline3_eval_v1(n::Int, t::Vector{Float64}, y::Vector{Float64}, z::Vector{Float64}, x::Float64)
   # Find the interval containing x
    i = 1
    for j in n-1:-1:1
        if x - t[j] >= 0.0
            i = j
            break
        end
    end

    h = t[i+1] - t[i]
    temp = 0.5 * z[i] + (x - t[i]) * (z[i+1] - z[i]) / (6.0 * h)
    temp = (y[i+1] - y[i]) / h - h * (z[i+1] + 2.0 * z[i]) / 6.0 + (x - t[i]) * temp
    return y[i] + (x - t[i]) * temp
end
# ==============================================================================
# 
# 
#
# ==============================================================================
# 
function spline3_eval_v2(n::Int, t::Vector{Float64}, y::Vector{Float64}, z::Vector{Float64}, x::Float64)
    h = 0.0
    temp = 0.0
    spline3_eval = 0.0
    i = 1

    for j in n-1:-1:1
        #if x - t[j] >= 0.0 attempt to access 4-element Vector{Float64} at index [i+1]
         if x >= t[j]
            i = j
            break
        end
    end

    h = t[i+1] - t[i]
    temp = 0.5 * z[i] + (x - t[i]) * (z[i+1] - z[i]) / (6.0 * h)
    temp = (y[i+1] - y[i]) / h - h * (z[i+1] + 2.0 * z[i]) / 6.0 + (x - t[i]) * temp
    spline3_eval_v2 = y[i] + (x - t[i]) * temp

    return spline3_eval_v2
end
# ==============================================================================
# 
# 
#
# ==============================================================================
"""
    spline3_eval(ntemp_spline, alogt, y, y2, x) -> Float64

Evaluate a natural cubic spline at point `x`.

Arguments
- `ntemp_spline::Int` : number of intervals (ncool-1). Not strictly required here,
                        but kept for API compatibility.
- `alogt::Vector{Float64}` : node abscissas (log10 temperatures), length = nt = ntemp_spline+1
- `y::AbstractVector{Float64}` : function values at nodes (length nt)
- `y2::AbstractVector{Float64}` : second derivatives at nodes (length nt), as produced by spline3_coef
- `x::Float64` : point where spline is evaluated (log10 temperature)

Returns
- interpolated value (Float64).
"""
function spline3_eval(ntemp_spline::Int, alogt::AbstractVector{Float64},
                      y::AbstractVector{Float64}, y2::AbstractVector{Float64},
                      x::Float64)::Float64
    nt = length(alogt)
    @assert length(y) == nt && length(y2) == nt "alogt, y and y2 must have same length"

    # handle boundaries: clamp to endpoints (same behaviour as many spline impls)
    if x <= alogt[1]
        return y[1]
    elseif x >= alogt[end]
        return y[end]
    end

    # binary search for interval k: alogt[k] <= x <= alogt[k+1]
    lo = 1
    hi = nt
    while hi - lo > 1
        mid = (lo + hi) >>> 1
        if alogt[mid] <= x
            lo = mid
        else
            hi = mid
        end
    end
    k = lo
    h = alogt[k+1] - alogt[k]
    if h == 0.0
        # degenerate spacing, fallback to linear
        return (y[k] + y[k+1]) / 2
    end

    a = (alogt[k+1] - x) / h
    b = (x - alogt[k]) / h

    # Cubic spline interpolation formula (from natural cubic spline with y2 second derivatives)
    return a * y[k] + b * y[k+1] + ((a^3 - a) * y2[k] + (b^3 - b) * y2[k+1]) * (h^2) / 6.0
end
