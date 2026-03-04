# ==============================================================================
# Statistics Reporting and Export Utilities Module
#
# This module provides helper functions to inspect, format, and export
# computed statistics for 2D datasets. It includes:
#   • Human-readable console summaries of statistical results
#   • Plain-text and PDF exporters (with timestamped filenames)
#   • Defensive I/O with status codes and structured logging
#   • Utilities to support automated reporting and QA workflows
#
# Typical usage:
#   - print_statistics(result)
#   - export_statistics(result; list_of_files=["out.txt", "out.pdf"], sav=true, disp=true)
#
# Notes:
#   - Keep statistical *computations* in `src/statistics/`.
#   - Use this module strictly for *inspection*, *reporting*, and *export*.
#
# Author: Tomás Lima
# Date: 2026-03-03
# ==============================================================================

# ==============================================================================
# 
# print_statistics(statistics::StatisticsData2D)
#
# ==============================================================================
"""
    print_statistics(statistics::StatisticsData2D)

Prints a summary of the statistical data contained within a `StatisticsData2D` object.

This function organizes and displays general statistics, extreme values, range,
axis limits, and the dimensions of the resulting matrix.

# Arguments
- `statistics::StatisticsData2D`: A struct containing the calculated statistical data.
"""
function print_statistics(statistics)
    # 1. GENERAL STATISTICS
    println("1. GENERAL STATISTICS:")
    println("   Sum: ", statistics.statistics_data.sum)
    println("   Mean: ", statistics.statistics_data.mean)
    println("   Variance: ", statistics.statistics_data.variance)
    println("   Standard Deviation: ", statistics.statistics_data.std_dev)
    println("   Number of Elements: ", statistics.statistics_data.n_elements)
    println("   Number of Rows: ", statistics.statistics_data.n_rows)
    println("   Number of Columns: ", statistics.statistics_data.n_columns)
    println()

    # 2. EXTREME VALUES
    println("2. EXTREME VALUES:")
    println("   Minimum Value: ", statistics.statistics_data.min_value.value2D)
    println("   Minimum Coordinates: ", statistics.statistics_data.min_value.index2D)
    println("   Maximum Value: ", statistics.statistics_data.max_value.value2D)
    println("   Maximum Coordinates: ", statistics.statistics_data.max_value.index2D)
    println()

    # 3. RANGE
    println("3. RANGE:")
    println("   Minimum Range: ", statistics.statistics_data.range_value.min)
    println("   Maximum Range: ", statistics.statistics_data.range_value.max)
    println()

    # 4. AXIS LIMITS
    println("4. AXIS LIMITS:")
    println("   X minimum: ", statistics.statistics_data.axis_limits.p2min.x)
    println("   X maximum: ", statistics.statistics_data.axis_limits.p2max.x)
    println("   Y minimum: ", statistics.statistics_data.axis_limits.p2min.y)
    println("   Y maximum: ", statistics.statistics_data.axis_limits.p2max.y)
    println()

    # 5. RESULTING MATRIX
    println("5. RESULTING MATRIX:")
    println("   Dimensions: ", size(statistics.matrix_result))
    #println("   Content:")
    #show(stdout, "text/plain", statistics.matrix_result)
    println("\n")
end

# ==============================================================================
# 
# 
#
# ==============================================================================

