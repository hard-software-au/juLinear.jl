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

            # Specific tests for the APPLIED_INTEGER_PROGRAMMING_9_7 problem
            if basename(file_path) == "ex_9-7.mps"
                # Check the objective function coefficients
                @test lp.c == [4.0, 3.0, 1.0, 7.0, 6.0]  # Expected objective function

                # Convert the sparse matrix A to a dense matrix for comparison
                expected_A = [
                    1.0  2.0  3.0  1.0 -3.0;  # ROW1
                    2.0 -1.0  2.0  2.0  1.0;  # ROW2
                    -3.0 2.0  1.0 -1.0  2.0   # ROW3
                ]

                @test Matrix(lp.A) == expected_A  # Compare the dense matrices
                
                # Check the RHS (b)
                @test lp.b == [9.0, 10.0, 11.0]  # Expected RHS values

                # Check the objective sense
                @test lp.is_minimize == false  # Objective is MAX, so not minimize

                # Check the lower bounds (l)
                @test lp.l == [0.0, 0.0, 0.0, 0.0, 0.0]  # Lower bounds are all 0

                # Check the upper bounds (u)
                @test lp.u == [Inf, Inf, Inf, Inf, Inf]  # No upper bounds, so all are ∞
            end

            # Specific tests for the BLEND problem
            if basename(file_path) == "blend.mps"
                # Check the objective function coefficients
                @test lp.c == [-110.0, -120.0, -130.0, -110.0, -115.0, 150.0]  # Expected objective function

                # Expected constraint matrix (A)
                expected_A = [
                    # VEG01, VEG02, OIL01, OIL02, OIL03, PROD
                    1.0   1.0   0.0   0.0   0.0   0.0;   # VVEG
                    0.0   0.0   1.0   1.0   1.0   0.0;   # NVEG
                    8.8   6.1   2.0   4.2   5.0  -6.0;   # UHRD
                    -8.8   -6.1   -2.0   -4.2   -5.0  3.0;   # LHRD
                    1.0   1.0   1.0   1.0   1.0  -1.0    # CONT
                ]
                # Compare the dense matrices directly
                @test Matrix(lp.A) == expected_A  # Direct comparison with 2D array

                # Check the RHS (b)
                @test lp.b == [200.0, 250.0, 0.0, 0.0, 0.0]  # Expected RHS values

                # Check the objective sense
                @test lp.is_minimize == false  # Objective is MAX, so not minimize

                # Check the lower bounds (l)
                @test lp.l == [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]  # Lower bounds for variables

                # Check the upper bounds (u)
                @test lp.u == [Inf, Inf, Inf, Inf, Inf, Inf]  # No upper bounds, so all are ∞
            end
        end
    end
end
