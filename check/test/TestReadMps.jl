# test_read_mps.jl

using Test
using LinearAlgebra
using SparseArrays

# Include test_helpers module
push!(LOAD_PATH, abspath(@__DIR__))
using TestHelpers  # Access exported functions from test_helpers

# Include lp_problem and lp_read_LP modules
push_directory_to_load_path(:src)
using LpProblem
using LpReadMPS

# List of MPS files to test
const MPS_FILES = [
    "ex4-3.mps", "ex_9-7.mps", "problem.mps", "simple.mps", "test.mps", "blend.mps"
]

# Define expected LPProblem instances for specific MPS files
const EXPECTED_LP_PROBLEMS = Dict(
    "ex_9-7.mps" => LPProblem(
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
    "blend.mps" => LPProblem(
        false,  # false indicates a maximization problem
        [-110.0, -120.0, -130.0, -110.0, -115.0, 150.0],  # Objective coefficients
        sparse(
            [
                1.0 1.0 0.0 0.0 0.0 0.0   # VVEG <= 200
                0.0 0.0 1.0 1.0 1.0 0.0   # NVEG <= 250
                8.8 6.1 2.0 4.2 5.0 -6.0   # UHRD <= 0
                -8.8 -6.1 -2.0 -4.2 -5.0 3.0   # -LHRD <= 0 (transformed from LHRD >= 0)
                1.0 1.0 1.0 1.0 1.0 -1.0    # CONT = 0
            ],
        ),
        [200.0, 250.0, 0.0, 0.0, 0.0],  # RHS values
        ['L', 'L', 'L', 'L', 'E'],      # Corrected constraint types
        [0.0, 0.0, 0.0, 0.0, 0.0, 0.0], # Lower bounds for variables
        [Inf, Inf, Inf, Inf, Inf, Inf], # Upper bounds for variables
        ["VEG01", "VEG02", "OIL01", "OIL02", "OIL03", "PROD"],  # Corrected variable names
        [:Continuous, :Continuous, :Continuous, :Continuous, :Continuous, :Continuous],  # Variable types
    ),
    # Add more expected LPProblem instances for other MPS files as needed
)

# Main test set
@testset "MPS Reader Tests" begin
    for file in MPS_FILES
        @testset "Tests for $file" begin
            # Read the LPProblem from the MPS file
            lp = read_mps_from_file(get_problems_path(file))

            # Test the general structure using the helper function
            test_general_structure(lp)

            # If there is an expected LPProblem for this file, test specific values
            if haskey(EXPECTED_LP_PROBLEMS, file)
                @testset "Specific values" begin
                    expected = EXPECTED_LP_PROBLEMS[file]
                    test_specific_values(lp, expected)
                end
            end
        end
    end
end
