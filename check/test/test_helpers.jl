# test_helpers.jl

using Test  # Import the Test module for @test macros
using LinearAlgebra
using SparseArrays

# include LPPoblem
include(joinpath(@__DIR__, "..", "..", "src", "problems", "lp_problem.jl"))

# Export functions
export get_src_path, push_directory_to_load_path
export get_problems_path, get_lp_problem
export test_general_structure, test_specific_values


################################################################################
## Base Directory and Structure
################################################################################


"""
    get_base_dir()

Finds and returns the absolute path of the base directory (`juLinear`) for the repository. 
This function traverses the directory tree upward from the current directory (`@__DIR__`) 
until it locates the `juLinear` base directory. If it fails to find the base directory, 
it raises an error.

# Returns
- `String`: The absolute path of the `juLinear` directory.

# Raises
- `Error`: If the `lp_code` base directory cannot be located.

# Example
```julia
base_dir = get_base_dir()
```
This returns the absolute path to the `juLinear` base directory.
"""
function get_base_dir()
    dir = abspath(@__DIR__)
    while basename(dir) != "lp_code"
        parent_dir = dirname(dir)
        if parent_dir == dir
            error("Could not locate the base directory for the juLinear/ repository.")
        end
        dir = parent_dir
    end
    return dir
end

BASE_DIR = get_base_dir()

"""
    PATHS::Dict{Symbol, String}

A dictionary that contains the absolute paths of various important directories within 
the `juLinear` repository, relative to the base directory (`juLinear``). 

# Structure
- `:base`: Base directory (`juLinear`).
- `:check`: Directory for checks and validations (`juLinear/check`).
- `:test`: Test directory (`juLinear/check/test`).
- `:problems`: Problems directory (`juLinear/check/problems`).
- `:problems_lp`: LP files directory (`juLinear/check/problems/lp_files`).
- `:problems_mps`: MPS files directory (`juLinear/check/problems/mps_files`).
- `:src`: Source code directory (`juLinear/src`).
- `:docs`: Documentation directory (`juLinear/docs`).
- `:nb`: Notebooks directory (`juLinear/nb`).
- `:res`: Resources directory (`juLinear/res`).
- `:tools`: Tools directory (`juLinear/tools`).

This dictionary is used throughout the project to access these common paths easily.

# Example
    println(PATHS[:base])

This prints the absolute path to the `juLinear` base directory.
"""
const PATHS = Dict(
    :base => BASE_DIR,
    :check => abspath(joinpath(BASE_DIR, "check")),
    :test => abspath(joinpath(BASE_DIR, "check", "test")),
    :problems => abspath(joinpath(BASE_DIR, "check", "problems")),
    :problems_lp => abspath(joinpath(BASE_DIR, "check", "problems", "lp_files")),
    :problems_mps => abspath(joinpath(BASE_DIR, "check", "problems", "mps_files")),
    :src => abspath(joinpath(BASE_DIR, "src")),
    :docs => abspath(joinpath(BASE_DIR, "docs")),
    :nb => abspath(joinpath(BASE_DIR, "nb")),
    :res => abspath(joinpath(BASE_DIR, "res")),
    :tools => abspath(joinpath(BASE_DIR, "tools")),
)
################################################################################
## Directory Functions
################################################################################

"""
    get_directory(level::Symbol)

Returns the absolute path of the specified directory level from the `PATHS` dictionary. 
This function retrieves the directory path without changing the current working directory.

# Arguments
- `level::Symbol`: A symbol representing the directory level (e.g., `:base`, `:src`). 
  The symbol must be a key in the `PATHS` dictionary.

# Returns
- `String`: The absolute path of the specified directory.

# Raises
- `Error`: If the directory level does not exist in `PATHS` or the directory path does not exist on the filesystem.

# Example
    src_dir = get_directory(:src)

This retrieves the absolute path of the source code directory (`juLinear/src`).
"""
function get_directory(level::Symbol)
    if haskey(PATHS, level)
        target_dir = PATHS[level]
        if isdir(target_dir)
            return target_dir
        else
            error("Directory $target_dir does not exist.")
        end
    else
        # error("Invalid level: $level. Available levels are: $(join(collect(keys(PATHS)), \", \")).")
    end
