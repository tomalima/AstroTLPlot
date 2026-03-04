
# ==============================================================================
# Plotting and Visualization Utilities Module
# 
# This module provides high-level functions for creating and customizing plots
# using Makie, including heatmaps, contour plots, combined visualizations, and
# multi-panel layouts. It# multi-panel layouts. It offers pre-configured plotting structures, flexible
# customization options, and automated routines for rendering simulation data
# slices and saving figures in multiple formats.
#
# Author: [Tomás Lima]
# Date: [2025-10-17]
# ==============================================================================

using Dates
using Printf
using Statistics
using LaTeXStrings
using CairoMakie # to work i must put otherwise in main fail ==> UndefVarError: `Figure` not defined 


# ==============================================================================
#
# create_plot_structure 
#
# ==============================================================================

"""
    create_plot_structure(; xsize=800, ysize=800,
                          title="Title", subtitle="", titlesize=20, titlegap=16,
                          xlabel="X(pc)", ylabel="Y(pc)",
                          valmin=0, step=200, valmax=1000,
                          axis_size=650, square_limits=true)

Creates and configures a Makie Figure and Axis with specified labels,
titles, and default tick settings, with options for square aspect ratio.

This function provides a pre-configured plotting canvas, ready for data.
By returning the `fig` and `ax` objects, it allows for further manual
customization, such as adding different plot types or modifying
properties. The function includes options for controlling the title,
subtitle, and ensuring a square aspect ratio for the plot area.

# Arguments
- `xsize::Int`: The width of the figure in pixels. Defaults to `800`.
- `ysize::Int`: The height of the figure in pixels. Defaults to `800`.
- `title::String`: The main title of the plot. Defaults to `"Title"`.
- `subtitle::String`: The subtitle of the plot. Defaults to `""`.
- `titlesize::Int`: Font size for the title. Defaults to `20`.
- `titlegap::Int`: Gap between title and plot area. Defaults to `16`.
- `xlabel::String`: The label for the x-axis. Defaults to `"X(pc)"`.
- `ylabel::String`: The label for the y-axis. Defaults to `"Y(pc)"`.
- `valmin::Real`: The starting value for axis ticks and limits. Defaults to `0`.
- `step::Real`: The interval between axis ticks. Defaults to `200`.
- `valmax::Real`: The ending value for axis ticks and limits. Defaults to `1000`.
- `axis_size::Int`: Width and height of the axis in pixels (for square plots). Defaults to `650`.
- `square_limits::Bool`: If `true`, ensures equal scaling for x and y axes. Defaults to `true`.

# Returns
- A tuple `(fig, ax)` containing the newly created `Figure` and `Axis` objects.
  These can be used for subsequent plotting and customization.

# Example
```julia
# Create a plot with the default settings (size 800x800, square aspect ratio)
fig, ax = create_plot_structure()

# Override default values for a specific plot with subtitle and custom ticks
fig2, ax2 = create_plot_structure(
    xsize=1000,
    ysize=1000,
    title="Custom Square Plot",
    subtitle="With sine wave",
    titlesize=24,
    xlabel="Time (s)",
    ylabel="Amplitude",
    valmin=-10,
    step=2,
    valmax=10,
    axis_size=700
)
# You can now add plots to the `ax` object
lines!(ax2, -10:0.1:10, sin)

# For a non-square plot, set square_limits=false
fig3, ax3 = create_plot_structure(square_limits=false, ysize=600)
"""
function create_plot_structure(;
    xsize=800,
    ysize=800,
    title="Title",
    subtitle = "",
    titlesize = 24,      
    titlegap = 12,        
    xlabel="X(pc)",
    ylabel="Y(pc)",
    labelsize = 20,
    ticksize = 15,    
    valmin=0,
    step=200,
    valmax=1000,
    tick_length = 7,  
    axis_size = 600,
    square_limits = true 
)
   # 1. Create the figure with the specified size
    fig = Figure(size=(xsize, ysize))
    
  # 2. Create the Axis with titles and labels
   ax = Axis(fig[1, 1],
        title=title,
        subtitle = subtitle,
        titlesize=titlesize,
        titlegap=titlegap,
        yticklabelrotation = π/2,
        
        xlabel=xlabel,
        ylabel=ylabel,
        xlabelsize=labelsize,
        ylabelsize=labelsize,
        
        xticklabelsize=ticksize,
        yticklabelsize=ticksize,
        
        xtickalign = 1,
        ytickalign = 1,
        xticksize = tick_length, 
        yticksize = tick_length,
        
        xticksmirrored = true,  
        yticksmirrored = true,  
        
        topspinevisible = true,    
        rightspinevisible = true,  
        
        xticksvisible = true,
        yticksvisible = true,
        
        xtickwidth=1.5,
        ytickwidth=1.5,
        
        # To keep square
        width      = axis_size,    # square
        height     = axis_size,    # square
        aspect     = DataAspect()  # 1 unit X = 1 unity Y
    )
    
    # 3. Set the axis ticks using the provided or default parameters
    ticks_range = valmin:step:valmax
    ax.xticks = ticks_range
    ax.yticks = ticks_range

    # Define the axis limits to ensure ticks are visible
    # The `limits!` function sets the limits for (min_x, max_x, min_y, max_y)
    limits!(ax, valmin, valmax, valmin, valmax)

    # 4. Return the objects for subsequent use
    return fig, ax
end

# ==============================================================================
#
#  get_element_label(atom::Int) -> String
#
# ==============================================================================

"""
    get_element_label(atom::Int) -> String

Returns the formatted electron-density label associated with a given
atomic number. The labels follow the convention:

    "log n_e(Element)/A(Element) [cm^{-3}]"

Only a predefined set of elements is supported. If an atomic number is
not present in the internal lookup table, the function returns `"Unknown"`.

# Arguments
- `atom::Int`: The atomic number of the element (e.g., 1 for H, 6 for C).

# Supported Elements
- `1`  → Hydrogen (H)
- `2`  → Helium (He)
- `6`  → Carbon (C)
- `7`  → Nitrogen (N)
- `8`  → Oxygen (O)
- `10` → Neon (Ne)
- `12` → Magnesium (Mg)
- `14` → Silicon (Si)
- `16` → Sulfur (S)
- `26` → Iron (Fe)

# Returns
- A `String` containing the standardized label (e.g. `"log n_e(O)/A(O) [cm^{-3}]"`),
  or `"Unknown"` if the atomic number is not defined in the lookup table.

# Example
```julia
julia> get_element_label(8)
"log n_e(O)/A(O) [cm^{-3}]"

julia> get_element_label(20)
"Unknown"
"""

function get_element_label(atom::Int)::String
    labels = Dict(
        1 => "log n_e(H)/A(H) [cm^{-3}]",
        2 => "log n_e(He)/A(He) [cm^{-3}]",
        6 => "log n_e(C)/A(C) [cm^{-3}]",
        7 => "log n_e(N)/A(N) [cm^{-3}]",
        8 => "log n_e(O)/A(O) [cm^{-3}]",
        10 => "log n_e(Ne)/A(Ne) [cm^{-3}]",
        12 => "log n_e(Mg)/A(Mg) [cm^{-3}]",
        14 => "log n_e(Si)/A(Si) [cm^{-3}]",
        16 => "log n_e(S)/A(S) [cm^{-3}]",
        26 => "log n_e(Fe)/A(Fe) [cm^{-3}]"
    )
    return get(labels, atom, "Unknown")
end

# ==============================================================================
#
#  Function to select the color palette (equivalent to the palett subroutine)
#
# ==============================================================================
"""
    get_palette(type::Int)

Selects a predefined color palette based on an integer type.

# Arguments
- `type::Int`: The integer code for the desired palette.

# Returns
- `Symbol` or `Vector{Symbol}`: The selected color palette. If the type is not recognized, it returns `:rainbow` and issues a warning.

# Palettes
- `1`: gray scale (`:grays`)
- `2`: rainbow (default) (`:rainbow`)
- `3`: heat (`:thermal`)
- `4`: weird IRAF (`:haline`)
- `5`: AIPS (`:viridis`)
- `6`: PGPLOT (`:plasma`)
- `7`: Saoimage A scale (`:inferno`)
- `8`: Saoimage BB scale (`:magma`)
- `9`: Saoimage HE scale (`:cividis`)
- `10`: Saoimage I8 scale (`:jet`)
- `11`: DS scale (`:turbo`)
- `12`: Cyclic scale (`:hsv`)
- `13`: Cambridge LUT (`[:blue, :green, :red, :white]`)
- `14`: Color spectrum LUT (`[:blue, :cyan, :green, :yellow, :red, :magenta, :white]`)
- `15`: Custom scale (`[:white, :blue, :cyan, :yellow, :red, :black]`)
"""
function get_palette(type::Int)
    # Predefined palettes equivalent to Fortran ones
    if type == 1  # gray scale
        return :grays
    elseif type == 2  # rainbow (default)
        return :rainbow
    elseif type == 3  # heat
        return :thermal
    elseif type == 4  # weird IRAF
        return :haline
    elseif type == 5  # AIPS
        return :viridis
    elseif type == 6  # PGPLOT
        return :plasma
    elseif type == 7  # Saoimage A scale
        return :inferno
    elseif type == 8  # Saoimage BB scale
        return :magma
    elseif type == 9  # Saoimage HE scale
        return :cividis
    elseif type == 10  # Saoimage I8 scale
        return :jet
    elseif type == 11  # DS scale
        return :turbo
    elseif type == 12  # Cyclic scale
        return :hsv
    elseif type == 13  # Cambridge LUT
        return [:blue, :green, :red, :white]
    elseif type == 14  # Color spectrum LUT
        return [:blue, :cyan, :green, :yellow, :red, :magenta, :white]
    elseif type == 15
        return [:white, :blue, :cyan, :yellow, :red, :black]
    else
        @warn "Unrecognized palette, using rainbow as default"
        return :rainbow
    end
end

# ==============================================================================
#
#  Function to select the plot label (equivalent to the label subroutine)
#
# ==============================================================================
"""
    get_label(variavel::String, logs::Bool, atom::Int, ion::String)

Converts the Fortran code nomenclatures into LaTeX strings,
ready to be used for Makie plots.

# Arguments
- `variavel::String`: The name of the variable (e.g., "den", "tem").
- `logs::Bool`: `true` if the scale is logarithmic.
- `atom::Int`: The atomic number (for variables like "elez").
- `ion::String`: The ion name (for ratio variables like "NoO").

# Returns
- A `LaTeXString` object with the formatted label.
"""
function get_label(variavel::String, logs::Bool, atom::Int, ion::String)::LaTeXString
    label_str = ""

    if variavel == "ent"
        label_str = logs ? "log s [\$\\text{erg cm}^{-3}\\text{ K}^{-1}\$]" : "\$s [\\text{erg cm}^{-3}\\text{ K}^{-1}\$]"
    elseif variavel == "dto"
        label_str = "log N(H)"
    elseif variavel == "den"
        label_str = logs ? "log n [\$\\text{cm}^{-3}\$]" : "\$n [\\text{cm}^{-3}\$]"
    elseif variavel in ("tem", "tec")
        label_str = logs ? "log T [\$\\text{K}\$]" : "\$T [\\text{K}\$]"
    elseif variavel == "pok"
        label_str = logs ? "log P/k [\$\\text{cm}^{-3}\\text{ K}\$]" : "\$P/k [\\text{cm}^{-3}\\text{ K}\$]"
    elseif variavel == "pre"
        label_str = logs ? "log P\$_\\text{th}\$ [\$\\text{dyne cm}^{-2}\$]" : "\$P_\\text{th} [\\text{dyne cm}^{-2}\$]"
    elseif variavel == "ram"
        label_str = logs ? "log P\$_\\text{ram}\$ [\$\\text{dyne cm}^{-2}\$]" : "\$P_\\text{ram} [\\text{dyne cm}^{-2}\$]"
    elseif variavel == "rok"
        label_str = logs ? "log P\$_\\text{ram}\$/k [\$\\text{K cm}^{-3}\$]" : "\$P_\\text{ram}/k [\\text{K cm}^{-3}\$]"
    elseif variavel == "pmag"
        label_str = logs ? "log P\$_\\text{mag}\$ [\$\\text{dyne cm}^{-2}\$]" : "\$P_\\text{mag} [\\text{dyne cm}^{-2}\$]"
    elseif variavel in ("bxz", "bxy")
        label_str = logs ? "log B [\$\\mu\\text{G}\$]" : "\$B [\\mu\\text{G}\$]"
    elseif variavel == "val"
        label_str = logs ? "log V\$_\\text{A}\$ [\$\\text{km s}^{-1}\$]" : "\$V_\\text{A} [\\text{km s}^{-1}\$]"
    elseif variavel == "machb"
        label_str = logs ? "log M\$_\\text{A}\$" : "\$M_\\text{A}\$"
    elseif variavel == "mach"
        label_str = logs ? "log v/c\$_\\text{s}\$" : "\$v/c_\\text{s}\$"
    elseif variavel == "beta"
        label_str = logs ? "log \$\\beta\$" : "\$\\beta\$"
    elseif variavel in ("co1", "co2", "co3")
        label_str = ""
    elseif variavel == "diB"
        label_str = logs ? "log div B" : "div B"
    elseif variavel == "diV"
        label_str = logs ? "log div v" : "div v"
    elseif variavel == "rot"
        label_str = logs ? "log rot v" : "rot v"
    elseif variavel == "elez"
        if atom == 1; label_str = "log n\$_\\text{e}\$(H)/A(H) [\$\\text{cm}^{-3}\$]"
        elseif atom == 2; label_str = "log n\$_\\text{e}\$(He)/A(He) [\$\\text{cm}^{-3}\$]"
        elseif atom == 6; label_str = "log n\$_\\text{e}\$(C)/A(C) [\$\\text{cm}^{-3}\$]"
        elseif atom == 7; label_str = "log n\$_\\text{e}\$(N)/A(N) [\$\\text{cm}^{-3}\$]"
        elseif atom == 8; label_str = "log n\$_\\text{e}\$(O)/A(O) [\$\\text{cm}^{-3}\$]"
        elseif atom == 10; label_str = "log n\$_\\text{e}\$(Ne)/A(Ne) [\$\\text{cm}^{-3}\$]"
        elseif atom == 12; label_str = "log n\$_\\text{e}\$(Mg)/A(Mg) [\$\\text{cm}^{-3}\$]"
        elseif atom == 14; label_str = "log n\$_\\text{e}\$(Si)/A(Si) [\$\\text{cm}^{-3}\$]"
        elseif atom == 16; label_str = "log n\$_\\text{e}\$(S)/A(S) [\$\\text{cm}^{-3}\$]"
        elseif atom == 26; label_str = "log n\$_\\text{e}\$(Fe)/A(Fe) [\$\\text{cm}^{-3}\$]"
        else; label_str = "Unknown"
        end
    elseif variavel == "ele"
        label_str = logs ? "log n\$_\\text{e}\$ [\$\\text{cm}^{-3}\$]" : "\$n_\\text{e} [\\text{cm}^{-3}\$]"
    elseif variavel in ("CoO", "NoO")
        label_str = ion == "NoO" ? "log n(NV)/n(OVI)" : "log n(CIV)/n(OVI)"
    elseif variavel in ("AoO", "AoH")
        label_str = ion == "AoO" ? "log n(ArI)/n(OI)" : "log n(ArI)/n(HI)"
    else
        label_str = "Unknown"
    end
  return LaTeXString(label_str)
end

# ==============================================================================
#
#  Function to add the color scale (equivalent to the escala subroutine)
#
# ==============================================================================
"""
    setup_colorbar!(fig::Figure, setmin::Real, setmax::Real; kwargs...)

Adds a colorbar (color scale) to a Makie Figure, automatically determining the
label based on the variable and its units, and allowing flexible positioning.

# Arguments
- `fig::Figure`: The Makie Figure object to which the colorbar will be added.
- `setmin::Real`: The minimum value for the color scale limits.
- `setmax::Real`: The maximum value for the color scale limits.
- `side::Symbol = :right`: Position relative to the main plot area (`:right`, `:left`, `:top`, `:bottom`).
- `grid_position::Union{Nothing,Tuple{Int,Int}} = nothing`: Specific grid position (row, column) if `side` is not enough. If set, `side` only determines orientation.
- `labelsize = 18`: Font size for the colorbar label.
- `colormap = :viridis`: The color map to use for the colorbar.
- `logs::Bool = false`: Whether the scale is logarithmic (used for label generation, though Makie handles the visual scale).
- `front::Bool = false`: (Unused in the current implementation, likely for future compatibility).
- `variavel::String = "den"`: The variable name to determine the correct LaTeX label (e.g., "den", "tem").
- `atom::Int = 1`: The atomic number, used for specific variable labels like "elez".
- `labelion::String = ""`: An optional string to override the auto-generated label.
- `width::Real = 25`: Pixel width of the colorbar.
- `tickalign::Real = 1`: Alignment of ticks (0 = outside, 1 = inside, 0.5 = centered).

# Returns
- `Colorbar`: The created Makie Colorbar object.
"""
function setup_colorbar!(fig::Figure,
               setmin::Real,
               setmax::Real;
               side::Symbol = :right, # :right, :left, :top, :bottom
               grid_position::Union{Nothing,Tuple{Int,Int}} = nothing,
               labelsize = 24,     #28
               ticklabelsize = 14, #18 #15
               colormap = :viridis,
               logs::Bool = false,
               front::Bool = false,
               variavel::String = "den",
               atom::Int = 1,
               labelion::String = "")

     # --- Find Label ---
     # label = generate_label("elez"; atom=8)
   if isempty(labelion)
       label = get_label(variavel, logs, atom, "H+")
   else
        label = labelion
   end
     
     # --- Define Position and Orientation ---
    pos_map = Dict(
        :right   => ((1, 2), true),  # vertical on the right
        :left    => ((1, 0), true),  # vertical on the left
        :top     => ((0, 1), false), # horizontal above
        :bottom  => ((2, 1), false)  # horizontal below
    )

    if isnothing(grid_position)
        pos, vertical = pos_map[side]
    else
        pos = grid_position
        vertical = side in (:right, :left) # infer from the choice
    end
    
 # --- Int Ticks to setmin..setmax ---
    tmin = ceil(Int, setmin)
    tmax = floor(Int, setmax)
   
    step_minor = 0.125 #
    positions  = collect(range(tmin, tmax; step=step_minor)) |> float

    labels = map(positions) do x
        isapprox(x, round(x); atol=1e-9) ? string(Int(round(x))) : ""
    end

    # --- Create colorbar ---
    cbar = Colorbar(fig[pos...],
        limits = (setmin, setmax),
        colormap = colormap,
        vertical = vertical,
        label = label, 
        ticklabelrotation = π/2, # rotate
        
         ticksvisible = true,
        
        topspinevisible = true,
        bottomspinevisible = true,
        
        leftspinevisible = true,
        rightspinevisible = true,
        
        ticks = (positions, labels), 
        labelsize = labelsize,
        width = 25,    # colorbar with
        tickalign = 1, #  0 (default); 1 (inside);  0.5 (center)
    )
    cbar.ticksvisible = true
    return cbar
end

