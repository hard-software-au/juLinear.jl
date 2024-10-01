module lp_read_mps

using SparseArrays
using DataStructures
using JuMP
using MathOptInterface
const MOI = MathOptInterface

using lp_problem

export read_file_to_string, read_mps_from_file, read_mps_from_string, read_mps_with_JuMP
export read_mps


###################################################################################
## File methods
###################################################################################

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
    read_mps_from_file(file_path::String) -> LPProblem

Reads an MPS file and converts it into an `LPProblem` struct.

# Arguments
- `file_path::String`: The path to the MPS file.

# Returns
- `LPProblem`: A struct containing the LP problem data.
"""
function read_mps_from_file(file_path::String)
    mps_string = read_file_to_string(file_path)
    return read_mps_from_string(mps_string)
end


function read_mps(file_path::String)
    mps_string = read_file_to_string(file_path)
    return read_mps_from_string(mps_string)
end


###################################################################################
## read_mps_from_string
###################################################################################


"""
    read_mps_from_string(mps_string::String) -> LPProblem

This function parses a given MPS (Mathematical Programming System) formatted string and converts it into an `LPProblem` struct, representing a Linear Programming (LP) problem in Julia.

# Arguments:
- `mps_string::String`: A string representing the content of an MPS file.

# Returns:
- `LPProblem`: A struct containing the LP problem data.
"""
function read_mps_from_string(mps_string::String)
    lines = split(mps_string, '\n')
    sections = Dict("NAME" => "", "ROWS" => [], "COLUMNS" => OrderedDict(), "RHS" => Dict(), "BOUNDS" => Dict())
    current_section = ""
    objective_name = ""
    is_minimize = true
    objective_set = false
    in_integer_block = false
    variable_types = OrderedDict{String, Symbol}()

    for line in lines
        words = split(line)
        (isempty(words) || (line[1] == '*')) && continue

        if (line[1] != ' ') && words[1] in ["NAME", "OBJSENSE", "ROWS", "COLUMNS", "RHS", "BOUNDS", "ENDATA"]
            current_section = words[1]
            continue
        end

        if current_section == "NAME"
            sections["NAME"] = words[1]
        elseif current_section == "OBJSENSE"
            if words[1] == "MAX"
                is_minimize = false
                objective_set = true
            elseif words[1] == "MIN"
                is_minimize = true
                objective_set = true
            end
        elseif current_section == "ROWS"
            row_type, row_name = words
            push!(sections["ROWS"], (type=row_type, name=row_name))
            if row_type == "N"
                objective_name = row_name
            end
        elseif current_section == "COLUMNS"
            if words[1] == "MARKER"
                if words[2] == "'INTORG'"
                    in_integer_block = true
                elseif words[2] == "'INTEND'"
                    in_integer_block = false
                end
                continue
            end

            col_name = words[1]
            if !haskey(sections["COLUMNS"], col_name)
                sections["COLUMNS"][col_name] = OrderedDict()
                variable_types[col_name] = in_integer_block ? :Integer : :Continuous
            end

            row_name_1, value_1 = words[2:3]
            sections["COLUMNS"][col_name][row_name_1] = parse(Float64, value_1)
            
            if length(words) > 3
                row_name_2, value_2 = words[4:5]
                sections["COLUMNS"][col_name][row_name_2] = parse(Float64, value_2)
            end
        elseif current_section == "RHS"
            if length(words) == 3
                _, row_name, value = words
            else
                row_name, value = words[2:3]
            end
            sections["RHS"][row_name] = parse(Float64, value)
        elseif current_section == "BOUNDS"
            if length(words) == 4  # LO, UP, FX, BV
                bound_type, _, var_name, value = words
            elseif length(words) == 3  # FR, MI, PL
                bound_type, _, var_name = words
                value = Inf
            end

            if !haskey(sections["BOUNDS"], var_name)
                sections["BOUNDS"][var_name] = Dict()
            end

            if bound_type in ["BV", "LI", "UI", "SC", "SI"]
                if bound_type == "BV"
                    variable_types[var_name] = :Binary
                elseif bound_type == "LI" || bound_type == "UI"
                    variable_types[var_name] = :Integer
                elseif bound_type == "SC"
                    variable_types[var_name] = :SemiContinuous
                elseif bound_type == "SI"
                    variable_types[var_name] = :SemiInteger
                end
            end

            if bound_type == "FR"
                sections["BOUNDS"][var_name][bound_type] = nothing
            else
                sections["BOUNDS"][var_name][bound_type] = parse(Float64, value)
            end
        end
    end

    # Convert to LPProblem structure
    vars = collect(keys(sections["COLUMNS"]))
    n_vars = length(vars)
    n_constraints = count(row -> row.type != "N", sections["ROWS"])

    c = zeros(n_vars)
    A = spzeros(n_constraints, n_vars)
    b = zeros(n_constraints)
    constraint_types = Char[]

    for (i, var) in enumerate(vars)
        if haskey(sections["COLUMNS"][var], objective_name)
            c[i] = sections["COLUMNS"][var][objective_name]
        end
    end

    constraint_index = 0
    for row in sections["ROWS"]
        if row.type != "N"
            constraint_index += 1
            push!(constraint_types, row.type[1])
            for (i, var) in enumerate(vars)
                if haskey(sections["COLUMNS"][var], row.name)
                    A[constraint_index, i] = sections["COLUMNS"][var][row.name]
                end
            end
            b[constraint_index] = get(sections["RHS"], row.name, 0.0)
            
            if row.type == "G"
                A[constraint_index, :] *= -1
                b[constraint_index] *= -1
            end
        end
    end

    lb = fill(-Inf, n_vars)
    ub = fill(Inf, n_vars)
    for (i, var) in enumerate(vars)
        if haskey(sections["BOUNDS"], var)
            bounds = sections["BOUNDS"][var]
            if haskey(bounds, "LO")
                lb[i] = bounds["LO"]
            end
            if haskey(bounds, "UP")
                ub[i] = bounds["UP"]
            end
            if haskey(bounds, "FX")
                lb[i] = ub[i] = bounds["FX"]
            end
            if haskey(bounds, "FR")
                lb[i] = -Inf
                ub[i] = Inf
            end
        else
            lb[i] = 0.0  # Default lower bound is 0 if not specified
        end
    end

    variable_types_array = [variable_types[var] for var in vars]

    # Return an LPProblem struct
    lp_problem = LPProblem(
        is_minimize,
        c,
        A,
        b,
        constraint_types,
        lb,
        ub,
        vars,
        variable_types_array
    )

    return lp_problem
end


####################################################################################
# JuMP based reader
####################################################################################


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


"""
    read_mps_with_JuMP(file_path::String) -> LPProblem

