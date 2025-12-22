
# ==============================================================================
# AstroTLPlot Main Module
# 
# This module serves as the central entry point for the AstroTLPlot package,
# integrating data structures, configuration systems, visualization tools,
# statistical analysis, and processing routines for plasma and MHD# statistical analysis, and processing routines for plasma and MHD simulations.
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

include("data_structures/constants.jl")
include("data_structures/data_structure.jl")
include("data_structures/config.jl")
include("data_structures/pgp.jl")
include("data_structures/modions.jl")
include("data_structures/runtime.jl")

include("data_structures/data_statistics.jl")
include("data_structures/read_config.jl")
include("read_data/read_data.jl")

include("maps/maps.jl")
include("ions/ions.jl")
include("ions/electron.jl")
include("setup/setup.jl")
include("utils/spline.jl") 
include("data_structures/show_methods.jl")
include("statistics/statistics.jl")
include("process/process.jl")

# Export  constants selected 

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

# export config
export
    GridSize,Debug,Directories,FileFormat,SimulationType,RealDims,MapsDims,NumberOfPlots,
    SetMinMaxIndex,Increments,VariableParams,SimulationData,Scales,IonsPlot,IonsType,
    Abundances,AtomicIonicFraction,Interpolation,Element,
    MainConfig

# export PGP
export # Point2D, Point3D, MinMaxRange,
        SetMinMaxVar,ContourLimits,Views,Labels,Title,Device,GLMinMax,
        mainPGP,initialize_main_PGP

# modions
export IonProperties,IonLabels,IonStatistics,IonFractions,TemperatureProperties,SetMinMaxIons,
       MainModions,initialize_main_modions       
 
 
# runTime 
export LoopGraphic,OutputPlot,ExecutionState,Transformation,PlotSetting,Tracer,Volume,TimeFile,Data,Aspect,
        initialize_main_runtime
        
# read_config
export
   ConfigData, PGPData, RuntimeData, ModionsData    
   
#readdata   
export variables, 
    readlist,readlist!,read_ref_data_ds,
    readdata_hdf4!,readdata_hdf5!, 
    read_hdf5_file_,analyze_hdf5_datasets, load_simulation_data!, # read refdata.dat
    variables_v2!
   
# export
   
 # Setup  
 export 
      open_file,load_simulation_config_struct,load_simulation_config, allocate_vars, configure  
 
 # util/spline.jl
 export 
        spline3_coef, spline3_eval, 
        natural_cubic_spline, evaluate_spline,spline3_eval_v2,
        parse_float_scientific, print_vect, print_struct_info
  
 # maps   # util/maps.jl
 export
      create_plot_structure,get_palette,escala!, get_element_label,get_label_,get_label,pglabel!,
      add_copyright,add_text_at,pgmtext_in, escrever!,
      writeplot,save_or_display,add_labels!, 
        
       plot_heatmap,plot_contour, plot_heat_cont,
       maps!, mapas_ions!,plot_element_subplot
       plot_heatmap_log3 ,crop_slice,
       get_pdf_label,plot_pdf_test,
       calculate_pdf, find_min_max_coords,
       maps_subplot!
       
 # statistics
 export find_axis_limits_data,
        statistics_data1D,statistics_data_windowed1D,statistics_dic1D,
        statistics_data2D,statistics_data_windowed2D,statistics_dic2D,
        statistics_data3D,statistics_data_windowed3D,statistics_dic3D,
        statistics_data2D_optimized,statistics_data2D_native,
        export_statistics, save_stats_from_writeplot,
     
        print_statistics
        
 # process/process.jl
 export 
      process_variable,process_simulation_files,process_simulation_list,
      load_data, index_to_coord,compute_variable,setminmaxvar #private
      
 #Ions  #util/ions.jl
 export
    allocate_ions,create_ionproperties,
    count_ions,
    ions_read_vf, 
    abundances!,fractions_spline!,
    #mapfractions!,
    ionstexto,
    plot_element_subplot,
    ions! 
    
 # ions/electron.jl")
 export
    electron!

end
