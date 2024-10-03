# test_standard_form_converter.jl

using Test
using LinearAlgebra
using SparseArrays

# Include test_helpers module
push!(LOAD_PATH, abspath(@__DIR__))
using test_helpers  # Access exported functions from test_helpers

# Include lp_problem and lp_read_LP modules
push_directory_to_load_path(:src)
using lp_problem
using lp_standard_form_converter
using lp_read_LP

# List of LP files to test
const Problems = [
    # "blend.mps",
    "ex4-3.lp",
    "ex_9-7.lp",
    "problem.lp",
    # "test.mps",
    "juLinear_ex1.lp"
]

# Function to check if all constraints in an LPProblem are 'L'
function all_constraints_are_E(lp::LPProblem)
    # println(lp.constraint_types)  # Print the constraint types for debugging
    return all(c == 'E' for c in lp.constraint_types)
end

function is_min(lp::LPProblem)
    return all(obj == true for obj in lp.is_minimize)
end


@testset "standard_form_converter Tests" begin
    # Test valid Problems
    for file in Problems
        @testset "Tests for $file" begin
            # Get the full path to the LP file
            lp_file_path = get_problems_path(file)
            
            # Read the LPProblem from the LP file
            lp = read_lp(lp_file_path)

            @testset "General structure before" begin
                test_general_structure(lp)
            end

            lp_standard_form = convert_to_standard_form(lp)
            
            @testset "General structure after" begin
                test_general_structure(lp_standard_form)
            end

            @testset "Check if minimization" begin
                @test is_min(lp_standard_form)
            end
        end
    end
end
        