# ==============================================================================
#
#  add_copyright(fig_or_ax; kwargs...)
#
# ==============================================================================
"""
    add_copyright(fig_or_ax; kwargs...)

Adds a copyright notice or arbitrary text to a Makie Axis object at a relative position.

# Arguments
- `fig_or_ax`: The Makie `Figure` or `Axis` object. Currently only supports `Axis`.
- `text = L"\$\\copyright\$ TUE 2025"`: The text to display. Uses `L"..."` for LaTeX formatting.
- `x_percent::Real = 5`: Horizontal position as a percentage from the left edge (0-100).
- `y_percent::Real = 5`: Vertical position as a percentage from the bottom edge (0-100).
- `align = (:left, :bottom)`: Text alignment relative to the calculated position.
- `fontsize = 12`: Font size of the text.
- `color = :gray`: Color of the text.
- `kwargs...`: Additional keyword arguments passed to Makie's `text!` function.

# Behavior
- Calculates the absolute position within the Axis limits based on the percentage values.
- **Currently only supports `Axis`**.

# Throws
- `error`: If `fig_or_ax` is a `Figure` (as only `Axis` is currently supported by the internal logic).
"""
function add_copyright(fig_or_ax;
    text = L"$\copyright$ TUE 2025",
    x_percent::Real = 5,
    y_percent::Real = 5,
    align = (:left, :bottom),
    fontsize = 12,
    color = :gray,
    kwargs...)
    
   if fig_or_ax isa Axis
        ax = fig_or_ax
        # Get final plot limits safely
        lims = ax.finallimits[]
        xmin = lims.origin[1]
        xmax = lims.origin[1] + lims.widths[1]
        ymin = lims.origin[2]
        ymax = lims.origin[2] + lims.widths[2]
        # Calculate positions
        x_pos = xmin + (x_percent/100) * (xmax - xmin)
        y_pos = ymin + (y_percent/100) * (ymax - ymin)
        # Add text
        text!(ax, text,
              position = Point2f(x_pos, y_pos),
              align = align,
              fontsize = fontsize,
              color = color,
              kwargs...)
    else
        error("Currently only supports Axis. For Figure, use Label directly.")
    end
end

# ==============================================================================
#
#  Smart text annotation function for Makie plots with flexible positioning options.
#
# ==============================================================================
"""
    add_text_at(ax, (x, y)::NTuple{2, Any}, texto; kwargs...)

    Smart text annotation function for Makie plots with flexible positioning options.
    
    # Arguments
    - `ax`: The Axis object where the text will be added
    - `x`: X-coordinate position (interpretation depends on `is_percentage`)
    - `y`: Y-coordinate position (interpretation depends on `is_percentage`)
    - `texto`: Text string to display
    
    # Keyword Arguments
    - `align`: Text alignment tuple (horizontal, vertical). Default: (:center, :center)
    - `fontsize`: Font size of the text. Default: 12
    - `color`: Color of text and marker. Default: :black
    - `is_percentage`: If true, x and y are interpreted as relative positions (0-1).
                       If false, x and y are interpreted as absolute coordinates. Default: true
    - `marker`: Symbol specifying marker type (e.g., :circle, :cross). If nothing, no marker is added. Default: nothing
    - `offset`: Tuple (dx, dy) for text offset from the calculated position. Default: (0.0, 0.0)
    - `marker_size`: Size of the marker. Default: 10
    - `kwargs...`: Additional keyword arguments passed to both text! and scatter! functions
    
    # Returns
    - Named tuple (x, y) with the final calculated coordinates where text was placed
    
    # Examples
    ```julia
    # Add text at 50% width, 75% height of plot area
    add_text_at(ax, (0.5, 0.75), "Center Text")
    
    # Add text with marker at absolute coordinates
    add_text_at(ax, (5, 3), "Point", is_percentage=false, marker=:circle)
    
    # Add text with offset and custom styling
    add_text_at(ax, (0.3, 0.4), "Offset Text", offset=(0.1, -0.05), color=:red, fontsize=14)
    ```
    """

 function add_text_at(fig, ax, (x, y)::NTuple{2,Any}, text;
    align = (:center, :center),
    fontsize = 18,
    color = :black,
    is_percentage = true,
    marker = nothing,
    offset = (0.0, 0.0),
    marker_size = 10,
    space = :axis,
    kwargs...)

     dx, dy = offset isa Number ? (offset, offset) :
             offset isa Tuple  ? offset :
             error("`offset` deve ser Number ou Tuple de 2 elementos; recebido $(typeof(offset))")
    
    if space == :axis
        lims = ax.limits[]
        
        if lims isa Tuple && length(lims) == 4
                    x_min, x_max, y_min, y_max = lims
        elseif lims isa Tuple && length(lims) == 2 && all(l -> l isa Tuple && length(l) == 2, lims)
                    (x_min, x_max), (y_min, y_max) = lims
        else
                    error("Formato inesperado de ax.limits[]: $(lims)")
    end

        if is_percentage
            x_pos = x_min + x * (x_max - x_min)
            y_pos = y_min + y * (y_max - y_min)
        else
            x_pos = x
            y_pos = y
        end

        final_x = x_pos + dx
        final_y = y_pos + dy

        if !isnothing(marker)
            scatter!(ax, [x_pos], [y_pos];
                marker = marker, markersize = marker_size, color = color, kwargs...)
        end

        text!(ax, Point2f(final_x, final_y);
            text = string(text), align = align, fontsize = fontsize,
            color = color, kwargs...)

        return (final_x, final_y)

    elseif space == :figure
        final_pos = (x + dx, y + dy)

        text!(fig.scene, text;
            position = final_pos,
            space = :relative,
            align = align,
            fontsize = fontsize,
            color = color,
            kwargs...)
       # return (x = final_pos[1], y = final_pos[2])
       return final_pos
    end
end   
    
# ==============================================================================
#
#   pgmtext_in
#
# ==============================================================================

function pgmtext_in(fig, side::String, padding::Real, x::Real, y::Real, text::String; fontsize=12)
    pos = lowercase(side[1]) == 'b' ? Bottom() :
          lowercase(side[1]) == 'l' ? Left() :
          lowercase(side[1]) == 't' ? Top() : error("Side not valid: $side")

    rot = side == "L" ? π/2 : 0
    halign = (side == "B" || side == "T") ? :center : :right
    valign = (side == "L") ? :center : :top

    Label(fig[1, 1, pos],
          text = text,
          rotation = rot,
          padding = (10, 10, 10, padding * 10),
          halign = halign,
          valign = valign,
          fontsize = fontsize)
end

# ==============================================================================
#
#  write_!
#
# ==============================================================================
function write_!(fig, xlabel::String, ylabel::String, title::String;
                   variavel::String, ion::String,
                   top::Bool = true,
                   writetime::Bool = false,
                   front::Bool = false,
                   localizar::Bool = false,
                   _local::String = "",
                   resolution::String = "",
                   timeid::Float64 = 0.0,
                   unittime::String = "")

    titleion = ""
    title1 = ""
    if variavel in ["CoO", "NoO"]
        titleion = ion == "NoO" ? "n(NV)/n(OVI)" : "n(CIV)/n(OVI)"
    elseif variavel in ["AoO", "AoH"]
        titleion = ion == "AoO" ? "[ArI/OI]" : "[ArI/HI]"
    elseif variavel == "dto"
        title1 = "Column Density"
    else
        title1 = title
    end

    if variavel in ["hyd", "hel", "car", "nit", "oxy", "neo", "mgn", "sil", "sul", "arg", "iro",
                    "CoO", "NoO", "AoO", "AoH"]
        if top
            pgmtext_in(fig, "B", 2.7, 0.5, 0.5, xlabel)
            pgmtext_in(fig, "L", 2.2, 0.5, 0.5, ylabel)
            pgmtext_in(fig, "T", 1.3, 0.5, 0.5, titleion)
            if !isempty(resolution)
                pgmtext_in(fig, "B", 2.7, 0.0, 0.0, resolution)
            end
        else
            pglabel!(fig, xlabel, ylabel, titleion)
        end
    elseif variavel == "ele"
        if top
            pgmtext_in(fig, "B", 2.7, 0.5, 0.5, xlabel)
            pgmtext_in(fig, "L", 2.2, 0.5, 0.5, ylabel)
            pgmtext_in(fig, "T", 1.3, 0.5, 0.5, title1)
        else
            pglabel!(fig, xlabel, ylabel, title1)
        end
    else
        if top
            pgmtext_in(fig, "B", 2.7, 0.5, 0.5, xlabel)
            pgmtext_in(fig, "L", 2.2, 0.5, 0.5, ylabel)
            pgmtext_in(fig, "T", 1.3, 0.5, 0.5, title1)
        else
            pglabel!(fig, xlabel, ylabel, title1)
        end
    end

    # Time
    if writetime
        timetit = @sprintf("%.2f %s", timeid, unittime)
        if front
            pgmtext_in(fig, "T", 0.5, 0.9, 0.3, timetit; fontsize=14)
        else
            pgmtext_in(fig, "T", 1.0, 0.95, 0.2, timetit)
        end
    end

    # Localização extra opcional
    if localizar && !isempty(_local)
        println("local = ", _local)
        pgmtext_in(fig, "B", 3.0, 0.0, 0.0, _local)
    end

    return fig
end

# ==============================================================================
#
#  pglabel
#
# ==============================================================================
function pglabel!(fig, xlabel::String, ylabel::String, title::String)
    pgmtext_in(fig, "B", 2.7, 0.5, 0.5, xlabel)
    pgmtext_in(fig, "L", 2.2, 0.5, 0.5, ylabel)
    pgmtext_in(fig, "T", 1.3, 0.5, 0.5, title)
end

# ==============================================================================
#
#  add_labels!
#
# ==============================================================================
"""
    add_labels!(ax::Axis; xlabel::Union{String, Nothing}=nothing,
                             ylabel::Union{String, Nothing}=nothing,
                             title::Union{String, Nothing}=nothing,
                             colorbar::Union{Colorbar, Nothing}=nothing,
                             colorbar_label::Union{String, Nothing}=nothing)

Utility function to add labels and title to an existing plot.
Optionally updates the label of an associated Colorbar.
"""
function add_labels!(ax::Axis; 
                     xlabel::Union{String, Nothing}=nothing,
                     ylabel::Union{String, Nothing}=nothing,
                     title::Union{String, Nothing}=nothing,
                     colorbar::Union{Colorbar, Nothing}=nothing,
                     colorbar_label::Union{String, Nothing}=nothing)
    
    if xlabel !== nothing
        ax.xlabel = xlabel
    end
    if ylabel !== nothing
        ax.ylabel = ylabel
    end
    if title !== nothing
        ax.title = title
    end
    if colorbar !== nothing && colorbar_label !== nothing
        colorbar.label = colorbar_label
    end
end

# ==============================================================================
#
#  Generates plot files in multiple formats (PDF, PNG, JPG) with the option to include a timestamp in # the name.
#
# ==============================================================================
"""
    writeplot(ref::Int; kwargs...)

Generates plot files in multiple formats (PDF, PNG, JPG) with the option to include a timestamp in the name.

# Arguments
- `ref::Int`: Reference number
- `lmap::Bool`: If true, generates map files
- `lpdf::Bool`: If true, generates PDF files
- `color::Bool`: Use colors (for maps)
- `cont::Bool`: Use contours (for maps)
- `grey::Bool`: Use grayscale (for maps)
- `side/front/top::Bool`: Viewing direction
- `variavel::String`: Type of variable plotted
- `ion::String`: Specific ion (for certain plot types)
- `filenum::Int`: File number
- `atom::Int`: Atomic number (for specific plots)
- `formats::Vector{String}`: Output formats (["pdf", "png", "jpg"])
- `add_datetime::Bool`: If true, adds a timestamp to the name (default=true)
- `datetime_format::String`: Date/time format (default="yyyymmdd_HHMMSS")

# Returns
- `Vector{String}`: List of generated files
"""
function writeplot(ref::Int; 
               lmap::Union{Bool,Nothing}=nothing, 
               lpdf::Union{Bool,Nothing}=nothing,
               color::Bool=false, 
               cont::Bool=false, 
               grey::Bool=false,
               side::Bool=false, 
               front::Bool=false, 
               top::Bool=false,
               variavel::String="", 
               ion::String="", 
               filenum::Int=0,
               atom::Int=0,
               formats::Vector{String}=["pdf"],
               add_datetime::Bool=true,
               datetime_format::String="yyyymmdd_HHMMSS")
    
    # Variable initialization
    plotfile = ""
    view = ""
    graf1 = ""
    generated_files = String[]
    
    # Generate timestamp if needed
    timestamp = add_datetime ? "_" * Dates.format(now(), datetime_format) : ""

    # Part for map generation (lmap)
    if lmap !== nothing && lmap
        # Determine the type of plot
        if color
            graf1 = cont ? "ctcl" : "colo"
        elseif grey
            graf1 = cont ? "ctgr" : "grey"
        elseif cont
            graf1 = "cont"
        end

        # Determine the view
        if side
            view = "sid"
        elseif front
            view = "frt"
        elseif top
            view = "top"
        end

        if cont || color || grey
            # Generate the base file name
            if variavel in ["CoO", "NoO", "HoA", "OoA"]
                plotfile = @sprintf("%3s%04d%4s%03d-%3s", ion, filenum, graf1, ref, view)
            elseif variavel in ["hyd", "car", "nit", "oxy", "sul"]
                plotfile = @sprintf("%4s%04d%4s%03d-%3s", ion, filenum, graf1, ref, view)
            elseif variavel in ["hel", "neo", "mgn", "sil", "arg", "iro"]
                plotfile = @sprintf("%5s%04d%4s%03d-%3s", ion, filenum, graf1, ref, view)
            elseif variavel == "elez"
                plotfile = @sprintf("elez_%02d-%04d%4s%03d-%3s", atom, filenum, graf1, ref, view)
            else
                plotfile = @sprintf("%s%04d%4s%03d-%3s", variavel, filenum, graf1, ref, view)
            end
            
            # Remove extra spaces and add timestamp
            plotfile = replace(plotfile, " " => "") * timestamp
        end
    end

    # Part for PDF generation (lpdf)
    if lpdf !== nothing && lpdf
        if variavel == "elez" && atom in [1, 2, 6, 7, 8, 10, 12, 14, 16, 26]
            plotfile = @sprintf("elez_%02d-%06d-%03d", atom, filenum, ref)
        else
            # General pattern for PDFs
            prefix = startswith(variavel, "ent") ? "entr" : 
                     startswith(variavel, "mach") ? "mach" : "" * variavel*"_"
            plotfile = @sprintf("%s%06d-%03d", prefix, filenum, ref)
        end
        plotfile = plotfile * timestamp
    end

    # Generate the files in the requested formats
    if !isempty(plotfile)
        for format in lowercase.(formats)
            filename = plotfile * "." * format
            try
                # Simulation of file generation - replace with your actual logic:
                # Example: save(filename, plot_object)  
                println("[SUCCESS] File generated: ", filename)  # Simulation
                push!(generated_files, filename)
            catch e
                @error "[ERROR] Failed to generate file" filename exception=e
            end
        end
    end

    return generated_files
end

# ==============================================================================
#
#  The Makie figure object to be saved or displayed. 
#
# ==============================================================================
"""
    save_or_display(fig::Figure, list_of_files::Vector{String};
                    sav::Bool,
                    disp::Bool,
                    output_path::String)

Save and/or display a Makie `Figure`.

# Arguments
- `fig::Figure`: The Makie figure object to be saved or displayed.
- `list_of_files::Vector{String}`: List of filenames (with extensions) to save the figure as.
- `sav::Bool`: If `true`, saves the figure to all files listed in `list_of_files` inside `output_path`.
- `disp::Bool`: If `true`, displays the figure in the active display backend.
- `output_path::String`: Directory path where files will be saved (created if it doesn't exist).

# Notes
- `list_of_files` must not be empty; an error is thrown otherwise.
- The function does not overwrite prevention checks — existing files will be replaced.
"""
function save_or_display(
    fig::Figure, list_of_files::Vector{String};
    sav::Bool,
    disp::Bool,
    output_path::String
)
    # Ensure the list of files is not empty
    isempty(list_of_files) && error("list_of_files cannot be empty.")

    # Save the figure if requested
    if sav
        mkpath(output_path)  # Create the directory if it does not exist
        for file in list_of_files
            path = joinpath(output_path, file)
            save(path, fig; size = (800,800))   # Save figure to the given file path
            @info "Figure saved: $path"
        end
    end

    # Display the figure if requested
    if disp
        display(fig)
    end
end

# ==============================================================================
#
#  Plot a heatmap of the base-10 logarithm of a selected Z-plane from a 3D data cube.
#
# ==============================================================================
"""
    plot_heatmap_log3(
        data::Array{Float64, 3},
        X_grid::Vector{Float64},
        Y_grid::Vector{Float64}
    ) -> Nothing

Plot a heatmap of the base-10 logarithm of a selected Z-plane from a 3D data cube.

This function:
1. Selects the first Z slice (`z_index = 1`) from the 3D array `data`.
2. Scales the 2D slice by a density scale factor (`denscale = 1.67e-24`), then applies `log10`.
3. Builds a colormap using `get_palette(15)` and `cgrad`.
4. Renders the heatmap using the provided X/Y grids.
5. Adds a right-side color scale, a watermark, and a marker at a fixed `max_point`.
6. Writes the plot to `pdf` and `png` and saves/displays it to a target output path.

# Arguments
- `data::Array{Float64,3}`: 3D array of values; the heatmap is generated from `data[:, :, 1]`.
- `X_grid::Vector{Float64}`: X-axis grid coordinates corresponding to columns of the selected 2D slice.
- `Y_grid::Vector{Float64}`: Y-axis grid coordinates corresponding to rows of the selected 2D slice.

# Notes
- The function uses a fixed Z-plane (`z_index = 1`). If you need another plane, consider parametrizing it.
- The color palette comes from `get_palette(15)` and is converted to a gradient via `cgrad`.
- Output files are created via `writeplot(...)` and saved with `save_or_display(...)`.
- Several utility functions must exist in scope: `get_palette`, `cgrad`, `statistics_data`, `create_plot_structure`,
  `heatmap!`, `setup_colorbar!`, `add_copyright`, `add_text_at`, `writeplot`, `save_or_display`.

# Side Effects
- Writes plot files (`pdf` and `png`) and displays the figure depending on `save_or_display` settings.
- Prints warnings/notes depending on downstream utilities (if any).

# Returns
- `Nothing`. The function operates via side effects (file generation and display).
"""
function plot_heatmap_log3(data::Array{Float64, 3}, X_grid::Vector{Float64}, Y_grid::Vector{Float64})
    # 1) Prepare data: select a Z-plane (first plane)
    z_index = 1
    dados_2d = data[:, :, z_index]

    # 2) Build the colormap from a predefined palette (type 15)
    my_pallete_color = cgrad(get_palette(15))

    # 3) Scale by density and compute log10
    denscale = 1.67e-24
    dados_2d ./= denscale
    dados_2d_log = log10.(dados_2d)

    # 4) Optional statistics on the raw (scaled) 2D data
    teste = statistics_data(dados_2d)
    # println(teste)

    # 5) Create figure and axis
    fig, ax = create_plot_structure(xsize = 800, ysize = 600)

    # 6) Render the heatmap
    heatmap!(ax, X_grid, Y_grid, dados_2d_log, colormap = my_pallete_color)

    # 7) Add color scale on the right
    setup_colorbar!(fig, -4, 1.6; side = :right, colormap = my_pallete_color, variavel = "tem")

    # 8) Add a small watermark
    add_copyright(ax; text = "TL © 2024", x_percent = 10, y_percent = 5, color = :black, fontsize = 14)

    # 9) Find max value (already computed); here a fixed point is used for marking
    max_val, max_idx = findmax(dados_2d)
    # max_point = (data[max_idx], max_val)  # Example of how to build a point from indices
    # println(max_point)

    max_point = (500, 500)
    add_text_at(ax; marker = :circle, point = max_point, color = :red)

    # 10) Generate output file names for oxygen element (8) with compact date format
    files = writeplot(
        42;
        lpdf = true,
        variavel = "tem",
        atom = 8,
        filenum = 3000,
        datetime_format = "ddmmyy_HHMM",
        formats = ["pdf", "png"]
    )

    # 11) Save and/or display
    save_or_display(
        fig, files;
        sav = true,
        disp = true,
        output_path = "./data/output/mapas/teste" #       output_path = "./data/output/mapas/teste"
    )