"""
    save_stats_from_writeplot(
        files::Vector{String},
        save_path::AbstractString,
        stats_result;
        subfolder_name::AbstractString = "statistics",
        report_ext::AbstractString = ".txt",
        file_index::Int = 1,
        sav::Bool = true,
        disp::Bool = false,
        allow_empty_files::Bool = false
    ) -> Int

Create (if needed) a dedicated `statistics` subfolder adjacent to the variable folder,
derive the base filename from the first `writeplot` output, and export a statistics report
(via your `export_statistics`) with the same basename and a chosen extension (default `.txt`).

**Folder rule:** if `save_path` is `<base>/<var>/<type>` (e.g., `./figures/mavil/den/color`),
the statistics folder is resolved as `<base>/<var>/<subfolder_name>` (e.g., `./figures/mavil/den/statistics`).

# Arguments
- `files::Vector{String}`: Filenames produced by `writeplot` (basename with extension; no paths).
- `save_path::AbstractString`: Final output directory for the plot type (e.g., `.../den/color`).
- `stats_result`: Object containing statistics **in the exact structure** expected by your
  `write_txt_statistics`/`export_statistics` (e.g., the object from `statistics_data2D(...)`).
  It must have fields like `statistics_data.sum, mean, variance, std_dev, n_elements, ...`,
  `min_value.value2D/index2D`, `max_value.value2D/index2D`, `range_value.min/max`,
  `axis_limits.p2min/p2max`, and `matrix_result`.

# Keyword arguments
- `subfolder_name`: Name of the statistics subfolder (default `"statistics"`).
- `report_ext`: Extension of the report (default `".txt"`, can be `".pdf"` if you implement `write_pdf_statistics`).
- `file_index`: Which file from `files` to use for the basename (default `1`).
- `sav`: Whether to save the report (passed to `export_statistics`).
- `disp`: Whether to display the stats in console (passed to `export_statistics`).
- `allow_empty_files`: If `true`, and `files` is empty, generates a fallback basename with timestamp.

# Returns
- `Int`: Status code returned by `export_statistics` (e.g., `STATUS_SAVE_SUCCESS`, or error codes).

# Usage
After `writeplot(...); save_or_display(..., output_path = save_path)`, call:

    _ = save_stats_from_writeplot(files, save_path, stats)

This will create:
    dirname(save_path)/subfolder_name/basename(report_ext)
e.g., `./figures/mavil/den/statistics/den_003000-042_171225_1428.txt`.
"""
function save_stats_from_writeplot(
    files::Vector{String},
    save_path::AbstractString,
    stats_result;
    subfolder_name::AbstractString = "statistics",
    report_ext::AbstractString = ".txt",
    file_index::Int = 1,
    sav::Bool = true,
    disp::Bool = false,
    allow_empty_files::Bool = false
) :: Int
    try
        # 1) Select basename from writeplot outputs (or fallback)
        basename_str = nothing
        if isempty(files)
            if allow_empty_files
                ts = Dates.format(Dates.now(), "ddmmyy_HHMM")
                basename_str = "report_$(ts)"  # generic fallback
                @warn "save_stats_from_writeplot: files is empty; using fallback basename='$basename_str'."
            else
                @warn "save_stats_from_writeplot: files list is empty and allow_empty_files=false; skipping."
                return AstroTLPlot.ERROR_EMPTY_FILE_LIST
            end
        else
            if file_index < 1 || file_index > length(files)
                @warn "save_stats_from_writeplot: file_index out of bounds; defaulting to 1."
                file_index = 1
            end
            # 'files' are names returned by writeplot (no paths)
            basename_str = splitext(basename(files[file_index]))[1]
        end

        # 2) Resolve the statistics folder: dirname(save_path)/subfolder_name
        # save_path == base/var/type -> stats_dir == base/var/subfolder_name
        var_folder = dirname(save_path)
        stats_dir  = joinpath(var_folder, subfolder_name)
        isdir(stats_dir) || mkpath(stats_dir)

        # 3) Build list_of_files for export_statistics (name only; path passed separately)
        # e.g., "den_003000-042_171225_1428.txt"
        stats_files = [string(basename_str, report_ext)]

        # 4) Call user's export function (it handles directory, permissions, etc.)
        return export_statistics(
            stats_result;
            list_of_files = stats_files,
            sav = sav,
            disp = disp,
            output_path = stats_dir
        )
    catch e
        @error "save_stats_from_writeplot: failed to export statistics." exception        @error "save_stats_from_writeplot: failed to export statistics." exception=(e, catch_backtrace())
        return AstroTLPlot.ERROR_GENERIC_SAVE_FAIL
    end
end

# ==============================================================================
# 
# 
#
# ==============================================================================
"""
    export_statistics(result, var_name::String, path::String=".")

Save the computed statistics and matrix information to a text file with a dynamic filename in a specified directory.
If the directory does not exist, it will be created automatically.

# Arguments
- `result`: The result object returned by `statistics_data2D_optimized` or similar function.
- `var_name::String`: A descriptive name for the variable or dataset, used in the filename.
- `path::String`: Directory where the file will be saved. Defaults to current directory `"."`.

# Behavior
Generates a filename in the format:
    statistics_output-var_name-YYYYMMDD_HHMMSS.txt
Writes the following sections to the file:
1. General statistics
2. Extreme values
3. Range
4. Axis limits
5. Resulting matrix dimensions

If the directory does not exist, it is created automatically.

# Example
```julia
export_statistics(result, "test_matrix", "/home/user/output")

"""

