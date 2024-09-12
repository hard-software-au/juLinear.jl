module lp_solver

using LinearAlgebra
using SparseArrays
using Random
using ArgParse

# Local modules
# push!(LOAD_PATH, realpath("../code"))
push!(LOAD_PATH, ".")
using lp_constants
using lp_utils
using lp_presolve
using lp_problem
using lp_read_mps
using lp_revised_simplex
using lp_standard_form_converter

println("Hello User")


"""
    parse_commandline() -> Dict

Parses command-line arguments using the ArgParse package. It defines options such as the problem file path, method type (simplex or interior point), optimization type (minimization or maximization), and verbosity.

# Returns
- `Dict`: A dictionary of parsed arguments.

# Command-Line Arguments
- `--filename, -f`: Path to the problem file in MPS format (required).
- `--interior, -i`: Use the interior point method (LP only).
- `--min`: Minimize the objective function (default).
- `--max`: Maximize the objective function.
- `--no_presolve`: Skip the presolve step (default is false).
- `--simplex, -s`: Use the simplex method (default).
- `--verbose, -v`: Enable verbose output.
"""
function parse_commandline()
    # Initialize ArgParse settings
    s = ArgParseSettings()

    # Define the argument table
    @add_arg_table! s begin
        "--filename", "-f"
            help = "Path to the problem file (mps format)"
            default = "/Users/roryyarr/Desktop/Linear Programming/lp_code/check/problems/mps_files/ex_9-7.mps"
            arg_type = String
            required = false
        
        "--interior", "-i"
            help = "Use interior point method (LP only)"
            action = :store_true
        
        "--min"
            help = "Minimization of the objective function (default)"
            action = :store_true
            
        "--max"
            help = "Maximization of the objective function"
            action = :store_true
            
        "--no_presolve"
            help = "Do not presolve (default is false)"
            action = :store_true
        
        "--simplex", "-s"
            help = "Use simplex method (default)"
            action = :store_true
        
        "--verbose", "-v"
            help = "Verbose output"
            action = :store_true
    end

    # Parse the command-line arguments
    return parse_args(s)
end


"""
    load_lp_problem_from_mps(filename::String) -> LPProblem

Loads a linear programming (LP) problem from an MPS file. It uses the `read_mps_from_file` function to read and parse the problem into an `LPProblem` struct.

# Arguments
- `filename::String`: The path to the MPS file containing the LP problem.

# Returns
- `LPProblem`: The parsed LP problem struct.

# Example
```julia
lp = load_lp_problem_from_mps("problem.mps")
```
"""
function load_lp_problem_from_mps(filename::String)
    println("Loading LP problem from file: $filename")
    lp = read_mps_from_file(filename)  # Assuming read_mps is defined in lp_read_mps
    return lp
end

"""
    handle_lp_operations(parsed_args::Dict)

Handles the operations required to solve the LP problem based on the parsed command-line arguments. It decides which method (simplex or interior point) to use, whether to presolve, and whether to minimize or maximize the objective function.

# Arguments
- `parsed_args::Dict`: The parsed command-line arguments, including options such as the file path, optimization method, and presolve option.

# Example
```julia
handle_lp_operations(parsed_args)
```
"""
function handle_lp_operations(parsed_args)
    lp = load_lp_problem_from_mps(parsed_args["filename"])

    if parsed_args["no_presolve"]
        println("Skipping presolve step")
    else
        # Add presolve logic here if necessary
        println("Running presolve...")
    end

    if parsed_args["interior"]
        println("Using interior point method (not implemented in this example)")
        # Call interior point method logic here
    elseif parsed_args["simplex"]
        println("Using simplex method")
        solution, objective_value = revised_simplex(lp)
        println("Solution: ", solution)
        println("Objective value: ", objective_value)
    else
        println("Defaulting to simplex method")
        solution, objective_value = revised_simplex(lp)
        println("Solution: ", solution)
        println("Objective value: ", objective_value)
    end
end

"""
    main()

The main function that orchestrates the entire LP solving process. It parses command-line arguments, handles problem type (minimization or maximization), and calls the appropriate method (simplex or interior point) based on user input.

# Example
```bash
julia we_need_a_name.jl --filename "../check/problems/mps_files/ex_9-7.mps" --min --simplex --no_presolve --verbose
```
"""
function main()
    parsed_args = parse_commandline()

    # Handle the problem type and whether to minimize or maximize
    if parsed_args["max"]
        println("Maximization selected")
    elseif parsed_args["min"]
        println("Minimization selected")
    else
        println("Defaulting to minimization")
    end

    # Handle LP operations
    handle_lp_operations(parsed_args)
end

# Run the main function
main()

end # module lp_solver