end

# ==============================================================================
#
#  Extracts a cropped region from a 2D data slice based on optional coordinate bounds.
#
# ==============================================================================
"""
    crop_slice(slice::AbstractMatrix, xgrid::AbstractVector, ygrid::AbstractVector;
               xmin=nothing, xmax=nothing, ymin=nothing, ymax=nothing)

Extracts a cropped region from a 2D data slice based on optional coordinate bounds.

# Arguments
- `slice::AbstractMatrix`: 2D matrix of data values.
- `xgrid::AbstractVector`: X-axis coordinate grid.
- `ygrid::AbstractVector`: Y-axis coordinate grid.
- `xmin`: Minimum X value to include (optional).
- `xmax`: Maximum X value to include (optional).
- `ymin`: Minimum Y value to include (optional).
- `ymax`: Maximum Y value to include (optional).

# Returns
- `xsel`: Selected X coordinates within bounds.
- `ysel`: Selected Y coordinates within bounds.
- `cropped_slice`: Submatrix of `slice` corresponding to selected coordinates.
"""

function crop_slice(slice::AbstractMatrix, xgrid::AbstractVector, ygrid::AbstractVector;
                    xmin=nothing, xmax=nothing, ymin=nothing, ymax=nothing)

    # Select X coordinates within bounds if provided
    xsel = isnothing(xmin) ? xgrid : xgrid[(xgrid .>= xmin) .& (xgrid .<= xmax)]

    # Select Y coordinates within bounds if provided
    ysel = isnothing(ymin) ? ygrid : ygrid[(ygrid .>= ymin) .& (ygrid .<= ymax)]

    # Create masks to extract the corresponding slice region
    xmask = in.(xgrid, Ref(xsel))
    ymask = in.(ygrid, Ref(ysel))

    # Return selected coordinates and cropped data
    return xsel, ysel, slice[xmask, ymask]
end

# ==============================================================================
#
#  Render a heatmap for a 2D data slice
#
# ==============================================================================
"""
    plot_heatmap(
        xg::AbstractVector,
        yg::AbstractVector,
        slice::AbstractMatrix,
        var_name::String,
        smin::Float64,
        smax::Float64;
        is_ions::Bool = false,
        kern::Int = 0,
        ionz::Int = 0,
        xlabel::String = "",
        ylabel::String = "",
        title::String = "",
        author::String = "",
        resolution::String = "",
        unittime::String = "",
        filenum::Int = 3000,
        colormap = :viridis,
        min_color = :black,
        max_color = :white,
        colorbar_label::String = "",
        show_stats::Bool = false,
        logscale::Bool = false,
        stats::Union{Nothing, Matrix2DStatistics} = nothing,
        formats::Vector{String} = ["pdf"],
        rasterize_scale::Int = 1,
        save_path::AbstractString = "./data/output/mapas/color",
        stats_save_path::Union{Nothing,AbstractString} = nothing
    ) -> Figure

Render a heatmap for a 2D data slice over grids `xg` and `yg` using Makie, with optional log scaling,
min/max markers, a colorbar, watermark/overlay text, and saving in multiple formats.

# Arguments
- `xg::AbstractVector`, `yg::AbstractVector`: Axis grid coordinates (X for columns, Y for rows).
- `slice::AbstractMatrix`: 2D data matrix to visualize.
- `var_name::String`: Variable name for labeling/saving (overridden in ion mode).
- `smin::Float64`, `smax::Float64`: Colorbar min/max. If both are `0.0` and `logscale == true`,
  they are auto-derived from `log10(minval)` and `log10(maxval)`.

# Keywords
- `is_ions::Bool`: If `true`, ion-specific title/labels are taken from `ionstexto(kern, ionz)`.
- `kern::Int`, `ionz::Int`: Ion kernel and ionization state.
- `xlabel::String`, `ylabel::String`, `title::String`: Axis and title labels (title overridden in ion mode).
- `author::String`, `resolution::String`, `unittime::String`: Watermark and overlay text.
- `filenum::Int`: Index number used to build filenames when exporting the plot.
- `colormap`, `min_color`, `max_color`, `colorbar_label`: Reserved; internally a fixed palette (`get_palette(15)`) is used.
- `show_stats::Bool`: If `true`, shows a small statistics panel below the plot.
- `logscale::Bool`: If `true`, uses the log10‑transformed matrix from `stats.matrix_result`.
- `stats::Union{Nothing, Matrix2DStatistics}`: Precomputed statistics object; if `nothing`, computed automatically.
- `formats::Vector{String}`: Output formats (`["pdf","png","svg"]`).  
  Vector formats (`pdf`/`svg`) activate optional heatmap rasterization.
- `rasterize_scale::Int`: Resolution multiplier for rasterizing only the heatmap layer when exporting vector graphics.
- `save_path::AbstractString`: Directory in which rendered plots are saved.
- `stats_save_path::Union{Nothing, AbstractString}`: Optional directory to write associated statistics files.

# Behavior
1. Computes or uses provided statistics (min/max/mean).
2. Selects between raw data and log-transformed data based on `logscale`.
3. Uses a color gradient constructed from `get_palette(15)` via `cgrad`.
4. Draws the heatmap, marking min/max locations with custom annotations (`add_text_at`).
5. Adds a right‑side color scale using `setup_colorbar!`, respecting ion/non‑ion labeling.
6. Adds watermark and overlay text.
7. Generates filenames through `writeplot`, prepares output folders, and saves/displays.
8. If saving vector formats, optionally rasterizes the heatmap layer using `rasterize_scale`.
9. Saves statistics to `stats_save_path` if provided, otherwise to `save_path`.

# Returns
- `Figure`: The Makie figure for further inspection or composition.

# Dependencies
Requires in scope: `statistics_data`, `Matrix2DStatistics`, `ionstexto`, `create_plot_structure`,
`LaTeXString`, `get_palette`, `cgrad`, `heatmap!`, `setup_colorbar!`, `add_text_at`, `writeplot`,
`save_or_display`, `save_stats_from_writeplot`.
"""

function plot_heatmap(xg::AbstractVector, yg::AbstractVector,
                      slice::AbstractMatrix,
                      var_name::String,
                      smin::Float64, smax::Float64;  
                      is_ions::Bool = false,
                      kern::Int = 0, ionz::Int = 0,
                      xlabel::String = "",
                      ylabel::String = "",
                      title::String = "",
                      author::String = "",
                      resolution::String = "",
                      unittime::String = "",
                      filenum::Int = 3000,
                      # atom::Int = 0
                      colormap = :viridis,
                      min_color = :black,
                      max_color = :white,
                      colorbar_label::String = "",
                      show_stats::Bool = false,
                      logscale::Bool = false,
                      stats::Union{Nothing, Matrix2DStatistics} = nothing,
                      formats::Vector{String} = ["pdf"],     
                      rasterize_scale::Int = 1,  # 1..3: DPI multiplier for rasterized layers
                      save_path::AbstractString = "./figures/mavil2",
                      stats_save_path::Union{Nothing,AbstractString} = nothing    
            )
# --- Detect if output is vector format → activate rasterization ---
    export_vector = any(fmt -> lowercase(fmt) in ("pdf", "svg"), formats)
            
    # Compute statistics if not provided
    stats === nothing && (stats = statistics_data(slice))

    # Min and max values (from the statistics object)
    minval = stats.statistics_data.min_value.value2D
    maxval = stats.statistics_data.max_value.value2D

    # Select plot data and color range depending on log-scale usage
    if logscale
        # When logscale is used, rely on precomputed log matrix from stats
        plotdata = stats.matrix_result
        crange = (log10(minval), log10(maxval))

        # If smin/smax are both zero, derive from data (log10 of min/max)
        if smax == 0.0 && smin == 0.0
            smin = log10(minval)
            smax = log10(maxval)
        end
    else
        plotdata = slice
        crange = (minval, maxval)
    end

    # Define custom colormap (fixed palette type 15)
    my_pallete_color = cgrad(get_palette(15))  # palette for colors

    # Apply ion labels if requested
    if is_ions
        ion_labels = ionstexto(kern, ionz)
        title = ion_labels.titleion
    end

    # Create figure and axis with labels and title
    fig, ax = create_plot_structure(
        xlabel = xlabel, ylabel = ylabel, title = LaTeXString(title)
    )

    # Plot the heatmap
    hm = heatmap!(ax, xg, yg, plotdata;
        colormap = my_pallete_color,
        colorrange = crange,   # rasterize_scale::Int = 1,  # 1..3: DPI multiplier for rasterized layers
        rasterize = export_vector ? rasterize_scale : false # decrease --> low size
    )

    # Extract min/max indices (matrix coordinates) from stats
    min_coord = stats.statistics_data.min_value.index2D   # Point2D(i, j)
    max_coord = stats.statistics_data.max_value.index2D

    # Convert matrix indices -> data coordinates
    # Matrix row (i) maps to Y, matrix column (j) maps to X
    x_min = xg[min_coord.y]   # column -> X
    y_min = yg[min_coord.x]   # row    -> Y
    x_max = xg[max_coord.y]
    y_max = yg[max_coord.x]

#=
 _ = add_text_at(fig, ax, (x_min, y_min), "min=$(round(minval, digits=2))";
    fontsize=14,
    space = :axis,           
    is_percentage = false,
    offset = (0.2, 0.2),
    marker = :circle, marker_size = 14, color = :blue
    )    
    
_ = add_text_at(fig, ax, (x_max, y_max), "max=$(round(maxval, digits=2))";
    fontsize=14,
    space = :axis,           
    is_percentage = false,
    offset = (0.2, 0.2),
    marker = :star5, marker_size = 14, color = :red
  ) 
=#
    # Add colorbar (ion/non-ion variants)
    if is_ions
        setup_colorbar!(fig, smin, smax; side = :right, colormap = my_pallete_color, logs = logscale, labelion = ion_labels.labelion)
    else
        setup_colorbar!(fig, smin, smax; side = :right, colormap = my_pallete_color, logs = logscale, variavel = var_name, atom=kern)
    end

   # Add copyright/watermark
   # add_copyright(ax; text = LaTeXString(author), x_percent = 10, y_percent = 5, color = :black, fontsize = 22)
     _ = add_text_at(fig,ax, (0.15, 0.05), LaTeXString(author); fontsize = 18, is_percentage = true, color = :black)
    
   pos = show_stats ? (0.85, 0.94) : (0.85, 0.91)
    
   _ = add_text_at(fig,ax, pos, LaTeXString(L"\text{300.00  } " * unittime);space = :figure, fontsize = 24, is_percentage = false, color = :black)
    
    # Optionally show statistics panel
   if show_stats
        txt = @sprintf("Statistical Summary\n Min=%.3f | Max=%.3f | Mean=%.3f | Std_dev=%.3f | Variance=%.3f ",
                       minval, maxval, stats.statistics_data.mean, stats.statistics_data.std_dev, stats.statistics_data.variance)
        Label(fig[2, 1], txt; tellwidth = false, halign = :center)
    end
    
    # Configure output files (use the parameterized 'formats')
    files = writeplot(42;
        lpdf = true,
        variavel = var_name,
        atom = kern,
        filenum = filenum,
        datetime_format = "ddmmyy_HHMM",
        formats = formats
    )

    # Save or display the figure
    save_or_display(
        fig, files;
        sav = true,
        disp = true,
       # output_path = subdir
       output_path = save_path  
    )

    # Choose where to write statistics (default: save_path; FAIR: vp.statistics)
    stats_outdir = isnothing(stats_save_path) ? save_path : stats_save_path

    # Export statistics
_ = save_stats_from_writeplot(files, save_path, stats; 
    subfolder_name = "statistics",    # default value
    report_ext = ".txt",              # or ".pdf" if need
    file_index = 1,                    
    sav = true,
    disp = false,
    allow_empty_files = false)

    return fig
end

# ==============================================================================
#
#  Render contour lines for a 2D data slice
#
# ==============================================================================
"""
    plot_contour(
        xg::AbstractVector,
        yg::AbstractVector,
        slice::AbstractMatrix,
        var_name::String,
        smin::Float64,
        smax::Float64;
        is_ions::Bool = false,
        kern::Int = 0,
        ionz::Int = 0,
        xlabel::String = "",
        ylabel::String = "",
        title::String = "",
        author::String = "",
        resolution::String = "",
        unittime::String = "",
        filenum::Int = 3000,
        colormap = :viridis,
        min_color = :black,
        max_color = :white,
        colorbar_label::String = "",
        show_stats::Bool = false,
        logscale::Bool = false,
        stats::Union{Nothing, Matrix2DStatistics} = nothing,
        formats::Vector{String} = ["pdf"],
        rasterize_scale::Int = 1,
        save_path::AbstractString = "./data/output/maps/contour"
    ) -> Figure

Render contour lines for a 2D data slice over grids `xg` and `yg` using Makie,
with optional log scaling, min/max markers, colorbar, labels, and file output.

# Arguments
- `xg::AbstractVector`: X-axis grid coordinates (columns).
- `yg::AbstractVector`: Y-axis grid coordinates (rows).
- `slice::AbstractMatrix`: 2D data matrix to contour.
- `var_name::String`: Variable name for labeling/saving (used when `is_ions == false`).
- `smin::Float64`, `smax::Float64`: Colorbar min/max. If both are `0.0` **and** `logscale == true`,
  they default to `log10(minval)` and `log10(maxval)` derived from `slice`.

# Keywords
- `is_ions::Bool`: If `true`, ion-specific title and colorbar label are taken from `ionstexto(kern, ionz)`.
- `kern::Int`, `ionz::Int`: Kernel and ionization state for ion labels.
- `xlabel::String`, `ylabel::String`: Axis labels.
- `title::String`: Plot title (overridden in ion mode).
- `author::String`: Watermark text at lower-left.
- `resolution::String`, `unittime::String`: Overlay text near the top-right.
- `filenum::Int`: Numeric identifier appended to exported filenames.
- `colormap`, `min_color`, `max_color`, `colorbar_label`: Reserved/unused; fixed palette (`get_palette(15)`) is used.
- `show_stats::Bool`: If `true`, prints a short stats summary below the plot.
- `logscale::Bool`: If `true`, uses `stats.matrix_result` and a log10 color range.
- `stats::Union{Nothing, Matrix2DStatistics}`: Precomputed statistics object; if `nothing`, computed automatically.
- `formats::Vector{String}`: Export formats (`["pdf","png","svg"]`).
  Vector formats trigger Makie rasterization options depending on `rasterize_scale`.
- `rasterize_scale::Int`: Resolution multiplier for rasterized layers when exporting vector graphics.
- `save_path::AbstractString`: Base directory for saving contour plots.

# Behavior
1. Computes or uses provided statistics (min/max/mean).
2. Chooses `plotdata` and `colorrange` depending on `logscale`.
3. Uses a color gradient from `get_palette(15)` via `cgrad`.
4. Renders contour lines.
5. Marks min/max positions using `add_text_at` (with markers and labels).
6. Adds a right-side colorbar via `setup_colorbar!` (ion/non-ion variants).
7. Adds watermark and overlay text (`author`, `resolution`, `unittime`).
8. **Rasterization:**  
   - If `formats` includes vector types (`pdf`, `svg`), Makie may rasterize supported layers.  
   - Contour lines remain vector objects even when heatmap-like layers are rasterized.  
     CairoMakie may warn: *"Contour... is not supported by cairo right now"*.
9. Creates a variable-specific subfolder and exports files using `writeplot` and `save_or_display`.

# Returns
- `Figure`: The Makie figure for further use.

# Dependencies
Requires: `statistics_data`, `Matrix2DStatistics`, `ionstexto`, `create_plot_structure`,
`LaTeXString`, `get_palette`, `cgrad`, `contour!`, `setup_colorbar!`, `add_text_at`,
`writeplot`, `save_or_display`.

# Notes
- If you want to honor the `colormap` keyword, replace the fixed palette (`get_palette(15)`).
"""

function plot_contour(xg::AbstractVector, yg::AbstractVector,
    slice::AbstractMatrix,
    var_name::String,    # filename::String;
    smin::Float64, smax::Float64; 
    is_ions::Bool = false,   
    kern::Int=0, ionz::Int=0, 
    xlabel::String = "",
    ylabel::String = "",
    title::String = "",
    author::String = "",
    resolution::String= "",
    unittime::String= "",
    filenum::Int = 3000,
    colormap = :viridis,
    min_color = :black,
    max_color = :white,
    colorbar_label::String = "",
    show_stats::Bool = false,
    logscale::Bool = false,
    stats::Union{Nothing, Matrix2DStatistics} = nothing,
    formats::Vector{String} = ["pdf"], 
    rasterize_scale::Int = 1,  # 1..3: DPI multiplier for rasterized layers
    save_path::AbstractString = "./data/output/maps/contour" 
)
     # --- Detect if output is vector format → activate rasterization ---  
    export_vector = any(fmt -> lowercase(fmt) in ("pdf", "svg"), formats)
    # Compute statistics if not provided
    stats === nothing && (stats = statistics_data(slice))

    # Min and max values (from the statistics object)
    minval = stats.statistics_data.min_value.value2D
    maxval = stats.statistics_data.max_value.value2D

    # Select plot data and color range depending on log-scale usage
    if logscale
        plotdata = stats.matrix_result
        crange = (log10(minval), log10(maxval))
        # If smin/smax are both zero, auto-derive from log10(min/max)
        if smax == 0.0 && smin == 0.0
            smin = log10(minval)
            smax = log10(maxval)
        end
    else
        plotdata = slice
        crange = (minval, maxval)  
    end

    # Build the colormap (fixed palette type 15)
    my_pallete_color = cgrad(get_palette(15))

    # Apply ion labels if requested
    if is_ions
        ion_labels = ionstexto(kern, ionz)
        title = ion_labels.titleion
    end     

    # Create figure and axis
    fig, ax = create_plot_structure(
        xlabel = xlabel, ylabel = ylabel, title = LaTeXString(title)
    )

    # Render contour plot
    co = contour!(ax, xg, yg, plotdata; colormap = my_pallete_color
    #rasterize = export_vector ? rasterize_scale : false # decrease --> low size
    )

    # Add colorbar (ion/non-ion variants)
    if is_ions
        setup_colorbar!(fig, smin, smax; side = :right, colormap = my_pallete_color, logs = logscale, labelion = ion_labels.labelion )
    else
        setup_colorbar!(fig, smin, smax; side = :right, colormap = my_pallete_color, logs = logscale, variavel = var_name, atom=kern)
    end

    # Add watermark
    _ = add_text_at(fig,ax, (0.15, 0.05), LaTeXString(author); fontsize = 18, is_percentage = true, color = :black)

    # Extract min/max indices (matrix coordinates) from stats
    min_coord = stats.statistics_data.min_value.index2D   # Point2D(i, j)
    max_coord = stats.statistics_data.max_value.index2D

    # Convert matrix indices -> data coordinates
    x_min = xg[min_coord.y]   # column -> X
    y_min = yg[min_coord.x]   # row    -> Y
    x_max = xg[max_coord.y]
    y_max = yg[max_coord.x]

    _ = add_text_at(fig, ax, (x_min, y_min), "min=$(round(minval, digits=2))";fontsize=14,
    space = :axis,is_percentage = false, offset = (0.2, 0.2), marker = :star5, marker_size = 14, color = :red
    )    
    
    _ = add_text_at(fig, ax, (x_max, y_max), "max=$(round(maxval, digits=2))";fontsize=14,
    space = :axis, is_percentage = false, offset = (0.2, 0.2), marker = :star5, marker_size = 14, color = :red
    )
       _ = add_text_at(fig,ax, (0.15, 0.05), LaTeXString(author); fontsize = 18, is_percentage = true, color = :black)
    
    pos = show_stats ? (0.85, 0.94) : (0.85, 0.91)
    
    # Overlay resolution and time near the top-right (relative coords)
   _ = add_text_at(fig,ax, pos, LaTeXString(L"\text{300.00  } " * unittime);space = :figure, fontsize = 24, is_percentage = false, color = :black)
  

    
    # Optionally show a short stats summary
    if show_stats
        txt = @sprintf("min=%.3f, max=%.3f, mean=%.3f", minval, maxval, stats.statistics_data.mean)
        Label(fig[2, 1], txt; tellwidth = false, halign = :left)
    end

    # Configure output files
    files = writeplot(42;
        lpdf = true,
        variavel = var_name,
        atom = kern,
        filenum = filenum,
        datetime_format = "ddmmyy_HHMM",
        formats = formats, #formats = ["png"] #  formats = formats
       
    )
    # Save or display the figure
    save_or_display(
        fig, files;
        sav = true,
        disp = true,
        output_path = save_path 
    )
    return fig
