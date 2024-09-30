# # Add the path to your src/ directory to the LOAD_PATH
# push!(LOAD_PATH, joinpath(@__DIR__, "../../src"))


using Test
using lp_problem
using lp_read_mps
using test_framework  # Load the base directory

# List of MPS file paths you want to test, using relative paths
mps_files = [
    get_full_path("problems/mps_files/ex4-3.mps"),
    get_full_path("problems/mps_files/ex_9-7.mps"),
    get_full_path("problems/mps_files/problem.mps"),
    get_full_path("problems/mps_files/simple.mps"),
    get_full_path("problems/mps_files/test.mps"),
    get_full_path("problems/mps_files/blend.mps")
    # Add more MPS files here
]

# Top-level test set for all MPS files
@testset "MPS Reader Tests" begin
    for file_path in mps_files
        # Testset for each individual file
        @testset "Tests for $(basename(file_path))" begin
            lp = read_mps_from_file(file_path)  # Load MPS file
            
            # General structure tests
            @testset "General structure tests for $(basename(file_path))" begin
                @test length(lp.c) > 0  # Check if c vector is not empty
                @test size(lp.A, 1) > 0  # Check if A matrix has rows
                @test size(lp.A, 2) > 0  # Check if A matrix has columns
                @test length(lp.b) > 0  # Check if b vector is not empty
                @test length(lp.vars) > 0  # Check if vars vector is not empty
                @test length(lp.constraint_types) > 0  # Check if constraint_types vector is not empty
            end
            
            # Specific tests for individual files
            @testset "Specific tests for $(basename(file_path))" begin
                if basename(file_path) == "ex4-3.mps"
                    @test lp.is_minimize == true  # Expected for ex4-3.mps
                elseif basename(file_path) == "blend.mps"
                    @test lp.is_minimize == false  # Expected for blend.mps
                end
            end
        end
    end
end

