"""
    read_indatpgp3(filename)

Reads and parses the YAML configuration file (`filename`) and maps the content 
into structured data types (`ConfigData`, `PGPData`, `RuntimeData`, `ModionsData`).

# Arguments
- `filename::String`: Path to the YAML configuration file.

# Returns
- A tuple `(config_data, pgp_data, runtime_data, modions_data)` containing the 
  parsed configuration, visualization, runtime, and ion-specific parameters.

# Notes
- Includes error handling to capture and report issues such as missing keys, 
  invalid types, or unreadable files.
"""
function read_indatpgp3(filename)
    try
        # Load YAML configuration file
        data = YAML.load_file(filename)

        # =========================
        # Configuration Data
        # =========================
        config_data = ConfigData(
            Debug(data["Debug"]["ldebug"]),
            Directories(data["Directories"]["directory"], data["Directories"]["diratomic"]),
            SimulationType(data["SimulationType"]["lhdrun"], data["SimulationType"]["lmhdrun"]),
            FileFormat(data["FileFormat"]["lhdf"], data["FileFormat"]["lascii"], data["FileFormat"]["lvtk"]),
            GridSize(Config.Point3D(data["GridSize"]["in"], data["GridSize"]["jn"], data["GridSize"]["kn"])),
            RealDims(Config.Point3D(data["RealDims"]["xmin"], data["RealDims"]["ymin"], data["RealDims"]["zmin"]),
                     Config.Point3D(data["RealDims"]["xmax"], data["RealDims"]["ymax"], data["RealDims"]["zmax"]),
                     data["RealDims"]["units"]),
            MapsDims(Config.Point3D(data["MapsDims"]["x1"], data["MapsDims"]["y1"], data["MapsDims"]["z1"]),
                     Config.Point3D(data["MapsDims"]["x2"], data["MapsDims"]["y2"], data["MapsDims"]["z2"])),
            NumberOfPlots(data["NumberOfPlots"]["nfiles"], data["NumberOfPlots"]["nfile_start"], data["NumberOfPlots"]["nfile_end"],
                          data["NumberOfPlots"]["jump"], data["NumberOfPlots"]["nl"], data["NumberOfPlots"]["numx"], data["NumberOfPlots"]["numy"]),
            VariableParams(
                data["VariableParams"]["ldens"], data["VariableParams"]["ltemp"], data["VariableParams"]["lpres"], data["VariableParams"]["lpram"],
                data["VariableParams"]["lmagn"], data["VariableParams"]["lentr"], data["VariableParams"]["lmach"], data["VariableParams"]["lions"],
                data["VariableParams"]["lele"], data["VariableParams"]["lratios"], data["VariableParams"]["lele_kern"]
            ),
            Interpolation(data["Interpolation"]["lspline"], data["Interpolation"]["lrloss"]),
            Abundances(data["Abundances"]["lallen"], data["Abundances"]["lag89"], data["Abundances"]["lasplund"],
                       data["Abundances"]["lgas07"], data["Abundances"]["lagss09"], data["Abundances"]["zmetal"],
                       data["Abundances"]["deplt"]),
            Scales(
                data["Scales"]["timescale"], 
                data["Scales"]["bscale"], 
                data["Scales"]["denscale"],
                data["Scales"]["temscale"], 
                data["Scales"]["velscale"], 
                data["Scales"]["elescale"], 
                data["Scales"]["logs"]
            ),
            IonsPlot(
                data["IonsPlot"]["plhyd"], data["IonsPlot"]["plhel"], data["IonsPlot"]["plcar"],
                data["IonsPlot"]["plnit"], data["IonsPlot"]["ploxy"], data["IonsPlot"]["plne"],
                data["IonsPlot"]["plmg"], data["IonsPlot"]["plsil"], data["IonsPlot"]["plsul"],
                data["IonsPlot"]["plar"], data["IonsPlot"]["plfe"]
            ),
            IonsType(
                data["IonsType"]["lhyd"], data["IonsType"]["lhel"], data["IonsType"]["lcar"],
                data["IonsType"]["lnit"], data["IonsType"]["loxy"], data["IonsType"]["lne"],
                data["IonsType"]["lmg"], data["IonsType"]["lsil"], data["IonsType"]["lsul"],
                data["IonsType"]["lar"], data["IonsType"]["lfe"]
            ),
            AtomicIonicFraction(data["AtomicIonicFraction"]["id"], data["AtomicIonicFraction"]["ncool"], 0, 0.0)
        )

        # =========================
        # PGP Data
        # =========================
        pgp_data = PGPData(
            SetMinMaxVar(
                PGP.MinMaxRange(data["setminmaxvar"]["dmin"], data["setminmaxvar"]["dmax"]),
                PGP.MinMaxRange(data["setminmaxvar"]["tmin"], data["setminmaxvar"]["tmax"]),
                PGP.MinMaxRange(data["setminmaxvar"]["pmin"], data["setminmaxvar"]["pmax"]),
                PGP.MinMaxRange(data["setminmaxvar"]["pokmin"], data["setminmaxvar"]["pokmax"]),
                PGP.MinMaxRange(data["setminmaxvar"]["bmin"], data["setminmaxvar"]["bmax"]),
                PGP.MinMaxRange(data["setminmaxvar"]["pmagmin"], data["setminmaxvar"]["pmagmax"]),
                PGP.MinMaxRange(data["setminmaxvar"]["betamin"], data["setminmaxvar"]["betamax"]),
                PGP.MinMaxRange(data["setminmaxvar"]["valfmin"], data["setminmaxvar"]["valfmax"]),
                PGP.MinMaxRange(data["setminmaxvar"]["machmin"], data["setminmaxvar"]["machmax"]),
                PGP.MinMaxRange(data["setminmaxvar"]["rotmin"], data["setminmaxvar"]["rotmax"]),
                PGP.MinMaxRange(data["setminmaxvar"]["vzmin"], data["setminmaxvar"]["vzmax"])
            ),
            ContourLimits(
                PGP.MinMaxRange(data["mincontours"]["tmincont"], data["mincontours"]["tmaxcont"]),
                PGP.MinMaxRange(data["mincontours"]["dmincont"], data["mincontours"]["dmaxcont"])
            ),
            Device(data["Device"]["device"], data["Device"]["dev"]),
            Views(data["Views"]["top"], data["Views"]["front"], data["Views"]["side"], data["Views"]["vertvar"], false),
            Title(data["Title"]["title"], data["Title"]["resolution"], data["Title"]["supernova"],
                  data["Title"]["author"], data["Title"]["unittime"]),
            Labels(data["Labels"]["xlabel"], data["Labels"]["ylabel"], data["Labels"]["writetime"], data["Labels"]["localizar"])
        )

        # =========================
        # Runtime Data
        # =========================
        runtime_data = RuntimeData(
            LoopGraphic(data["Loopgraf"]["lmin"], data["Loopgraf"]["lmax"], data["Loopgraf"]["stepl"]),
            OutputPlot(data["OutputPlot"]["pdf"], data["OutputPlot"]["cont"], data["OutputPlot"]["grey"], data["OutputPlot"]["color"], data["OutputPlot"]["nconts"]),
            PlotSetting(data["PlotSetting"]["paleta"], data["PlotSetting"]["orientacao"]),
            Tracer(data["Tracer"]["nmintrace"], data["Tracer"]["ntraces"]),
            Aspect(data["Aspects"]["width"], data["Aspects"]["aspect"])
        )

        # =========================
        # Modions Data
        # =========================
        modions_data = ModionsData(
            SetMinMaxIons(
                Modions.MinMaxRange(data["setminmaxions"]["elemin"], data["setminmaxions"]["elemax"]),
                Modions.MinMaxRange(data["setminmaxions"]["ovimin"], data["setminmaxions"]["ovimax"])
            )
        )

        # Return grouped structured data
        return (config_data, pgp_data, runtime_data, modions_data)

    catch e
        # Exception handling: capture and display error details
        @error "Error reading configuration file $filename: $(e.msg)"
        rethrow(e)  # rethrow to propagate the error if needed
    end
