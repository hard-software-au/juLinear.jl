# test_lp_read_LP.jl

using Test
using LinearAlgebra

# Add the source folder to the load path
push!(LOAD_PATH, abspath(@__DIR__, "..", "..", "src"))
using lp_problem
using lp_read_mps

# Constants
const TEST_DIR = @__DIR__
const PROBLEMS_DIR = joinpath(TEST_DIR, "..", "..", "check", "problems", "lp_files")

# Helper function to get full path of an MPS file
get_full_path(filename::String) = abspath(joinpath(PROBLEMS_DIR, filename))

# List of MPS files to test
const MPS_FILES = [
    "ex4-3.lp",
    "ex_9-7.lp",
    "problem.lp",
   # "simple.mps",
    "test.lp",
    "juLinear.lp"
]

# Struct to hold expected values for specific problems
struct ExpectedValues
    c::Vector{Float64}
    A::Matrix{Float64}
    b::Vector{Float64}
    is_minimize::Bool
    l::Vector{Float64}
    u::Vector{Float64}
end

# Define expected values for specific problems
const EXPECTED_VALUES = Dict(
    "ex_9-7.mps" => ExpectedValues(
        [4.0, 3.0, 1.0, 7.0, 6.0],
        [
            1.0  2.0  3.0  1.0 -3.0;
            2.0 -1.0  2.0  2.0  1.0;
            -3.0 2.0  1.0 -1.0  2.0
        ],
        [9.0, 10.0, 11.0],
        false,
        [0.0, 0.0, 0.0, 0.0, 0.0],
        [Inf, Inf, Inf, Inf, Inf]
    ),
    # "blend.mps" => ExpectedValues(
    #     [-110.0, -120.0, -130.0, -110.0, -115.0, 150.0],
    #     [
    #         1.0   1.0   0.0   0.0   0.0   0.0;
    #         0.0   0.0   1.0   1.0   1.0   0.0;
    #         8.8   6.1   2.0   4.2   5.0  -6.0;
    #         -8.8  -6.1  -2.0  -4.2  -5.0   3.0;
    #         1.0   1.0   1.0   1.0   1.0  -1.0
    #     ],
    #     [200.0, 250.0, 0.0, 0.0, 0.0],
    #     false,
    #     [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    #     [Inf, Inf, Inf, Inf, Inf, Inf]
    # )
)

# Helper functions for tests
function test_general_structure(lp::lp_problem.LPProblem)
    @test !isempty(lp.c)
    @test size(lp.A, 1) > 0
    @test size(lp.A, 2) > 0
    @test !isempty(lp.b)
    @test !isempty(lp.vars)
    @test !isempty(lp.constraint_types)
end

function test_specific_values(lp::lp_problem.LPProblem, expected::ExpectedValues)
    @test lp.c ≈ expected.c
    @test Matrix(lp.A) ≈ expected.A
    @test lp.b ≈ expected.b
    @test lp.is_minimize == expected.is_minimize
    @test lp.l ≈ expected.l
    @test lp.u ≈ expected.u
end

# Main test set
@testset "MPS Reader Tests" begin
    for file in MPS_FILES
        @testset "Tests for $file" begin
            lp = read_mps_from_file(get_full_path(file))
            
            @testset "General structure" begin
                test_general_structure(lp)
            end
            
            if haskey(EXPECTED_VALUES, file)
                @testset "Specific values" begin
                    test_specific_values(lp, EXPECTED_VALUES[file])
                end
            end
            
            # Additional specific tests
            if file == "ex4-3.mps"
                @test lp.is_minimize == true
            # elseif file == "blend.mps"
            #     @test lp.is_minimize == false
            end
        end
    end
end
