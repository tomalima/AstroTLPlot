# ==============================================================================
# FAIR Data Path Management Utilities Module
#
# This module provides helper functions for constructing and organizing
# FAIR‑compliant directory structures used throughout the simulation
# output pipeline. It includes:
#
#   • Snapshot ID builders (e.g., "all00####")
#   • Automatic creation of standardized folder hierarchies for:
#         - Physical variables
#         - Ion species (per-element and per-ionization state)
#         - Electron densities (total and per-element)
#   • Consistent folder sets for: {color, contour, heat_cont, pdf, statistics, subplots}
#   • Idempotent directory creation using `mkpath`
#
# These utilities ensure reproducible, machine‑readable, and human‑navigable
# output structures following FAIR principles (Findable, Accessible,
# Interoperable, Reusable), simplifying downstream visualization,
# analysis, and data publishing workflows.
#
# Author: Tomás Lima
# Date: 2026-03-03
# ============================================================================== 
using Printf

"""
Build the snapshot id_string as "all00<filenum>", where <filenum> is zero-padded to 4 digits
if passed as Integer. If you already pass "3000" (String), it will produce "all003000".
Examples:
  build_id_string(3000)   -> "all003000"
  build_id_string("3000") -> "all003000"
"""
function build_id_string(filenum::Union{Integer,AbstractString})
    num_str = filenum isa Integer ? @sprintf("%04d", filenum) : String(filenum)
    return "all00" * num_str
end

# ==============================================================================
# 
# 
#
# ==============================================================================
"""
Ensure FAIR-compliant variable folders exist under:
    <root>/snapshots/<id_string>/variables/<var_name>/{color,contour,heat_cont,pdf,statistics}
Returns all resolved paths. `subplots` is returned but not created here.
"""
function prepare_variable_paths(
    id_string::AbstractString,
    var_name::AbstractString;
    root::AbstractString = "output_fair",
)
    var_base = joinpath(root, "snapshots", id_string, "variables", var_name)
    mkpath(var_base)

    color_path     = joinpath(var_base, "color")      ; mkpath(color_path)
    contour_path   = joinpath(var_base, "contour")    ; mkpath(contour_path)
    heatcont_path  = joinpath(var_base, "heat_cont")  ; mkpath(heatcont_path)
    pdf_path       = joinpath(var_base, "pdf")        ; mkpath(pdf_path)
    stats_path     = joinpath(var_base, "statistics") ; mkpath(stats_path)
    subplots_path  = joinpath(var_base, "subplots")   # create lazily

    return (
        base       = var_base,
        color      = color_path,
        contour    = contour_path,
        heat_cont  = heatcont_path,
        pdf        = pdf_path,
        statistics = stats_path,
        subplots   = subplots_path,  # not created yet
    )
end

# ==============================================================================
# 
# 
#
# ==============================================================================

"""
Ensure FAIR-compliant folders for an ion state under:
  <root>/snapshots/<id_string>/species/ions/<element>/<state>/{color,contour,heat_cont,pdf,statistics}
Returns a NamedTuple with all resolved paths. `subplots` is NOT created here
(because subplots for ions live at the element level, not per-state).
- `element` e.g. "H", "He", "C", ...
- `state`   e.g. "H00", "H01", "C06"
"""
function prepare_ion_paths(
    id_string::AbstractString,
    element::AbstractString,
    state::AbstractString;
    root::AbstractString = "output_fair",
)
    base = joinpath(root, "snapshots", id_string, "species", "ions", element, state)
    mkpath(base)

    color_path     = joinpath(base, "color")      ; mkpath(color_path)
    contour_path   = joinpath(base, "contour")    ; mkpath(contour_path)
    heatcont_path  = joinpath(base, "heat_cont")  ; mkpath(heatcont_path)
    pdf_path       = joinpath(base, "pdf")        ; mkpath(pdf_path)
    stats_path     = joinpath(base, "statistics") ; mkpath(stats_path)

    return (
        base       = base,
        color      = color_path,
        contour    = contour_path,
        heat_cont  = heatcont_path,
        pdf        = pdf_path,
        statistics = stats_path,
    )
end

# ==============================================================================
# 
# 
#
# ==============================================================================

"""
Ensure FAIR folders for an ion element under:
  <root>/snapshots/<id_string>/species/ions/<element>/subplots

Returns a NamedTuple: (base, subplots)
- base     = .../species/ions/<element>
- subplots = .../species/ions/<element>/subplots
"""
function prepare_ion_element_paths(
    id_string::AbstractString,
    element::AbstractString;
    root::AbstractString = "output_fair",
)
    elem_base = joinpath(root, "snapshots", id_string, "species", "ions", element)
    mkpath(elem_base)
    subplots = joinpath(elem_base, "subplots")
    # não criamos já subplots; fazemos mkpath quando formos gravar
    return (base = elem_base, subplots = subplots)
end

# ==============================================================================
# 
# 
#
# ==============================================================================

"""
Return FAIR-compliant folder paths for **total electron density (ele)**:

    <root>/snapshots/<id_string>/species/electrons/ele/{
        color, contour, heat_cont, pdf, statistics
    }

Notes:
- All folder paths are created idempotently (using `mkpath`) before returning.
- `subplots` is returned but **not** created here; create it lazily when you actually save a subplot panel.
"""
function prepare_electrons_total_paths(
    id_string::AbstractString; root::AbstractString = "output_fair"
)
    base = joinpath(root, "snapshots", id_string, "species", "electrons", "ele")
    mkpath(base)

    color      = joinpath(base, "color")      ; mkpath(color)
    contour    = joinpath(base, "contour")    ; mkpath(contour)
    heat_cont  = joinpath(base, "heat_cont")  ; mkpath(heat_cont)
    pdf        = joinpath(base, "pdf")        ; mkpath(pdf)
    statistics = joinpath(base, "statistics") ; mkpath(statistics)
    subplots   = joinpath(base, "subplots")   # create lazily when needed

    return (base=base, color=color, contour=contour, heat_cont=heat_cont,
            pdf=pdf, statistics=statistics, subplots=subplots)
end

# ==============================================================================
# 
# 
#
# ==============================================================================
"""
Return FAIR-compliant folder paths for **per-element electrons (elez)**:

    <root>/snapshots/<id_string>/species/electrons/elez/<Elem>/{
        color, contour, heat_cont, pdf, statistics
    }

Arguments:
- `id_string`: snapshot identifier (e.g., "all003000").
- `elem_sym` : element symbol string (e.g., "H", "He", "C", "N", "O").

Notes:
- All subfolders are created idempotently (`mkpath`) before returning.
- `subplots` path is returned but not created; create it lazily when needed.
"""
function prepare_electrons_per_element_paths(
    id_string::AbstractString, elem_sym::AbstractString;
    root::AbstractString = "output_fair"
)
    base = joinpath(root, "snapshots", id_string, "species", "electrons", "elez", elem_sym)
    mkpath(base)

    color      = joinpath(base, "color")      ; mkpath(color)
    contour    = joinpath(base, "contour")    ; mkpath(contour)
    heat_cont  = joinpath(base, "heat_cont")  ; mkpath(heat_cont)
    pdf        = joinpath(base, "pdf")        ; mkpath(pdf)
    statistics = joinpath(base, "statistics") ; mkpath(statistics)
    subplots   = joinpath(base, "subplots")   # create lazily when needed

    return (base=base, color=color, contour=contour, heat_cont=heat_cont,
            pdf=pdf, statistics=statistics, subplots=subplots)
end