function export_statistics_(result, var_name::String, path::String=".")
# Create directory if it does not exist
mkpath(path)
# Generate dynamic filename
timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
filename = joinpath(path, "statistics_output-$(var_name)-$(timestamp).txt")

open(filename, "w") do io
    # 1. GENERAL STATISTICS
    println(io, "1. GENERAL STATISTICS:")
    println(io, "   Sum: ", result.statistics_data.sum)
    println(io, "   Mean: ", result.statistics_data.mean)
    println(io, "   Variance: ", result.statistics_data.variance)
    println(io, "   Standard Deviation: ", result.statistics_data.std_dev)
    println(io, "   Number of Elements: ", result.statistics_data.n_elements)
    println(io, "   Number of Rows: ", result.statistics_data.n_rows)
    println(io, "   Number of Columns: ", result.statistics_data.n_columns)
    println(io)

    # 2. EXTREME VALUES
    println(io, "2. EXTREME VALUES:")
    println(io, "   Minimum Value: ", result.statistics_data.min_value.value2D)
    println(io, "   Minimum Coordinates: ", result.statistics_data.min_value.index2D)
    println(io, "   Maximum Value: ", result.statistics_data.max_value.value2D)
    println(io, "   Maximum Coordinates: ", result.statistics_data.max_value.index2D)
    println(io)

    # 3. RANGE
    println(io, "3. RANGE:")
    println(io, "   Minimum Range: ", result.statistics_data.range_value.min)
    println(io, "   Maximum Range: ", result.statistics_data.range_value.max)
    println(io)

    # 4. AXIS LIMITS
    println(io, "4. AXIS LIMITS:")
    println(io, "   X minimum: ", result.statistics_data.axis_limits.p2min.x)
    println(io, "   X maximum: ", result.statistics_data.axis_limits.p2max.x)
    println(io, "   Y minimum: ", result.statistics_data.axis_limits.p2min.y)
    println(io, "   Y maximum: ", result.statistics_data.axis_limits.p2max.y)
    println(io)

    # 5. RESULTING MATRIX
    println(io, "5. RESULTING MATRIX:")
    println(io, "   Dimensions: ", size(result.matrix_result))
    println(io)
end

println(" Statistics saved to file: $filename")

end

# ==============================================================================
# 
# 
#
# ==============================================================================

"""
    export_statistics(result, var_name::String; path::String=".", writeTime::Bool=true)

Save computed statistics and matrix information to a text file with a dynamic filename
in a specified directory. If the directory does not exist, it will be created automatically.

# Arguments
- `result`: The result object returned by `statistics_data2D_optimized` or a similar function.
- `var_name::String`: A descriptive name for the variable/dataset, used in the filename.
- `path::String` (keyword, default `"."`): Directory where the file will be saved.
- `writeTime::Bool` (keyword, default `true`): If `true`, appends a timestamp to the filename; if `false`, no timestamp.

# Behavior
Generates a filename in one of the following formats:
- With timestamp: `statistics_output-var_name-YYYYMMDD_HHMMSS.txt`
- Without timestamp: `statistics_output-var_name.txt`

Writes the following sections to the file:
1. General statistics
2. Extreme values
3. Range
4. Axis limits
5. Resulting matrix dimensions

If the directory does not exist, it is created automatically.

# Returns
- `String`: The full path to the saved file.

# Examples
```julia
export_statistics(result, "test_matrix")                                           # defaults: path=".", writeTime=true
export_statistics(result, "test_matrix"; path="/home/user/output")                # with timestamp
export_statistics(result, "test_matrix"; path="/home/user/output", writeTime=false)  # without timestamp
"""

