using Test

# Include the modules with the correct paths
include("../lp_julia/read_mps.jl")
using .MPSReader

include("../lp_julia/lp_problem.jl")
using .lpProblem

@testset "MPSReader" begin
    # Test read_mps_from_file function
    file_path = "benchmarks/mps_files/ex4-3.mps"
    lp = read_mps_from_file(file_path)
    
    @test lp.is_minimize == true  # Replace with expected value
    @test length(lp.c) > 0  # Check if c vector is not empty
    @test size(lp.A, 1) > 0  # Check if A matrix has rows
    @test size(lp.A, 2) > 0  # Check if A matrix has columns
    @test length(lp.b) > 0  # Check if b vector is not empty
    @test length(lp.vars) > 0  # Check if vars vector is not empty
    @test length(lp.constraint_types) > 0  # Check if constraint_types vector is not empty
    
    # Additional specific tests based on the expected content of the MPS file
    # For example:
    # @test lp.c == [expected coefficients]
    # @test lp.b == [expected RHS values]
    # @test lp.vars == ["x1", "x2", ...]  # Replace with expected variable names
    # @test lp.constraint_types == ['=', '≤', ...]  # Replace with expected constraint types
end


