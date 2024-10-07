# Modules are loaded here.
push!(LOAD_PATH, abspath(@__DIR__))
using TestHelpers
using TestFramework

# All unit tests should be placed in this array.
tests = ["ReadLP", "ReadMPS", 
        "StandardFormConverter", "Presolve",
        "juLinear"]

# The test are run here.
run_tests(tests)