end



#=
function read_indatpgp3(filename)
    data = YAML.load_file(filename)

    # Dados de Configuração
    config_data = ConfigData(
        Debug(data["Debug"]["ldebug"]),
        Directories(data["Directories"]["directory"], data["Directories"]["diratomic"]),
        SimulationType(data["SimulationType"]["lhdrun"], data["SimulationType"]["lmhdrun"]),
        FileFormat(data["FileFormat"]["lhdf"], data["FileFormat"]["lascii"], data["FileFormat"]["lvtk"]),
        GridSize(Config.Point3D(data["GridSize"]["in"], data["GridSize"]["jn"], data["GridSize"]["kn"])),
        RealDims(Config.Point3D(data["RealDims"]["xmin"], data["RealDims"]["ymin"], data["RealDims"]["zmin"]),
                 Config.Point3D(data["RealDims"]["xmax"], data["RealDims"]["ymax"], data["RealDims"]["zmax"]),
                 data["RealDims"]["units"]),
        MapsDims(Config.Point3D(data["MapsDims"]["x1"], data["MapsDims"]["y1"], data["MapsDims"]["z1"]),
                 Config.Point3D(data["MapsDims"]["x2"], data["MapsDims"]["y2"], data["MapsDims"]["z2"])),
        NumberOfPlots(data["NumberOfPlots"]["nfiles"], data["NumberOfPlots"]["nfile_start"], data["NumberOfPlots"]["nfile_end"],
                      data["NumberOfPlots"]["jump"], data["NumberOfPlots"]["nl"], data["NumberOfPlots"]["numx"], data["NumberOfPlots"]["numy"]),
        VariableParams(
            data["VariableParams"]["ldens"], data["VariableParams"]["ltemp"], data["VariableParams"]["lpres"], data["VariableParams"]["lpram"],
            data["VariableParams"]["lmagn"], data["VariableParams"]["lentr"], data["VariableParams"]["lmach"], data["VariableParams"]["lions"],
            data["VariableParams"]["lele"], data["VariableParams"]["lratios"], data["VariableParams"]["lele_kern"]
        ),
        Interpolation(data["Interpolation"]["lspline"], data["Interpolation"]["lrloss"]),
        Abundances(data["Abundances"]["lallen"], data["Abundances"]["lag89"], data["Abundances"]["lasplund"],
                   data["Abundances"]["lgas07"], data["Abundances"]["lagss09"], data["Abundances"]["zmetal"],
                   data["Abundances"]["deplt"]),
        Scales(
            data["Scales"]["timescale"], 
            data["Scales"]["bscale"], 
            data["Scales"]["denscale"],
            data["Scales"]["temscale"], 
            data["Scales"]["velscale"], 
            data["Scales"]["elescale"], 
            data["Scales"]["logs"]
        ),
        IonsPlot(
            data["IonsPlot"]["plhyd"], data["IonsPlot"]["plhel"], data["IonsPlot"]["plcar"],
            data["IonsPlot"]["plnit"], data["IonsPlot"]["ploxy"], data["IonsPlot"]["plne"],
            data["IonsPlot"]["plmg"], data["IonsPlot"]["plsil"], data["IonsPlot"]["plsul"],
            data["IonsPlot"]["plar"], data["IonsPlot"]["plfe"]
        ),
        IonsType(
            data["IonsType"]["lhyd"], data["IonsType"]["lhel"], data["IonsType"]["lcar"],
            data["IonsType"]["lnit"], data["IonsType"]["loxy"], data["IonsType"]["lne"],
            data["IonsType"]["lmg"], data["IonsType"]["lsil"], data["IonsType"]["lsul"],
            data["IonsType"]["lar"], data["IonsType"]["lfe"]
        ),
        AtomicIonicFraction(data["AtomicIonicFraction"]["id"], data["AtomicIonicFraction"]["ncool"], 0, 0.0)
    )

    # Dados de PGP
    pgp_data = PGPData(
        SetMinMaxVar(
            PGP.MinMaxRange(data["setminmaxvar"]["dmin"], data["setminmaxvar"]["dmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["tmin"], data["setminmaxvar"]["tmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["pmin"], data["setminmaxvar"]["pmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["pokmin"], data["setminmaxvar"]["pokmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["bmin"], data["setminmaxvar"]["bmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["pmagmin"], data["setminmaxvar"]["pmagmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["betamin"], data["setminmaxvar"]["betamax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["valfmin"], data["setminmaxvar"]["valfmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["machmin"], data["setminmaxvar"]["machmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["rotmin"], data["setminmaxvar"]["rotmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["vzmin"], data["setminmaxvar"]["vzmax"])
        ),
        ContourLimits(
            PGP.MinMaxRange(data["mincontours"]["tmincont"], data["mincontours"]["tmaxcont"]),
            PGP.MinMaxRange(data["mincontours"]["dmincont"], data["mincontours"]["dmaxcont"])
        ),
        Device(data["Device"]["device"], data["Device"]["dev"]),
        Views(data["Views"]["top"], data["Views"]["front"], data["Views"]["side"], data["Views"]["vertvar"], false),
        Title(data["Title"]["title"], data["Title"]["resolution"], data["Title"]["supernova"],
              data["Title"]["author"], data["Title"]["unittime"]),
        Labels(data["Labels"]["xlabel"], data["Labels"]["ylabel"], data["Labels"]["writetime"], data["Labels"]["localizar"])
    )

    # Dados de Runtime
    runtime_data = RuntimeData(
        LoopGraphic(data["Loopgraf"]["lmin"], data["Loopgraf"]["lmax"], data["Loopgraf"]["stepl"]),
        OutputPlot(data["OutputPlot"]["pdf"], data["OutputPlot"]["cont"], data["OutputPlot"]["grey"], data["OutputPlot"]["color"], data["OutputPlot"]["nconts"]),
        PlotSetting(data["PlotSetting"]["paleta"], data["PlotSetting"]["orientacao"]),
        Tracer(data["Tracer"]["nmintrace"], data["Tracer"]["ntraces"]),
        Aspect(data["Aspects"]["width"], data["Aspects"]["aspect"])
    )

    # Dados de Modions
    modions_data = ModionsData(
        SetMinMaxIons(
            Modions.MinMaxRange(data["setminmaxions"]["elemin"], data["setminmaxions"]["elemax"]),
            Modions.MinMaxRange(data["setminmaxions"]["ovimin"], data["setminmaxions"]["ovimax"])
        )
    )
    # Retorna os dados agrupados em structs
    return (config_data, pgp_data, runtime_data, modions_data)
end

=#

# *****************************************************************************************

function _read_indatpgp3(filename)
    data = YAML.load_file(filename)

    # Dados de Configuração
    config_data = ConfigData(
        Debug(data["Debug"]["ldebug"]),
        Directories(data["Directories"]["directory"], data["Directories"]["diratomic"]),
        SimulationType(data["SimulationType"]["lhdrun"], data["SimulationType"]["lmhdrun"]),
        FileFormat(data["FileFormat"]["lhdf"], data["FileFormat"]["lascii"], data["FileFormat"]["lvtk"]),
        GridSize(Config.Point3D(data["GridSize"]["in"], data["GridSize"]["jn"], data["GridSize"]["kn"])),
        RealDims(Config.Point3D(data["RealDims"]["xmin"], data["RealDims"]["ymin"], data["RealDims"]["zmin"]),
                 Config.Point3D(data["RealDims"]["xmax"], data["RealDims"]["ymax"], data["RealDims"]["zmax"]),
                 data["RealDims"]["units"]),
        MapsDims(Config.Point3D(data["MapsDims"]["x1"], data["MapsDims"]["y1"], data["MapsDims"]["z1"]),
                 Config.Point3D(data["MapsDims"]["x2"], data["MapsDims"]["y2"], data["MapsDims"]["z2"])),
        NumberOfPlots(data["NumberOfPlots"]["nfiles"], data["NumberOfPlots"]["nfile_start"], data["NumberOfPlots"]["nfile_end"],
                      data["NumberOfPlots"]["jump"], data["NumberOfPlots"]["nl"], data["NumberOfPlots"]["numx"], data["NumberOfPlots"]["numy"]),
        VariableParams(
            data["VariableParams"]["ldens"], data["VariableParams"]["ltemp"], data["VariableParams"]["lpres"], data["VariableParams"]["lpram"],
            data["VariableParams"]["lmagn"], data["VariableParams"]["lentr"], data["VariableParams"]["lmach"], data["VariableParams"]["lions"],
            data["VariableParams"]["lele"], data["VariableParams"]["lratios"], data["VariableParams"]["lele_kern"]
        ),
        Interpolation(data["Interpolation"]["lspline"], data["Interpolation"]["lrloss"]),
        Abundances(data["Abundances"]["lallen"], data["Abundances"]["lag89"], data["Abundances"]["lasplund"],
                   data["Abundances"]["lgas07"], data["Abundances"]["lagss09"], data["Abundances"]["zmetal"],
                   data["Abundances"]["deplt"]),
        Scales(
            data["Scales"]["timescale"], data["Scales"]["bscale"], data["Scales"]["denscale"],
            data["Scales"]["temscale"], data["Scales"]["velscale"], data["Scales"]["elescale"], data["Scales"]["logs"]
        ),
        IonsPlot(
            data["IonsPlot"]["plhyd"], data["IonsPlot"]["plhel"], data["IonsPlot"]["plcar"],
            data["IonsPlot"]["plnit"], data["IonsPlot"]["ploxy"], data["IonsPlot"]["plne"],
            data["IonsPlot"]["plmg"], data["IonsPlot"]["plsil"], data["IonsPlot"]["plsul"],
            data["IonsPlot"]["plar"], data["IonsPlot"]["plfe"]
        ),
        IonsType(
            data["IonsType"]["lhyd"], data["IonsType"]["lhel"], data["IonsType"]["lcar"],
            data["IonsType"]["lnit"], data["IonsType"]["loxy"], data["IonsType"]["lne"],
            data["IonsType"]["lmg"], data["IonsType"]["lsil"], data["IonsType"]["lsul"],
            data["IonsType"]["lar"], data["IonsType"]["lfe"]
        ),
        AtomicIonicFraction(data["AtomicIonicFraction"]["id"], data["AtomicIonicFraction"]["ncool"], 0, 0.0)
    )

    # Dados de PGP
    pgp_data = PGPData(
        SetMinMaxVar(
            PGP.MinMaxRange(data["setminmaxvar"]["dmin"], data["setminmaxvar"]["dmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["tmin"], data["setminmaxvar"]["tmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["pmin"], data["setminmaxvar"]["pmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["pokmin"], data["setminmaxvar"]["pokmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["bmin"], data["setminmaxvar"]["bmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["pmagmin"], data["setminmaxvar"]["pmagmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["betamin"], data["setminmaxvar"]["betamax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["valfmin"], data["setminmaxvar"]["valfmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["machmin"], data["setminmaxvar"]["machmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["rotmin"], data["setminmaxvar"]["rotmax"]),
            PGP.MinMaxRange(data["setminmaxvar"]["vzmin"], data["setminmaxvar"]["vzmax"])
        ),
        ContourLimits(
            PGP.MinMaxRange(data["mincontours"]["tmincont"], data["mincontours"]["tmaxcont"]),
            PGP.MinMaxRange(data["mincontours"]["dmincont"], data["mincontours"]["dmaxcont"])
        ),
        Device(data["Device"]["device"], data["Device"]["dev"]),
        Views(data["Views"]["top"], data["Views"]["front"], data["Views"]["side"], data["Views"]["vertvar"], false),
        Title(data["Title"]["title"], data["Title"]["resolution"], data["Title"]["supernova"],
              data["Title"]["author"], data["Title"]["unittime"]),
        Labels(data["Labels"]["xlabel"], data["Labels"]["ylabel"], data["Labels"]["writetime"], data["Labels"]["localizar"])
    )

    # Dados de Runtime
    runtime_data = RuntimeData(
        LoopGraphic(data["Loopgraf"]["lmin"], data["Loopgraf"]["lmax"], data["Loopgraf"]["stepl"]),
        OutputPlot(data["OutputPlot"]["pdf"], data["OutputPlot"]["cont"], data["OutputPlot"]["grey"], data["OutputPlot"]["color"], data["OutputPlot"]["nconts"]),
        PlotSetting(data["PlotSetting"]["paleta"], data["PlotSetting"]["orientacao"]),
        Tracer(data["Tracer"]["nmintrace"], data["Tracer"]["ntraces"]),
        Aspect(data["Aspects"]["width"], data["Aspects"]["aspect"])
    )

    # Dados de Modions
    modions_data = ModionsData(
        SetMinMaxIons(
            Modions.MinMaxRange(data["setminmaxions"]["elemin"], data["setminmaxions"]["elemax"]),
            Modions.MinMaxRange(data["setminmaxions"]["ovimin"], data["setminmaxions"]["ovimax"])
        )
    )
    # Retorna os dados agrupados em structs
    return SimulationData(config_data, pgp_data, runtime_data, modions_data)
end



# sim = read_indatpgp3("config.dat")
# mapa(sim, output_file="grafico.png")



# **************************************************************