end

# ==============================================================================
#
#  Render a combined heatmap + contour
#
# ==============================================================================

"""
    plot_heat_cont(
        xg::AbstractVector,
        yg::AbstractVector,
        slice::AbstractMatrix,
        var_name::String,
        smin::Float64,
        smax::Float64;
        is_ions::Bool = false,
        kern::Int = 0,
        ionz::Int = 0,
        xlabel::String = "",
        ylabel::String = "",
        title::String = "",
        author::String = "",
        resolution::String = "",
        unittime::String = "",
        filenum::Int = 3000,
        colormap = :viridis,
        min_color = :black,
        max_color = :white,
        colorbar_label::String = "",
        show_stats::Bool = false,
        logscale::Bool = false,
        stats::Union{Nothing, Matrix2DStatistics} = nothing,
        formats::Vector{String} = ["png"],
        rasterize_scale::Int = 1,
        save_path::AbstractString = "./data/output/mapas/heat_cont"
    ) -> Figure

Render a combined heatmap + contour overlay for a 2D data slice over grids `xg` and `yg` using Makie.
Supports optional log scaling, min/max markers, a colorbar, watermark/overlay text, and saving in multiple formats.

# Arguments
- `xg::AbstractVector`: X-axis grid coordinates (columns).
- `yg::AbstractVector`: Y-axis grid coordinates (rows).
- `slice::AbstractMatrix`: 2D data matrix to visualize.
- `var_name::String`: Variable name for labeling/saving (overridden in ion mode).
- `smin::Float64`, `smax::Float64`: Colorbar min/max. If both are `0.0` **and** `logscale == true`,
  they default to `log10(minval)` and `log10(maxval)` derived from the data.
- `is_ions::Bool`: If `true`, ion-specific title and colorbar label are taken from `ionstexto(kern, ionz)`.
- `kern::Int`, `ionz::Int`: Kernel and ionization state passed to `ionstexto`.
- `xlabel::String`, `ylabel::String`: Axis labels.
- `title::String`: Plot title (overridden by ion title if `is_ions`).
- `author::String`: Watermark text at lower-left.
- `resolution::String`, `unittime::String`: Overlay text near the top-right (`resolution ␣ 300.00 ␣ unittime`).
- `colormap`, `min_color`, `max_color`, `colorbar_label`: Reserved/unused here; a fixed palette from `get_palette(15)` is applied.
- `show_stats::Bool`: If `true`, shows a short stats summary below the plot.
- `logscale::Bool`: If `true`, uses `stats.matrix_result` and a log10 color range.
- `stats::Union{Nothing, Matrix2DStatistics}`: Precomputed statistics; computed via `statistics_data(slice)` if `nothing`.
- `formats::Vector{String}`: Output formats (e.g., `["pdf","png","svg"]`).  
  Vector formats automatically enable rasterization of heatmap layers depending on `rasterize_scale`.
- `rasterize_scale::Int`: Resolution multiplier controlling rasterization of heatmap layers when exporting vector formats.
- `filenum::Int`: Numeric identifier appended to output filenames.
- `save_path::AbstractString`: Base folder where the plot will be saved (a subfolder per `var_name` is created).

# Behavior
1. Computes or uses provided statistics (min/max/mean).
2. Selects either raw or log‑transformed data depending on `logscale`.
3. Constructs a color gradient using `get_palette(15)` and `cgrad`.
4. Renders a heatmap and overlays contour lines.
5. Marks minimum and maximum values using `add_text_at` with markers placed in axis coordinates.
6. Adds a right‑side colorbar via `setup_colorbar!`, matching ion or non‑ion labels.
7. Adds watermark (`author`) and overlay text (`resolution`, `unittime`).
8. Generates output filenames via `writeplot`, creates a subfolder under `save_path`, and saves/displays.
9. Uses `rasterize_scale` for rasterization of heatmap layers when exporting to vector formats (PDF/SVG).

# Returns
- `Figure`: The Makie figure for further inspection or composition.

# Dependencies
Requires in scope: `statistics_data`, `Matrix2DStatistics`, `ionstexto`,
`create_plot_structure`, `LaTeXString`, `get_palette`, `cgrad`, `heatmap!`,
`contour!`, `setup_colorbar!`, `add_text_at`, `writeplot`, `save_or_display`.

# Notes
- To allow use of custom colormaps, replace the fixed palette (`get_palette(15)`) with `colormap`.
"""

function plot_heat_cont(xg::AbstractVector, yg::AbstractVector,
    slice::AbstractMatrix,
    var_name::String,
    smin::Float64, smax::Float64;
    is_ions::Bool = false,
    kern::Int = 0, ionz::Int = 0,
    xlabel::String = "",
    ylabel::String = "",
    title::String = "",
    author::String = "",
    resolution::String = "",
    unittime::String = "",
    filenum::Int = 3000,
    colormap = :viridis,
    min_color = :black,
    max_color = :white,
    colorbar_label::String = "",
    show_stats::Bool = false,
    logscale::Bool = false,
    stats::Union{Nothing, Matrix2DStatistics} = nothing ,
    formats::Vector{String} = ["png"],                             
    rasterize_scale::Int = 1,  # 1..3: DPI multiplier for rasterized layers
    save_path::AbstractString = "./data/output/maps/heat_cont"      
)

    export_vector = any(fmt -> lowercase(fmt) in ("pdf", "svg"), formats)
    # Build the colormap (fixed palette type 15)
    my_pallete_color = cgrad(get_palette(15))

    # Compute statistics if not provided
    stats === nothing && (stats = statistics_data(slice))

    # Min and max values (from the statistics object)
    minval = stats.statistics_data.min_value.value2D
    maxval = stats.statistics_data.max_value.value2D

    # Select plot data and color range depending on log-scale usage
    if logscale
        plotdata = stats.matrix_result
        crange = (log10(minval), log10(maxval))
        # If smin/smax are both zero, auto-derive from log10(min/max)
        if smax == 0.0 && smin == 0.0
            smin = log10(minval)
            smax = log10(maxval)
        end
    else
        plotdata = slice
        crange = (minval, maxval)
    end

    # Apply ion labels if requested
    if is_ions
        ion_labels = ionstexto(kern, ionz)
        title = ion_labels.titleion
    end

    # Create figure and axis
    fig, ax = create_plot_structure(
        xlabel = xlabel, ylabel = ylabel, title = LaTeXString(title)
    )

    # Render heatmap
    hm = heatmap!(ax, xg, yg, plotdata; colormap = my_pallete_color, colorrange = crange,
    rasterize = export_vector ? rasterize_scale : false # decrease → smaller file size
    )

    # Overlay contour lines (black)
    co = contour!(ax, xg, yg, plotdata; color = :black
    #rasterize = export_vector ? rasterize_scale : false # decrease --> low size
    )

    # Add colorbar (ion/non-ion variants)
    if is_ions
        setup_colorbar!(fig, smin, smax; side = :right, colormap = my_pallete_color, logs = logscale, labelion = ion_labels.labelion)
    else
        setup_colorbar!(fig, smin, smax; side = :right, colormap = my_pallete_color, logs = logscale, variavel = var_name, atom=kern)
    end

    # Add watermark
     _ = add_text_at(fig,ax, (0.15, 0.05), LaTeXString(author); fontsize = 18, is_percentage = true, color = :black)
   
    # Extract min/max indices (matrix coordinates) from stats
    min_coord = stats.statistics_data.min_value.index2D   # Point2D(i, j)
    max_coord = stats.statistics_data.max_value.index2D

    # Convert matrix indices -> data coordinates
    x_min = xg[min_coord.y]   # column -> X
    y_min = yg[min_coord.x]   # row    -> Y
    x_max = xg[max_coord.y]
    y_max = yg[max_coord.x]

     _ = add_text_at(fig, ax, (x_min, y_min), "min=$(round(minval, digits=2))";fontsize=14,
    space = :axis,           
    is_percentage = false,
    offset = (0.2, 0.2),
    marker = :circle, marker_size = 14, color = :blue
    )    
    
_ = add_text_at(fig, ax, (x_max, y_max), "max=$(round(maxval, digits=2))";fontsize=14,
    space = :axis,           
    is_percentage = false,
    offset = (0.2, 0.2),
    marker = :star5, marker_size = 14, color = :red
    ) 
    pos = show_stats ? (0.85, 0.94) : (0.85, 0.91)
# Overlay resolution and time near the top-right (relative coords)
     _ = add_text_at(fig,ax, pos, LaTeXString(L"\text{300.00  } " * unittime);space = :figure, fontsize = 24, is_percentage = false, color = :black)
    
    
    # Optionally show a short stats summary
    if show_stats
        txt = @sprintf("min=%.3f, max=%.3f, mean=%.3f", minval, maxval, stats.statistics_data.mean)
        Label(fig[2, 1], txt; tellwidth = false, halign = :left)
    end

    # Configure output files using the parameterized 'formats'
    files = writeplot(42;
        lpdf = true,
        variavel = var_name,
        atom = kern,
        filenum = filenum,
        datetime_format = "ddmmyy_HHMM",
        formats = formats # formats = ["png"] # formats = formats
    )
 
 # Save or display the figure
    save_or_display(
        fig, files;
        sav = true,
        disp = true,
       # output_path = subdir
       output_path = save_path
       )

    return fig
end
    
# ==============================================================================
#
#  Generate multiple 2D maps (TOP/FRONT/SIDE views) from a 3D data cube by slicing along a looped 
# index
#
# ==============================================================================

"""
    maps!(
        data::AbstractArray{Float64,3},
        xgrid,
        ygrid,
        zgrid,
        var_name::String;
        kern,
        ionz,
        is_ions,
        cfg::ConfigData,
        pgp::PGPData,
        rt::RuntimeData,
        modions::ModionsData,
        formats::Vector{String} = ["png"],
        base_save_path::AbstractString = "./data/output/mapas"
    ) -> Nothing

Generate multiple 2D maps (TOP/FRONT/SIDE views) from a 3D data cube by slicing along a looped index
and dispatching to plotting routines (heatmap, contour, and heat+contour). The function handles cropping
to real-space bounds, optional density scaling for `den`, and min/max range selection via `setminmaxvar`.

# Arguments
- `data::AbstractArray{Float64,3}`: 3D data cube.
- `xgrid`, `ygrid`, `zgrid`: Grid vectors for X/Y/Z axes (expected to be `AbstractVector{<:Real}`).
- `var_name::String`: Variable name used for labeling and saving.
- `kern`, `ionz`, `is_ions`: Ion-related parameters forwarded to plotting functions.
- `cfg::ConfigData`: Configuration (contains real-space limits, scales, log usage, etc.).
- `pgp::PGPData`: Plot/graphics parameters (labels, titles, view toggles).
- `rt::RuntimeData`: Runtime settings (loop ranges, plot color, etc.).
- `modions::ModionsData`: Ion configuration (for `setminmaxvar`).
- `formats::Vector{String}`: Output formats to use when saving plots (e.g., `["pdf","png","svg"]`).
- `base_save_path::AbstractString`: Base path under which subfolders per plot type are created.

# Additional Keywords
- `id_string::AbstractString = "UNKNOWN_ID"`: Snapshot identifier used to generate filenames and FAIR-compliant folder paths.
- `root::AbstractString = "output_fair"`: Root directory for FAIR-compliant output. Used by `prepare_variable_paths` to build a complete directory tree.
- `rasterize_scale::Int = 1`: DPI multiplier for rasterizing heatmap layers when exporting vector formats (PDF/SVG). Helps reduce file size while keeping axes/text vectors.

# Behavior
1. Reads real-space bounds from `cfg.real_dims` and prepares Z loop from `rt.loop_graphic`.
2. For each loop index `l`, slices the cube for TOP view (fixed `Z = l`) if enabled via `pgp.view.top`.
3. Crops the slice using `crop_slice(...; xmin, xmax, ymin, ymax)`.  
   If the variable is `"den"`, applies density scaling via `cfg.scales.denscale`.
4. Computes 2D statistics (linear or `log10` based on `cfg.scales.logs`) and selects `(smin, smax)` via `setminmaxvar`.
5. Dispatches to:
   - `plot_heatmap`
   - `plot_contour`
   - `plot_heat_cont`
   - `plot_pdf`
   forwarding all presentation metadata (`title`, `author`, `resolution`, `unittime`) and export options (`formats`, `save_path`).
6. Creates FAIR-style output folders using `prepare_variable_paths(id_string, var_name; root)`, e.g.:
   - `vp.color`
   - `vp.contour`
   - `vp.heat_cont`
   - `vp.pdf`
   - `vp.statistics`
7. Saves all figures in the folder corresponding to each plot type.

# FRONT and SIDE Views
- FRONT view extracts XZ planes using `crop_slice(data[:, l, :], ...)`.
- SIDE view extracts YZ planes using `crop_slice(data[l, :, :], ...)`.
- These sections remain scaffolds and can be extended using the same pattern as TOP.

# Returns
- `Nothing`. The function generates plots as a side effect.

# Dependencies
Requires:  
`crop_slice`, `statistics_data`, `setminmaxvar`,  
`plot_heatmap`, `plot_contour`, `plot_heat_cont`, `plot_pdf`,  
`prepare_variable_paths`, `mkpath`, `LaTeXString`, `add_text_at`,  
and types `ConfigData`, `PGPData`, `RuntimeData`, `ModionsData`.

# Notes
- Subfolders are created automatically under `root` using FAIR conventions:
  - Heatmap: `vp.color`
  - Contour: `vp.contour`
  - Heat+Contour: `vp.heat_cont`
  - PDF: `vp.pdf`
  - Statistics: `vp.statistics`
- When exporting vector formats (PDF/SVG), heatmap layers are rasterized using `rasterize_scale`, whereas contours, axes, and text remain vector objects.
- `fn` (from `id_string`) is passed to plotting functions for consistent filenames.
"""
function maps!(data::AbstractArray{Float64,3}, xgrid, ygrid, zgrid,
               var_name::String;
               kern, ionz, is_ions,
               cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData,
               formats::Vector{String} = ["png"],
               id_string::AbstractString = "UNKNOWN_ID",   
               root::AbstractString = "output_fair"       
   )

    # Real-space cropping limits (min/max for x, y, z)
    xmin = cfg.real_dims.min.x
    xmax = cfg.real_dims.max.x
    ymin = cfg.real_dims.min.y
    ymax = cfg.real_dims.max.y
    jmin = cfg.real_dims.min.z
    jmax = cfg.real_dims.max.z

    # Plot color from runtime settings (currently unused, kept for future use)
    color = rt.output_plot.color
    
 # Prepare FAIR-compliant variable folders for this snapshot + variable
    vp = prepare_variable_paths(id_string, var_name; root = root)
    # convenience aliases
    heatmap_path  = vp.color
    contour_path  = vp.contour
    heatcont_path = vp.heat_cont
    pdf_path      = vp.pdf
    stats_path    = vp.statistics   # if/when you write stats files
    
    fn = parse(Int, replace(id_string, "all00" => ""))
  
    # Main loop over the selected index (lmin:stepl:lmax)
    for l in rt.loop_graphic.lmin:rt.loop_graphic.stepl:rt.loop_graphic.lmax

        # --- TOP slice (fix Z = l) ---
        if pgp.view.top
            # Crop the XY plane at Z = l to the requested bounds; also return cropped X/Y grids
            xg, yg, slice = crop_slice(data[:, :, l], xgrid, ygrid; xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)

            # Optional scaling for density variable
            if var_name == "den"
                slice ./= cfg.scales.denscale  # e.g., denscale = 1.67e-24
            end

            # Compute statistics (using log10 where appropriate)
            stats = statistics_data(slice, log10)

            # Select colorbar min/max from configuration or ion settings
            result = setminmaxvar(var_name, pgp, modions)
            smin, smax = result === nothing ? (0.0, 0.0) : result

            println("TOP view OK (Z = $l)")

            # Heatmap
            plot_heatmap(
                xg, yg, slice, var_name,
                smin, smax;
                kern = kern, ionz = ionz, is_ions = is_ions,
                xlabel = pgp.labels.xlabel, ylabel = pgp.labels.ylabel,
                title = pgp.title.title, author = pgp.title.author,
                resolution = pgp.title.resolution,
                unittime = pgp.title.unitime,
                filenum =fn,
                colormap = :viridis,
                min_color = :blue, max_color = :red,
                show_stats = false, logscale = cfg.scales.logs,
                stats = stats,
                formats = formats,
                save_path = heatmap_path,
                stats_save_path=stats_path             
            )

            # Contour
            plot_contour(
                xg, yg, slice, var_name,
                smin, smax;
                kern = kern, ionz = ionz, is_ions = is_ions,
                xlabel = pgp.labels.xlabel, ylabel = pgp.labels.ylabel,
                title = pgp.title.title, author = pgp.title.author,
                resolution = pgp.title.resolution,
                unittime = pgp.title.unitime,
                filenum =fn,
                min_color = :blue, max_color = :red,
                show_stats = false, logscale = cfg.scales.logs,
                stats = stats,
                formats = formats,
                save_path = contour_path
            )

            # Heat + Contour overlay
            plot_heat_cont(
                xg, yg, slice, var_name,
                smin, smax;
                kern = kern, ionz = ionz, is_ions = is_ions,
                xlabel = pgp.labels.xlabel, ylabel = pgp.labels.ylabel,
                title = pgp.title.title, author = pgp.title.author,
                resolution = pgp.title.resolution,
                unittime = pgp.title.unitime,
                filenum =fn,
                colormap = :viridis,
                min_color = :blue, max_color = :red,
                show_stats = false, logscale = cfg.scales.logs,
                stats = stats,
                formats = formats,
                save_path = heatcont_path
            )

            # Optional: PDF plot (kept as in original; add formats/save_path if supported)
            plot_pdf(
                xg, yg, slice, var_name;
                kern = kern, ionz = ionz, is_ions = is_ions,
                author = pgp.title.author,
                resolution = pgp.title.resolution,
                unittime = pgp.title.unitime,
                filenum =fn,
                show_stats = false,
                logscale = cfg.scales.logs,
                stats = stats,
                formats = formats,
                save_path = pdf_path
            )
        end

        # --- FRONT slice (fix Y = l) ---
        if pgp.view.front
            # Crop the XZ plane at Y = l (kept consistent with original scaffold)
            slice = crop_slice(data[:, l, :], xgrid, zgrid; xmin = xmin, xmax = xmax, jmin = jmin, jmax = jmax)

        end

        # --- SIDE slice (fix X = l) ---
        if pgp.view.side
            # Crop the YZ plane at X = l
            slice = crop_slice(data[l, :, :], ygrid, zgrid; ymin = ymin, ymax = ymax, jmin = jmin, jmax = jmax)

            # TODO: If needed, mirror plotting calls for SIDE using (yg, zgrid)
            println("Side view OK (X = $l)")
        end
    end

       return nothing
