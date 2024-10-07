module test_mps

using Test

# push!(LOAD_PATH, realpath("../../src/code"))
# push!(LOAD_PATH, realpath("src/code"))
push!(LOAD_PATH, realpath(joinpath(@__DIR__, "../../src/code")))

#using lp_read_mps
using lp_read_mps: read_file_to_string, read_mps_from_string_mip, read_mps_with_JuMP_MIP

export test_mps_parsing_consistency

function test_mps_parsing_consistency(
    mps_file::String;
    check_is_minimize::Bool=true,
    check_objective_coeffs::Bool=true,
    check_constraint_matrix::Bool=true,
    check_rhs_values::Bool=true,
    check_lower_bounds::Bool=true,
    check_upper_bounds::Bool=true,
    check_variable_names::Bool=true,
    check_constraint_types::Bool=true,
    check_variable_types::Bool=true,
)
    @testset "Test consistency between MPS parsing functions with $mps_file" begin

        # Read the MPS file content as a string
        mps_string = read_file_to_string(mps_file)

        # Parse the MPS string using both functions
        lp_mip_1 = read_mps_from_string_mip(mps_string)
        lp_mip_2 = read_mps_with_JuMP_MIP(mps_file)

        # Conditional checks based on the arguments
        if check_is_minimize
            println("Testing is_minimize...")
            @test lp_mip_1.is_minimize == lp_mip_2.is_minimize ||
                println("is_minimize check failed")
        end

        if check_objective_coeffs
            println("Testing objective coefficients...")
            @test lp_mip_1.c == lp_mip_2.c || println("Objective coefficients check failed")
        end

        if check_constraint_matrix
            println("Testing constraint matrix...")
            @test lp_mip_1.A == lp_mip_2.A || println("Constraint matrix check failed")
        end

        if check_rhs_values
            println("Testing RHS values...")
            @test lp_mip_1.b == lp_mip_2.b || println("RHS values check failed")
        end

        if check_lower_bounds
            println("Testing lower bounds...")
            @test lp_mip_1.l == lp_mip_2.l || println("Lower bounds check failed")
        end

        if check_upper_bounds
            println("Testing upper bounds...")
            @test lp_mip_1.u == lp_mip_2.u || println("Upper bounds check failed")
        end

        if check_variable_names
            println("Testing variable names...")
            @test lp_mip_1.vars == lp_mip_2.vars || println("Variable names check failed")
        end

        if check_constraint_types
            println("Testing constraint types...")
            @test lp_mip_1.constraint_types == lp_mip_2.constraint_types ||
                println("Constraint types check failed")
        end

        # if check_variable_types
        #     println("Testing variable types...")
        #     @test lp_mip_1.variable_types == lp_mip_2.variable_types || println("Variable types check failed")
        # end

    end
end

end #mps_with_JuMP module