function export_statistics__(result, var_name::String; path::String=".", writeTime::Bool=true)
    # Ensure the directory exists
    mkpath(path)
    # Build filename (with or without timestamp)
    filename = if writeTime
        timestamp = Dates.format(Dates.now(), "yyyymmdd_HHMMSS")
        joinpath(path, "statistics_output-$(var_name)-$(timestamp).txt")
    else
        joinpath(path, "statistics_output-$(var_name).txt")
    end

    # Write content
    open(filename, "w") do io
        # 1. GENERAL STATISTICS
        println(io, "1. GENERAL STATISTICS:")
        println(io, "   Sum: ", result.statistics_data.sum)
        println(io, "   Mean: ", result.statistics_data.mean)
        println(io, "   Variance: ", result.statistics_data.variance)
        println(io, "   Standard Deviation: ", result.statistics_data.std_dev)
        println(io, "   Number of Elements: ", result.statistics_data.n_elements)
        println(io, "   Number of Rows: ", result.statistics_data.n_rows)
        println(io, "   Number of Columns: ", result.statistics_data.n_columns)
        println(io)

        # 2. EXTREME VALUES
        println(io, "2. EXTREME VALUES:")
        println(io, "   Minimum Value: ", result.statistics_data.min_value.value2D)
        println(io, "   Minimum Coordinates: ", result.statistics_data.min_value.index2D)
        println(io, "   Maximum Value: ", result.statistics_data.max_value.value2D)
        println(io, "   Maximum Coordinates: ", result.statistics_data.max_value.index2D)
        println(io)

        # 3. RANGE
        println(io, "3. RANGE:")
        println(io, "   Minimum Range: ", result.statistics_data.range_value.min)
        println(io, "   Maximum Range: ", result.statistics_data.range_value.max)
        println(io)

        # 4. AXIS LIMITS
        println(io, "4. AXIS LIMITS:")
        println(io, "   X minimum: ", result.statistics_data.axis_limits.p2min.x)
        println(io, "   X maximum: ", result.statistics_data.axis_limits.p2max.x)
        println(io, "   Y minimum: ", result.statistics_data.axis_limits.p2min.y)
        println(io, "   Y maximum: ", result.statistics_data.axis_limits.p2max.y)
        println(io)

        # 5. RESULTING MATRIX
        println(io, "5. RESULTING MATRIX:")
        println(io, "   Dimensions: ", size(result.matrix_result))
        println(io)
    end

    println("Statistics saved to file: $filename")
    return filename
end

#-------------------------------------

# --- Helper: write plain-text statistics -> returns status code ---
function write_txt_statistics(path::String, result)::Int
    try
        open(path, "w") do io
            println(io, "1. GENERAL STATISTICS:")
            println(io, "   Sum: ", result.statistics_data.sum)
            println(io, "   Mean: ", result.statistics_data.mean)
            println(io, "   Variance: ", result.statistics_data.variance)
            println(io, "   Standard Deviation: ", result.statistics_data.std_dev)
            println(io, "   Number of Elements: ", result.statistics_data.n_elements)
            println(io, "   Number of Rows: ", result.statistics_data.n_rows)
            println(io, "   Number of Columns: ", result.statistics_data.n_columns)
            println(io)

            println(io, "2. EXTREME VALUES:")
            println(io, "   Minimum Value: ", result.statistics_data.min_value.value2D)
            println(io, "   Minimum Coordinates: ", result.statistics_data.min_value.index2D)
            println(io, "   Maximum Value: ", result.statistics_data.max_value.value2D)
            println(io, "   Maximum Coordinates: ", result.statistics_data.max_value.index2D)
            println(io)

            println(io, "3. RANGE:")
            println(io, "   Minimum Range: ", result.statistics_data.range_value.min)
            println(io, "   Maximum Range: ", result.statistics_data.range_value.max)
            println(io)

            println(io, "4. AXIS LIMITS:")
            println(io, "   X minimum: ", result.statistics_data.axis_limits.p2min.x)
            println(io, "   X maximum: ", result.statistics_data.axis_limits.p2max.x)
            println(io, "   Y minimum: ", result.statistics_data.axis_limits.p2min.y)
            println(io, "   Y maximum: ", result.statistics_data.axis_limits.p2max.y)
            println(io)

            println(io, "5. RESULTING MATRIX:")
            println(io, "   Dimensions: ", size(result.matrix_result))
            println(io)
        end
        
        @info AstroTLPlot.error_message(STATUS_SAVE_SUCCESS) code=STATUS_SAVE_SUCCESS path=path kind="txt"
        return AstroTLPlot.STATUS_SAVE_SUCCESS
    catch e
        @error error_message(ERROR_TXT_WRITE_FAIL) error=e code=ERROR_TXT_WRITE_FAIL path=path kind="txt"
        return ERROR_TXT_WRITE_FAIL
    end
end

