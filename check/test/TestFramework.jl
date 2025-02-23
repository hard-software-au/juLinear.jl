########################################################################################################################
######################################            TestFramework module            ######################################
########################################################################################################################

module TestFramework

# Include test utilities
include("test_helpers.jl")

# Export functions and constants so they can be used outside the module
export run_tests, create_module_tests


#####################################################################################
## Running Unit Tests
#####################################################################################

"""
    run_tests(test_methods::Vector{String}; verbose::Bool=false)

Run all unit tests in the specified test modules.

# Arguments
- `test_methods::Vector{String}`: A list of method block names (as strings) to test.
- `verbose::Bool`: If `true`, returns detailed test results.

# Example
```julia
run_tests(["MethodA", "MethodB", "MethodC"]; verbose=true)
"""
function run_tests(test_methods::Vector{String}; verbose::Bool=false)
    results = @testset "All Tests" begin
        for method_name in test_methods
            file_path = "test_$(method_name).jl"
            include(file_path)
        end
    end
    if verbose
        println()
        println("~ "^40)
        println("Verbose:")
        println("~ "^40)
        return results
    else
        return nothing
    end
end


#####################################################################################
## Creating Unit Tests
#####################################################################################

"""
    create_module_tests(module_name::String)

Create a test file for a given module.

# Arguments
- `module_name::String`: The name of the module to create tests for.

# Example
```julia
create_module_tests("ModuleA")
```
"""
# function create_module_tests(module_name::String)
#     filename = joinpath(@__DIR__, "Test$(module_name).jl")
#     open(filename, "w") do file
#         # Write the test file content with header, blank lines, and test structure
#         write(
#             file,
#             """
# # Test$module_name.jl

# using Test
# using LinearAlgebra
# using SparseArrays

# # Include TestHelpers module for test utilies 
# push!(LOAD_PATH, abspath(@__DIR__))
# using TestHelpers  # Access exported functions from TestHelpers

# # Include local modules
# push_directory_to_load_path(:src)
# using LpProblem

# using Lp$module_name




# @testset "$module_name Tests" begin
#     # put your test logic here
# end
#         """,
#         )
#     end
#     return println("Created test file: $filename")
# end

end  # module TestFramework
