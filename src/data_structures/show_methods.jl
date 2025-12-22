
# Show para StatisticsData1D
function Base.show(io::IO, v::Vector1DStatistics{T}) where T
    println(io, "Vector1DStatistics{$T} with:")
    println(io, "  Statistics:")
    println(io, "    Sum: $(v.statistics_data.sum)")
    println(io, "    Mean: $(v.statistics_data.mean)")
    println(io, "    Variance: $(v.statistics_data.variance)")
    println(io, "    Standard Deviation: $(v.statistics_data.std_dev)")
    println(io, "    Minimum Value: $(v.statistics_data.min_value.value1D) at index $(v.statistics_data.min_value.index1D)")
    println(io, "    Maximum Value: $(v.statistics_data.max_value.value1D) at index $(v.statistics_data.max_value.index1D)")
    println(io, "    Range: $(v.statistics_data.range_value.min) to $(v.statistics_data.range_value.max)")
    println(io, "    Number of Elements: $(v.statistics_data.n_elements)")
    println(io, "  Axis Limits:")
    println(io, "    Min: $(v.statistics_data.axis_limits.p1min)")
    println(io, "    Max: $(v.statistics_data.axis_limits.p1max)")
    println(io, "  Resultant Vector:")
    show(io, "text/plain", v.vector_result) # Use "text/plain" for better vector printing
end

# Reimplementação das funções Base.show
function Base.show(io::IO, m::Matrix2DStatistics{T}) where T
    println(io, "Matrix2DStatistics{$T} with:")
    println(io, "  Statistics:")
    println(io, "    Sum: $(m.statistics_data.sum)")
    println(io, "    Mean: $(m.statistics_data.mean)")
    println(io, "    Variance: $(m.statistics_data.variance)")
    println(io, "    Standard Deviation: $(m.statistics_data.std_dev)")
    println(io, "    Minimum Value: $(m.statistics_data.min_value.value2D) at index $(m.statistics_data.min_value.index2D)")
    println(io, "    Maximum Value: $(m.statistics_data.max_value.value2D) at index $(m.statistics_data.max_value.index2D)")
    println(io, "    Range: $(m.statistics_data.range_value.min) to $(m.statistics_data.range_value.max)")
    println(io, "    Number of Elements: $(m.statistics_data.n_elements)")
    println(io, "    Number of Rows: $(m.statistics_data.n_rows)")
    println(io, "    Number of Columns: $(m.statistics_data.n_columns)")
    println(io, "  Axis Limits:")
    println(io, "    Min: $(m.statistics_data.axis_limits.p2min)")
    println(io, "    Max: $(m.statistics_data.axis_limits.p2max)")
    println(io, "  Resultant Matrix:")
    show(io, "text/plain", m.matrix_result) # Use "text/plain" for better matrix printing
end

function Base.show(io::IO, m::Matrix3DStatistics{T}) where T
    println(io, "Matrix3DStatistics{$T} with:")
    println(io, "  Statistics:")
    println(io, "    Sum: $(m.statistics_data.sum)")
    println(io, "    Mean: $(m.statistics_data.mean)")
    println(io, "    Variance: $(m.statistics_data.variance)")
    println(io, "    Standard Deviation: $(m.statistics_data.std_dev)")
    println(io, "    Minimum Value: $(m.statistics_data.min_value.value3D) at index $(m.statistics_data.min_value.index3D)")
    println(io, "    Maximum Value: $(m.statistics_data.max_value.value3D) at index $(m.statistics_data.max_value.index3D)")
    println(io, "    Range: $(m.statistics_data.range_value.min) to $(m.statistics_data.range_value.max)")
    println(io, "    Number of Elements: $(m.statistics_data.n_elements)")
    println(io, "    Number of Rows: $(m.statistics_data.n_rows)")
    println(io, "    Number of Columns: $(m.statistics_data.n_columns)")
    println(io, "    Number of Slices: $(m.statistics_data.n_slices)")
    println(io, "  Axis Limits:")
    println(io, "    Min: $(m.statistics_data.axis_limits.p3min)")
    println(io, "    Max: $(m.statistics_data.axis_limits.p3max)")
    println(io, "  Resultant Matrix:")
    show(io, "text/plain", m.matrix_result)  # Use "text/plain" for better matrix printing
end
#------

# Show detalhado (text/plain)
function Base.show(io::IO, ::MIME"text/plain", m::Matrix2DStatistics{T}) where T
    stats = m.statistics_data
    dims = "$(stats.n_rows)×$(stats.n_columns)"
    
    println(io, "Matrix2DStatistics{$T}")
    println(io, "═"^50)
    println(io, "📊 Estatísticas [$(stats.n_elements) elementos, $dims]:")
    println(io, "├── Tendência Central")
    println(io, "│   ├── Soma:      ", round(stats.sum, digits=4))
    println(io, "│   ├── Média:     ", round(stats.mean, digits=4))
    println(io, "│   └── Range:     ", round(stats.range_value.min, digits=4), " → ", round(stats.range_value.max, digits=4))
    println(io, "├── Dispersão")
    println(io, "│   ├── Variância: ", round(stats.variance, digits=4))
    println(io, "│   └── Desvio Pad: ", round(stats.std_dev, digits=4))
    println(io, "└── Extremos")
    println(io, "    ├── Mínimo:    ", round(stats.min_value.value2D, digits=4), " @ (", stats.min_value.index2D.x, ",", stats.min_value.index2D.y, ")")
    println(io, "    └── Máximo:    ", round(stats.max_value.value2D, digits=4), " @ (", stats.max_value.index2D.x, ",", stats.max_value.index2D.y, ")")
    
end
