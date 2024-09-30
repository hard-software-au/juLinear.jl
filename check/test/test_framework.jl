module test_framework

using Test

# Export functions and constants so they can be used outside the module
export BASE_DIR, get_full_path, get_test_file_path, run_tests

# Function to manually set the base directory to check/
function get_base_dir()
    current_dir = pwd()  # Get the current working directory
    
    # Manually determine the correct directory
    if endswith(current_dir, "check")
        return current_dir  # Already in check/
    elseif endswith(current_dir, "test") || endswith(current_dir, "src")
        return abspath(joinpath(current_dir, ".."))  # Move up one level to check/
    elseif endswith(current_dir, "lp_code")
        return abspath(joinpath(current_dir, "check"))  # Go into check/ from lp_code/
    elseif contains(current_dir, "Linear Programming")
        return abspath(joinpath(current_dir, "lp_code", "check"))  # If higher level, go to check/
    else
        error("Could not locate the base directory for the check/ folder.")
    end
end

const BASE_DIR = get_base_dir()  # Set the base directory to check/

# Helper function to get the full path of any file relative to the base directory
function get_full_path(relative_path::String)
    return joinpath(BASE_DIR, relative_path)
end

# Function to get the correct relative path to test files
function get_test_file_path(file_name::String)
    if isfile(file_name)
        return file_name
    elseif isfile(joinpath(BASE_DIR, "check/test", file_name))  # Check if file exists in the test folder
        return joinpath(BASE_DIR, "check/test", file_name)
    else
        error("Test file not found: $file_name")
    end
end

"""
    run_tests(test_modules::Vector{String})

Run all unit tests in the specified test modules.

# Arguments
- `test_modules::Vector{String}`: A list of module names (as strings) to test.

# Example
```julia
run_tests(["ModuleA", "ModuleB", "ModuleC"])
```
"""
function run_tests(test_modules::Vector{String})
    @testset "All Tests" begin
        for module_name in test_modules
            file_path = get_test_file_path("test_$(module_name).jl")
            include(file_path)
        end
    end
end

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

end  # module TestFramework