# --- Helper: write PDF statistics -> returns status code ---
function write_pdf_statistics(path::String, result)::Int
    try
        # Example using Luxor.jl (ensure it's available in your environment)
        # using Luxor
        d = Luxor.Drawing(path, 595, 842, :pdf)  # A4 portrait
        Luxor.origin()
        Luxor.fontface("Helvetica")
        Luxor.setcolor("black")

        Luxor.text("1. GENERAL STATISTICS:", Luxor.Point(-260, -360))
        Luxor.text("   Sum: $(result.statistics_data.sum)", Luxor.Point(-260, -340))
        Luxor.text("   Mean: $(result.statistics_data.mean)", Luxor.Point(-260, -320))
        Luxor.text("   Variance: $(result.statistics_data.variance)", Luxor.Point(-260, -300))
        Luxor.text("   Standard Deviation: $(result.statistics_data.std_dev)", Luxor.Point(-260, -280))
        Luxor.text("   Number of Elements: $(result.statistics_data.n_elements)", Luxor.Point(-260, -260))
        Luxor.text("   Number of Rows: $(result.statistics_data.n_rows)", Luxor.Point(-260, -240))
        Luxor.text("   Number of Columns: $(result.statistics_data.n_columns)", Luxor.Point(-260, -220))

        Luxor.text("2. EXTREME VALUES:", Luxor.Point(-260, -190))
        Luxor.text("   Minimum Value: $(result.statistics_data.min_value.value2D)", Luxor.Point(-260, -170))
        Luxor.text("   Minimum Coordinates: $(result.statistics_data.min_value.index2D)", Luxor.Point(-260, -150))
        Luxor.text("   Maximum Value: $(result.statistics_data.max_value.value2D)", Luxor.Point(-260, -130))
        Luxor.text("   Maximum Coordinates: $(result.statistics_data.max_value.index2D)", Luxor.Point(-260, -110))

        Luxor.text("3. RANGE:", Luxor.Point(-260, -80))
        Luxor.text("   Minimum Range: $(result.statistics_data.range_value.min)", Luxor.Point(-260, -60))
        Luxor.text("   Maximum Range: $(result.statistics_data.range_value.max)", Luxor.Point(-260, -40))

        Luxor.text("4. AXIS LIMITS:", Luxor.Point(-260, -10))
        Luxor.text("   X minimum: $(result.statistics_data.axis_limits.p2min.x)", Luxor.Point(-260, 10))
        Luxor.text("   X maximum: $(result.statistics_data.axis_limits.p2max.x)", Luxor.Point(-260, 30))
        Luxor.text("   Y minimum: $(result.statistics_data.axis_limits.p2min.y)", Luxor.Point(-260, 50))
        Luxor.text("   Y maximum: $(result.statistics_data.axis_limits.p2max.y)", Luxor.Point(-260, 70))

        Luxor.text("5. RESULTING MATRIX:", Luxor.Point(-260, 100))
        Luxor.text("   Dimensions: $(size(result.matrix_result))", Luxor.Point(-260, 120))

        Luxor.finish()
        @info error_message(STATUS_SUCCESS) code=STATUS_SUCCESS path=path kind="pdf"
        return STATUS_SUCCESS
    catch e
        @error error_message(ERROR_PDF_WRITE_FAIL) error=e code=ERROR_PDF_WRITE_FAIL path=path kind="pdf"
        return ERROR_PDF_WRITE_FAIL
    end
end

# ==============================================================================
# 
# 
#
# ==============================================================================

"""
    export_statistics(result;
                            list_of_files::Union{Nothing,Vector{String}}=nothing,
                            sav::Bool=true,
                            disp::Bool=false,
                            output_path::String=".") :: Int

Save computed statistics and matrix information to one or more files when `list_of_files`
is provided and non-empty (supports only `.txt` and `.pdf`). Optionally display the statistics.

Special behavior:
- If `list_of_files === nothing` (omitted), the function **immediately calls** `print_statistic(result)`,
  logs the outcome using `error_message(...)`, and returns a **status code** (`STATUS_SUCCESS` or `STATUS_DISPLAY_FAIL`).

Defensive behavior:
- Uses `try/catch` for I/O failures.
- Creates `output_path` if missing and checks write permissions.
- Validates supported output extensions (only `.txt` and `.pdf`).

Returns:
- `Int`: Status code.
  - `STATUS_SUCCESS` (0) if all requested actions succeed.
  - Specific error code (e.g., `ERROR_TXT_WRITE_FAIL`, `ERROR_PDF_WRITE_FAIL`, `STATUS_DISPLAY_FAIL`, …) otherwise.

Examples:
```julia
# 1) Omitted list_of_files: immediately display (ignores sav/disp)
code = export_statistics(result)

# 2) Save to current directory, do not display
code = export_statistics(result; list_of_files=["den-3000-12122025-103030.txt"])

# 3) Save and display
code = export_statistics(result; list_of_files=["den-3000-12122025-103030.txt"],
                               output_path="/home/user/out", sav=true, disp=true)

# 4) Only display, skip saving
code = export_statistics(result; list_of_files=["den-3000-12122025-103030.txt"], sav=false, disp=true)

# 5) Save PDF
code = export_statistics(result; list_of_files=["den-3000-12122025-103030.pdf"], output_path=".")

"""

