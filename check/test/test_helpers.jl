# test_helpers.jl

module test_helpers

    using Test  # Import the Test module for @test macros
    using LinearAlgebra
    using SparseArrays

    # Add the source folder to the load path
    push!(LOAD_PATH, abspath(@__DIR__, "..", "..", "src"))
    using lp_problem  # Ensure lp_problem is accessible

    # Export functions
    export test_general_structure, test_specific_values, get_problems_path, get_src_path, push_directory_to_load_path


    # Function to get the base directory (lp_code)
    function get_base_dir()
        dir = abspath(@__DIR__)
        while basename(dir) != "lp_code"
            parent_dir = dirname(dir)
            if parent_dir == dir
                error("Could not locate the base directory for the lp_code/ repository.")
            end
            dir = parent_dir
        end
        return dir
    end

    BASE_DIR =get_base_dir()

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
    :tools => abspath(joinpath(BASE_DIR, "tools"))
)

    # Function to get a directory path without changing the current working directory
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

    # Function to push the directory to LOAD_PATH
    function push_directory_to_load_path(level::Symbol)
        dir = get_directory(level)
        if dir ∉ LOAD_PATH
            push!(LOAD_PATH, dir)
            println("Pushed directory $dir to LOAD_PATH.")
        else
            println("Directory $dir is already in LOAD_PATH.")
        end
    end

    # Returns the problem path
    function get_problems_path(filename::String; dirs=["lp_files", "mps_files"])
        for dir in dirs
            path = abspath(joinpath(PATHS[:problems], dir, filename))
            if isfile(path)
                return path
            end
        end
        # error("File $filename not found in specified directories: $(join(dirs, \", \")).")
    end


    # Checks the structure and consistency of the LPProblem
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

    # Checks specific values of the LPProblem against expected values
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

end # module test_helpers
