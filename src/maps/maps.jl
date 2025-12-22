

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

"""
    create_plot_structure(; xsize=800, ysize=600,
                          title="Title", xlabel="X(pc)", ylabel="Y(pc)",
                          valmin=0, step=200, valmax=1000)

Creates and configures a Makie Figure and Axis with specified labels,
titles, and default tick settings.

This function provides a pre-configured plotting canvas, ready for data.
By returning the `fig` and `ax` objects, it allows for further manual
customization, such as adding different plot types or modifying
properties.

# Arguments
- `xsize::Int`: The width of the figure in pixels. Defaults to `800`.
- `ysize::Int`: The height of the figure in pixels. Defaults to `600`.
- `title::String`: The main title of the plot. Defaults to `"Title"`.
- `xlabel::String`: The label for the x-axis. Defaults to `"X(pc)"`.
- `ylabel::String`: The label for the y-axis. Defaults to `"Y(pc)"`.
- `valmin::Real`: The starting value for axis ticks. Defaults to `0`.
- `step::Real`: The interval between axis ticks. Defaults to `200`.
- `valmax::Real`: The ending value for axis ticks. Defaults to `1000`.

# Returns
- A tuple `(fig, ax)` containing the newly created `Figure` and `Axis` objects.
  These can be used for subsequent plotting and customization.

# Example
```julia
# Create a plot with the default settings (size 800x600, ticks 0:200:1000)
fig, ax = create_plot_structure()

# Override default values for a specific plot
fig2, ax2 = create_plot_structure(
    xsize=1000,
    ysize=500,
    title="Custom Ticks and Size",
    xlabel="Time (s)",
    ylabel="Velocity (m/s)",
    valmin=-10,
    step=5,
    valmax=10
)

# You can now add plots to the `ax` object
lines!(ax2, -10:10, sin)

"""
function create_plot_structure(;
    xsize=800,
    ysize=800,
    title="Title",
    subtitle = "",
    titlesize = 16,      # increase the size font
    titlegap = 20,       # increase the size betweenthe title and graphic
    xlabel="X(pc)",
    ylabel="Y(pc)",
    valmin=0,
    step=200,
    valmax=1000
)
   # 1. Create the figure with the specified size
    fig = Figure(size=(xsize, ysize))
  # 2. Create the Axis with titles and labels
   ax = Axis(fig[1, 1],
        title=title,
        subtitle = subtitle,
        titlesize=titlesize,
        titlegap=titlegap,
        xlabel=xlabel,
        ylabel=ylabel
    )
    # 3. Set the axis ticks using the provided or default parameters
    ticks_range = valmin:step:valmax
    ax.xticks = ticks_range
    ax.yticks = ticks_range

    # 3. Define os limites dos eixos para garantir que os ticks sejam visíveis
    # A função `limits!` define os limites para (min_x, max_x, min_y, max_y)
    limits!(ax, valmin, valmax, valmin, valmax)

    # 4. Return the objects for subsequent use
    return fig, ax
end

# ==============================================================================


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

# Function to select the color palette (equivalent to the palett subroutine)
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

# Function to select the plot label (equivalent to the label subroutine)
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

# Function to add the color scale (equivalent to the escala subroutine)
"""
    escala!(fig::Figure, setmin::Real, setmax::Real; kwargs...)

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

# Returns
- `Colorbar`: The created Makie Colorbar object.
"""
function escala!(fig::Figure,
               setmin::Real,
               setmax::Real;
               side::Symbol = :right, # :right, :left, :top, :bottom
               grid_position::Union{Nothing,Tuple{Int,Int}} = nothing,
               labelsize = 18,
               colormap = :viridis,
               logs::Bool = false,
               front::Bool = false,
               variavel::String = "den",
               atom::Int = 1,
               labelion::String = "")

     # --- Determine Label ---
     # label = generate_label("elez"; atom=8)
   if isempty(labelion)
       # Note: The original code uses fixed values (true, 8, "H+") for log, atom, and ion
       # when labelion is empty, which might be a bug or temporary choice.
       # Using the provided kwargs for a more general case, but keeping the original logic for atom/ion fallback.
       # The `get_label` function is expected to be defined elsewhere.
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
    
    # --- Create colorbar ---
    cbar = Colorbar(fig[pos...],
        limits = (setmin, setmax),
        colormap = colormap,
        vertical = vertical,
        label = label, # <-- LaTeXString conversion is handled internally by Makie/CairoMakie
        labelsize = labelsize 
    )

    return cbar
end

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
    #text::String = "© Copyright",
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

"""
    add_text_at(ax, x, y, texto; kwargs...)
    
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
    add_text_at(ax, 0.5, 0.75, "Center Text")
    
    # Add text with marker at absolute coordinates
    add_text_at(ax, 5, 3, "Point", is_percentage=false, marker=:circle)
    
    # Add text with offset and custom styling
    add_text_at(ax, 0.3, 0.4, "Offset Text", offset=(0.1, -0.05), color=:red, fontsize=14)
    ```
    """

function add_text_at(ax, x, y, text;
                        align = (:center, :center),
                        fontsize = 12,
                        color = :black,
                        is_percentage = true,
                        marker::Union{Symbol,Nothing} = nothing,
                        offset = (0.0, 0.0),
                        marker_size = 10,
                        kwargs...)
 
 # Handle percentage-based positioning
        if is_percentage
            # Access current axis limits to calculate relative positioning
            x_min, x_max, y_min, y_max = ax.limits[]
            
            # Convert relative coordinates (0-1 range) to absolute plot coordinates
            x_pos = x_min + x * (x_max - x_min)
            y_pos = y_min + y * (y_max - y_min)
        else
            # Use coordinates directly for absolute positioning
            x_pos = x
            y_pos = y
        end
        
        # Apply offset to the calculated position
        dx, dy = offset
        final_x = x_pos + dx
        final_y = y_pos + dy

        # Add marker at the original position (before offset) if specified
        if !isnothing(marker)
            scatter!(ax, [x_pos], [y_pos],
                    marker = marker,
                    markersize = marker_size,
                    color = color,
                    kwargs...)
        end

        # Add text at the final position (including offset)
        text!(ax, Point2f(final_x, final_y),
            text = string(text),  # Ensure input is converted to string
            align = align,
            fontsize = fontsize,
            color = color,
            kwargs...)
        
        # Return final coordinates for reference or further processing
        return (x = final_x, y = final_y)
end   
   
   
# ==============================================================================