end

# ==============================================================================
#
#  Generate ion maps (TOP view by default) for a 3D array
#
# ==============================================================================
"""
    maps_ions!(
        data::Array{Float64,3},
        xgrid, ygrid, zgrid,
        var_name::String;
        kern,
        ionz,
        is_ions,
        cfg::ConfigData,
        pgp::PGPData,
        rt::RuntimeData,
        modions::ModionsData,
        formats::Vector{String} = ["png"],                    
        save_path::AbstractString = "./data/output/ions"     
    ) -> Nothing

Generate ion maps (TOP view by default) for a 3D array, producing heatmap, contour,
heat+contour, and PDF plots. The function crops to real-space bounds, optionally scales density,
computes statistics and color ranges, and forwards `formats`/`save_path` to plotting routines.

# Arguments
- `data::Array{Float64,3}`: 3D volume to visualize (ion fraction or other).
- `xgrid`, `ygrid`, `zgrid`: Axis grid vectors for X/Y/Z (typically `AbstractVector{<:Real}`).
- `var_name::String`: Variable name used for labeling/saving (ion mode may override titles/labels).
- `kern`, `ionz`, `is_ions`: Ion element index, ionization state, and mode flag. In ion mode,
  min/max range is taken from `"ele"` via `setminmaxvar`.
- `cfg::ConfigData`: Configuration (real-space limits, scales, log flags).
- `pgp::PGPData`: Plot parameters (labels, titles, view toggles).
- `rt::RuntimeData`: Runtime loop configuration (`lmin`, `stepl`, `lmax`) and plotting flags.
- `modions::ModionsData`: Ion configuration passed to `setminmaxvar`.
- `formats::Vector{String}`: Output formats to save (e.g., `["png"]`, `["pdf","png"]`, `["svg"]`).
- `save_path::AbstractString`: Base folder where plots are saved (subfolders per plot type are created here).

# Behavior
1. Reads real-space cropping bounds from `cfg.real_dims`.
2. Loops over `l = lmin:stepl:lmax`. For TOP view (`pgp.view.top`), crops XY at `Z = l`.
3. Optionally scales density slice if `var_name == "den"`.
4. Computes 2D statistics (with `log10` handler) and selects `smin/smax` from `setminmaxvar`,
   using `"ele"` for ion mode.
5. Calls `plot_heatmap`, `plot_contour`, `plot_heat_cont`, and `plot_pdf`, forwarding
   `formats` and `save_path` (which are organized per plot type).

# Returns
- `Nothing`. Side effects include generating plots and saving them to disk.

# Dependencies
Requires: `crop_slice`, `statistics_data`, `setminmaxvar`, `plot_heatmap`, `plot_contour`,
`plot_heat_cont`, `plot_pdf` to be in scope and accept `formats` and `save_path`.
"""
function maps_ions!(data::Array{Float64,3}, xgrid, ygrid, zgrid,
                         var_name::String;
                         kern::Int, ionz::Int, is_ions::Bool, 
                         cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData,
                         formats::Vector{String} = ["pdf"],                        
                         id_string::AbstractString,
                         root::AbstractString = "output_fair" 
    )
    # Real-space cropping limits (min/max for x, y, z)
    xmin = cfg.real_dims.min.x
    xmax = cfg.real_dims.max.x
    ymin = cfg.real_dims.min.y
    ymax = cfg.real_dims.max.y
    jmin = cfg.real_dims.min.z
    jmax = cfg.real_dims.max.z

    # Plot color from runtime settings (currently unused, kept for future use)
    color = rt.output_plot.color

     # ── Get ion labels (single source of truth)
    @assert is_ions "maps_ions! should be called with is_ions=true"
    ion_labels  = ionstexto(kern, ionz)
    element     = split(ion_labels.titleion)[1]    # e.g. "C"
    state_label = ion_labels.ion                   # e.g. "C06+"
    state       = replace(state_label, '+' => "")  # e.g. "C06" (folder-safe)

    var_name=state
    
    # ── FAIR paths for this ion state
    ip = prepare_ion_paths(id_string, element, state; root=root)
    fn = parse(Int, replace(id_string, "all00" => ""))

    # Main loop over the selected index (lmin:stepl:lmax)
    for l in rt.loop_graphic.lmin:rt.loop_graphic.stepl:rt.loop_graphic.lmax

        # --- TOP slice (fix Z = l) ---
        if pgp.view.top
            # Crop the XY plane at Z = l to the requested bounds; also return cropped X/Y grids
            xg, yg, slice = crop_slice(data[:, :, l], xgrid, ygrid; xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)

            # Optional scaling for density variable
            if var_name == "den"
                slice ./= cfg.scales.denscale  # e.g., denscale = 1.67e-24
            end

            # Compute statistics (using log10 where appropriate)
            stats = statistics_data(slice, log10)

            # Select colorbar min/max from configuration or ion settings
            # In ion mode, use 'ele' as a proxy variable for min/max selection
            result = is_ions ? setminmaxvar("ele", pgp, modions) : setminmaxvar(var_name, pgp, modions)
            smin, smax = result === nothing ? (0.0, 0.0) : result

            println("TOP view OK (Z = $l)")

            # Heatmap
            plot_heatmap(
                xg, yg, slice, var_name,
                smin, smax;
                is_ions = is_ions,
                kern = kern, ionz = ionz,
                xlabel = pgp.labels.xlabel,
                ylabel = pgp.labels.ylabel,
                title = pgp.title.title,
                author = pgp.title.author,
                resolution = pgp.title.resolution,
                unittime = pgp.title.unitime,
                filenum =fn,
                colormap = :viridis,
                min_color = :blue, max_color = :red,
                show_stats = false, logscale = cfg.scales.logs,
                stats = stats,
                formats = formats,
                
                save_path=ip.color,             
                stats_save_path=ip.statistics  
            )

            # Contour
            plot_contour(
                xg, yg, slice, var_name,
                smin, smax;
                is_ions = is_ions,
                kern = kern, ionz = ionz,
                xlabel = pgp.labels.xlabel,
                ylabel = pgp.labels.ylabel,
                title = pgp.title.title,
                author = pgp.title.author,
                resolution = pgp.title.resolution,
                unittime = pgp.title.unitime,
                filenum =fn,
                min_color = :blue, max_color = :red,
                show_stats = false, logscale = cfg.scales.logs,
                stats = stats,
                formats = formats,
                save_path = ip.contour  
            )

            # Heat + Contour overlay
            plot_heat_cont(
                xg, yg, slice, var_name,
                smin, smax;
                is_ions = is_ions,
                kern = kern, ionz = ionz,
                xlabel = pgp.labels.xlabel,
                ylabel = pgp.labels.ylabel,
                title = pgp.title.title,
                author = pgp.title.author,
                resolution = pgp.title.resolution,
                unittime = pgp.title.unitime,
                filenum =fn,
                colormap = :viridis,
                min_color = :blue, max_color = :red,
                show_stats = false, logscale = cfg.scales.logs,
                stats = stats,
                formats = formats,
                save_path = ip.heat_cont 
            )
        end

        # --- FRONT slice (fix Y = l) ---
        if pgp.view.front
            # Crop the XZ plane at Y = l (kept consistent with original scaffold)
            slice = crop_slice(data[:, l, :], xgrid, zgrid; xmin = xmin, xmax = xmax, jmin = jmin, jmax = jmax)
            # TODO: replicate plotting calls for FRONT with appropriate grids (xgrid, zgrid) and labels if needed
        end

        # --- SIDE slice (fix X = l) ---
        if pgp.view.side
            # Crop the YZ plane at X = l
            slice = crop_slice(data[l, :, :], ygrid, zgrid; ymin = ymin, ymax = ymax, jmin = jmin, jmax = jmax)
            # TODO: replicate plotting calls for SIDE using (yg, zgrid)
            println("Side view OK (X = $l)")
        end
    end

    return nothing
end

# ==============================================================================
#
#  Generate electron maps (TOP view) for a 3D array
#
# ==============================================================================
"""
    maps_electron!(
        data::Array{Float64,3},
        xgrid, ygrid, zgrid,
        var_name::String;
        kern::Int, ionz::Int, is_ions::Bool,
        cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData,
        formats::Vector{String} = ["pdf"],
        id_string::AbstractString,
        root::AbstractString = "output_fair"
    ) -> Nothing

Generate electron maps (TOP view) for a 3D array, producing heatmap, contour,
and heat+contour plots. The function crops to real‑space bounds, applies optional
electron scaling, computes statistics and color ranges, and forwards `formats`
and FAIR-style `save_path` directories to the plotting routines.

This wrapper is specialized for **electron density variables**:
- `"ele"`   → total electron density
- `"elez"`  → electrons per chemical element  
and uses FAIR-compliant folder structures automatically.

# Arguments
- `data::Array{Float64,3}`: 3D electron-related data cube.
- `xgrid`, `ygrid`, `zgrid`: Grid vectors for the X/Y/Z axes.
- `var_name::String`: Must be `"ele"` or `"elez"`. Determines which FAIR folder tree is used.
- `kern::Int`, `ionz::Int`, `is_ions::Bool`: Ion and state parameters.  
  (Electron mode always sets `is_ions = false` inside plotting functions.)
- `cfg::ConfigData`: Contains real-space limits, scaling values (`elescale`), and log flags.
- `pgp::PGPData`: Plot parameters (labels, titles, metadata, view toggles).
- `rt::RuntimeData`: Runtime loop control (`lmin`, `stepl`, `lmax`).
- `modions::ModionsData`: Passed to `setminmaxvar` for consistent electron range selection.
- `formats::Vector{String}`: Output formats to save (e.g., `["png"]`, `["pdf","svg"]`).
- `id_string::AbstractString`: Snapshot identifier used for FAIR folder creation and for filenames.
- `root::AbstractString`: Root directory for FAIR-compliant output.

# Behavior
1. Reads spatial cropping limits from `cfg.real_dims`.
2. Determines electron FAIR paths by calling:
   - `prepare_electrons_total_paths(id_string; root)`  if `var_name == "ele"`
   - `prepare_electrons_per_element_paths(id_string, elem_sym; root)` if `var_name == "elez"`
3. Extracts one Z‑slice per loop index (`lmin:stepl:lmax`) when `pgp.view.top` is enabled.
4. Applies electron scaling (`cfg.scales.elescale`) if `var_name ∈ {"ele", "elez"}`.
5. Computes 2D statistics (`statistics_data(..., log10)`).
6. Selects plotting range `(smin, smax)` using:
   - `setminmaxvar("ele", ...)` for `"elez"` to maintain consistent scaling.
7. Calls the plotting functions with all metadata, forwarding `formats` and the appropriate
   FAIR path:
   - `plot_heatmap(..., save_path = ip.color, stats_save_path = ip.statistics)`
   - `plot_contour(..., save_path = ip.contour)`
   - `plot_heat_cont(..., save_path = ip.heat_cont)`
8. FRONT and SIDE views are scaffolded for future extension.

# Returns
- `Nothing`. All plots are generated and saved as side effects.

# Dependencies
Requires in scope:
`crop_slice`, `statistics_data`, `setminmaxvar`,
`plot_heatmap`, `plot_contour`, `plot_heat_cont`,
`ionstexto`,  
FAIR helpers: `prepare_electrons_total_paths`, `prepare_electrons_per_element_paths`.

# Notes
- `(smin, smax)` fallback: when `setminmaxvar` returns `(0.0, 0.0)`, the stats-derived min/max are used.
- For `"elez"` variables, using `"ele"` as the scaling key ensures global consistency across elements.
- PDF plotting is currently commented; re-enable as needed with `save_path = ip.pdf`.
"""

function maps_electron!(data::Array{Float64,3}, xgrid, ygrid, zgrid,
                        var_name::String;
                        kern::Int, ionz::Int, is_ions::Bool,
                        cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData,
                        formats::Vector{String} = ["pdf"],
                        id_string::AbstractString,
                        root::AbstractString = "output_fair"
                    )
    # --- Spatial limits (copied from your style) ---
    xmin = cfg.real_dims.min.x; xmax = cfg.real_dims.max.x
    ymin = cfg.real_dims.min.y; ymax = cfg.real_dims.max.y
    jmin = cfg.real_dims.min.z; jmax = cfg.real_dims.max.z

    # --- Resolve FAIR paths for electrons ---
   # Obtain labels for this ionization state
     ion_labels = ionstexto(kern, 0)
     elem_sym = first(split(ion_labels.titleion))
     fn = parse(Int, replace(id_string, "all00" => ""))
   
    ip = nothing
    if var_name == "ele"
        ip = prepare_electrons_total_paths(id_string; root=root)
        
    elseif var_name == "elez"
       # @assert elem_sym !== nothing "maps_electron!: elem_sym must be provided when var_name='elez'"
        ip = prepare_electrons_per_element_paths(id_string, elem_sym; root=root)
        
    else
        error("maps_electron!: unsupported var_name='$var_name' (use 'ele' or 'elez')")
    end

    # --- Main loop over selected slices (top view as in your code) ---
    for l in rt.loop_graphic.lmin:rt.loop_graphic.stepl:rt.loop_graphic.lmax
        if pgp.view.top
            # 2D crop at fixed Z = l
            xg, yg, slice = crop_slice(data[:, :, l], xgrid, ygrid;
                                       xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax)

            # Optional scaling for electron densities
            if var_name == "ele" || var_name == "elez"
                # If your scaling is already applied upstream, remove this division
                slice ./= cfg.scales.elescale
            end

            # Statistics + ranges
            stats  = statistics_data(slice, log10)
            # For per-element electrons ("elez") reuse "ele" limits if you prefer consistent scaling
            key    = (var_name == "elez") ? "ele" : var_name
            result = setminmaxvar(key, pgp, modions)
            smin, smax = result === nothing ? (0.0, 0.0) : result

            # Fallback if setminmaxvar returns (0,0)
            if smin == 0.0 && smax == 0.0
                smin = stats.statistics_data.min_value.value2D
                smax = stats.statistics_data.max_value.value2D
            end

            plot_heatmap(
                xg, yg, slice, var_name,
                smin, smax;
                is_ions = false,            # electrons branch does not use ion labels
                kern = kern, ionz = ionz,
                xlabel = pgp.labels.xlabel, ylabel = pgp.labels.ylabel,
                title = pgp.title.title, author = pgp.title.author,
                resolution = pgp.title.resolution, unittime = pgp.title.unitime,
                filenum =fn,
                colormap = :viridis, min_color = :blue, max_color = :red,
                show_stats = false, logscale = cfg.scales.logs,
                stats = stats, formats = formats,
                save_path = ip.color,
                stats_save_path = ip.statistics
            )

            plot_contour(
                xg, yg, slice, var_name,
                smin, smax;
                is_ions=false, kern=kern, ionz=ionz,
                xlabel=pgp.labels.xlabel, ylabel=pgp.labels.ylabel,
                title=pgp.title.title, author=pgp.title.author,
                resolution=pgp.title.resolution, unittime=pgp.title.unitime,
                filenum =fn,
                min_color=:blue, max_color=:red, show_stats=false,
                logscale=cfg.scales.logs, stats=stats, formats=formats,
                save_path = ip.contour
            )

            plot_heat_cont(
                xg, yg, slice, var_name,
                smin, smax;
                is_ions=false, kern=kern, ionz=ionz,
                xlabel=pgp.labels.xlabel, ylabel=pgp.labels.ylabel,
                title=pgp.title.title, author=pgp.title.author,
                resolution=pgp.title.resolution, unittime=pgp.title.unitime,
                filenum =fn,
                colormap=:viridis, min_color=:blue, max_color=:red,
                show_stats=false, logscale=cfg.scales.logs, stats=stats, formats=formats,
                save_path = ip.heat_cont
            )

         #=   plot_pdf(
                xg, yg, slice, var_name;
                is_ions=false, kern=kern, ionz=ionz,
                author=pgp.title.author, resolution=pgp.title.resolution, unittime=pgp.title.unitime,
                show_stats=false, logscale=cfg.scales.logs, stats=stats, formats=formats,
                save_path = ip.pdf 
            )
         =#
        end

        # FRONT / SIDE: replicate if/when needed (as in your other wrappers)
    end

    return nothing
end


# ==============================================================================
#
#  For 3D matrix
#
# ==============================================================================

function plot_slice(
    data3d::Array{<:Real,3},
    xgrid::AbstractVector,
    ygrid::AbstractVector,
    zgrid::AbstractVector;
    nx::Int=2000,
    ny::Int=2000,
    nz::Int=1,
    plane::Symbol=:XY,
    index::Union{Int,Nothing}=nothing,
    xmin=nothing, xmax=nothing,
    ymin=nothing, ymax=nothing,
    zmin=nothing, zmax=nothing,
    logscale::Bool=true,
    ldebug::Bool=false,
    eps::Float64=1e-12,
    colormap=:viridis
)
    denscale = 1.67e-24

    if index === nothing
        index = plane == :XY ? nz ÷ 2 :
                plane == :XZ ? ny ÷ 2 :
                plane == :YZ ? nx ÷ 2 : error("Not valid : $plane")
    end

    fig = Figure(size=(800,600))
    ax = Axis(fig[1,1], title="Slice $plane @ index=$index")

    if plane == :XY
        slice = data3d[:,:,index]
        xsel = (xmin === nothing) ? xgrid : xgrid[(xgrid .>= xmin) .& (xgrid .<= xmax)]
        ysel = (ymin === nothing) ? ygrid : ygrid[(ygrid .>= ymin) .& (ygrid .<= ymax)]
        xmask = in.(xgrid, Ref(xsel))
        ymask = in.(ygrid, Ref(ysel))
        slice_crop = slice[xmask, ymask] 
        slice_crop .*= denscale
        if logscale
            slice_crop = log10.(slice_crop)
        end
        hm = heatmap!(ax, xsel, ysel, slice_crop, colormap=colormap)
        ax.xlabel = "X"; ax.ylabel = "Y"
        ax.title = "Plano XY (z ≈ $(round(zgrid[index], digits=2)))"

    elseif plane == :XZ
        slice = data3d[:,index,:]
        xsel = (xmin === nothing) ? xgrid : xgrid[(xgrid .>= xmin) .& (xgrid .<= xmax)]
        zsel = (zmin === nothing) ? zgrid : zgrid[(zgrid .>= zmin) .& (zgrid .<= zmax)]
        xmask = in.(xgrid, Ref(xsel))
        zmask = in.(zgrid, Ref(zsel))
        slice_crop = slice[xmask, zmask]
        slice_crop .*= denscale
        if logscale
            slice_crop = log10.(slice_crop)
        end
        hm = heatmap!(ax, xsel, zsel, slice_crop, colormap=colormap)
        ax.xlabel = "X"; ax.ylabel = "Z"
        ax.title = "Plano XZ (y ≈ $(round(ygrid[index], digits=2)))"

    elseif plane == :YZ
        slice = data3d[index,:,:]
        ysel = (ymin === nothing) ? ygrid : ygrid[(ygrid .>= ymin) .& (ygrid .<= ymax)]
        zsel = (zmin === nothing) ? zgrid : zgrid[(zgrid .>= zmin) .& (zgrid .<= zmax)]
        ymask = in.(ygrid, Ref(ysel))
        zmask = in.(zgrid, Ref(zsel))
        slice_crop = slice[ymask, zmask]
        slice_crop .*= denscale
        if logscale
            slice_crop = log10.(slice_crop )
        end
        hm = heatmap!(ax, ysel, zsel, slice_crop, colormap=colormap)
        ax.xlabel = "Y"; ax.ylabel = "Z"
        ax.title = "Plano YZ (x ≈ $(round(xgrid[index], digits=2)))"

    else
        return (status=:fail, reason="Plano inválido. Use :XY, :XZ ou :YZ")
    end

    Colorbar(fig[1,2], hm, label="Valor")
    return (status=:success, fig=fig, ax=ax, hm=hm)
