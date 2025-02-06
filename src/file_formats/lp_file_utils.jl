"""
    read_file_to_string(file_path::String) -> String

Reads the contents of a file and returns it as a string.

# Arguments
- `file_path::String`: The path to the file.

# Returns
- `String`: The contents of the file as a string.
"""
function read_file_to_string(file_path::String)
    return open(file_path, "r") do f
        read(f, String)
    end
end


"""
    get_variable_type(var) -> String

Determines the type of a variable in a mathematical optimization model.

# Arguments
- `var`: The variable whose type is to be determined. This is typically a variable from a mathematical optimization model, such as a JuMP variable.

# Returns
- `String`: The type of the variable as a string. Possible values are:
    - `"Binary"`: If the variable is binary (i.e., it can take values 0 or 1).
    - `"Integer"`: If the variable is an integer (i.e., it can take integer values).
    - `"Continuous"`: If the variable is continuous (i.e., it can take any real value).

# Example
```julia
var = @variable(model, Bin)
println(get_variable_type(var))  # Outputs "Binary"
```
This function uses `is_binary` and `is_integer` to determine whether a variable is binary, integer, or continuous. 
"""
function get_variable_type(var)
    if is_binary(var)
        return :Binary
    elseif is_integer(var)
        return :Integer
    else
        return :Continuous
    end
end