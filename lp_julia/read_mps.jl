module MPSReader

export read_mps_from_string, read_mps_from_file, LPProblem

struct LPProblem
    is_minimize::Bool
    c::Vector{Float64}
    A::Matrix{Float64}
    b::Vector{Float64}
    vars::Vector{String}
    constraint_types::Vector{Char}
end

function read_mps_from_string(mps_string::String)
    lines = split(mps_string, '\n')
    sections = Dict("NAME" => "", "ROWS" => [], "COLUMNS" => Dict(), "RHS" => Dict(), "BOUNDS" => Dict())
    current_section = ""
    objective_name = ""
    is_minimize = true

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
                sections["COLUMNS"][col_name] = Dict()
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
            bound_type, _, var_name, value = words
            if !haskey(sections["BOUNDS"], var_name)
                sections["BOUNDS"][var_name] = Dict()
            end
            sections["BOUNDS"][var_name][bound_type] = parse(Float64, value)
        end
    end

    # Convert to LPProblem structure
    vars = collect(keys(sections["COLUMNS"]))
    n_vars = length(vars)
    n_constraints = count(row -> row.type != "N", sections["ROWS"])

    c = zeros(n_vars)
    A = zeros(n_constraints, n_vars)
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
        else
            lb[i] = 0.0  # Default lower bound is 0 if not specified
        end
    end

    # Add bound constraints to A and b
    n_bound_constraints = count(x -> x > -Inf, lb) + count(x -> x < Inf, ub)
    A_with_bounds = zeros(n_constraints + n_bound_constraints, n_vars)
    b_with_bounds = zeros(n_constraints + n_bound_constraints)
    
    A_with_bounds[1:n_constraints, :] = A
    b_with_bounds[1:n_constraints] = b
    
    bound_constraint_index = n_constraints
    for i in 1:n_vars
        if lb[i] > -Inf
            bound_constraint_index += 1
            A_with_bounds[bound_constraint_index, i] = 1
            b_with_bounds[bound_constraint_index] = lb[i]
            push!(constraint_types, 'G')
        end
        if ub[i] < Inf
            bound_constraint_index += 1
            A_with_bounds[bound_constraint_index, i] = 1
            b_with_bounds[bound_constraint_index] = ub[i]
            push!(constraint_types, 'L')
        end
    end

    return LPProblem(is_minimize, c, A_with_bounds, b_with_bounds, vars, constraint_types)
end

function read_mps_from_file(file_path::String)
    file_content = open(file_path, "r") do file
        read(file, String)
    end
    return read_mps_from_string(file_content)
end

end # module MPSReader



