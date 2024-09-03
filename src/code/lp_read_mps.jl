module lp_read_mps

using SparseArrays
using DataStructures
using lp_problem

export read_mps_from_string, read_mps_from_file, read_mps_from_string_mip, read_mps_from_file_mip, read_file_to_string


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

    for line in lines
        words = split(line)
        (isempty(words) || (line[1] == '*')) && continue  # Skip empty lines and comments

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
            col_name, row_name, value = words
            value = parse(Float64, value)
            if !haskey(sections["COLUMNS"], col_name)
                sections["COLUMNS"][col_name] = OrderedDict()
            end
            sections["COLUMNS"][col_name][row_name] = value
        elseif current_section == "RHS"
            if length(words) == 3
                _, row_name, value = words
            else
                row_name, value = words[2:3]
            end
            sections["RHS"][row_name] = parse(Float64, value)
        elseif current_section == "BOUNDS"
            if length(words) == 4  # LO, UP, FX
                bound_type, _, var_name, value = words
            elseif length(words) == 3  # FR
                bound_type, _, var_name = words
                value = Inf
            end
            if !haskey(sections["BOUNDS"], var_name)
                sections["BOUNDS"][var_name] = Dict()
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

    # Populate objective function
    for (i, var) in enumerate(vars)
        if haskey(sections["COLUMNS"][var], objective_name)
            c[i] = sections["COLUMNS"][var][objective_name]
        end
    end

    # Populate constraint matrix and right-hand side
    constraint_index = 0
    for row in sections["ROWS"]
        if row.type != "N"
            constraint_index += 1
            push!(constraint_types, row.type[1])  # Store constraint type
            for (i, var) in enumerate(vars)
                if haskey(sections["COLUMNS"][var], row.name)
                    A[constraint_index, i] = sections["COLUMNS"][var][row.name]
                end
            end
            b[constraint_index] = get(sections["RHS"], row.name, 0.0)
            
            # Adjust for 'G' type constraints
            if row.type == "G"
                A[constraint_index, :] *= -1
                b[constraint_index] *= -1
            end
        end
    end

    # Process bound constraints
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

    return LPProblem(is_minimize, c, A, b, lb, ub, vars, constraint_types)
end

"""
    read_mps_from_string_mip(mps_string::String) -> MIPProblem

This function parses a given MPS formatted string and converts it into a `MIPProblem` struct, representing a Mixed Integer Programming (MIP) problem in Julia.
"""
function read_mps_from_string_mip(mps_string::String)
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

    # Convert to MIPProblem structure
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

    mip_problem = MIPProblem(
        is_minimize,
        c,
        A,
        b,
        lb,
        ub,
        vars,
        variable_types_array,
        constraint_types
    )

    return mip_problem
end

# New function to read a file and return its contents as a string
function read_file_to_string(file_path::String)
    return open(file_path, "r") do f
        read(f, String)
    end
end

# Modified function for reading LP problems from an MPS file
function read_mps_from_file(file_path::String)
    mps_string = read_file_to_string(file_path)
    return read_mps_from_string(mps_string)
end

# Modified function for reading MIP problems from an MPS file
function read_mps_from_file_mip(file_path::String)
    mps_string = read_file_to_string(file_path)
    return read_mps_from_string_mip(mps_string)
end


end # module