function pgmtext_in(fig, side::String, padding::Real, x::Real, y::Real, text::String; fontsize=12)
    pos = lowercase(side[1]) == 'b' ? Bottom() :
          lowercase(side[1]) == 'l' ? Left() :
          lowercase(side[1]) == 't' ? Top() : error("Side inválido: $side")

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

function escrever!(fig, xlabel::String, ylabel::String, title::String;
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

function pglabel!(fig, xlabel::String, ylabel::String, title::String)
    pgmtext_in(fig, "B", 2.7, 0.5, 0.5, xlabel)
    pgmtext_in(fig, "L", 2.2, 0.5, 0.5, ylabel)
    pgmtext_in(fig, "T", 1.3, 0.5, 0.5, title)
end

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
                plotfile = @sprintf("elez=%02d-%04d%4s%03d-%3s", atom, filenum, graf1, ref, view)
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
            plotfile = @sprintf("elez=%02d-%06d-%03d", atom, filenum, ref)
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
            save(path, fig)   # Save figure to the given file path
            @info "Figure saved: $path"
        end
    end

    # Display the figure if requested
    if disp
        display(fig)
    end
end

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
  `heatmap!`, `escala!`, `add_copyright`, `add_text_at`, `writeplot`, `save_or_display`.

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
    escala!(fig, -4, 1.6; side = :right, colormap = my_pallete_color, variavel = "tem")

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
        colormap = :viridis,
        min_color = :black,
        max_color = :white,
        colorbar_label::String = "",
        show_stats::Bool = false,
        logscale::Bool = false,
        stats::Union{Nothing, Matrix2DStatistics} = nothing,
        formats::Vector{String} = ["png"],                         # NEW: output formats
        save_path::AbstractString = "./data/output/mapas/color"    # NEW: base output path
    ) -> Figure

Render a heatmap for a 2D data slice over grids `xg` and `yg` using Makie, with optional log scaling,
min/max markers, a colorbar, watermark/overlay text, and saving in multiple formats.

# Arguments
- `xg::AbstractVector`, `yg::AbstractVector`: Axis grid coordinates (X for columns, Y for rows).
- `slice::AbstractMatrix`: 2D data matrix to visualize.
- `var_name::String`: Variable name for labeling/saving (overridden in ion mode).
- `smin::Float64`, `smax::Float64`: Colorbar min/max. If both are `0.0` and `logscale == true`,
  they are auto-derived from `log10(minval)` and `log10(maxval)`.
- `is_ions::Bool`: If `true`, ion-specific title/labels are taken from `ionstexto(kern, ionz)`.
- `kern::Int`, `ionz::Int`: Ion kernel and ionization state (passed to `ionstexto`).
- `xlabel::String`, `ylabel::String`, `title::String`: Axis labels and plot title (title overridden if `is_ions`).
- `author::String`, `resolution::String`, `unittime::String`: Watermark and overlay text.
- `colormap`, `min_color`, `max_color`, `colorbar_label`: Reserved; a fixed palette (`get_palette(15)`) is used here.
- `show_stats::Bool`: If `true`, shows a small stats summary below the plot.
- `logscale::Bool`: If `true`, uses `stats.matrix_result` and a log10 color range.
- `stats::Union{Nothing, Matrix2DStatistics}`: Precomputed statistics; if `nothing`, computed via `statistics_data2D(slice)`.
- `formats::Vector{String}`: Output formats (e.g., `["pdf","png","svg"]`).
- `save_path::AbstractString`: Base folder where plots are saved (a subfolder per `var_name` or ion is created).

# Behavior
1. Computes or uses provided statistics (min/max/mean).
2. Chooses `plotdata` and `colorrange` according to `logscale`.
3. Uses a color gradient built from `get_palette(15)` (`cgrad`).
4. Renders heatmap and marks min/max in data coordinates.
5. Adds a right-side color scale via `escala!` (ion/non-ion variants).
6. Adds watermark and overlay text.
7. Generates output filenames via `writeplot`, creates a subfolder under `save_path`, and saves/displays.

# Returns
- `Figure`: The Makie figure for further inspection or composition.

