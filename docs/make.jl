using AstroTLPlot
using Documenter

DocMeta.setdocmeta!(AstroTLPlot, :DocTestSetup, :(using AstroTLPlot); recursive=true)

makedocs(;
    modules=[AstroTLPlot],
    authors="tomasclima <tomaslima.eduga@gmail.com> and contributors",
    sitename="AstroTLPlot.jl",
    format=Documenter.HTML(;
        canonical="https://tomalima.github.io/AstroTLPlot.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/tomalima/AstroTLPlot.jl",
    devbranch="main",
)
