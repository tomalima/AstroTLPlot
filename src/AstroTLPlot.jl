# ==============================================================================
# AstroTLPlot Main Module
# 
# This module serves as the central entry point for the AstroTLPlot package,
# integrating data structures, configuration systems, visualization tools,
# statistical analysis, and processing routines for plasma and MHD# statistical analysis, 
# and processing routines for plasma and MHD simulations.
# It provides a unified interface for reading simulation data, managing
# configurations, generating plots, and performing post-processing tasks.
#
# Author: [Tomás Lima]
# Date: [2025-10-17]
# ==============================================================================

module AstroTLPlot

using HDF5
using YAML
using PyCall

# ==============================================================================
# Utility modules (inspection, diagnostics, FAIR path helpers)
# ==============================================================================
include("utils/inspect_statistics.jl")  # Utilities for printing and exporting statistical summaries (txt/pdf)
include("utils/inspect.jl")             # Generic inspection helpers (arrays, structs, debugging tools)
include("utils/paths.jl")               # FAIR‑compliant path builders (snapshot IDs, folder structures)

# ==============================================================================
# Core data structures (constants, configurations, PGP parsing, runtime state)
# ==============================================================================
include("data_structures/constants.jl")      # Physical/constants definitions and global immutable parameters
include("data_structures/data_structure.jl") # Primary composite types used across the codebase
include("data_structures/config.jl")         # Configuration structs and parameter containers
include("data_structures/pgp.jl")            # Parsing and handling of .pgp simulation configuration files
include("data_structures/modions.jl")        # Element/ion metadata structures and indexing models
include("data_structures/runtime.jl")        # Runtime mutable containers and simulation execution state

# ==============================================================================
# Statistical data structures and configuration readers
# ==============================================================================
include("data_structures/data_statistics.jl") # Types for statistical results (2D/3D statistics containers)
include("data_structures/read_config.jl")     # Reading and loading user configuration files

# ==============================================================================
# Data ingestion (input readers)
# ==============================================================================
include("read_data/read_data.jl") # High‑level routines to read physical fields, grids, and snapshots

# ==============================================================================
# Scientific modules (maps, ions, setup)
# ==============================================================================
include("maps/maps.jl")        # Map generation pipelines (heatmaps, contours, combined plots)
include("ions/ions.jl")        # Ion metadata, labeling utilities, ionization indexing logic
include("ions/electron.jl")    # Electron‑specific helpers (total/element‑resolved electrons)

include("setup/setup.jl")      # Initialization, directory preparation, and environment setup routines

# ==============================================================================
# Mathematical and structural helpers
# ==============================================================================
include("utils/spline.jl")             # Cubic spline interpolation routines (coefficients, evaluation)
include("data_structures/show_methods.jl")   # Pretty-printing and custom show() methods for structs

# ==============================================================================
# Statistical computations and field processing
# ==============================================================================
include("statistics/statistics.jl")    # Actual computation of statistics (mean, variance, extrema, ranges)
include("process/process.jl")          # Processing workflows (filters, transforms, field operations)


export GAMMA, GAMM1
export BOLTZ, CLIGHT, HPL
export ELMA, MP, MH
export SMALLP, CMPC
export PI
export SP, DP, QP

export MAXCOO, MAX_ATOMIC_NUMBER
export WIDTHPLOT, ASPECTPLOT
export GUNIT, LUNIT, TEMGUNIT, TEMLUNIT, PREGUNIT, PRELUNIT, RAMGUNIT, RAMLUNIT

export MAXCOO, MAX_ATOMIC_NUMBER,
       error_message

# data_structure.jl
export  Point2D, Point3D, MinMaxRange #All module can access Point2D, Point3D, MinMaxRange
        
export Coordinate2DResult, Axis2DLimits,MinMaxRange,StatisticsData2D,Matrix2DStatistics 

export build_id_string, prepare_variable_paths

# export config
export
    GridSize,Debug,Directories,FileFormat,SimulationType,RealDims,MapsDims,NumberOfPlots,
    SetMinMaxIndex,Increments,VariableParams,SimulationData,Scales,IonsPlot,IonsType,
    Abundances,AtomicIonicFraction,Interpolation,Element,
    MainConfig

# export PGP
export  
        Point2D, Point3D, MinMaxRange,
        SetMinMaxVar,ContourLimits,Views,Labels,Title,Device,GLMinMax,
        mainPGP,initialize_main_PGP

# modions
export IonProperties,IonLabels,IonStatistics,IonFractions,TemperatureProperties,SetMinMaxIons,
       MainModions,initialize_main_modions       
 
# runTime 
export LoopGraphic,OutputPlot,ExecutionState,Transformation,PlotSetting,Tracer,Volume,TimeFile,Data,Aspect,
        initialize_main_runtime
        
export read_ref_data_ds,readdata_hdf5!, variables!
   
 # Setup  
 export 
    load_simulation_config, configure, allocate_vars                

 # util/inspect.jl
 export
  print_vect, print_struct_info
  
 # maps   
 export
      plot_heatmap,plot_contour, plot_heat_cont,
      maps!, mapas_ions!, plot_heatmap_log3,
      plot_element_subplot,
      maps_subplot!
       
 # statistics
 export statistics_data, statistics_dic
        statistics_data2D_optimized,statistics_data2D_native

 # inspect_statistics.jl"     
 export export_statistics, save_stats_from_writeplot,
        print_statistics
  
 # process/process.jl
 export 
      process_simulation_files,process_simulation_list,
      compute_variable
      
 #Ions  #ions/ions.jl
 export count_ions,abundances!,ions_read, create_ionproperties,ions! 
    
 # ions/electron.jl")
 export
    electron!

end