# Dependencies
Requires in scope: `statistics_data2D`, `Matrix2DStatistics`, `ionstexto`, `create_plot_structure`, `LaTeXString`,
`get_palette`, `cgrad`, `heatmap!`, `escala!`, `add_copyright`,
`writeplot`, `save_or_display`.
"""
function plot_heatmap(xg::AbstractVector, yg::AbstractVector,
                      slice::AbstractMatrix,
                      var_name::String,
                      smin::Float64, smax::Float64;  # filename::String;
                      is_ions::Bool = false,
                      kern::Int = 0, ionz::Int = 0,
                      xlabel::String = "",
                      ylabel::String = "",
                      title::String = "",
                      author::String = "",
                      resolution::String = "",
                      unittime::String = "",
                      # atom::Int = 0
                      colormap = :viridis,
                      min_color = :black,
                      max_color = :white,
                      colorbar_label::String = "",
                      show_stats::Bool = false,
                      logscale::Bool = false,
                      stats::Union{Nothing, Matrix2DStatistics} = nothing,
                      formats::Vector{String} = ["png"],                         # NEW
                      save_path::AbstractString = "./figures/mavil2"    # NEW
                     # stats_save_path::Union{Nothing,AbstractString} = nothing   # NEW
            )

    # Compute statistics if not provided
    stats === nothing && (stats = statistics_data2D(slice))

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
        colorrange = crange
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

    # Mark min value (blue circle) and add its text label
    scatter!(ax, [x_min], [y_min], color = :blue, marker = :circle, markersize = 12)
    text!(ax, [x_min], [y_min], text = "min=$(round(minval, digits = 2))", color = :blue, align = (:left, :bottom))

    # Mark max value (red star) and add its text label
    scatter!(ax, [x_max], [y_max], color = :red, marker = :star5, markersize = 14)
    text!(ax, [x_max], [y_max], text = "max=$(round(maxval, digits = 2))", color = :red, align = (:left, :bottom))

    # Add colorbar (ion/non-ion variants)
    if is_ions
        escala!(fig, smin, smax; side = :right, colormap = my_pallete_color, logs = logscale, labelion = ion_labels.labelion)
    else
        escala!(fig, smin, smax; side = :right, colormap = my_pallete_color, logs = logscale, variavel = var_name)
    end

    # Add copyright/watermark
    add_copyright(ax; text = LaTeXString(author), x_percent = 10, y_percent = 5, color = :black, fontsize = 14)

    # Overlay resolution and time near the top-right (relative coordinates)
    text!(fig.scene, LaTeXString(resolution * L"\quad " * L"\text{300.00  } " * unittime),
          position = (0.85, 0.95),
          space = :relative,
          align = (:right, :center),
          fontsize = 14,
          color = :gray)

    # Optionally show statistics panel
    if show_stats
        txt = @sprintf("Statistical Summary\n Min=%.3f | Max=%.3f | Mean=%.3f | Std_dev=%.3f | Variance=%.3f ",
                       minval, maxval, stats.statistics_data.mean, stats.statistics_data.std_dev, stats.statistics_data.variance)
        Label(fig[2, 1], txt; tellwidth = false, halign = :center)
    end

    # Adjust var_name for ion mode (short code) before saving
    if is_ions
        var_name = ion_labels.ion
    end

    # Configure output files (use the parameterized 'formats')
    files = writeplot(42;
        lpdf = true,
        variavel = var_name,
        atom = 8,
        filenum = 3000,
        datetime_format = "ddmmyy_HHMM",
        formats = formats
    )

    # Create subfolder for this variable under the parameterized base path
    if is_ions
        # Use the first token of the ion title as folder name (e.g., "O" from "O VIII")
        var_name = split(ion_labels.titleion)[1]
        subdir = joinpath(save_path, var_name)
        isdir(subdir) || mkdir(subdir)
        save_path = subdir
    end

   # subdir = joinpath(save_path, var_name) <--
   # isdir(subdir) || mkdir(subdir)  <--

    # Save or display the figure
    save_or_display(
        fig, files;
        sav = true,
        disp = true,
       # output_path = subdir
       output_path = save_path  # <--
    )

    # Export statistics
_ = save_stats_from_writeplot(files, save_path, stats; 
    subfolder_name = "statistics",    # por defeito
    report_ext = ".txt",              # ou ".pdf" se útil e implementado
    file_index = 1,                   # usa o primeiro nome
    sav = true,
    disp = false,
    allow_empty_files = false)

    return fig
end

# ==================================================================================================


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
        colormap = :viridis,
        min_color = :black,
        max_color = :white,
        colorbar_label::String = "",
        show_stats::Bool = false,
        logscale::Bool = false,
        stats::Union{Nothing, Matrix2DStatistics} = nothing,
        formats::Vector{String} = ["png"],                # NEW: output formats
        save_path::AbstractString = "./data/output/mapas/teste/contornos"  # NEW: base output path

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
- `is_ions::Bool`: If `true`, ion-specific title and colorbar label are taken from `ionstexto(kern, ionz)`.
- `kern::Int`, `ionz::Int`: Kernel and ionization state for ion labels.
- `xlabel::String`, `ylabel::String`: Axis labels.
- `title::String`: Plot title (overridden in ion mode).
- `author::String`: Watermark text at lower-left.
- `resolution::String`, `unittime::String`: Overlay text near the top-right (`resolution ␣ 300.00 ␣ unittime`).
- `colormap`, `min_color`, `max_color`, `colorbar_label`: Reserved/unused here; a fixed palette from `get_palette(15)` is used.
- `show_stats::Bool`: If `true`, prints a short stats summary below the plot.
- `logscale::Bool`: If `true`, uses `stats.matrix_result` and a log10 color range.
- `stats::Union{Nothing, Matrix2DStatistics}`: Precomputed statistics; if `nothing`, computed via `statistics_data2D(slice)`.

# Behavior
1. Computes or uses provided statistics (min/max/mean).
2. Chooses `plotdata` and `colorrange` according to `logscale`.
3. Uses a color gradient from `get_palette(15)` via `cgrad`.
4. Renders contour lines and marks min/max positions in data coordinates.
5. Adds a right-side color scale via `escala!` (ion/non-ion variants).
6. Adds watermark and overlay text.
7. Generates output file names, creates a subfolder under `./data/output/mapas/teste/contornos`, and saves/displays.

# Returns
- `Figure`: The Makie figure for further use.

# Dependencies
Requires: `statistics_data2D`, `Matrix2DStatistics`, `ionstexto`, `create_plot_structure`, `LaTeXString`,
`get_palette`, `cgrad`, `contour!`, `escala!`, `add_copyright`, `writeplot`, `save_or_display`.

# Notes
- If you want to honor the `colormap` keyword, replace the fixed palette (`get_palette(15)`) accordingly.
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
    colormap = :viridis,
    min_color = :black,
    max_color = :white,
    colorbar_label::String = "",
    show_stats::Bool = false,
    logscale::Bool = false,
    stats::Union{Nothing, Matrix2DStatistics} = nothing,
    
    formats::Vector{String} = ["png"],                                # NEW
    save_path::AbstractString = "./data/output/maps/contour" # NEW

    
)
    # Compute statistics if not provided
    stats === nothing && (stats = statistics_data2D(slice))

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
    co = contour!(ax, xg, yg, plotdata; colormap = my_pallete_color)

    # Add colorbar (ion/non-ion variants)
    if is_ions
        escala!(fig, smin, smax; side = :right, colormap = my_pallete_color, logs = logscale, labelion = ion_labels.labelion )
    else
        escala!(fig, smin, smax; side = :right, colormap = my_pallete_color, logs = logscale, variavel = var_name)
    end

    # Add watermark
    add_copyright(ax; text = LaTeXString(author), x_percent = 10, y_percent = 5, color = :black, fontsize = 14)

    # Extract min/max indices (matrix coordinates) from stats
    min_coord = stats.statistics_data.min_value.index2D   # Point2D(i, j)
    max_coord = stats.statistics_data.max_value.index2D

    # Convert matrix indices -> data coordinates
    x_min = xg[min_coord.y]   # column -> X
    y_min = yg[min_coord.x]   # row    -> Y
    x_max = xg[max_coord.y]
    y_max = yg[max_coord.x]

    # Mark min (blue circle) and max (red star) with labels
    scatter!(ax, [x_min], [y_min], color = :blue, marker = :circle, markersize = 12)
    text!(ax, [x_min], [y_min], text = "min=$(round(minval, digits=2))", color = :blue, align = (:left, :bottom))

    scatter!(ax, [x_max], [y_max], color = :red, marker = :star5, markersize = 14)
    text!(ax, [x_max], [y_max], text = "max=$(round(maxval, digits=2))", color = :red, align = (:left, :bottom))

    # Overlay resolution and time near the top-right (relative coords)
    text!(fig.scene, LaTeXString(resolution * L"\quad " * L"\text{300.00  }" * unittime),
          position = (0.85, 0.95),
          space = :relative,
          align = (:right, :center),
          fontsize = 14,
          color = :gray)

    # Optionally show a short stats summary
    if show_stats
        txt = @sprintf("min=%.3f, max=%.3f, mean=%.3f", minval, maxval, stats.statistics_data.mean)
        Label(fig[2, 1], txt; tellwidth = false, halign = :left)
    end

    # Configure output files
    files = writeplot(42;
        lpdf = true,
        variavel = var_name,
        atom = 8,
        filenum = 3000,
        datetime_format = "ddmmyy_HHMM",
        formats = formats,
        #formats = ["png"] #  formats = formats
    )
    # Save or display the figure
    save_or_display(
        fig, files;
        sav = true,
        disp = true,
        #output_path = subdir #  output_path = subdir # NEW: uses subdir built from save_path
        output_path = save_path # <---
    )
    return fig
end

# ============================================================================================

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
        colormap = :viridis,
        min_color = :black,
        max_color = :white,
        colorbar_label::String = "",
        show_stats::Bool = false,
        logscale::Bool = false,
        stats::Union{Nothing, Matrix2DStatistics} = nothing,
        formats::Vector{String} = ["png"],                 # NEW: output formats
        save_path::AbstractString = "./data/output/mapas/heat_cont"  # NEW: base output path
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
- `stats::Union{Nothing, Matrix2DStatistics}`: Precomputed statistics; computed via `statistics_data2D(slice)` if `nothing`.
- `formats::Vector{String}`: Output formats (e.g., `["pdf","png","svg"]`).
- `save_path::AbstractString`: Base folder where the plot will be saved (a subfolder per `var_name` is created).

# Behavior
1. Computes or uses provided statistics (min/max/mean).
2. Chooses `plotdata` and `colorrange` according to `logscale`.
3. Builds a color gradient from `get_palette(15)` via `cgrad`.
4. Renders a heatmap and overlays contour lines.
5. Marks min/max positions in data coordinates and adds a right-side color scale via `escala!`.
6. Adds watermark and overlay text.
7. Generates output file names via `writeplot`, creates a subfolder under `save_path`, and saves/displays.

# Returns
- `Figure`: The Makie figure for further inspection or composition.

# Dependencies
Requires in scope: `statistics_data2D`, `Matrix2DStatistics`, `ionstexto`, `create_plot_structure`, `LaTeXString`,
`get_palette`, `cgrad`, `heatmap!`, `contour!`, `escala!`, `add_copyright`,
`writeplot`, `save_or_display`.

# Notes
- If you prefer to honor the `colormap` keyword, replace the fixed palette (`get_palette(15)`) accordingly.
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
    colormap = :viridis,
    min_color = :black,
    max_color = :white,
    colorbar_label::String = "",
    show_stats::Bool = false,
    logscale::Bool = false,
    stats::Union{Nothing, Matrix2DStatistics} = nothing ,
    formats::Vector{String} = ["png"],                               # NEW
    save_path::AbstractString = "./data/output/maps/heat_cont"       # NEW
)
    # Build the colormap (fixed palette type 15)
    my_pallete_color = cgrad(get_palette(15))

    # Compute statistics if not provided
    stats === nothing && (stats = statistics_data2D(slice))

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
    hm = heatmap!(ax, xg, yg, plotdata; colormap = my_pallete_color, colorrange = crange)

    # Overlay contour lines (black)
    co = contour!(ax, xg, yg, plotdata; color = :black)

    # Add colorbar (ion/non-ion variants)
    if is_ions
        escala!(fig, smin, smax; side = :right, colormap = my_pallete_color, logs = logscale, labelion = ion_labels.labelion)
    else
        escala!(fig, smin, smax; side = :right, colormap = my_pallete_color, logs = logscale, variavel = var_name)
    end

    # Add watermark
    add_copyright(ax; text = LaTeXString(author), x_percent = 10, y_percent = 5, color = :black, fontsize = 14)

    # Extract min/max indices (matrix coordinates) from stats
    min_coord = stats.statistics_data.min_value.index2D   # Point2D(i, j)
    max_coord = stats.statistics_data.max_value.index2D

    # Convert matrix indices -> data coordinates
    x_min = xg[min_coord.y]   # column -> X
    y_min = yg[min_coord.x]   # row    -> Y
    x_max = xg[max_coord.y]
    y_max = yg[max_coord.x]

    # Mark min (blue circle) and max (red star) with labels
    scatter!(ax, [x_min], [y_min], color = :blue, marker = :circle, markersize = 12)
    text!(ax, [x_min], [y_min], text = "min=$(round(minval, digits=2))", color = :blue, align = (:left, :bottom))

    scatter!(ax, [x_max], [y_max], color = :red, marker = :star5, markersize = 14)
    text!(ax, [x_max], [y_max], text = "max=$(round(maxval, digits=2))", color = :red, align = (:left, :bottom))

    # Overlay resolution and time near the top-right (relative coords)
    text!(fig.scene, LaTeXString(resolution * L"\quad " * L"\text{300.00  }" * unittime),
          position = (0.85, 0.95),
          space = :relative,
          align = (:right, :center),
          fontsize = 14,
          color = :gray)

    # Optionally show a short stats summary
    if show_stats
        txt = @sprintf("min=%.3f, max=%.3f, mean=%.3f", minval, maxval, stats.statistics_data.mean)
        Label(fig[2, 1], txt; tellwidth = false, halign = :left)
    end

    # Configure output files using the parameterized 'formats'
    files = writeplot(42;
        lpdf = true,
        variavel = var_name,
        atom = 8,
        filenum = 3000,
        datetime_format = "ddmmyy_HHMM",
        formats = formats
       # formats = ["png"] # formats = formats
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
    
# ================================================================================================

# ==============================================================================

"""
    maps(
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

# Behavior
1. Reads real-space bounds from `cfg.real_dims` and prepares Z loop from `rt.loop_graphic`.
2. For each loop index `l`, slices the cube for TOP view (fixed Z = `l`) if enabled via `pgp.view.top`.
3. Crops the slice using `crop_slice(...; xmin, xmax, ymin, ymax)`, optionally scales `den` by `cfg.scales.denscale`.
4. Computes 2D statistics (optionally with `log10`) and selects color range (`smin/smax`) via `setminmaxvar`.
5. Calls `plot_heatmap`, `plot_contour`, and `plot_heat_cont`, forwarding `formats` and a derived `save_path` per plot type.
6. FRONT and SIDE views are scaffolded and can be completed similarly (currently commented as in the original).

# Returns
- `Nothing`. The function produces plots via side effects (file generation and display).

# Dependencies
Requires: `crop_slice`, `statistics_data2D`, `setminmaxvar`, `plot_heatmap`, `plot_contour`, `plot_heat_cont`, `plot_pdf_test`,
and configuration types `ConfigData`, `PGPData`, `RuntimeData`, `ModionsData`.

# Notes
- Subfolders are created under `base_save_path` for each plot type:
  - Heatmap: `joinpath(base_save_path, "color")`
  - Contour: `joinpath(base_save_path, "teste", "contornos")`
  - Heat+Contour: `joinpath(base_save_path, "heat_cont")`
- If you prefer different folder names, adjust the `*_path` variables below.
"""
function maps!(data::AbstractArray{Float64,3}, xgrid, ygrid, zgrid,
               var_name::String;
               kern, ionz, is_ions,
               cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData,
               formats::Vector{String} = ["png"],
               save_path::AbstractString = "./data/output/maps")

    # Real-space cropping limits (min/max for x, y, z)
    xmin = cfg.real_dims.min.x
    xmax = cfg.real_dims.max.x
    ymin = cfg.real_dims.min.y
    ymax = cfg.real_dims.max.y
    jmin = cfg.real_dims.min.z
    jmax = cfg.real_dims.max.z

    # Plot color from runtime settings (currently unused, kept for future use)
    color = rt.output_plot.color

    # Derived save paths per plot type (kept consistent with existing functions)
    heatmap_path   = joinpath(save_path, "color")
    contour_path   = joinpath(save_path, "contour")
    heatcont_path  = joinpath(save_path, "heat_cont")
    pdf_path       = joinpath(save_path, "pdf")
   # statistic_path = joinpath(save_path, "statistic") 

    # Ensure base folders exist (subfolders per variable are created inside plot functions)
  #=  isdir(heatmap_path)         || mkdir(heatmap_path)
    isdir(contour_path)         || mkdir(contour_path)
    isdir(heatcont_path)        || mkdir(heatcont_path)
    isdir(pdf_path)             || mkdir(pdf_path) =#
   # isdir(statistic_path)       || mkdir(pdf_path)
   
    mkpath(heatmap_path)
    mkpath(contour_path)
    mkpath(heatcont_path)
    mkpath(pdf_path)
    
  
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
            stats = statistics_data2D(slice, log10)

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
                colormap = :viridis,
                min_color = :blue, max_color = :red,
                show_stats = true, logscale = cfg.scales.logs,
                stats = stats,
                formats = formats,
                save_path = heatmap_path
               # stats_save_path = statistic_path     # NEW ← passa a pasta
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
                colormap = :viridis,
                min_color = :blue, max_color = :red,
                show_stats = false, logscale = cfg.scales.logs,
                stats = stats,
                formats = formats,
                save_path = heatcont_path
            )

            # Optional: PDF test plot (kept as in original; add formats/save_path if supported)
            plot_pdf_test(
                xg, yg, slice, var_name;
                kern = kern, ionz = ionz, is_ions = is_ions,
                author = pgp.title.author,
                resolution = pgp.title.resolution,
                unittime = pgp.title.unitime,
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

"""
    mapas_ions!(
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
        formats::Vector{String} = ["png"],                    # NEW: output formats
        save_path::AbstractString = "./data/output/ions"      # NEW: base output path
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
5. Calls `plot_heatmap`, `plot_contour`, `plot_heat_cont`, and `plot_pdf_test`, forwarding
   `formats` and `save_path` (which are organized per plot type).

# Returns
- `Nothing`. Side effects include generating plots and saving them to disk.

# Dependencies
Requires: `crop_slice`, `statistics_data2D`, `setminmaxvar`, `plot_heatmap`, `plot_contour`,
`plot_heat_cont`, `plot_pdf_test` to be in scope and accept `formats` and `save_path`.
"""
function mapas_ions!(data::Array{Float64,3}, xgrid, ygrid, zgrid,
                         var_name::String;
                         kern, ionz, is_ions,
                         cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData,
                         formats::Vector{String} = ["png"],                      # NEW
                         save_path::AbstractString = "./figures/mavil2/ions"       # NEW
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

    # Derived save paths per plot type (organized under save_path)
if(!is_ions)
    heatmap_path  = joinpath(save_path, "color")
    contour_path  = joinpath(save_path, "contours")
    heatcont_path = joinpath(save_path, "heat_cont")
    pdf_path      = joinpath(save_path, "pdf")

    # Ensure base folders exist
    isdir(heatmap_path)  || mkdir(heatmap_path)
    isdir(contour_path)  || mkdir(contour_path)
    isdir(heatcont_path) || mkdir(heatcont_path)
    isdir(pdf_path)      || mkdir(pdf_path)
end
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
            stats = statistics_data2D(slice, log10)

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
                colormap = :viridis,
                min_color = :blue, max_color = :red,
                show_stats = false, logscale = cfg.scales.logs,
                stats = stats,
                formats = formats,
                save_path = save_path
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
                min_color = :blue, max_color = :red,
                show_stats = false, logscale = cfg.scales.logs,
                stats = stats,
                formats = formats,
                save_path = save_path
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
                colormap = :viridis,
                min_color = :blue, max_color = :red,
                show_stats = false, logscale = cfg.scales.logs,
                stats = stats,
                formats = formats,
                save_path = save_path
            )

            # PDF (ion/non-ion use same logic; saved under pdf_path)
            plot_pdf_test(
                xg, yg, slice, var_name;
                is_ions = is_ions,
                kern = kern, ionz = ionz,
                author = pgp.title.author,
                resolution = pgp.title.resolution,
                unittime = pgp.title.unitime,
                show_stats = false,
                logscale = cfg.scales.logs,
                stats = stats,
                formats = formats,
                save_path = save_path
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



# ==============================================================================


# ==============================================================================

# Para matriz 3D

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
                plane == :YZ ? nx ÷ 2 : error("Plano inválido: $plane")
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

# Para matriz 2D
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

# for 3D matrix

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
    
    # Dictionary to store plot parameters.
    # Initializes with default values that can be overwritten.
    params = Dict{String, Any}(
        "ylabelmin" => -5.0,
        "ylabelmax" => 0.0,
        "x2label" => "log dN/N",
        "xtick" => 1.0,
        "binmin" => 0.0,
        "dbin" => 0.0,
        "xlabelmin" => 0.0,
        "xlabelmax" => 0.0,
        "x1label" => "Unrecognized Variable"
    )

    # Logic to select parameters, similar to Fortran's `select case`
    if var_name == "den"
        params["binmin"] = -5.0
        params["dbin"] = 0.1
        params["xlabelmin"] = -5.0
        params["xlabelmax"] = 3.0
        params["x1label"] = L"log n [\mathrm{cm}^{-3}]"
    
    elseif var_name == "pre"
        params["binmin"] = -18.0
        params["dbin"] = 0.1
        params["xlabelmin"] = -18.0
        params["xlabelmax"] = -8.0
        params["x1label"] = L"log P_{\mathrm{th}} [\mathrm{dyne} \mathrm{cm}^{-2}]"
    
    elseif var_name == "pok"
        params["binmin"] = -2.0
        params["dbin"] = 0.1
        params["xlabelmin"] = -2.0
        params["xlabelmax"] = 8.0
        params["x1label"] = L"log P/k_{\mathrm{B}} [\mathrm{cm}^{-3} \mathrm{K}]"
    
    elseif var_name == "ram"
        params["binmin"] = -18.0
        params["dbin"] = 0.1
        params["xlabelmin"] = -18.0
        params["xlabelmax"] = -8.0
        params["x1label"] = L"log P_{\mathrm{ram}} [\mathrm{dyne} \mathrm{cm}^{-2}]"
    
    elseif var_name == "rok"
        params["binmin"] = -2.0
        params["dbin"] = 0.1
        params["xlabelmin"] = -2.0
        params["xlabelmax"] = 8.0
        params["x1label"] = L"log P_{\mathrm{ram}}/k_{\mathrm{B}} [\mathrm{cm}^{-3} \mathrm{K}]"
    
    elseif var_name == "tem"
        params["binmin"] = 0.0
        params["dbin"] = 0.1
        params["xlabelmin"] = 0.0
        params["xlabelmax"] = 8.0
        params["x1label"] = L"log T [\mathrm{K}]"
    
    elseif var_name == "mach"
        params["binmin"] = -3.0
        params["dbin"] = 0.1
        params["xlabelmin"] = -3.0
        params["xlabelmax"] = 2.0
        params["x1label"] = L"log \mathcal{M}"
    
    elseif var_name == "ent"
        params["binmin"] = 9.0
        params["dbin"] = 0.01
        params["xlabelmin"] = 9.3
        params["xlabelmax"] = 9.7
        params["xtick"] = 0.1
        params["x1label"] = L"log s [\mathrm{erg} \mathrm{cm}^{-3} \mathrm{K}^{-1}]"
    
    elseif var_name == "ele"
        params["binmin"] = -8.0
        params["dbin"] = 0.1
        params["xlabelmin"] = -7.0
        params["xlabelmax"] = 2.0
        params["x1label"] = L"log n_{\mathrm{e}} [\mathrm{cm}^{-3}]"
    
    elseif var_name == "elez"
        params["binmin"] = -7.0
        params["dbin"] = 0.1
        params["xlabelmin"] = -7.0
        params["xlabelmax"] = 2.0
        
        # Selection based on the atomic number `atom`
        if atom == 1
            params["x1label"] = L"log n_{\mathrm{e}}(\mathrm{H}) / A(\mathrm{H}) [\mathrm{cm}^{-3}]"
        elseif atom == 2
            params["x1label"] = L"log n_{\mathrm{e}}(\mathrm{He}) / A(\mathrm{He}) [\mathrm{cm}^{-3}]"
        elseif atom == 6
            params["x1label"] = L"log n_{\mathrm{e}}(\mathrm{C}) / A(\mathrm{C}) [\mathrm{cm}^{-3}]"
        elseif atom == 7
            params["x1label"] = L"log n_{\mathrm{e}}(\mathrm{N}) / A(\mathrm{N}) [\mathrm{cm}^{-3}]"
        elseif atom == 8
            params["x1label"] = L"log n_{\mathrm{e}}(\mathrm{O}) / A(\mathrm{O}) [\mathrm{cm}^{-3}]"
        elseif atom == 10
            params["x1label"] = L"log n_{\mathrm{e}}(\mathrm{Ne}) / A(\mathrm{Ne}) [\mathrm{cm}^{-3}]"
        elseif atom == 12
            params["x1label"] = L"log n_{\mathrm{e}}(\mathrm{Mg}) / A(\mathrm{Mg}) [\mathrm{cm}^{-3}]"
        elseif atom == 14
            params["x1label"] = L"log n_{\mathrm{e}}(\mathrm{Si}) / A(\mathrm{Si}) [\mathrm{cm}^{-3}]"
        elseif atom == 16
            params["x1label"] = L"log n_{\mathrm{e}}(\mathrm{S}) / A(\mathrm{S}) [\mathrm{cm}^{-3}]"
        elseif atom == 26
            params["x1label"] = L"log n_{\mathrm{e}}(\mathrm{Fe}) / A(\mathrm{Fe}) [\mathrm{cm}^{-3}]"
        else
            params["x1label"] = L"log n_{\mathrm{e}}(??) / A(??) [\mathrm{cm}^{-3}]"
        end
    end
    
    return params
end

# ==============================================================================

"""
    plot_pdf_test(
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
        show_stats::Bool = false,
        logscale::Bool = true,
        stats::Union{Nothing, Matrix2DStatistics} = nothing,
        formats::Vector{String} = ["pdf", "png"],               # NEW: output formats
        save_path::AbstractString = "./data/output/mapas/pdf"   # NEW: base output path
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
- `vol_local::Float64`: Local volume normalization (used by `calculate_pdf`; if not set, defaults to `length(plotdata)`).
- `xlabel::String`, `ylabel::String`: Axis labels (the function uses labels from `get_pdf_label(var_name)` for the PDF axes).
- `title::String`: Plot title (overridden if `is_ions == true`).
- `author::String`: Watermark text at the lower-left.
- `resolution::String`, `unittime::String`: Overlay text near the top-right (`resolution ␣ 300.00 ␣ unittime`).
- `show_stats::Bool`: If `true`, shows a short statistics summary below the plot.
- `logscale::Bool`: If `true`, uses `stats.matrix_result` (assumed log-transformed data) for the PDF; otherwise uses `slice`.
- `stats::Union{Nothing, Matrix2DStatistics}`: Precomputed statistics. If `nothing`, they are computed via `statistics_data2D(slice)`.
- `formats::Vector{String}`: Output formats (e.g., `["pdf","png","svg"]`).
- `save_path::AbstractString`: Base folder where the plot will be saved (a subfolder per `var_name` is created).

# Behavior
1. Computes or uses provided statistics (`min`, `max`) and selects `plotdata` according to `logscale`.
2. Derives logarithmic bounds (`binmin`, `tmp_max`) from `log10(minval)` and `log10(maxval)`.
3. Computes `nli` (number of bins) and calls `calculate_pdf(plotdata, binmin, dbin, nli, vol_local)`.
4. Finds min/max points on the PDF with `find_min_max_coords`.
5. Creates a Makie `Figure` and `Axis`, plots the PDF curve, and annotates min/max points.
6. Overlays author/resolution/time labels, and saves outputs via `writeplot` + `save_or_display`.

# Returns
- `Tuple{Axis, Figure}`: The axis and figure objects for further customization or composition.

# Dependencies
Requires the following to be in scope: `statistics_data2D`, `Matrix2DStatistics`, `get_pdf_label`,
`calculate_pdf`, `find_min_max_coords`, `ionstexto`, `LaTeXString`, `add_text_at`,
`writeplot`, `save_or_display`, and Makie plotting primitives (`Figure`, `Axis`, `lines!`, etc.).

# Notes
- If your data can contain non-positive values, `log10(minval)` may be invalid. Consider clamping to a
  small positive epsilon or filtering prior to computing log-space bounds.
- The function currently relies on `get_pdf_label(var_name)` to set axis limits/labels for the PDF plot.
"""
function plot_pdf_test(xg::AbstractVector, yg::AbstractVector,
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
                      show_stats::Bool = false,
                      logscale::Bool = true,
                      stats::Union{Nothing, Matrix2DStatistics} = nothing,
                      formats::Vector{String} = ["pdf", "png"],               # NEW
                      save_path::AbstractString = "./data/output/maps/pdf"   # NEW
            )

    # Compute statistics if not provided
    stats === nothing && (stats = statistics_data2D(slice))

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
    fig = Figure(size = (800, 600))
    ax = Axis(fig[1, 1],
        title = "Density Probability for " * var_name_ion,
        xlabel = pdflabel["x1label"], xlabelsize = 16,
        ylabel = pdflabel["x2label"],
        limits = (pdflabel["xlabelmin"], pdflabel["xlabelmax"], pdflabel["ylabelmin"], pdflabel["ylabelmax"])
    )

    # Plot the PDF curve (equivalent to pgline)
    lines!(ax, dbf, dbrev6)

    # Annotate maximum point
    max_text = "($(round(max_coords[1], digits=2)), $(round(max_coords[2], digits=2)))"
    text = "Maximum: " * max_text
    _ = add_text_at(ax, max_coords[1], max_coords[2], text;
                    is_percentage = false, offset = (0.2, 0.2),
                    marker = :circle, marker_size = 15, color = :blue)

    # Annotate minimum point
    min_text = "($(round(min_coords[1], digits=2)), $(round(min_coords[2], digits=2)))"
    text = "Minimum: " * min_text
    _ = add_text_at(ax, min_coords[1], min_coords[2], text;
                    is_percentage = false, offset = (0.2, 0.2),
                    marker = :circle, marker_size = 15, color = :red)

    # Watermark and overlay text (relative coordinates)
    _ = add_text_at(ax, 0.10, 0.05, LaTeXString(author); fontsize = 14, is_percentage = true, color = :black)
    _ = add_text_at(ax, 0.85, 0.90, LaTeXString(resolution); fontsize = 14, is_percentage = true, color = :black)
    _ = add_text_at(ax, 0.85, 0.85, LaTeXString(L"\text{300.00  } " * unittime); fontsize = 14, is_percentage = true, color = :black)

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
        filenum = 3000,
        datetime_format = "ddmmyy_HHMM",
        formats = formats
    )

   # Create subfolder for this variable under the parameterized 'save_path'
   # subdir = joinpath(save_path, var_name)
   # isdir(subdir) || mkdir(subdir)

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

# ===================================================================

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
        formats::Vector{String} = ["png"],                       # NEW: output formats
        save_path::AbstractString = "./data/output/mapas/color"  # NEW: base output path
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

# Behavior
1. Reads real-space cropping limits from `cfg.real_dims`.
2. Loops over Z indices (`lmin:stepl:lmax`) and, if `pgp.view.top` is enabled, crops the XY plane at `Z = l`.
3. Applies density scaling (`./= cfg.scales.denscale`) when `var_name == "den"`.
4. Computes statistics via `statistics_data2D(slice, log10)` and selects `(smin, smax)` with `setminmaxvar`.
5. Builds a 2×2 figure:
   - **ax1**: Contour plot
   - **ax2**: Heatmap
   - **ax3**: Heatmap + Contour overlay
   - **ax4**: Probability Density Function (PDF) of the (possibly log-transformed) data
6. Adds colorbars for relevant subplots and overlays author/resolution/time annotations.
7. Saves the figure in each requested format under `joinpath(save_path, var_name)`.

# Returns
- `Nothing`. The function saves figures as side effects.

# Dependencies
Requires: `crop_slice`, `statistics_data2D`, `setminmaxvar`, `get_pdf_label`, `calculate_pdf`, `find_min_max_coords`,
Makie primitives (`Figure`, `Axis`, `Colorbar`, `contour!`, `heatmap!`, `lines!`), and utilities like `LaTeXString`, `add_text_at`.

# Notes
- `data_to_plot` uses log transform if `cfg.scales.logs` is true. Ensure `smin/smax` are set in the same space (log vs linear).
- If `result = setminmaxvar(...)` returns `nothing`, `(smin, smax)` is `(0.0, 0.0)`; consider providing sensible defaults.
"""

function maps_subplot!(data::AbstractArray{Float64,3}, xgrid, ygrid, zgrid,
                        var_name::String;
                        cfg::ConfigData, pgp::PGPData, rt::RuntimeData, modions::ModionsData,
                        formats::Vector{String} = ["png"],                         # NEW
                        base_save_path::AbstractString = "./mavil2"                # NEW
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
    
    
    
    # Ensure per-variable folder exists: ./data/output/maps/subplot/<var_name>
    #subdir = joinpath(save_path, var_name)
    #isdir(subdir) || mkpath(subdir)
    
    
    
   # Ensure hierarchical folders: <base>/<var_name> then <base>/<var_name>/subplot
    var_dir     = joinpath(base_save_path, var_name)
    isdir(var_dir)     || mkpath(var_dir)
    subplot_dir = joinpath(var_dir, "subplot")
    isdir(subplot_dir) || mkpath(subplot_dir)

    
    
    
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
            stats = statistics_data2D(slice, log10)
            result = setminmaxvar(var_name, pgp, modions)  # External function for min/max calculation
            smin, smax = result === nothing ? (0.0, 0.0) : result
            
            
            # Fallback quando setminmaxvar devolve (0.0, 0.0)
            if smin == 0.0 && smax == 0.0
               smin = stats.statistics_data.min_value.value2D # smin = minimum(data_to_plot)
               smax = stats.statistics_data.max_value.value2D # smax = maximum(data_to_plot)
            end

            # Se a fatia é constante, evitar ranges degenerados
            const_slice = isapprox(smin, smax; rtol = 1e-12, atol = 1e-12)
            if const_slice
                # Usa um epsilon pequeno para “abrir” a gama
                eps = max(abs(smin), 1.0) * 1e-6 + 1e-12
                smin -= eps/2
                smax += eps/2
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
                       ylabel = "Y (pc)")

            # ax2: Heatmap (top-right)
            ax2 = Axis(fig_final[1, 2][1, 1],
                       title = "Heatmap for $(var_namec)",
                       xlabel = "X (pc)",
                       ylabel = pgp.labels.ylabel)

            # ax3: Combined contour + heatmap (bottom-left)
            ax3 = Axis(fig_final[2, 1][1, 1],
                       title = "Contour + Heatmap for $(var_namec)",
                       xlabel = "X (pc)",
                       ylabel = "Y (pc)")

            # ax4: Probability density function (bottom-right)
            ax4 = Axis(fig_final[2, 2][1, 1],
                       title = "Density Probability for " * var_namec,
                       xlabel = pdflabel["x1label"],
                       ylabel = pdflabel["x2label"],
                       limits = (pdflabel["xlabelmin"], pdflabel["xlabelmax"],
                                 pdflabel["ylabelmin"], pdflabel["ylabelmax"]))

            # --- PLOT CREATION ---
            # P1: Contour plot
            p1 = contour!(ax1, xg, yg, data_to_plot;
                          levels = LinRange(smin, smax, 10),
                          colormap = :viridis,
                          linewidth = 1.5,
                          colorrange = (smin, smax),
                          label = "Contours: $(var_namec)")

            # P2: Heatmap
            p2 = heatmap!(ax2, xg, yg, data_to_plot;
                          colormap = :viridis,
                          colorrange = (smin, smax))

            # P3: Combined contour and heatmap
            p3_heat = heatmap!(ax3, xg, yg, data_to_plot;
                               colormap = :viridis,
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
            p4 = lines!(ax4, dbf, dbrev6, label = "PDF of $(var_name)")

            # --- COLORBAR CONFIGURATION ---
            # Colorbar for contour plot (P1)
            Colorbar(fig_final[1, 1][1, 2],
                     label = pdflabel["x1label"],
                     colormap = p1.colormap[],
                     colorrange = p1.colorrange[],
                     labelsize = 16)

            # Colorbar for heatmap (P2)
            Colorbar(fig_final[1, 2][1, 2],
                     label = pdflabel["x1label"],
                     
                     
                    colormap   = p2.colormap[],     # ← desreferenciado
                    colorrange = p2.colorrange[],   # ← desreferenciado

                     labelsize = 16)

            # Colorbar for combined plot (P3)
            Colorbar(fig_final[2, 1][1, 2],
                     label = pdflabel["x1label"],
                     
                    colormap   = p3_heat.colormap[],     # ← desreferenciado
                    colorrange = p3_heat.colorrange[],   # ← desreferenciado

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
            _ = add_text_at(ax4, max_coords[1], max_coords[2], text;
                            is_percentage = false, offset = (0.2, 0.2),
                            marker = :circle, marker_size = 15, color = :blue)

            min_text = "($(round(min_coords[1], digits = 2)), $(round(min_coords[2], digits = 2)))"
            text     = "Minimum: " * min_text
            _ = add_text_at(ax4, min_coords[1], min_coords[2], text;
                            is_percentage = false, offset = (0.2, 0.2),
                            marker = :circle, marker_size = 15, color = :red)

            # Watermark and metadata (relative positions on ax4)
            _ = add_text_at(ax4, 0.10, 0.05, LaTeXString(author);
                            fontsize = 14, is_percentage = true, color = :black)
            _ = add_text_at(ax4, 0.85, 0.90, LaTeXString(resolution);
                            fontsize = 14, is_percentage = true, color = :black)
            _ = add_text_at(ax4, 0.85, 0.85, LaTeXString(unittime);
                            fontsize = 14, is_percentage = true, color = :black)
             
           
  
# --- SAVE FIGURE(S) ---

# 1) Sanitize formats: never empty
if isempty(formats)
    @warn "formats is empty in mapas_subplot!, defaulting to [\"png\"]"
    formats = ["png"]
end

# 2) Build filenames with writeplot (for images: lpdf=false)
files = writeplot(42;
    lpdf = false,                    # no "PDF_" prefix for subplot images
    variavel = var_name,
    atom = 8,
    filenum = 3000,
    datetime_format = "ddmmyy_HHMM",
    formats = formats                # e.g., ["png"], ["png","svg"], etc.
)

# 3) Fallback: if writeplot returns empty (shouldn't), build a manual filename
if isempty(files)
    @warn "writeplot returned empty file list in mapas_subplot!; falling back to manual naming."
    # Construct a simple manual filename like: den_003000-042_YYYYMMDD_HHMM.png
    # If you have l/filenum/step codes in a helper, use that; here we use date only
    ts = Dates.format(Dates.now(), "yyyymmdd_HHMM")
      # base_manual = joinpath(subdir, "$(var_name)_$(ts).$(formats[1])")
    # files = [base_manual]
    
    files = ["$(var_name)_$(ts).$(formats[1])"]
end

# 4) Save or display into ./data/output/maps/subplot/<var_name>
# Save in <base>/<var_name>/subplot
save_or_display(
    fig_final, files;
    sav = true,
    disp = true,
    output_path = subplot_dir
)
         end
         
       end
   return nothing
 end