function export_statistics(result;
    list_of_files::Union{Nothing,Vector{String}}=nothing,
    sav::Bool=true,
    disp::Bool=false,
    output_path::String=".")::Int
# --- Case 1: list_of_files omitted -> immediate display, ignore sav/disp ---
if list_of_files === nothing
    try
        print_statistics(result)
        @info error_message(STATUS_SUCCESS) code=STATUS_SUCCESS context="display_only"
        return STATUS_SUCCESS
    catch e
        @error error_message(STATUS_DISPLAY_FAIL) error=e code=STATUS_DISPLAY_FAIL context="display_only"
        return STATUS_DISPLAY_FAIL
    end
end

# --- Case 2: list_of_files provided ---
status_code = STATUS_SUCCESS  # track first failure code (or success if none)


# --- Saving logic ---
if sav
    try
        if isempty(list_of_files)
            @warn error_message(ERROR_EMPTY_FILE_LIST) code=ERROR_EMPTY_FILE_LIST context="save_requested_but_empty_list"
            return ERROR_EMPTY_FILE_LIST
        else
            # Ensure output directory exists
            if !isdir(output_path)
                try
                    mkpath(output_path)
                    @info error_message(STATUS_SUCCESS) code=STATUS_SUCCESS context="created_output_path" output_path=output_path
                catch e
                    @error error_message(ERROR_PATH_CREATION_FAIL) error=e code=ERROR_PATH_CREATION_FAIL output_path=output_path
                    return ERROR_PATH_CREATION_FAIL
                end
            end

            # Check write permission on directory (POSIX-style)
            dir_stat = try
                stat(output_path)
            catch e
                @error error_message(ERROR_GENERIC_SAVE_FAIL) error=e code=ERROR_GENERIC_SAVE_FAIL output_path=output_path context="stat_failed"
                return ERROR_GENERIC_SAVE_FAIL
            end
            if !(dir_stat.mode & 0o222 != 0)
                @error error_message(ERROR_NO_WRITE_PERMISSIONS) code=ERROR_NO_WRITE_PERMISSIONS output_path=output_path
                return ERROR_NO_WRITE_PERMISSIONS
            end

            # Write each file using its extension; track first failure code
            for file in list_of_files
                ext = splitext(file)[2]
                full_path = joinpath(output_path, file)

                local_code = STATUS_SUCCESS
                if ext == ".txt"
                    local_code = write_txt_statistics(full_path, result)
                elseif ext == ".pdf"
                    local_code = write_pdf_statistics(full_path, result)
                else
                    @error error_message(ERROR_UNSUPPORTED_OUTPUT_TYPE) code=ERROR_UNSUPPORTED_OUTPUT_TYPE path=full_path ext=ext
                    local_code = ERROR_UNSUPPORTED_OUTPUT_TYPE
                end

                if status_code == STATUS_SUCCESS && local_code != STATUS_SUCCESS
                    status_code = local_code  # capture first failure
                end
            end
        end
    catch e
        @error error_message(ERROR_GENERIC_SAVE_FAIL) error=e code=ERROR_GENERIC_SAVE_FAIL context="save_block"
        return ERROR_GENERIC_SAVE_FAIL
    end
end
# --- Display logic (only when list_of_files was provided) ---
    if disp
        try
            print_statistics(result)
            @info error_message(STATUS_SUCCESS) code=STATUS_SUCCESS context="display_after_save_or_list"
        catch e
            @error error_message(STATUS_DISPLAY_FAIL) error=e code=STATUS_DISPLAY_FAIL context="display_after_save_or_list"
            if status_code == STATUS_SUCCESS
                status_code = STATUS_DISPLAY_FAIL
            end
        end
    end
    return status_code
end