end

"""
    push_directory_to_load_path(level::Symbol)

Adds the specified directory level's path to the `LOAD_PATH` if it's not already present. 
This function allows modules located in the directory to be loaded without changing 
the current working directory.

# Arguments
- `level::Symbol`: A symbol representing the directory level (e.g., `:src`, `:tools`). 
  The symbol must be a key in the `PATHS` dictionary.

# Returns
- `Nothing`

# Example
    push_directory_to_load_path(:src)

This adds the source code directory (`juLinear/src`) to the `LOAD_PATH` if it's not already there.
"""
function push_directory_to_load_path(level::Symbol)
    dir = get_directory(level)
    if dir ∉ LOAD_PATH
        push!(LOAD_PATH, dir)
        println("Pushed directory $dir to LOAD_PATH.")
    else
        println("Directory $dir is already in LOAD_PATH.")
    end
end

"""
    get_problems_path(filename::String; dirs=["lp_files", "mps_files"])

Searches for a problem file in the specified directories within the `roblems` directory. 
If the file is found, it returns its absolute path; otherwise, the function returns nothing.

# Arguments
- `filename::String`: The name of the problem file to search for (e.g., `"test.mps"`).
- `dirs::Vector{String}` (optional): A list of directories to search within the `problems` directory. 
    Defaults to `["lp_files", "mps_files"]`.

# Returns
- `String`: The absolute path of the problem file if found.

# Example
    problem_path = get_problems_path("test.mps")

This retrieves the absolute path of the `test.mps` file located in one of the subdirectories of the `problems` directory.
"""
function get_problems_path(filename::String; dirs=["lp_files", "mps_files"])
    for dir in dirs
        path = abspath(joinpath(PATHS[:problems], dir, filename))
        if isfile(path)
            return path
        end
    end
    # error("File $filename not found in specified directories: $(join(dirs, \", \")).")
end


################################################################################
## Reading problems
################################################################################

"""
    get_lp_problem(filename::String; dirs=["lp_files", "mps_files"])

Reads and returns a linear programming (LP) problem from a file. The function supports reading files in `.mps` and `.lp` formats using appropriate readers. It searches for the file in the specified directories and returns an instance of `LPProblem`.

# Arguments
- `filename::String`: The name of the file containing the LP problem. This can be either an `.mps` or `.lp` file.
- `dirs::Vector{String}` (optional): A list of directories to search for the file. Defaults to `["lp_files", "mps_files"]`.

# Returns
- An instance of `LPProblem` containing the LP problem data read from the file.

# Raises
- `Error`: If the file is not found in the specified directories or if the file extension is not supported.

# Example
```julia
lp = get_lp_problem("test.mps")
```
This reads the LP problem from test.mps located in one of the specified directories and returns it as an LPProblem instance. 
"""
function get_lp_problem(filename::String; dirs=["lp_files", "mps_files"])
    # Get the file path using the provided template function
    path = get_problems_path(filename; dirs=dirs)
    
    # Check the file extension to determine the appropriate reading method
    ext = splitext(path)[end]
    if ext == ".mps"
        return read_mps(path)
    elseif ext == ".lp"
        return read_lp(path)
    else
        error("Unsupported file extension: $ext. Only '.mps' and '.lp' files are supported.")
    end
end


################################################################################
## LPProblem Structure Tests
################################################################################