end

# ==============================================================================
#
#  for 2D matrix
#
# ==============================================================================
function plot_contour(
    data2d::AbstractArray{<:Real,2},
    xgrid::AbstractVector,
    ygrid::AbstractVector,
    zgrid::AbstractVector;
    nx::Int=2000,
    ny::Int=2000,
    nz::Int=1,
    plane::Symbol=:XY,
    index::Union{Int,Nothing}=nothing,
    xmin=nothing, xmax=nothing,
    ymin=nothing, ymax=nothing,
    zmin=nothing, zmax=nothing,
    colormap=:viridis,
    mincont::Union{Float64,Nothing}=nothing,
    maxcont::Union{Float64,Nothing}=nothing,
    nconts::Int=10,
    logscale::Bool=false,
    eps::Float64=1e-12,
    colorbar_label::String="Value"
)
    if plane != :XY
        return (status=:fail, reason="Plano $plane não disponível para matriz 2D")
    end

    denscale = 1.67e-24

    # Crop
    xsel = (xmin === nothing) ? xgrid : xgrid[(xgrid .>= xmin) .& (xgrid .<= xmax)]
    ysel = (ymin === nothing) ? ygrid : ygrid[(ygrid .>= ymin) .& (ygrid .<= ymax)]
    xmask = in.(xgrid, Ref(xsel))
    ymask = in.(ygrid, Ref(ysel))
    slice_crop = data2d[xmask, ymask] .* denscale

    #  log scale
    if logscale
        slice_crop = log10.(slice_crop )
    end

    # Limites
    minval, maxval = extrema(slice_crop)
    mincont = isnothing(mincont) ? minval : mincont
    maxcont = isnothing(maxcont) ? maxval : maxcont
    levels = range(mincont, maxcont; length=nconts)

    fig = Figure(size=(800,800))
    ax = Axis(fig[1,1])
    hm = contourf!(ax, xsel, ysel, slice_crop; colormap=colormap, levels=levels)

    Colorbar(fig[1,2], hm, label=colorbar_label)
    ax.xlabel = "X"; ax.ylabel = "Y"
    ax.title = "Plano XY (z ≈ $(round(zgrid[1], digits=2)))"

    return (status=:success, fig=fig, ax=ax, hm=hm)
end

# ==============================================================================
#
#  for 3D matrix
#
# ==============================================================================

function plot_contour(
    data3d::Array{<:Real,3},
    xgrid::AbstractVector,
    ygrid::AbstractVector,
    zgrid::AbstractVector;
    nx::Int=2000,
    ny::Int=2000,
    nz::Int=1,
    plane::Symbol=:XY,
    index::Union{Int,Nothing}=nothing,
    xmin=nothing, xmax=nothing,
    ymin=nothing, ymax=nothing,
    zmin=nothing, zmax=nothing,
    colormap=:viridis,
    mincont::Union{Float64,Nothing}=nothing,
    maxcont::Union{Float64,Nothing}=nothing,
    nconts::Int=10,
    logscale::Bool=false,
    eps::Float64=1e-12,
    colorbar_label::String="Value",
)
    nxdata, nydata, nzdata = size(data3d)

    # index default in center
    if index === nothing
        index = plane == :XY ? nzdata ÷ 2 :
                plane == :XZ ? nydata ÷ 2 :
                plane == :YZ ? nxdata ÷ 2 : error("Plano inválido: $plane")
    end

    denscale = 1.67e-24

    if plane == :XY
        slice = data3d[:,:,index]
        xsel = (xmin === nothing) ? xgrid : xgrid[(xgrid .>= xmin) .& (xgrid .<= xmax)]
        ysel = (ymin === nothing) ? ygrid : ygrid[(ygrid .>= ymin) .& (ygrid .<= ymax)]
        xmask = in.(xgrid, Ref(xsel))
        ymask = in.(ygrid, Ref(ysel))
        slice_crop = slice[xmask, ymask] #.* denscale
        xlabel, ylabel = "X", "Y"
        title = "Plano XY (z ≈ $(round(zgrid[index], digits=2)))"

    elseif plane == :XZ
        slice = data3d[:,index,:]
        xsel = (xmin === nothing) ? xgrid : xgrid[(xgrid .>= xmin) .& (xgrid .<= xmax)]
        zsel = (zmin === nothing) ? zgrid : zgrid[(zgrid .>= zmin) .& (zgrid .<= zmax)]
        xmask = in.(xgrid, Ref(xsel))
        zmask = in.(zgrid, Ref(zsel))
        slice_crop = slice[xmask, zmask] #.* denscale
        xlabel, ylabel = "X", "Z"
        title = "Plano XZ (y ≈ $(round(ygrid[index], digits=2)))"

    elseif plane == :YZ
        slice = data3d[index,:,:]
        ysel = (ymin === nothing) ? ygrid : ygrid[(ygrid .>= ymin) .& (ygrid .<= ymax)]
        zsel = (zmin === nothing) ? zgrid : zgrid[(zgrid .>= zmin) .& (zgrid .<= zmax)]
        ymask = in.(ygrid, Ref(ysel))
        zmask = in.(zgrid, Ref(zsel))
        slice_crop = slice[ymask, zmask] #.* denscale
        xlabel, ylabel = "Y", "Z"
        title = "Plano YZ (x ≈ $(round(xgrid[index], digits=2)))"

    else
        error("Plano inválido. Use :XY, :XZ ou :YZ")
    end

    # logscale isf need
    if logscale
        slice_crop = log10.(slice_crop)
    end
    
    # limits
    minval, maxval = extrema(slice_crop)
    mincont = isnothing(mincont) ? minval : mincont
    maxcont = isnothing(maxcont) ? maxval : maxcont
    levels = range(mincont, maxcont; length=nconts)

    fig = Figure(size=(800,800))
    ax = Axis(fig[1,1])
    hm = contourf!(ax, xsel, ysel, slice_crop; colormap=colormap, levels=levels)

    Colorbar(fig[1,2], hm, label=colorbar_label)
    ax.xlabel = xlabel; ax.ylabel = ylabel
    ax.title = title

    return (status=:success, fig=fig, ax=ax, hm=hm)
end

# ==============================================================================
#
#   Calculate_pdf(var::AbstractArray, binmin::Real, dbin::Real, nli::Int, vol_local::Real)
#
# ==============================================================================
"""
    calculate_pdf(var::AbstractArray, binmin::Real, dbin::Real, nli::Int, vol_local::Real)

Calculates the Probability Density Function (PDF) for the data in `var`.

# Arguments
- `var`: An array of data values.
- `binmin`: The minimum value for the first bin.
- `dbin`: The size of each bin.
- `nli`: The total number of bins.
- `vol_local`: The normalization factor for the PDF.

# Returns
- `dbf`: A vector with the upper limits of each bin.
- `dbrev6`: A vector with the normalized PDF in logarithmic scale.
"""
function calculate_pdf(var::AbstractArray, binmin::Real, dbin::Real, nli::Int, vol_local::Real)
    
    # 1. Compute the upper limits of the bins (dbf)
    dbf = [binmin + i * dbin for i in 1:nli]

    # 2. Initialize the count vector for each bin
    dbrev = zeros(Int, nli)

    # 3. Iterate over the data and count occurrences in each bin
    for val in var
        # Ensure the value is within the range
        if binmin <= val < (binmin + nli * dbin)
            bin_index = floor(Int, (val - binmin) / dbin) + 1
            # Increment the bin counter
            dbrev[bin_index] += 1
        end
    end

    # 4. Compute the normalized probability density and apply logarithmic scaling
    # Add a small constant to avoid log(0)
    dbrev6 = log10.(dbrev ./ vol_local .+ 1.0e-20)
    
    return dbf, dbrev6
end

# ==============================================================================
#
#  Finds the (x, y) coordinates of the minimum and maximum values in a dataset.
#
# ==============================================================================
"""
    find_min_max_coords(dbf::Vector{<:Real}, dbrev6::Vector{<:Real})

Finds the (x, y) coordinates of the minimum and maximum values in a dataset.

This function takes two vectors, `dbf` (the x-coordinates or bin boundaries) and `dbrev6`
(the y-coordinates or calculated values, such as PDF), and returns the coordinates of
the points corresponding to the minimum and maximum values in `dbrev6`.

# Arguments
- `dbf::Vector{<:Real}`: A vector of bin boundaries or x-coordinates.
- `dbrev6::Vector{<:Real}`: A vector of calculated values (e.g., PDF) or y-coordinates.

# Returns
A tuple containing two tuples: `(min_coords, max_coords)`.
- `min_coords::Tuple{Real, Real}`: The (x, y) coordinates of the minimum value.
- `max_coords::Tuple{Real, Real}`: The (x, y) coordinates of the maximum value.

# Example
```julia
dbf = [1.0, 2.0, 3.0, 4.0, 5.0]
dbrev6 = [0.1, 0.5, 0.05, 0.8, 0.2]
min_coords, max_coords = find_min_max_coords(dbf, dbrev6)
# min_coords will be (3.0, 0.05)
# max_coords will be (4.0, 0.8)

"""

function find_min_max_coords(dbf::Vector{<:Real}, dbrev6::Vector{<:Real})
    # Find the index of the minimum value in the dbrev6 vector
    min_index = argmin(dbrev6)

    # Find the index of the maximum value in the dbrev6 vector
    max_index = argmax(dbrev6)

    # Get the coordinates for the minimum point
    min_coords = (dbf[min_index], dbrev6[min_index])

    # Get the coordinates for the maximum point
    max_coords = (dbf[max_index], dbrev6[max_index])

    return min_coords, max_coords
end

# ==============================================================================
#
#  get_pdf_label
#
# ==============================================================================
"""
    get_pdf_label(var_name::String, atom::Int=0)

Returns the configuration parameters for the PDF plot in a dictionary, 
using LaTeX for label formatting.

# Arguments
- `var_name`: The name of the variable (e.g., "den", "tem").
- `atom`: The atomic number, used only for the "elez" case. Default is 0.

# Returns
- A dictionary containing the keys: "binmin", "dbin", "xlabelmin", "xlabelmax",
  "x1label", "ylabelmin", "ylabelmax", and "xtick".
"""

function get_pdf_label(var_name::String; atom::Int=1)
    # Makie uses MathTeX.jl (subset of LaTeX). It does NOT honor operator spacing for \log,
    # so we force a visible space using `\text{ }` after \log when followed by a symbol.
    # Example: L"\log\text{ }n\,[\mathrm{cm}^{-3}]" renders correctly as "log n [cm^-3]".

    # Defaults (can be overwritten below)  "log dN/N",
    params = Dict{String, Any}(
        "ylabelmin"  => -5.0,
        "ylabelmax"  =>  0.0,
        # Prefer a math label with proper fraction and parentheses. No extra spacing needed here.
        "x2label"    => L"\log(dN/N)",
        "xtick"      =>  1.0,
        "binmin"     =>  0.0,
        "dbin"       =>  0.0,
        "xlabelmin"  =>  0.0,
        "xlabelmax"  =>  0.0,
        "x1label"    => "Unrecognized Variable"
    )

    # Optional helper: atomic number -> chemical symbol (used in 'elez' case)
    atom_symbol = Dict(
        1=>"H", 2=>"He", 6=>"C", 7=>"N", 8=>"O",
        10=>"Ne", 12=>"Mg", 14=>"Si", 16=>"S", 26=>"Fe"
    )

    if var_name == "den"
        # Number density: log n [cm^-3]
        params["binmin"]    = -5.0
        params["dbin"]      =  0.1
        params["xlabelmin"] = -5.0
        params["xlabelmax"] =  3.0
        params["x1label"]   = L"\log\text{ }n\,[\mathrm{cm}^{-3}]"

    elseif var_name == "pre"
        # Thermal pressure: log P_th [dyne cm^-2]
        params["binmin"]    = -18.0
        params["dbin"]      =   0.1
        params["xlabelmin"] = -18.0
        params["xlabelmax"] =  -8.0
        params["x1label"]   = L"\log\text{ }P_{\mathrm{th}}\, [\mathrm{dyne}\,\mathrm{cm}^{-2}]"

    elseif var_name == "pok"
        # Pressure over Boltzmann constant: log (P/k_B) [cm^-3 K]
        params["binmin"]    =  -2.0
        params["dbin"]      =   0.1
        params["xlabelmin"] =  -2.0
        params["xlabelmax"] =   8.0
        # Parentheses/fractions are fine in Makie; no need for \text{ } inside the log(...)
        params["x1label"]   = L"\log\!\left(\frac{P}{k_{\mathrm{B}}}\right)\, [\mathrm{cm}^{-3}\,\mathrm{K}]"

    elseif var_name == "ram"
        # Ram pressure: log P_ram [dyne cm^-2]
        params["binmin"]    = -18.0
        params["dbin"]      =   0.1
        params["xlabelmin"] = -18.0
        params["xlabelmax"] =  -8.0
        params["x1label"]   = L"\log\text{ }P_{\mathrm{ram}}\, [\mathrm{dyne}\,\mathrm{cm}^{-2}]"

    elseif var_name == "rok"
        # Ram pressure over k_B: log (P_ram/k_B) [cm^-3 K]
        params["binmin"]    =  -2.0
        params["dbin"]      =   0.1
        params["xlabelmin"] =  -2.0
        params["xlabelmax"] =   8.0
        params["x1label"]   = L"\log\!\left(\frac{P_{\mathrm{ram}}}{k_{\mathrm{B}}}\right)\, [\mathrm{cm}^{-3}\,\mathrm{K}]"

    elseif var_name == "tem"
        # Temperature: log T [K]
        params["binmin"]    =   0.0
        params["dbin"]      =   0.1
        params["xlabelmin"] =   0.0
        params["xlabelmax"] =   8.0
        params["x1label"]   = L"\log\text{ }T\, [\mathrm{K}]"

    elseif var_name == "mach"
        # Mach number (dimensionless): log M
        params["binmin"]    =  -3.0
        params["dbin"]      =   0.1
        params["xlabelmin"] =  -3.0
        params["xlabelmax"] =   2.0
        params["x1label"]   = L"\log\text{ }\mathcal{M}"

    elseif var_name == "ent"
        # Specific entropy: log s [erg cm^-3 K^-1]
        params["binmin"]    =   9.0
        params["dbin"]      =   0.01
        params["xlabelmin"] =   9.3
        params["xlabelmax"] =   9.7
        params["xtick"]     =   0.1
        params["x1label"]   = L"\log\text{ }s\, [\mathrm{erg}\,\mathrm{cm}^{-3}\,\mathrm{K}^{-1}]"

    elseif var_name == "ele"
        # Electron number density: log n_e [cm^-3]
        params["binmin"]    =  -8.0
        params["dbin"]      =   0.1
        params["xlabelmin"] =  -7.0
        params["xlabelmax"] =   2.0
        params["x1label"]   = L"\log\text{ }n_{\mathrm{e}}\, [\mathrm{cm}^{-3}]"

    elseif var_name == "elez"
        # Electron density per abundance of element X: log(n_e(X)/A(X)) [cm^-3]
        params["binmin"]    =  -7.0
        params["dbin"]      =   0.1
        params["xlabelmin"] =  -7.0
        params["xlabelmax"] =   2.0

        sym = get(atom_symbol, atom, "??")
        # Inside log(...), spacing is fine; we only need \text{ } when log is directly followed by a symbol.
        params["x1label"]   = L"\log\!\left(\frac{n_{\mathrm{e}}(\mathrm{$sym})}{A(\mathrm{$sym})}\right)\, [\mathrm{cm}^{-3}]"
        # If interpolation inside L"..." ever fails in your environment, build the string first:
        # params["x1label"] = L"\log\!\left(\frac{n_{\mathrm{e}}(\mathrm{" * sym * "})}{A(\mathrm{" * sym * "})}\right)\, [\mathrm{cm}^{-3}]"
    end

    return params
end

