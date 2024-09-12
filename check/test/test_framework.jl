# test_framework.jl

using Test

#=
    run_tests(test_modules::Vector{String})

Run all unit tests in the specified test modules.

# Arguments
- `test_modules::Vector{String}`: A list of module names (as strings) to test.

# Example
```julia
run_tests(["ModuleA", "ModuleB", "ModuleC"])
```
=#
function run_tests(test_modules::Vector{String})
    @testset "All Tests" begin
        for module_name in test_modules
            include("test_$(module_name).jl")
        end
    end
end

#=
    create_module_tests(module_name::String)

Create a test file for a given module.

# Arguments
- `module_name::String`: The name of the module to create tests for.

# Example
```julia
create_module_tests("ModuleA")
```
=#
function create_module_tests(module_name::String)
    filename = "check/test/test_$(module_name).jl"
    open(filename, "w") do file
        write(file, """
        # test_$(module_name).jl

        using Test
        using $module_name

        @testset "$(module_name) Tests" begin
            # Add your tests here
            @test true  # Placeholder test
        end
        """)
    end
    println("Created test file: $filename")
end

# Example usage:
# Uncomment and modify the following lines to use the framework
# create_module_tests("ModuleA")
# create_module_tests("ModuleB")
# run_tests(["ModuleA", "ModuleB"])