Reads an MPS file using JuMP and converts it into a `LPProblem` struct.

# Arguments
- `file_path::String`: The path to the MPS file.

# Returns
- `LPProblem`: A struct containing the MIP problem data.
"""
function read_mps_with_JuMP(file_path::String)
    # Create a JuMP model
    model = Model()

    # Read the MPS file into the model
    MOI.read_from_file(model.moi_backend, file_path)

    # Extract variables
    variables = all_variables(model)

    # Extract variable names
    variable_names = [name(var) for var in variables]

    # Extract the objective function (assumes a linear objective)
    objective_function = MOI.get(model.moi_backend, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}())
    objective_coeffs = zeros(Float64, length(variables))

    # Populate the objective coefficients array
    for term in objective_function.terms
        objective_coeffs[term.variable.value] = term.coefficient
    end

    # Determine whether it's a minimization or maximization problem
    is_minimize = MOI.get(model.moi_backend, MOI.ObjectiveSense()) == MOI.MIN_SENSE

    # Separate constraints by type
    less_than_constraints = MOI.get(model.moi_backend, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{Float64}, MOI.LessThan{Float64}}())
    greater_than_constraints = MOI.get(model.moi_backend, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{Float64}, MOI.GreaterThan{Float64}}())
    equal_to_constraints = MOI.get(model.moi_backend, MOI.ListOfConstraintIndices{MOI.ScalarAffineFunction{Float64}, MOI.EqualTo{Float64}}())

    constraint_matrix_rows = Int64[]
    constraint_matrix_cols = Int64[]
    constraint_matrix_vals = Float64[]
    rhs_values = Float64[]
    constraint_types = Char[]

    # Process LessThan constraints
    for con in less_than_constraints
        func = MOI.get(model.moi_backend, MOI.ConstraintFunction(), con)
        set = MOI.get(model.moi_backend, MOI.ConstraintSet(), con)
        
        for term in func.terms
            push!(constraint_matrix_rows, con.value)  # Constraint index
            push!(constraint_matrix_cols, term.variable.value)  # Variable index
            push!(constraint_matrix_vals, term.coefficient)
        end
        push!(rhs_values, set.upper)
        push!(constraint_types, 'L')
    end

    # Process GreaterThan constraints
    for con in greater_than_constraints
        func = MOI.get(model.moi_backend, MOI.ConstraintFunction(), con)
        set = MOI.get(model.moi_backend, MOI.ConstraintSet(), con)
        
        for term in func.terms
            push!(constraint_matrix_rows, con.value)  # Constraint index
            push!(constraint_matrix_cols, term.variable.value)  # Variable index
            push!(constraint_matrix_vals, term.coefficient)
        end
        push!(rhs_values, set.lower)
        push!(constraint_types, 'G')
    end

    # Process EqualTo constraints
    for con in equal_to_constraints
        func = MOI.get(model.moi_backend, MOI.ConstraintFunction(), con)
        set = MOI.get(model.moi_backend, MOI.ConstraintSet(), con)
        
        for term in func.terms
            push!(constraint_matrix_rows, con.value)  # Constraint index
            push!(constraint_matrix_cols, term.variable.value)  # Variable index
            push!(constraint_matrix_vals, term.coefficient)
        end
        push!(rhs_values, set.value)
        push!(constraint_types, 'E')
    end

    # Convert to sparse matrix
    constraint_matrix = sparse(constraint_matrix_rows, constraint_matrix_cols, constraint_matrix_vals, length(rhs_values), length(variables))

    # Define lower and upper bounds
    lower_bounds = fill(0.0, length(variables))  # Default lower bounds (0.0)
    upper_bounds = fill(Inf, length(variables))  # Default upper bounds (Inf)

    # Variable types array
    variable_types = Vector{Symbol}(undef, length(variables))

    # Determine the type of each variable using the provided get_variable_type function
    for (i, var) in enumerate(variables)
        variable_types[i] = get_variable_type(var)
    end

    # Construct the LPProblem struct
    lp_problem = LPProblem(
        is_minimize,
        objective_coeffs,
        constraint_matrix,
        rhs_values,
        constraint_types,
        lower_bounds,
        upper_bounds,
        variable_names,
        variable_types
    )

    return lp_problem
end


end # module
