# docs/make.jl
using Documenter

# Include your modules
push!(LOAD_PATH, joinpath(@__DIR__, "../src"))
include("../src/lp_presolve.jl")                # Include the lp_presolve module
include("../src/lp_problem.jl")                 # Include the lp_problem module
include("../src/lp_read_mps.jl")                # Include the lp_read_mps module
include("../src/lp_revised_simplex.jl")         # Include the lp_revised_simplex module
include("../src/lp_standard_form_converter.jl") # Include the lp_standard_form_converter module
include("../src/we_need_a_name.jl")                  # Include the lp_solver module

# Build the documentation
makedocs(
    modules = [
        lp_presolve,
        lp_problem,
        lp_read_mps,
        lp_revised_simplex,
        lp_standard_form_converter,
        lp_solver
    ],
    sitename = "Julia lp_code documentation",
    pages = [
        "Home" => "index.md",
        "`lp_presolve`" => "lp_presolve.md",
        "`lp_problem`" => "lp_problem.md",
        "`lp_read_mps`" => "lp_read_mps.md",
        "`lp_revised_simplex`" => "lp_revised_simplex.md",
        "`lp_standard_form_converter`" => "lp_standard_form_converter.md",
        "`lp_solver`" => "lp_solver.md"
    ],
    format = Documenter.HTML(),
    clean = true
   )