# ==============================================================================
#
#  Plot a 1D probability density function (PDF) derived from a 2D slice.
#
# ==============================================================================
"""
    plot_pdf(
        xg::AbstractVector,
        yg::AbstractVector,
        slice::AbstractMatrix,
        var_name::String;
        is_ions,
        kern,
        ionz,
        atom::Int = 1,
        binmin::Float64 = 0.0,
        dbin::Float64 = 0.1,
        nli::Int = 100,
        vol_local::Float64 = 1.0,
        xlabel::String = "",
        ylabel::String = "",
        title::String = "",
        author::String = "",
        resolution::String = "",
        unittime::String = "",
        filenum::Int = 3000,
        show_stats::Bool = false,
        logscale::Bool = true,
        stats::Union{Nothing, Matrix2DStatistics} = nothing,
        formats::Vector{String} = ["pdf", "png"],
        rasterize_scale::Int = 1,
        save_path::AbstractString = "./data/output/mapas/pdf"
    ) -> Tuple{Axis, Figure}

Plot a 1D probability density function (PDF) derived from a 2D slice. The function computes basic statistics,
optionally applies a log transform, builds the PDF over logarithmic bins, highlights min/max points on the
PDF curve, overlays watermark/metadata text, and saves the figure in multiple formats.

# Arguments
- `xg::AbstractVector`, `yg::AbstractVector`: Grid vectors for X and Y (not directly used in the PDF, kept for consistency).
- `slice::AbstractMatrix`: 2D data matrix used to compute the PDF.
- `var_name::String`: Variable name used to select labels and for saving.
- `is_ions`, `kern`, `ionz`: Ion-related flags/indices; when `is_ions == true`, title/labels are taken from `ionstexto(kern, ionz)`.
- `atom::Int`: Atomic number used when building filenames via `writeplot`.
- `binmin::Float64`: Lower bound of the first bin (in log-space). If not set, auto-derived from data.
- `dbin::Float64`: Bin width (in log-space).
- `nli::Int`: Number of bins; if not set, auto-derived from data bounds.
- `vol_local::Float64`: Local volume normalization (default: `length(plotdata)`).
- `xlabel::String`, `ylabel::String`: Axis labels (actual PDF labels come from `get_pdf_label(var_name)`).
- `title::String`: Plot title (overridden if `is_ions == true`).
- `author::String`: Watermark text placed on the lower-left of the figure.
- `resolution::String`, `unittime::String`: Overlay text near the top-right.
- `show_stats::Bool`: If `true`, displays a statistics summary below the plot.
- `logscale::Bool`: If `true`, uses `stats.matrix_result` for the PDF; otherwise uses the raw slice.
- `stats::Union{Nothing, Matrix2DStatistics}`: Precomputed statistics. If `nothing`, computed automatically.
- `formats::Vector{String}`: Output formats (e.g., `["pdf","png","svg"]`).  
  When vector formats are included, rasterization is optionally applied to selected layers using `rasterize_scale`.
- `rasterize_scale::Int`: DPI multiplier when rasterizing plot layers (PDF/SVG export).
- `filenum::Int`: Numeric identifier appended to generated filenames.
- `save_path::AbstractString`: Base folder where output files are saved.

# Behavior
1. Computes or reuses provided statistics (`min`, `max`) and selects between raw/log-transformed inputs.
2. Computes logarithmic bounds (`binmin`, `tmp_max`) from `log10(minval)` and `log10(maxval)`.
3. Computes `nli` from the chosen bounds and calls `calculate_pdf(plotdata, binmin, dbin, nli, vol_local)`.
4. Locates min/max coordinates in the PDF output using `find_min_max_coords`.
5. Creates a Makie `Figure` and `Axis`, plots the PDF curve, and annotates extrema using `add_text_at`.
6. Adds watermark text, resolution label, and time label; text positioning uses figure-relative coordinates.
7. Exports the resulting plot with `writeplot` and `save_or_display`, supporting multiple output formats.

# Returns
- `Tuple{Axis, Figure}`: The PDF axis and the associated figure.

# Dependencies
The following must be available in scope:  
`statistics_data`, `Matrix2DStatistics`, `get_pdf_label`, `calculate_pdf`, `find_min_max_coords`,  
`ionstexto`, `LaTeXString`, `add_text_at`, `writeplot`, `save_or_display`,  
and Makie objects (`Figure`, `Axis`, `lines!`).

# Notes
- If the data contains non-positive values, `log10(minval)` may be invalid. Consider clamping to a small
  positive epsilon or filtering the data before computing log-space bounds.
- The axis limits and labels are derived from the dictionary returned by `get_pdf_label(var_name)`.
"""
function plot_pdf(xg::AbstractVector, yg::AbstractVector,
                      slice::AbstractMatrix,
                      var_name::String;
                      is_ions,
                      kern, ionz,
                      atom::Int = 1,
                      binmin::Float64 = 0.0,
                      dbin::Float64  = 0.1,
                      nli::Int = 100,
                      vol_local::Float64 = 1.0,   # local volume normalization
                      xlabel::String = "",
                      ylabel::String = "",
                      title::String = "",
                      author::String = "",
                      resolution::String = "",
                      unittime::String = "",
                      filenum::Int = 3000,
                      show_stats::Bool = false,
                      logscale::Bool = true,
                      stats::Union{Nothing, Matrix2DStatistics} = nothing,
                      formats::Vector{String} = ["pdf"],              
                      rasterize_scale::Int = 1,  # 1..3: DPI multiplier for rasterized layers
                      save_path::AbstractString = "./data/output/maps/pdf"   
            )
   # --- Detect if output is vector format → activate rasterization ---         
   export_vector = any(fmt -> lowercase(fmt) in ("pdf", "svg"), formats)       
    # Compute statistics if not provided
    stats === nothing && (stats = statistics_data(slice))

    # Min and max (from the statistics object)
    minval = stats.statistics_data.min_value.value2D
    maxval = stats.statistics_data.max_value.value2D

    # Choose data: log-scale uses stats.matrix_result; otherwise raw slice
    if logscale
        plotdata = stats.matrix_result
    else
        plotdata = slice
    end

    # Labels for the PDF plot (limits and axis names)
    pdflabel = get_pdf_label(var_name)

    # Log-space bounds from data min/max
    minval_log = log10(minval)
    maxval_log = log10(maxval)

    # Auto-derive bin range if not provided
    binmin = floor(minval_log)
    tmp_max = ceil(maxval_log)

    # For testing: set local volume to number of elements (can be replaced by a physical volume)
    vol_local = length(plotdata)

    # Auto-derive number of bins from range and bin width
    nli = floor(Int, (tmp_max - binmin) / dbin)

    # Compute the PDF over bins (dbf: bin centers; dbrev6: PDF values)
    dbf, dbrev6 = calculate_pdf(plotdata, binmin, dbin, nli, vol_local)

    # Find coordinates of min/max on the PDF curve
    min_coords, max_coords = find_min_max_coords(dbf, dbrev6)

    # Optional: derive y-axis bounds from PDF (unused here but kept for reference)
    ymin = minimum(dbrev6)
    ymax = ceil(maximum(dbrev6))

    # Ion mode: override title and displayed variable name
    var_name_ion = var_name
    if is_ions
        ion_labels = ionstexto(kern, ionz)
        title = ion_labels.titleion
        var_name_ion = ion_labels.titleion
    end

    # Create figure and axis
    fig = Figure(size = (800, 800))
    ax = Axis(fig[1, 1],titlesize=24,
        title = "Density Probability for " * var_name_ion,
        xlabel = pdflabel["x1label"], xlabelsize = 24,
        ylabel = pdflabel["x2label"], ylabelsize = 24,
    
        xticklabelsize = 15,
        yticklabelsize = 15,

        # 2. Enable ticks and use CORRECT names for mirroring

        yticksvisible = true,
        xticksmirrored = true,    
        yticksmirrored = true,    

        # 3. Set ticks to point inwards
        xtickalign = 1,
        ytickalign = 1,
        
        # 4. Tick aesthetics
        xticksize = 10,
        yticksize = 10,
        xtickwidth = 1.2,
        ytickwidth = 1.2,

        yticklabelrotation = π/2, # rotation

        # 5. Ensure the grid is also disabled
        xgridvisible = false,
        ygridvisible = false,
       # aspect     = DataAspect(),
            
        limits = (pdflabel["xlabelmin"], pdflabel["xlabelmax"], pdflabel["ylabelmin"], pdflabel["ylabelmax"])
    )

    # Plot the PDF curve (equivalent to pgline)
    lines!(ax, dbf, dbrev6,
    rasterize = export_vector ? rasterize_scale : false # decrease --> low size
    )

    # Annotate maximum point
    max_text = "($(round(max_coords[1], digits=2)), $(round(max_coords[2], digits=2)))"
    text = "Maximum: " * max_text
   _ = add_text_at(fig,ax, (max_coords[1], max_coords[2]), text;fontsize=24,
                    is_percentage = false, offset = (0.2, 0.2),
                    marker = :circle, marker_size = 15, color = :blue) 

    # Annotate minimum point
    min_text = "($(round(min_coords[1], digits=2)), $(round(min_coords[2], digits=2)))"
    text = "Minimum: " * min_text
    _ = add_text_at(fig,ax, (min_coords[1], min_coords[2]), text;
                    is_percentage = false, offset = (0.2, 0.2),
                    marker = :circle, marker_size = 15, color = :red)

    # Watermark and overlay text (relative coordinates)
    _ = add_text_at(fig,ax, (0.10, 0.05), LaTeXString(author); fontsize = 18, is_percentage = true, color = :black)
    _ = add_text_at(fig,ax, (0.60, 0.90), LaTeXString(resolution*"; "); fontsize = 24, is_percentage = true, color = :black)
    _ = add_text_at(fig,ax, (0.85, 0.90), LaTeXString(L"\text{300.00  } " * unittime); fontsize = 24, is_percentage = true, color = :black)

    # Optionally show a short stats summary below the plot
    if show_stats
        txt = @sprintf("min=%.3f, max=%.3f, mean=%.3f", minval, maxval, stats.statistics_data.mean)
        Label(fig[2, 1], txt; tellwidth = false, halign = :left)
    end

    # Configure output files using parameterized 'formats'
    files = writeplot(42;
        lpdf = true,
        variavel = var_name,
        atom = atom,
        filenum = filenum,
        datetime_format = "ddmmyy_HHMM",
        formats = formats
    )
    # Save or display the figure
    save_or_display(
        fig, files;
        sav = true,
        disp = true,
       # output_path = subdir
       output_path = save_path
    )
    return ax, fig
end

# ==============================================================================
#
#  Generate a 2×2 subplot figure
#
# ==============================================================================
"""
    maps_subplot!(
        data::AbstractArray{Float64,3},
        xgrid,
        ygrid,
        zgrid,
        var_name::String;
        cfg::ConfigData,
        pgp::PGPData,
        rt::RuntimeData,
        modions::ModionsData,
        formats::Vector{String} = ["png"],
        save_path::AbstractString = "./data/output/mapas/color"
    ) -> Nothing

Generate a 2×2 subplot figure (Contour, Heatmap, Contour+Heatmap, and PDF) for each selected Z-slice.
The function crops to real-space bounds, applies optional scaling for density, computes statistics and
color ranges, creates the subplots, annotates metadata, and saves the figure in multiple formats.

# Arguments
- `data::AbstractArray{Float64,3}`: 3D data cube.
- `xgrid`, `ygrid`, `zgrid`: Grid vectors for X/Y/Z axes (typically `AbstractVector{<:Real}`).
- `var_name::String`: Variable name used for labels, titles, and saving.
- `cfg::ConfigData`: Configuration with real-space limits, scales, and log flags.
- `pgp::PGPData`: Plot/graphics parameters (titles, labels, view toggles).
- `rt::RuntimeData`: Runtime loop configuration (`lmin`, `stepl`, `lmax`).
- `modions::ModionsData`: Ion-related configuration (used by `setminmaxvar`).
- `formats::Vector{String}`: Output formats to save (e.g., `["png"]`, `["pdf","png"]`, `["svg"]`).
- `save_path::AbstractString`: Base folder where figures are saved; subfolder per `var_name` is created.

# Additional Keywords
- `rasterize_scale::Int = 1`: DPI multiplier (e.g., `1..3`) used to rasterize only heatmap layers when exporting vector formats (PDF/SVG).
- `id_string::AbstractString = "UNKNOWN_ID"`: Snapshot identifier used for filenames and FAIR subdirectories created through `prepare_variable_paths`.
- `root::AbstractString = "output_fair"`: Root directory for FAIR-style output directory trees.

# Behavior
1. Reads real-space cropping limits from `cfg.real_dims`.
2. Loops over Z indices (`lmin:stepl:lmax`) and, if `pgp.view.top` is enabled, extracts the XY slice for that Z-plane.
3. Applies density scaling via `cfg.scales.denscale` if plotting density (`var_name == "den"`).
4. Computes descriptive statistics using `statistics_data(slice, log10)`, then selects the color range using `setminmaxvar`.  
   Falls back to raw min/max if `setminmaxvar` yields `(0.0, 0.0)`.
5. Creates a 2×2 figure:
   - **ax1**: Contour
   - **ax2**: Heatmap
   - **ax3**: Heatmap + Contour
   - **ax4**: PDF of raw or log-transformed data
6. Constructs colorbars with custom ticks between `smin` and `smax` (minor step `0.125`).
7. Annotates author/resolution/unittime and min/max locations.
8. Generates output filenames via `writeplot`, using `filenum` from `id_string`, and ensures valid fallback names if necessary.
9. Saves results to FAIR-style subfolders under `vp.subplots` from `prepare_variable_paths`.

# Returns
- `Nothing`. The function saves figures as side effects.

# Dependencies
Requires:  
`crop_slice`, `statistics_data`, `setminmaxvar`, `get_pdf_label`,  
`calculate_pdf`, `find_min_max_coords`,  
Makie primitives (`Figure`, `Axis`, `Colorbar`, `contour!`, `heatmap!`, `lines!`),  
metadata utilities (`LaTeXString`, `add_text_at`),  
I/O utilities (`writeplot`, `save_or_display`),  
FAIR folder generation (`prepare_variable_paths`, `mkpath`).

# Notes
- Use `cfg.scales.logs = true` to use log-transformed statistics for all subplots.
- Constant slices are auto-expanded using a small ε to avoid degenerate color ranges.
- Vector formats (`pdf`, `svg`) rasterize only heatmap layers using `rasterize_scale`; contours and text remain vector.
- If `formats` is empty, a warning is issued and the default `["pdf"]` is applied.
- If `writeplot` returns no filenames, a timestamp-based fallback name is generated.
"""

function maps_subplot!(data::AbstractArray{Float64,3}, xgrid, ygrid, zgrid,
                        var_name::String;
                        cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData,
                        formats::Vector{String} = ["pdf"],
                        rasterize_scale::Int = 1,  # 1..3: DPI multiplier for rasterized layers
                        id_string::AbstractString = "UNKNOWN_ID",     
                        root::AbstractString      = "output_fair"      
)
    # Extract spatial boundaries from configuration
    xmin = cfg.real_dims.min.x
    xmax = cfg.real_dims.max.x
    ymin = cfg.real_dims.min.y
    ymax = cfg.real_dims.max.y

    # Metadata for annotations
    author     = pgp.title.author
    resolution = pgp.title.resolution
    unittime   = pgp.title.unitime
    
    vp = prepare_variable_paths(id_string, var_name; root=root)
    fn = parse(Int, replace(id_string, "all00" => ""))
    export_vector = any(fmt -> lowercase(fmt) in ("pdf", "svg"), formats)

    # Loop through Z-dimension slices to generate figures
    for l in rt.loop_graphic.lmin:rt.loop_graphic.stepl:rt.loop_graphic.lmax
        if pgp.view.top
            # --- DATA PREPARATION SECTION ---
            # Extract 2D slice from 3D data at current Z-level and crop to bounds
            
            xg, yg, slice = crop_slice(data[:, :, l], xgrid, ygrid; xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)

            # Set a readable variable label for titles
            var_namec = var_name
            # Apply density scaling if this is a density variable
            if var_name == "den"
                var_namec = "Density"
                slice ./= cfg.scales.denscale
            end

            # Get PDF label configuration for current variable
            pdflabel = get_pdf_label(var_name)

            # Calculate statistics and plotting ranges
            stats = statistics_data(slice, log10)
            result = setminmaxvar(var_name, pgp, modions)  # External function for min/max calculation
            smin, smax = result === nothing ? (0.0, 0.0) : result
            
            # Fallback when setminmaxvar returns (0.0, 0.0)
            if smin == 0.0 && smax == 0.0
               smin = stats.statistics_data.min_value.value2D # smin = minimum(data_to_plot)
               smax = stats.statistics_data.max_value.value2D # smax = maximum(data_to_plot)
            end

            # if the slice is constant, avoid degenerate ranges.
            const_slice = isapprox(smin, smax; rtol = 1e-12, atol = 1e-12)
            if const_slice
                # Use a small epsilon to “open” the range.
                eps = max(abs(smin), 1.0) * 1e-6 + 1e-12
                smin -= eps/2
                smax += eps/2
            end
            
            # --- Int Ticks to setmin..setmax ---
            tmin = ceil(Int, smin)
            tmax = floor(Int, smax)
            # ticks_vec = collect(tmin:1:tmax) .|> float
        
            step_minor = 0.125 #
            positions  = collect(range(tmin, tmax; step=step_minor)) |> float
                    
        labels = map(positions) do x
            isapprox(x, round(x); atol=1e-9) ? string(Int(round(x))) : ""
        end       
                
            # Apply logarithmic transformation if enabled
            data_to_plot = cfg.scales.logs ? stats.matrix_result : slice

            # --- SUBPLOT CREATION SECTION ---
            # Create main figure with optimized size
            fig_final = Figure(size = (800, 800))

            # --- AXES CREATION ---
            # ax1: Contour plot (top-left)
            ax1 = Axis(fig_final[1, 1][1, 1],
                       title = "Contour for $(var_namec)",
                       xlabel = "X (pc)",
                       ylabel = "Y (pc)",
                       xtickalign = 1,
                       ytickalign = 1,
                       yticklabelrotation = π/2
                    )

            # ax2: Heatmap (top-right)
            ax2 = Axis(fig_final[1, 2][1, 1],
                       title = "Heatmap for $(var_namec)",
                       xlabel = "X (pc)",
                       ylabel = pgp.labels.ylabel,
                       xtickalign = 1,
                       ytickalign = 1,
                       yticklabelrotation = π/2)
                       
                       ax1.leftspinevisible   = false
                       ax1.rightspinevisible  = false
                       ax1.topspinevisible    = false
                       ax1.bottomspinevisible = false
                        
                       ax1.xgridvisible = false
                       ax1.ygridvisible = false

            # ax3: Combined contour + heatmap (bottom-left)
            ax3 = Axis(fig_final[2, 1][1, 1],
                       title = "Contour + Heatmap for $(var_namec)",
                       xlabel = "X (pc)",
                       ylabel = "Y (pc)",
                       xtickalign = 1,
                       ytickalign = 1,
                       yticklabelrotation = π/2)

            # ax4: Probability density function (bottom-right)
            ax4 = Axis(fig_final[2, 2][1, 1],
                       title = "Density Probability for " * var_namec,
                       xlabel = pdflabel["x1label"],
                       ylabel = pdflabel["x2label"],
                       
                        # 2. Enable ticks and use CORRECT names for mirroring
                        xticksvisible = true,
                        yticksvisible = true,
                        xticksmirrored = true,    
                        yticksmirrored = true,    

                        # 3. Set ticks to point inwards
                        xtickalign = 1,
                        ytickalign = 1,
                        
                        # 4. Tick aesthetics
                        xticksize = 10,
                        yticksize = 10,
                        xtickwidth = 1.2,
                        ytickwidth = 1.2,

                        yticklabelrotation = π/2, # rotation

                        # 5. Ensure the grid is also disabled
                        xgridvisible = false,
                        ygridvisible = false,
                       
                       limits = (pdflabel["xlabelmin"], pdflabel["xlabelmax"],
                                 pdflabel["ylabelmin"], pdflabel["ylabelmax"]))

            # --- PLOT CREATION ---
            # P1: Contour plot
            p1 = contour!(ax1, xg, yg, data_to_plot;
                          levels = LinRange(smin, smax, 10),
                          colormap = :viridis,
                          #linewidth = 1.5,
                          colorrange = (smin, smax),
                          label = "Contours: $(var_namec)")

            # P2: Heatmap
            p2 = heatmap!(ax2, xg, yg, data_to_plot;
                          colormap = :viridis,
                          rasterize = export_vector ? rasterize_scale : false, # decrease --> low size
                          colorrange = (smin, smax))

            # P3: Combined contour and heatmap
            p3_heat = heatmap!(ax3, xg, yg, data_to_plot;
                               colormap = :viridis,
                               rasterize = export_vector ? rasterize_scale : false, # decrease --> low size
                               colorrange = (smin, smax))
            p3_cont = contour!(ax3, xg, yg, data_to_plot;
                               levels = LinRange(smin, smax, 10),
                               color = :black,
                               linewidth = 0.5,
                               label = "Contours (Black)")

            # --- PDF (P4) CREATION ---
            # Calculate PDF statistics and bins
            minval     = stats.statistics_data.min_value.value2D
            maxval     = stats.statistics_data.max_value.value2D
            minval_log = log10(minval)
            maxval_log = log10(maxval)
            dbin       = 0.1

            binmin    = floor(minval_log)
            tmp_max   = ceil(maxval_log)
            vol_local = length(data_to_plot)  # Volume for normalization
            nli       = floor(Int, (tmp_max - binmin) / dbin)

            # Calculate probability density function
            dbf, dbrev6 = calculate_pdf(data_to_plot, binmin, dbin, nli, vol_local)

            # Find coordinates of maximum and minimum values
            min_coords, max_coords = find_min_max_coords(dbf, dbrev6)

            # Optionally derive y-axis limits for PDF plot (kept for reference)
            ymin = minimum(dbrev6)
            ymax = ceil(maximum(dbrev6))

            # Create PDF line plot
            p4 = lines!(ax4, dbf, dbrev6, label = "PDF of $(var_name)",
            rasterize = export_vector ? rasterize_scale : false # decrease --> low size
            )

            # --- COLORBAR CONFIGURATION ---
            # Colorbar for contour plot (P1)
            Colorbar(fig_final[1, 1][1, 2],
                     label = pdflabel["x1label"],
                     ticklabelrotation = π/2,
                     tickalign = 1,
                     colormap = p1.colormap[],
                     colorrange = p1.colorrange[],
                     ticks = (positions, labels),
                     labelsize = 16)

            # Colorbar for heatmap (P2)
            Colorbar(fig_final[1, 2][1, 2],
                     label = pdflabel["x1label"],
                     ticklabelrotation = π/2,
                     tickalign = 1,
                     colormap   = p2.colormap[],     
                     colorrange = p2.colorrange[],
                     ticks = (positions, labels), 
                     labelsize = 16)

            # Colorbar for combined plot (P3)
            Colorbar(fig_final[2, 1][1, 2],
                     ticklabelrotation = π/2,
                     tickalign = 1,
                     label = pdflabel["x1label"],
                     
                    colormap   = p3_heat.colormap[],     
                    colorrange = p3_heat.colorrange[],   
                    ticks = (positions, labels),
                    labelsize = 16)

            # --- FINAL FIGURE CONFIGURATION ---
            # Add global title
            Label(fig_final[0, :], "Multi-Method Analysis: $(var_name) Distribution at Z=$(l)";
                  fontsize = 20,
                  color = :navy,
                  padding = (0, 0, 5, 0))

            # Annotate max/min points on the PDF (ax4)
            max_text = "($(round(max_coords[1], digits = 2)), $(round(max_coords[2], digits = 2)))"
            text     = "Maximum: " * max_text
            _ = add_text_at(fig_final[2, 2][1, 1],ax4, (max_coords[1], max_coords[2]), text;fontsize = 12,is_percentage = false, offset = (0.2, 0.2), marker = :circle, marker_size = 13, color = :blue) 

            min_text = "($(round(min_coords[1], digits = 2)), $(round(min_coords[2], digits = 2)))"
            text     = "Minimum: " * min_text
           _ = add_text_at(fig_final[2, 2][1, 1],ax4, (min_coords[1], min_coords[2]), text;
                            is_percentage = false, offset = (0.2, 0.2),
                            marker = :circle, marker_size = 13, color = :red)

            # Watermark and metadata (relative positions on ax4)
            _ = add_text_at(fig_final[2, 2][1, 1],ax4, (0.15, 0.05), LaTeXString(author);
                            fontsize = 12, is_percentage = true, color = :black)
            _ = add_text_at(fig_final[2, 2][1, 1],ax4, (0.60, 0.90), LaTeXString(resolution*"; ");
                            fontsize = 12, is_percentage = true, color = :black)
            _ = add_text_at(fig_final[2, 2][1, 1],ax4, (0.85, 0.90), LaTeXString(L"\text{300.00} " * unittime);
                            fontsize = 12, is_percentage = true, color = :black) 
  