"""
    test_general_structure(lp::LPProblem)

Performs a series of tests to check the structure and consistency of an `LPProblem` instance. 
These tests validate that the fields in the `LPProblem` are well-formed and consistent with 
each other, ensuring that the problem definition is correct.

# Arguments
- `lp::LPProblem`: An instance of `LPProblem` to be tested.

# Tests Conducted
- Validates that `is_minimize` is a Boolean value.
- Verifies that the objective function coefficients (`c`) are non-empty.
- Checks that the constraint matrix (`A`) has valid dimensions.
- Ensures that the right-hand side (`b`) is non-empty.
- Confirms that `constraint_types` is non-empty.
- Validates that the lower (`l`) and upper (`u`) bounds are non-empty.
- Checks that the variables (`vars`) and variable types (`variable_types`) are non-empty.
- Verifies size consistency between `c`, `vars`, `A`, `b`, `constraint_types`, `l`, `u`, and `variable_types`.
- Ensures that each entry in `variable_types` is a recognized symbol from a set of valid types.
- Optionally verifies that variable names are unique.

# Returns
- `Nothing`: This function runs tests and will raise errors if any tests fail.

# Example
    test_general_structure(lp)

This tests the structure and consistency of the `lp` problem instance.
"""
function test_general_structure(lp::LPProblem)
    @testset "LPProblem Structure Tests" begin
        # Verify 'is_minimize' is a Boolean
        @test (typeof(lp.is_minimize) == Bool)

        # Verify 'c' is non-empty
        @test (!isempty(lp.c))

        # Verify 'A' has valid dimensions
        @test (size(lp.A, 1) > 0)
        @test (size(lp.A, 2) > 0)

        # Verify 'b' is non-empty
        @test (!isempty(lp.b))

        # Verify 'constraint_types' is non-empty
        @test (!isempty(lp.constraint_types))

        # Verify 'l' and 'u' are non-empty
        @test (!isempty(lp.l))
        @test (!isempty(lp.u))

        # Verify 'vars' is non-empty
        @test (!isempty(lp.vars))

        # Verify 'variable_types' is non-empty
        @test (!isempty(lp.variable_types))

        # === Size Consistency Checks ===

        # 1. Length of 'c' matches number of variables
        @test (length(lp.c) == length(lp.vars))

        # 2. Number of columns in 'A' matches length of 'c'
        @test (size(lp.A, 2) == length(lp.c))

        # 3. Length of 'l' and 'u' matches number of variables
        @test (length(lp.l) == length(lp.c))
        @test (length(lp.u) == length(lp.c))

        # 4. Number of rows in 'A' matches length of 'b' and 'constraint_types'
        @test (size(lp.A, 1) == length(lp.b))
        @test (size(lp.A, 1) == length(lp.constraint_types))

        # 5. Length of 'variable_types' matches number of variables
        @test (length(lp.variable_types) == length(lp.vars))

        # 6. Validate each entry in 'variable_types' is a recognized symbol
        valid_types = Set([:Continuous, :Integer, :Binary, :SemiContinuous, :SemiInteger])
        for (i, var_type) in enumerate(lp.variable_types)
            @test (var_type ∈ valid_types)
        end

        # Optional: Check for unique variable names
        @test (length(lp.vars) == length(unique(lp.vars)))
    end
end

"""
    test_specific_values(lp::LPProblem, expected::LPProblem)

Compares specific values of the fields in an `LPProblem` instance with expected values from another instance. 
This function checks if two `LPProblem` instances are identical in terms of their fields and values.

# Arguments
- `lp::LPProblem`: The `LPProblem` instance being tested.
- `expected::LPProblem`: The `LPProblem` instance containing the expected values.

# Tests Conducted
- Compares `is_minimize` values.
- Compares the objective function coefficients (`c`).
- Compares the constraint matrix (`A`).
- Compares the right-hand side (`b`).
- Compares the constraint types (`constraint_types`).
- Compares the lower (`l`) and upper (`u`) bounds.
- Compares the variable names (`vars`).
- Compares the variable types (`variable_types`).

# Returns
- `Nothing`: This function runs tests and will raise errors if any tests fail.

# Example
    test_specific_values(lp, expected_lp)

This tests whether the fields in the `lp` problem instance match the expected values in `expected_lp`.
"""
function test_specific_values(lp::LPProblem, expected::LPProblem)
    @testset "LPProblem Specific Values Tests" begin
        @test (lp.is_minimize == expected.is_minimize)
        @test (lp.c == expected.c)
        @test (Matrix(lp.A) == Matrix(expected.A))
        @test (lp.b == expected.b)
        @test (lp.constraint_types == expected.constraint_types)
        @test (lp.l == expected.l)
        @test (lp.u == expected.u)
        @test (lp.vars == expected.vars)
        @test (lp.variable_types == expected.variable_types)
    end
end
