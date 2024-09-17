module lp_read_LP

using SparseArrays
using LinearAlgebra
using DataStructures  # For OrderedDict if needed

using lp_problem

export read_lp


"""
    read_lp(filename::String) -> LPProblem

Reads a Linear Programming (LP) file in LP format and parses it into an `LPProblem` struct, which contains the objective function, constraints, bounds, and variable types.

# Arguments:
- `filename::String`: The name or path of the LP file to be read.

# Returns:
- `LPProblem`: A struct containing the parsed components of the LP problem:
  - `is_minimize::Bool`: Indicates if the problem is a minimization (`true`) or maximization (`false`) problem.
  - `c::Vector{Float64}`: Coefficients of the objective function.
  - `A::SparseMatrixCSC{Float64, Int64}`: Constraint matrix in sparse format.
  - `b::Vector{Float64}`: Right-hand side (RHS) values of the constraints.
  - `constraint_types::Vector{Char}`: A vector indicating the type of each constraint ('L' for `<=`, 'G' for `>=`, 'E' for `=`).
  - `l::Vector{Float64}`: Lower bounds for the variables.
  - `u::Vector{Float64}`: Upper bounds for the variables.
  - `vars::Vector{String}`: Names of the variables used in the problem.
  - `variable_types::Vector{Symbol}`: Variable types (:Binary, :Integer, or :Continuous).

# Sections handled in the LP file:
1. **Objective**: Parses the objective function, whether it's "Maximize" or "Minimize". Coefficients and variables are parsed into a dictionary.
2. **Constraints**: Parses constraints of the form `x1 + 2 x2 <= 10`, where coefficients and variables are stored in a sparse matrix format.
3. **Bounds**: Parses the variable bounds such as `0 <= x1 <= 100`, or single-sided bounds like `x2 <= 1`.
4. **Binary and Integer**: Handles binary and integer variable types.
5. **End**: Stops parsing when the "End" keyword is encountered.

# Raises:
- `ErrorException`: If parsing any term in the objective or constraints fails.
- `ErrorException`: If a variable in the objective or constraints is not defined in the variable set.

# Example:
```julia
lp = read_lp("example.lp")
println(lp.c)    # Objective function coefficients
println(lp.A)    # Constraint matrix
println(lp.b)    # Right-hand side of constraints
```
# Notes
- The function assumes that the LP file is well-formed and adheres to the standard LP file format.
- The contariants are stored in a sparse matrix for effient handling of large problems.
- Varibles without explicily defined bounds are assumend to have default bounds (-∞,∞).
"""
function read_lp(filename::String)::LPProblem
    # Initialize storage variables
    is_minimize = true
    objective = Dict{String, Float64}()
    constraints = Vector{Dict{String, Float64}}()
    constraint_types = Vector{Char}()
    b = Float64[]
    vars_set = Set{String}()
    variable_types = Dict{String, Symbol}()
    l_bounds = Dict{String, Float64}()
    u_bounds = Dict{String, Float64}()

    # Read all lines from the LP file
    lines = readlines(filename)
    current_section = ""

    for raw_line in lines
        # Clean the line by removing comments and trimming whitespace
        line = strip(split(raw_line, "\\")[1])  # Remove comments starting with '\'
        if line == ""
            continue  # Skip empty lines
        end

        # Detect section headers
        lower_line = lowercase(line)
        if startswith(lower_line, "minimize")
            current_section = "Objective"
            is_minimize = true
            continue
        elseif startswith(lower_line, "maximize")
            current_section = "Objective"
            is_minimize = false
            continue
        elseif startswith(lower_line, "subject to") || startswith(lower_line, "such that") || startswith(lower_line, "st")
            current_section = "Constraints"
            continue
        elseif startswith(lower_line, "bounds")
            current_section = "Bounds"
            continue
        elseif startswith(lower_line, "binary")
            current_section = "Binary"
            continue
        elseif startswith(lower_line, "general") || startswith(lower_line, "integer")
            current_section = "Integer"
            continue
        elseif startswith(lower_line, "end")
            break  # End of LP file
        end

        # Parse based on the current section
        if current_section == "Objective"
            # Handle multi-line objective functions by accumulating lines until the next section
            # Remove optional objective name (e.g., "obj: ")
            expr = startswith(line, ":") ? strip(line[2:end]) : line
            # Split the expression into tokens based on '+' and '-' operators
            tokens = split(expr, r"(?=[+-])")
            for token in tokens
                if isempty(token)
                    continue
                end
                # Determine the sign
                sign = 1.0
                if startswith(token, "-")
                    sign = -1.0
                    token = token[2:end]
                elseif startswith(token, "+")
                    token = token[2:end]
                end
                # Strip the token to remove any leading/trailing whitespace
                token = strip(token)
                # Split coefficient and variable
                m = match(r"^(\d*\.?\d*)\s*\*?\s*([A-Za-z][A-Za-z0-9_]*)$", token)
                if m !== nothing
                    coeff_str, var = m.captures[1], m.captures[2]
                    coeff = coeff_str == "" ? 1.0 : parse(Float64, coeff_str)
                    objective[var] = get(objective, var, 0.0) + sign * coeff
                    push!(vars_set, var)
                else
                    error("Failed to parse objective term: $token")
                end
            end
        elseif current_section == "Constraints"
            # Example constraint: c1: x1 + x2 <= 10
            # Split into name (optional), expression, relation, and RHS
            m = match(r"^(?:(\w+)\s*:\s*)?(.+?)\s*(<=|>=|=)\s*([+-]?\d+\.?\d*)$", line)
            if m === nothing
                error("Failed to parse constraint: $line")
            end
            _, expr, relation, rhs_str = m.captures
            rhs = parse(Float64, rhs_str)
            push!(b, rhs)
            # Parse the left-hand side expression
            constraint = Dict{String, Float64}()
            tokens = split(expr, r"(?=[+-])")
            constant_term = 0.0  # Initialize constant term

            for token in tokens
                if isempty(token)
                    continue
                end
                # Determine the sign
                sign = 1.0
                if startswith(token, "-")
                    sign = -1.0
                    token = token[2:end]
                elseif startswith(token, "+")
                    token = token[2:end]
                end
                # Strip the token to remove any leading/trailing whitespace
                token = strip(token)
                # Attempt to match variable terms
                m_var = match(r"^(\d*\.?\d*)\s*\*?\s*([A-Za-z][A-Za-z0-9_]*)$", token)
                if m_var !== nothing
                    coeff_str, var = m_var.captures[1], m_var.captures[2]
                    coeff = coeff_str == "" ? 1.0 : parse(Float64, coeff_str)
                    constraint[var] = get(constraint, var, 0.0) + sign * coeff
                    push!(vars_set, var)
                else
                    # Attempt to match constant terms
                    m_const = match(r"^([+-]?\d+\.?\d*)$", token)
                    if m_const !== nothing
                        const_val = parse(Float64, m_const.captures[1])
                        constant_term += sign * const_val
                    else
                        error("Failed to parse constraint term: $token")
                    end
                end
            end
            # Adjust RHS with the constant term
            b[end] = b[end] - constant_term

            push!(constraints, constraint)
            # Record constraint type
            relation_char = relation == "<=" ? 'L' : (relation == ">=" ? 'G' : 'E')
            push!(constraint_types, relation_char)
        elseif current_section == "Bounds"
            # Handle bounds like "0 <= x1 <= 100", "x2 >= 0", "x3 <= 50", "x4 free"
            # Split the line into tokens
            tokens = split(line)
            if length(tokens) == 5 && tokens[2] == "<=" && tokens[4] == "<="
                # Format: lower <= variable <= upper
                lower = parse(Float64, tokens[1])
                var = tokens[3]
                upper = parse(Float64, tokens[5])
                l_bounds[var] = lower
                u_bounds[var] = upper
                push!(vars_set, var)
            elseif length(tokens) == 3
                if tokens[2] == "<="
                    # Format: variable <= upper
                    var = tokens[1]
                    upper = parse(Float64, tokens[3])
                    u_bounds[var] = upper
                    push!(vars_set, var)
                elseif tokens[2] == ">="
                    # Format: variable >= lower
                    var = tokens[1]
                    lower = parse(Float64, tokens[3])
                    l_bounds[var] = lower
                    push!(vars_set, var)
                elseif tokens[1] == "free"
                    # Format: free variable
                    var = tokens[2]
                    l_bounds[var] = -Inf
                    u_bounds[var] = Inf
                    push!(vars_set, var)
                else
                    error("Unrecognized bounds format: $line")
                end
            elseif length(tokens) == 4 && tokens[1] == "free"
                # Handle "free variable"
                var = tokens[2]
                l_bounds[var] = -Inf
                u_bounds[var] = Inf
                push!(vars_set, var)
            else
                error("Unsupported bounds format: $line")
            end
        elseif current_section == "Binary"
            # List of binary variables, possibly multiple on one line
            vars = split(line)
            for var in vars
                variable_types[var] = :Binary
                push!(vars_set, var)
            end
        elseif current_section == "Integer"
            # List of integer variables, possibly multiple on one line
            vars = split(line)
            for var in vars
                variable_types[var] = :Integer
                push!(vars_set, var)
            end
        end
    end

    # Collect and sort variable names
    vars = sort(collect(vars_set))
    var_index = Dict(var => i for (i, var) in enumerate(vars))
    n_vars = length(vars)

    # Objective function coefficients
    c = zeros(Float64, n_vars)
    for (var, coeff) in objective
        if haskey(var_index, var)
            c[var_index[var]] = coeff
        else
            error("Variable $var in objective not defined in variables.")
        end
    end

    # Constraint matrix A in sparse format
    n_constraints = length(constraints)
    row = Int[]
    col = Int[]
    data = Float64[]

    for (i, constraint) in enumerate(constraints)
        for (var, coeff) in constraint
            if haskey(var_index, var)
                push!(row, i)
                push!(col, var_index[var])
                push!(data, coeff)
            else
                error("Variable $var in constraints not defined in variables.")
            end
        end
    end

    A_sparse = sparse(row, col, data, n_constraints, n_vars)

    # Right-hand side vector
    # Already collected in vector `b`

    # Bounds vectors
    l = fill(-Inf, n_vars)
    u = fill(Inf, n_vars)

    for var in vars
        if haskey(l_bounds, var)
            l[var_index[var]] = l_bounds[var]
        end
        if haskey(u_bounds, var)
            u[var_index[var]] = u_bounds[var]
        end
    end

    # Variable types vector
    variable_types_vec = Symbol[]
    for var in vars
        push!(variable_types_vec, get(variable_types, var, :Continuous))
    end

    # Create and return the LPProblem struct
    return LPProblem(
        is_minimize,
        c,
        A_sparse,
        b,
        constraint_types,
        l,
        u,
        vars,
        variable_types_vec
    )
end


end #lp_read_LP