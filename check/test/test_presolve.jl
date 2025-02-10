########################################################################################################################
########################################            test_presolve.jl            ########################################
########################################################################################################################

# include test utilities
include("test_helpers.jl")


# List of LP files to test
const LP_FILES = [
    "ex4-3.lp",
    "ex_9-7.lp",
    "problem.lp",
    # "test.lp",
    "juLinear_ex1.lp",
]

# List of functions to apply
const PRESOLVE_FUNCTIONS = [
    # lp_remove_zero_rows,
    # lp_detect_and_remove_fixed_variables,
    # lp_remove_row_singletons,
    # lp_remove_linearly_dependent_rows,
    # lp_remove_zero_columns,
    presolve_lp,
]

# run tests on presolve routine
@testset "LpPresolve Tests" begin
    for file in LP_FILES
        lp_file_path = get_problems_path(file)
        lp = read_lp(lp_file_path)

        @testset "Testing file: $file" begin
            # Initial general structure test
            @testset "Initial structure" begin
                test_general_structure(lp)
            end

            # Apply each function and test after each
            for func in PRESOLVE_FUNCTIONS
                func(lp)
                @testset "After $(func)" begin
                    test_general_structure(lp)
                end
            end
        end
    end
end
        