
# ==============================================================================
#
# Compute electron density distributions and generate visualization maps.
#
# ==============================================================================

"""
    electron!(
        tps::TemperatureProperties,
        elem::Element,
        sml::SimulationData,
        cfg::ConfigData,
        pgp::PGPData,
        rt::RuntimeData,
        modions::ModionsData;
        formats::Vector{String} = ["png"],                          
        base_save_path::AbstractString = "./data/output/electrons"  
    ) -> Nothing

Compute the **electron density** from ion fractions and generate maps.

This function fills:
- `tps.eleden` (3D): **total electron density** normalized by `cfg.scales.elescale`.
- `tps.eledenz` (4D): **per-element electron density** (normalized by element abundance and `elescale`).

It then dispatches plot generation via `mapas!`:
- A global map for `tps.eleden` (var `"ele"`).
- Per-element maps for `tps.eledenz[:,:,:,idk[kern]]` (var `"elez"`).

# Arguments
- `tps::TemperatureProperties`: Holds `xionvar` (ion fractions), and outputs `eleden` and `eledenz`.
- `elem::Element`: Element metadata (`nelem`, `zelem`, `idk`, `abund`, `kernmax`, etc.).
- `sml::SimulationData`: Grid coordinates (`X_grid`, `Y_grid`, `Z_grid`) for plotting.
- `cfg::ConfigData`: Configuration with real limits and scales (e.g., `scales.elescale`).
- `pgp::PGPData`: Plot/graphics parameters (labels, titles, view toggles).
- `rt::RuntimeData`: Runtime plotting flags (`output_plot.cont/color/grey/pdf`) and loop bounds.
- `modions::ModionsData`: Ion modeling configuration (forwarded to plotting utilities).
- `formats::Vector{String}`: Output formats for saving plots (e.g., `["png"]`, `["pdf","png"]`).
- `base_save_path::AbstractString`: Root folder for outputs; subfolders `"ele"` and `"elez"` are created.

# Additional Keywords
- `id_string::AbstractString`: Snapshot identifier used to create FAIR-compliant output folders and consistent filenames; forwarded to downstream plotters.
- `root::AbstractString = "output_fair"`: Root directory for FAIR output trees; used by helpers like `prepare_electrons_total_paths`/`prepare_electrons_per_element_paths`.

# Behavior
1. Derives grid bounds from `cfg.real_dims` and initializes electron density storages to zero.
2. For each voxel `(ii,jj,kk)`, accumulates electron contributions:
   - For each valid element `kern` (where `zelem[kern] == true`), sum `ion_level * xionvar[..., idk[kern], ion_level]`
     over ionization levels `ionlev = 1:kern` (neutral level excluded as in the original code).
   - Accumulate per-element electron density (`eledenz`) normalized by `abund[kern]` and `elescale`.
   - Accumulate total electron density (`eleden`) normalized by `elescale`.
3. If plotting is enabled, generates a global electron density map and per-element maps.
   Downstream, FAIR paths are resolved via `prepare_electrons_total_paths(id_string; root)` and
   `prepare_electrons_per_element_paths(id_string, elem_sym; root)`, and passed to the plotting wrappers
   (e.g., `maps_electron!`) together with `formats`.

# Returns
- `Nothing`. Side effects include populating `tps.eleden`, `tps.eledenz`, and saving/displaying plots.

# Dependencies
Requires in scope:
- Plotting dispatcher: `mapas!` (preferably extended to accept `formats` and `base_save_path`) or wrappers like `maps_electron!`.
- FAIR helpers: `prepare_electrons_total_paths`, `prepare_electrons_per_element_paths` (used downstream).
- Types: `TemperatureProperties`, `Element`, `SimulationData`, `ConfigData`, `PGPData`, `RuntimeData`, `ModionsData`.

# Notes
- Indexing for ion levels uses `1:kern` (consistent with earlier code paths where `ionz+1` indexes neutral+ions).
- If your ion fraction array `xionvar` stores neutral at index `1` and ions thereafter, the loop `1:kern` excludes the neutral (level 0).
- Consider switching `println` to `@info` in production for structured logging.
"""
function electron!(tps::TemperatureProperties,
                   elem::Element,
                   sml::SimulationData,
                   cfg::ConfigData,
                   pgp::PGPData,
                   rt::RuntimeData,
                   modions::ModionsData;
                   formats::Vector{String} = ["png"],                     
                   id_string::AbstractString,
                   root::AbstractString="output_fair"
)
    println("Starting ELECTRON density computation")

    # --- Grid dimensions ---
    in_dim = cfg.grid_size.grid_point.x
    jn_dim = cfg.grid_size.grid_point.y
    kn_dim = cfg.grid_size.grid_point.z

    # --- Processing boundaries (1-based indexing consistent with Julia arrays) ---
    imin = Int(cfg.real_dims.min.x + 1)
    imax = in_dim
    jmin = Int(cfg.real_dims.min.y + 1)
    jmax = jn_dim
    kmin = Int(cfg.real_dims.min.z + 1)
    kmax = kn_dim

    # --- Real-space limits (optional, for plotting/cropping elsewhere) ---
    xmin = cfg.real_dims.min.x
    xmax = cfg.real_dims.max.x
    ymin = cfg.real_dims.min.y
    ymax = cfg.real_dims.max.y
    # z limits not used directly here

    # --- Atomic data ---
    nelem  = elem.nelem      # number of elements
    zelem  = elem.zelem      # flags for availability per element
    idk    = elem.idk        # mapping of element index -> id key in xionvar
    idkmin = elem.idkmin     # lower bound (reference)
    idkmax = elem.idkmax     # upper bound (reference)

    kernmax = elem.kernmax   # maximum element index
    abund   = elem.abund     # element abundances (normalization)

    # --- Initialize electron density storages ---
    tps.eleden  .= 0.0   # total electron density (3D)
    tps.eledenz .= 0.0   # per-element electron density (4D; last dim is element id)

    # Precompute inverse scale (multiply is faster than divide)
    inv_elescale = 1.0 / cfg.scales.elescale

    # --- Main computation loops: fill eledenz and eleden ---
    @inbounds for kk in kmin:kmax
        for jj in jmin:jmax
            for ii in imin:imax
                # Initialize a small positive baseline to avoid zeros (consistent with original 1e-30)
                xnes = 1.0e-30

                # Iterate over elements
                for kern in 1:kernmax
                    if zelem[kern]  # element is present
                        znes = 0.0  # electron contribution for current element
                        # Sum over ionization levels (1..kern); neutral (0) excluded
                        for ionlev in 1:kern
                            zz   = Float64(ionlev)  # ionization level multiplier
                            znes += tps.xionvar[ii, jj, kk, idk[kern], ionlev] * zz
                        end
                        # Accumulate contribution to total electron density
                        xnes += znes
                        # Store per-element electron density, normalized by abundance and scale
                        tps.eledenz[ii, jj, kk, idk[kern]] = (znes / abund[kern]) * inv_elescale
                    end
                end

                # Store total electron density, normalized by scale
                tps.eleden[ii, jj, kk] = xnes * inv_elescale
            end
        end
    end

    println("Electron density computation completed successfully.")
    
    # --- Plotting: total electron density (var_name = "ele") ---
    if rt.output_plot.cont || rt.output_plot.color || rt.output_plot.grey
        println("Generating electron density map...")
        
        paths = prepare_electrons_total_paths(id_string; root=root)

        maps_electron!(tps.eleden, sml.X_grid, sml.Y_grid, sml.Z_grid, "ele";
               kern = 0, ionz = 0, is_ions = false,
               cfg = cfg, pgp = pgp, rt = rt, modions = modions,
               formats = formats,
               id_string = id_string,
               root = root
            )   
    end

    # --- Plotting: per-element electron density (var_name = "elez") ---
    var_name = "elez"
    for kern in 1:kernmax
        if zelem[kern]
            # Optional PDF output gate
            if rt.output_plot.pdf
                # add your PDF computation here if necessary
            end
            # Obtain labels for this ionization state
            ion_labels = ionstexto(kern, 0)
            elem_sym = first(split(ion_labels.titleion))
            
            paths = prepare_electrons_per_element_paths(id_string, elem_sym; root=root) #

            maps_electron!(tps.eledenz[:, :, :, idk[kern]], sml.X_grid, sml.Y_grid, sml.Z_grid, var_name;
                   kern = kern, ionz = 0, is_ions = false,
                   cfg = cfg, pgp = pgp, rt = rt, modions = modions,
                   formats = formats,
                   id_string = id_string,
                   root = root
                )
        end
    end

    return nothing
end