# --- SAVE FIGURE(S) ---

# 1) Sanitize formats: never empty
if isempty(formats)
    @warn "formats is empty in mapas_subplot!, defaulting to [\"png\"]"
    formats = ["pdf"]
end

# 2) Build filenames with writeplot (for images: lpdf=false)
files = writeplot(42;
    lpdf = false,                    # no "PDF_" prefix for subplot images
    variavel = var_name,
    atom = 8,
    filenum = fn,
    datetime_format = "ddmmyy_HHMM",
    formats = formats                # e.g., ["png"], ["png","svg"], etc.
)

# 3) Fallback: if writeplot returns empty (shouldn't), build a manual filename
if isempty(files)
    ts = Dates.format(Dates.now(), "ddmmyy_HHMM")
    files = ["$(var_name)_00$(fn)-042_$(ts).$(formats[1])"]
end

# 4) Save or display into ./data/output/maps/subplot/<var_name>
# Save in <base>/<var_name>/subplot
    mkpath(vp.subplots)   # creates <root>/snapshots/<id>/variables/<var>/subplots
    save_or_display(
        fig_final, files;
        sav = true,
        disp = true,
        output_path = vp.subplots
    )
    end
 end
   return nothing
end



#---------------------------------------



# ==============================================================================
# Function: plot_ion_heatmap
# Purpose: Generate 2D heatmap visualizations of 3D ion fraction data
# ==============================================================================

"""
    plot_ion_heatmap(data_3d, kern, ionz; slice_axis = :z, slice_index = 1, title_suffix = "")

Generate 2D heatmap visualizations from 3D ion fraction data by slicing along specified axes.

This function creates detailed 2D heatmap plots of ion population fractions by extracting
slices from 3D simulation data. It supports slicing along any of the three spatial axes
(X, Y, Z) and provides comprehensive labeling with element and ionization state information.

# Arguments
- `data_3d::Array{Float64,3}`: 3D array containing ion fraction data (typically from `temprops.xionvar`)
- `kern::Int`: Element identifier/kernel number for labeling
- `ionz::Int`: Ionization state for labeling

# Keyword Arguments
- `slice_axis::Symbol=:z`: Axis along which to slice (:x, :y, or :z)
- `slice_index::Int=1`: Index position along the slicing axis
- `title_suffix::String=""`: Additional text to append to the plot title

# Visualization Features
- Automatic logarithmic scaling of ion fraction data
- Comprehensive labeling with element and ionization state information
- Configurable slicing along X, Y, or Z axes
- Professional color mapping using Viridis colormap
- Proper aspect ratio preservation for accurate spatial representation

# Output
- Displays an interactive figure with heatmap and colorbar
- Returns the figure object for further manipulation or saving

# Example
```julia
# Plot a Z-slice at index 50 for element 6, ionization state 2
plot_ion_heatmap(ion_data, 6, 2, slice_axis=:z, slice_index=50, title_suffix="Mid-plane")

"""
function plot_ion_heatmap(data_3d, kern, ionz; slice_axis = :z, slice_index = 1, title_suffix = "")
    # Apply logarithmic scaling to ion fraction data for better visualization
    log_data = log10.(data_3d)

    # Extract 2D slice based on specified axis and index
    if slice_axis == :x
        slice_data = log_data[slice_index, :, :]
        slice_info = "Slice X = $slice_index"
    elseif slice_axis == :y
        slice_data = log_data[:, slice_index, :]
        slice_info = "Slice Y = $slice_index"
    else  # Default: slice along Z-axis
        slice_data = log_data[:, :, slice_index]
        slice_info = "Slice Z = $slice_index"
    end

    # Generate ion-specific labels for plot elements
    ion_labels = ionstexto(kern, ionz)

    # Create figure with appropriate dimensions
    fig = Figure(size = (800, 600))

    # Construct comprehensive title string
    title_str = "Element: $kern, Ion: $ionz | $slice_info $title_suffix"

    # Create axis with ion-specific labeling
    ax = Axis(fig[1, 1], 
            title = ion_labels.titleion, 
            xlabel = "X Grid Index", 
            ylabel = "Y Grid Index")

    # Generate heatmap with scientific colormap
    hm = heatmap!(ax, slice_data, colormap = :viridis)

    # Add colorbar with ion fraction labeling
    Colorbar(fig[1, 2], hm, label = ion_labels.labelion)

    # Maintain proper data aspect ratio for accurate spatial representation
    ax.aspect = DataAspect()

    # Display the generated figure
    display(fig)

    return fig
end


# ==============================================================================
#
# Create a multi-subplot figure visualizing all ionization states
#
# ==============================================================================

"""
    plot_element_subplot(
        temp_props::TemperatureProperties,
        sml::SimulationData,
        element::Element,
        ee_num::Int;
        ncols::Int = 3,
        save_dir::AbstractString = "",
        formats::Vector{String} = ["png"],
        fixed_colorrange::Tuple{Float64,Float64} = (-12.0, 2.5),
        z_index::Int = 1,
        colormap = cgrad(get_palette(15)),
        xticks::AbstractVector = 0:200:1000,
        yticks::AbstractVector =  0:200:1000
    ) -> Figure

Create a multi-subplot figure visualizing all ionization states (0..ee_num) for a given element.
Each subplot shows a heatmap (log10 of the data) with a **fixed** color range across subplots and a
colorbar. The layout is automatically computed with `ncols` columns and enough rows to fit all states.

# Arguments
- `temp_props::TemperatureProperties`: Structure containing `xionvar` (`Nx × Ny × Nz × Nelements × Nions`).
- `sml::SimulationData`: Provides `X_grid` and `Y_grid` for axis coordinates.
- `element::Element`: Element metadata (`kernmax`, `zelem`, `idk`, etc.).
- `ee_num::Int`: Highest ionization state to display. Plots states `0:ee_num`.
- `ncols::Int`: Number of columns in the subplot grid.
- `save_dir::AbstractString`: Directory where output is saved. If empty, the figure is only returned.
- `formats::Vector{String}`: Output formats (e.g., `["png"]`, `["pdf","png"]`, `["svg"]`).
- `fixed_colorrange::Tuple{Float64,Float64}`: Fixed color range in log-space for all subplots.
- `z_index::Int`: Which Z‑plane of `xionvar` to visualize (default: `1`).
- `colormap`: Colormap used for heatmaps (default: `cgrad(get_palette(15))`).
- `xticks`, `yticks`: Tick locations for X and Y axes.

# Additional Keyword
- `rasterize_scale::Int = 1`: DPI multiplier (1..3) used to rasterize heatmap layers when exporting vector formats (PDF/SVG). Axes, text, contours remain vector.

# Behavior
1. Validates `ee_num`, element ID, number of ions, and `z_index` against `xionvar` dimensions.
2. Computes grid layout based on `ee_num + 1` subplots and `ncols` columns.
3. For each ionization state:
   - Extracts the corresponding 2D slice from `xionvar[:, :, z_index, eid, ionz+1]`.
   - Applies `log10` to the values.
   - If all values are identical, injects a tiny variation so the fixed color scale remains valid.
   - Plots a heatmap using the global `fixed_colorrange`.
   - Adds a per‑subplot colorbar with fixed tick positions.
4. Annotates each subplot with element and ionization state metadata (via `ionstexto`).
5. Applies consistent axis ticks (`xticks`, `yticks`) and styling across subplots.
6. Saves the final figure to `save_dir` in all requested `formats`, with a timestamped filename.

# Returns
- `Figure`: The final composed multi‑subplot figure.

# Dependencies
Requires:  
`get_palette`, `cgrad`, `ionstexto`, `get_element_fname`,  
Makie primitives (`Figure`, `Axis`, `GridLayout`, `Colorbar`, `heatmap!`),  
time utilities (`Dates.now`) for timestamping.

# Notes
- `z_index` must satisfy `1 ≤ z_index ≤ size(xionvar, 3)`.
- Fixed color ranges enforce comparability across ionization states.
- If your coordinate grids are not parsecs, adjust X/Y axis labels accordingly.
- When exporting vector formats (`pdf`, `svg`), only heatmap layers are rasterized (via `rasterize_scale`).
"""
function plot_element_subplot(temp_props::TemperatureProperties, 
        sml::SimulationData,
        element::Element, ee_num::Int;
        ncols::Int = 3,
        save_dir::AbstractString = "",
        formats::Vector{String} = ["pdf"], 
        rasterize_scale::Int = 1,  # 1..3: DPI multiplier for rasterized layers
        fixed_colorrange::Tuple{Float64,Float64} = (-12.0, 2.5), 
        z_index::Int = 1,                                        
        colormap = cgrad(get_palette(15)),                       
        xticks::AbstractVector = 0:200:1000,                     
        yticks::AbstractVector = 0:200:1000                      
    )

    # --- Detect if output is vector format → activate rasterization ---
    export_vector = any(fmt -> lowercase(fmt) in ("pdf", "svg"), formats)
    
    # Validate ionization state availability for the element
    if ee_num > element.kernmax || !element.zelem[ee_num]
        println("Ionization state index is not available for this element.")
        return nothing
    end

    # Resolve element id and number of ion states to display
    eid   = element.idk[ee_num]
    nions = ee_num + 1

    # Validate xionvar dimensions (element id and number of ions)
    if (eid > size(temp_props.xionvar, 4)) || (nions > size(temp_props.xionvar, 5))
        println("Insufficient dimensions in 'xionvar' to visualize all ion states.")
        return nothing
    end

    # Validate z_index bounds for the 3rd dimension of xionvar
    if !(1 <= z_index <= size(temp_props.xionvar, 3))
        println("Invalid z_index=$(z_index). Must be within 1..$(size(temp_props.xionvar,3)).")
        return nothing
    end
    
    
    # Create output directory if specified
    if save_dir != ""
        mkpath(save_dir)
    end

    # Superscript dictionary (optional, not currently used in titles)
    superscript_dict = Dict(
        0 => "⁰", 1 => "¹", 2 => "²", 3 => "³", 4 => "⁴", 5 => "⁵", 
        6 => "⁶", 7 => "⁷", 8 => "⁸", 9 => "⁹", 10 => "¹⁰", 11 => "¹¹", 12 => "¹²"
    )

    # --- DYNAMIC LAYOUT COMPUTATION ---
    # Ensure we don't create more columns than we have plots
    nplots = ee_num + 1
    actual_ncols = min(ncols, nplots)
    nrows  = ceil(Int, nplots / actual_ncols)
    
    
    first_label = ionstexto(ee_num, 0)        # tem titleion, etc.
    elem_sym   = first(split(first_label.titleion))  # normalmente dá o símbolo/identificação à esquerda
    
    element_name=get_element_fname(ee_num)

    title_str = @sprintf("(%s%02d--%s%02d)", elem_sym, 0,elem_sym,nplots-1)

    # Calculate figure size based on the actual grid used
    fig_width  = 800 * actual_ncols
    fig_height = 600 * nrows
    fig = Figure(size = (fig_width, fig_height))

    # Global title spanning all columns
    rowsize!(fig.layout, 1, Fixed(46))
    Label(fig[1, 1:actual_ncols], "Ionization States of $element_name: $title_str",
          fontsize = 24, font = :bold, color = :navy, halign = :center)

     println("Starting automatic subplot creation for $nplots ionization states...")
    println("Layout: $nrows rows × $actual_ncols columns")
    println("Fixed color range: $fixed_colorrange") 
    
    smin, smax = fixed_colorrange
    tmin = ceil(Int, smin)              # smallest integer >= smin
    tmax = floor(Int, smax)             # largest integer <= smax
    cb_step_minor = 0.5                 # minor tick step (adjust if too dense)
    cb_positions = Float64.(collect(range(tmin, tmax; step = cb_step_minor)))
    cb_labels = [isapprox(x, round(x); atol=1e-9) ? string(Int(round(x))) : "" for x in cb_positions]
 
    # Loop through all ionization states (0..ee_num)
    for (idx, ionz) in enumerate(0:ee_num)
        # Compute position in the grid
        row = ((idx - 1) ÷ actual_ncols) + 1
        col = ((idx - 1) % actual_ncols) + 1
        
        # Shift one row down because title occupies row 1
        target_row = row + 1
        target_col = col

        superscript_str = get(superscript_dict, ionz, string(ionz))
        println("Processing state $idx/$nplots: ionization $ionz  → Position [$row, $col]") 

        # Obtain labels for this ionization state
        ion_labels = ionstexto(ee_num, ionz)

        # Extract data for this ionization state at the given Z-plane
        data = temp_props.xionvar[:, :, z_index, eid, ionz + 1]

        # Apply log10 transform (ensure positivity upstream if needed)
        data_log = log10.(data)

        # Create an internal grid to control plot + colorbar
        gl = GridLayout(fig[target_row, target_col], alignmode = Outside(30))

        # Main axis for the subplot
        ax = Axis(gl[1, 1],
                  title   = ion_labels.titleion * " - " * ion_labels.ion,
                  xlabel  = "X (pc)",
                  ylabel  = "Y (pc)",
                  titlesize = 14,
                  xtickalign = 1,
                  ytickalign = 1,
                  yticklabelrotation = π/2)

        # Axis ticks configuration
        ax.xticks = xticks
        ax.yticks = yticks

        # Heatmap with the FIXED color range for all subplots
        data_min = minimum(data_log)
        data_max = maximum(data_log)

        if isapprox(data_min, data_max)
            # Special case: all values identical → fabricate tiny variation inside fixed range
            println("  WARNING: All values are identical; using fixed color range placeholder.")
            data_fixed = fill(fixed_colorrange[1], size(data_log))
            if size(data_fixed, 1) > 1 && size(data_fixed, 2) > 1
                data_fixed[1, 1] = fixed_colorrange[2]  # one pixel different
            end

            hm = heatmap!(ax, sml.X_grid, sml.Y_grid, data_fixed;
                          colormap = colormap,
                          colorrange = fixed_colorrange,
                          rasterize = export_vector ? rasterize_scale : false # decrease --> low size
                          )
            # Informative overlay text
          #=  text!(ax,
                  "Constant data\nlog(value) = $(round(data_min, digits = 3))",
                  position = (mean(sml.X_grid), mean(sml.Y_grid)),
                  align    = (:center, :center),
                  color    = :red,
                  fontsize = 10)
          =#
        else
            # Normal case: use the fixed color range
            hm = heatmap!(ax, sml.X_grid, sml.Y_grid, data_log;
                          colormap = colormap,
                          colorrange = fixed_colorrange,
                          rasterize = export_vector ? rasterize_scale : false)
        end

        # Colorbar in the second column of the internal grid
        Colorbar(gl[1, 2], hm;
                 label     = ion_labels.labelion,
                 ticks     = (cb_positions, cb_labels),  # <-- custom ticks applied here
                 ticklabelrotation = π/2, # rotate
                 ticklabelsize = 12,
                 width     = 15,
                 labelsize = 10,
                 tickalign = 1, #  0 (default); 1 (inside);  0.5 (center)
                 vertical  = true
                 )

        # Add identification of the ion state in the plot area
      #=  text!(ax, "$(ion_labels.ion)",
              position = (maximum(sml.X_grid) * 0.85, maximum(sml.Y_grid) * 0.9),
              align    = (:center, :center),
              color    = :white,
              fontsize = 12,
              font     = :bold)
      =#

        # Internal layout proportions (plot ~400px, colorbar ~60px)
        colsize!(gl, 1, Fixed(400))
        colsize!(gl, 2, Fixed(60))
    end

    # Adjust spacing between subplots
    rowgap!(fig.layout, 10)
    colgap!(fig.layout, 10)

    # Ensure main columns have uniform width
    for c in 1:actual_ncols
        colsize!(fig.layout, c, Auto())
    end

    # Display the composed figure
    # display(fig)

    # Save the figure in all requested formats
    if save_dir != ""
        temp_labels = ionstexto(ee_num, 0)
        elem_sym = first(split(temp_labels.titleion))
        data_str = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
        #basefile = joinpath(save_dir, "$(elem_sym)_$(id_string)_states-0to$(ee_num)_$(data_str)")
        basefile = joinpath(save_dir, "$(elem_sym)_states-0to$(ee_num)_$(data_str)")
        for ext in formats
            save("$(basefile).$(ext)", fig)
        end
        println("Figure saved under: $(save_dir) (formats: $(join(formats, ", ")))")
    end
    
     println("Automatic subplot creation completed!") 

   return fig
 end 

# =================================================================================================




