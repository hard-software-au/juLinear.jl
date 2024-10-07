module juLinear

using LinearAlgebra
using SparseArrays
using Random
using ArgParse

# Local modules
push!(LOAD_PATH, ".")
using lp_constants
using lp_utils
using lp_presolve
using lp_problem
using lp_read_LP  # Updated to use read_lp from this module
using lp_read_mps
using lp_revised_simplex
using lp_standard_form_converter

"""
    parse_commandline() -> Dict

Parses command-line arguments using the ArgParse package. It defines options such as the problem file path, method type (simplex or interior point), and verbosity.

# Returns
- `Dict`: A dictionary of parsed arguments.

# Command-Line Arguments
- `--filename, -f`: Path to the problem file in LP format (required).
- `--interior, -i`: Use the interior point method (LP only).
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
        help = "Path to the problem file (LP or MPS format)"
        default = "/Users/roryyarr/Desktop/Linear Programming/lp_code/check/problems/mps_files/ex_9-7.mps"
        arg_type = String
        required = false

        "--interior", "-i"
        help = "Use interior point method (LP only)"
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
    load_lp_problem_from_lp(filename::String) -> LPProblem

Loads a linear programming (LP) problem from an LP file using the `read_lp` function.

# Arguments
- `filename::String`: The path to the LP file containing the problem.

# Returns
- `LPProblem`: The parsed LP problem struct.

# Example
lp = load_lp_problem_from_lp("problem.lp")
"""
function load_lp_problem(filename::String)
    println("Loading LP problem from file: $filename")

    # Determine file extension and call the appropriate reader
    if endswith(filename, ".lp")
        lp = read_lp(filename)  # Assuming read_lp is defined in lp_read_LP
    elseif endswith(filename, ".mps")
        lp = read_mps(filename)  # Assuming read_mps_from_file is defined in lp_read_mps
    else
        error("Unsupported file format. Please provide a .lp or .mps file.")
    end

    return lp
end

"""
    handle_lp_operations(parsed_args::Dict)

Handles the operations required to solve the LP problem based on the parsed command-line arguments. It decides which method (simplex or interior point) to use, and whether to presolve.

# Arguments
- `parsed_args::Dict`: The parsed command-line arguments, including options such as the file path, optimization method, and presolve option.

# Example
handle_lp_operations(parsed_args)
"""
function handle_lp_operations(parsed_args)
    lp = load_lp_problem(parsed_args["filename"])

    if parsed_args["no_presolve"]
        println("Skipping presolve step")
        preprocessed_problem = PreprocessedLPProblem(
            lp, lp, [], [], Dict(), Dict(), [], [], false
        )
    else
        println("Running presolve...")
        preprocessed_problem = presolve_lp(lp; verbose=parsed_args["verbose"])
    end

    if parsed_args["interior"]
        println("Using interior point method (not implemented in this example)")
        # Call interior point method logic here
    elseif parsed_args["simplex"]
        println("Using simplex method")
        solution, objective_value = revised_simplex(
            preprocessed_problem; verbose=parsed_args["verbose"]
        )
        println("Solution: ", solution)
        println("Objective value: ", objective_value)
    else
        println("Defaulting to simplex method")
        solution, objective_value = revised_simplex(
            preprocessed_problem; verbose=parsed_args["verbose"]
        )
        println("Solution: ", solution)
        println("Objective value: ", objective_value)
    end
end

"""
    main()

The main function that orchestrates the entire LP solving process. It parses command-line arguments and calls the appropriate method (simplex or interior point) based on user input.

# Example
```bash
julia juLinear.jl --filename "../check/problems/lp_files/ex_9-7.lp" --simplex --no_presolve --verbose
```
"""
function main()
    parsed_args = parse_commandline()

    # Handle LP operations
    return handle_lp_operations(parsed_args)
end

# Run the main function
main()

end # module juLinear
