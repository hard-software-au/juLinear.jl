########################################################################################################################
########################################            run_all_tests.jl            ########################################
########################################################################################################################

# Load the TestFramework module
push!(LOAD_PATH, abspath(@__DIR__))
using TestFramework

# All unit tests should be placed in this array.
tests = ["read_mps", "read_lp", 
        "standard_form_converter", "presolve",
        "juLinear"]

# Run unit tests/
run_tests(tests)
