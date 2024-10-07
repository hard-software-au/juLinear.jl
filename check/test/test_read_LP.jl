# test_read_LP.jl

using Test
using LinearAlgebra
using SparseArrays

# Include test_helpers module
push!(LOAD_PATH, abspath(@__DIR__))
using test_helpers  # Access exported functions from test_helpers

# Include lp_problem and lp_read_LP modules
push_directory_to_load_path(:src)
using lp_problem
using lp_read_LP

# List of LP files to test
const LP_FILES = [
    "ex4-3.lp",
    "ex_9-7.lp",
    "problem.lp",
    # "test.lp",
    "juLinear_ex1.lp",
]

const CORRUPT_LP_FILES = ["test.lp"]

# Define expected LPProblem instances for specific LP files
const EXPECTED_LP_PROBLEMS = Dict(
    "ex_9-7.lp" => LPProblem(
        false,  # false indicates a maximization problem
        [4.0, 3.0, 1.0, 7.0, 6.0],  # Objective coefficients: [X1, X2, X3, X4, X5]
        sparse([
            1.0 2.0 3.0 1.0 -3.0  # ROW1 coefficients for [X1, X2, X3, X4, X5]
            2.0 -1.0 2.0 2.0 1.0  # ROW2 coefficients
            -3.0 2.0 1.0 -1.0 2.0   # ROW3 coefficients
        ]),
        [9.0, 10.0, 11.0],  # RHS values for [ROW1, ROW2, ROW3]
        ['L', 'L', 'L'],     # Constraint types: all are 'Less than or equal to'
        [0.0, 0.0, 0.0, 0.0, 0.0],  # Lower bounds for [X1, X2, X3, X4, X5]
        [Inf, Inf, Inf, Inf, Inf],  # Upper bounds for [X1, X2, X3, X4, X5]
        ["X1", "X2", "X3", "X4", "X5"],  # Variable names
        [:Continuous, :Continuous, :Continuous, :Continuous, :Continuous],  # Variable types
    ),
    # Add more expected LPProblem instances for other LP files as needed
)

# Main test set
@testset "LP Reader Tests" begin
    # Test valid LP files
    for file in LP_FILES
        @testset "Tests for $file" begin
            # Get the full path to the LP file
            lp_file_path = get_problems_path(file)

            # Read the LPProblem from the LP file
            lp = read_lp(lp_file_path)

            @testset "General structure" begin
                test_general_structure(lp)
            end

            if haskey(EXPECTED_LP_PROBLEMS, file)
                @testset "Specific values" begin
                    expected_lp = EXPECTED_LP_PROBLEMS[file]
                    test_specific_values(lp, expected_lp)
                end
            end
        end
    end

    # Test corrupt LP files
    for file in CORRUPT_LP_FILES
        @testset "Corrupt LP File: $file" begin
            corrupt_file_path = get_problems_path(file)

            # Attempt to read the corrupt LP file and expect an ArgumentError
            @test_throws ArgumentError read_lp(corrupt_file_path)
        end
    end
end
