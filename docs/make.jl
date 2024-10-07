# docs/make.jl
using Documenter

# Include your modules
push!(LOAD_PATH, joinpath(@__DIR__, "../src"))
include("../src/LpPresolve.jl")              # Include the LpPresolve module
include("../src/LpProblem.jl")               # Include the LpProblem module
include("../src/LpReadMPS.jl")               # Include the LpReadMPS module
include("../src/LpReadLP.jl")                # Include the LpReadLP module
include("../src/LpRevisedSimplex.jl")        # Include the lpRevisedSimplex module
include("../src/LpStandardFormConverter.jl") # Include the LpStandardFormConverter module
include("../src/juLinear.jl")                # Include the juLinear module

# Build the documentation
makedocs(;
    modules=[
        LpPresolve,
        LpProblem,
        LpReadMPS,
        LpReadLP,
        LpRevisedSimplex,
        LpStandardFormConverter,
        juLinear,
    ],
    sitename="juLinear.jl documentation",
    pages=[
        "Home" => "index.md",
        "`LpPresolve`" => "LpPresolve.md",
        "`LpProblem`" => "LpProblem.md",
        "`LpReadMPS`" => "LpReadMPS.md",
        "`LpReadLP`" => "LpReadLP.md",
        "`LpRevisedSimplex`" => "LpRevisedSimplex.md",
        "`LpStandardFormConverter`" => "LpStandardFormConverter.md",
        "`juLinear`" => "juLinear.md",
    ],
    format=Documenter.HTML(),
    clean=true,
)
