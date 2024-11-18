# module LpReadLP

# using SparseArrays
# using LinearAlgebra
# using DataStructures  # For OrderedDict if needed

# using LpProblem

# export read_lp, write_lp

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
function read_lp(filename::String; verbose::Bool=false)
    # Initialize storage variables
    if verbose
        println("Starting to read LP file: $filename")
    end
    is_minimize = true
    objective = Dict{String,Float64}()
    constraints = Vector{Dict{String,Float64}}()
    constraint_types = Vector{Char}()
    b = Float64[]
    vars_set = Set{String}()
    variable_types = Dict{String,Symbol}()
    l_bounds = Dict{String,Float64}()
    u_bounds = Dict{String,Float64}()

    # Read all lines from the LP file
    lines = readlines(filename)
    current_section = ""

    for raw_line in lines
        # Clean the line by removing comments and trimming whitespace
        line = strip(split(raw_line, "\\")[1])  # Remove comments starting with '\'
        # Ensure 'line' is a String, not SubString
        line = String(line)
        if line == ""
            if verbose
                println("Skipping empty line")
            end
            continue  # Skip empty lines
        end

        # Detect section headers
        lower_line = lowercase(line)
        if verbose
            println("Processing line: $line")
        end
        if startswith(lower_line, "minimize")
            current_section = "Objective"
            is_minimize = true
            if verbose
                println("Detected section: Objective (Minimize)")
            end
            continue
        elseif startswith(lower_line, "maximize")
            current_section = "Objective"
            is_minimize = false
            if verbose
                println("Detected section: Objective (Maximize)")
            end
            continue
        elseif startswith(lower_line, "subject to") ||
            startswith(lower_line, "such that") ||
            startswith(lower_line, "st")
            current_section = "Constraints"
            if verbose
                println("Detected section: Constraints")
            end
            continue
        elseif startswith(lower_line, "bounds")
            current_section = "Bounds"
            if verbose
                println("Detected section: Bounds")
            end
            continue
        elseif startswith(lower_line, "binary")
            current_section = "Binary"
            if verbose
                println("Detected section: Binary Variables")
            end
            continue
        elseif startswith(lower_line, "general") || startswith(lower_line, "integer")
            current_section = "Integer"
            if verbose
                println("Detected section: Integer Variables")
            end
            continue
        elseif startswith(lower_line, "end")
            if verbose
                println("End of LP file detected")
            end
            break  # End of LP file
        end

        # Parse based on the current section
        if current_section == "Objective"
            if verbose
                println("Parsing objective line: $line")
            end

            # Handle the "obj:" prefix, if it exists
            if startswith(lowercase(line), "obj:")
                line = strip(line[5:end])  # Remove "obj:" prefix (5 characters including the space)
            end

            # Remove optional colon (e.g., ":") if present, then proceed with parsing the expression
            expr = startswith(line, ":") ? strip(line[2:end]) : line

            # Parse the expression and update the objective dictionary
            parse_expression(expr, objective, vars_set; verbose=verbose)

        elseif current_section == "Constraints"
            if verbose
                println("Parsing constraint line: $line")
            end

            # Example constraint: c1: x1 + x2 <= 10
            m = match(r"^(?:(\w+)\s*:\s*)?(.+?)\s*(<=|>=|=)\s*([+-]?\d+\.?\d*)$", line)
            if m === nothing
                error("Failed to parse constraint: $line")
            end
            _, expr, relation, rhs_str = m.captures
            rhs = parse(Float64, rhs_str)
            push!(b, rhs)
            if verbose
                println("Parsed constraint RHS: $rhs with relation: $relation")
            end

            constraint = Dict{String,Float64}()
            # Parse the constraint expression
            constant_term = parse_expression(expr, constraint, vars_set; verbose=verbose)

            # Adjust RHS with the constant term
            b[end] = b[end] - constant_term
            if verbose
                println("Adjusted RHS: $(b[end]) with constant term: $constant_term")
            end

            push!(constraints, constraint)
            relation_char = relation == "<=" ? 'L' : (relation == ">=" ? 'G' : 'E')
            push!(constraint_types, relation_char)

        elseif current_section == "Bounds"
            if verbose
                println("Parsing bounds line: $line")
            end
            parse_bounds(line, l_bounds, u_bounds, vars_set; verbose=verbose)

        elseif current_section == "Binary"
            if verbose
                println("Parsing binary variable line: $line")
            end
            vars = split(line)
            for var in vars
                variable_types[var] = :Binary
                push!(vars_set, var)
                if verbose
                    println("Parsed binary variable $var")
                end
            end
        elseif current_section == "Integer"
            if verbose
                println("Parsing integer variable line: $line")
            end
            vars = split(line)
            for var in vars
                variable_types[var] = :Integer
                push!(vars_set, var)
                if verbose
                    println("Parsed integer variable $var")
                end
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
            if verbose
                println("Assigned coefficient for variable $var: $coeff")
            end
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
                if verbose
                    println("Added constraint for variable $var at row $i: $coeff")
                end
            else
                error("Variable $var in constraints not defined in variables.")
            end
        end
    end

    A_sparse = sparse(row, col, data, n_constraints, n_vars)

    # Bounds vectors
    l = fill(-Inf, n_vars)
    u = fill(Inf, n_vars)

    for var in vars
        if haskey(l_bounds, var)
            l[var_index[var]] = l_bounds[var]
            if verbose
                println("Lower bound for $var: $(l_bounds[var])")
            end
        end
        if haskey(u_bounds, var)
            u[var_index[var]] = u_bounds[var]
            if verbose
                println("Upper bound for $var: $(u_bounds[var])")
            end
        end
    end

    # Variable types vector
    variable_types_vec = Symbol[]
    for var in vars
        push!(variable_types_vec, get(variable_types, var, :Continuous))
        if verbose
            println("Variable type for $var: $(get(variable_types, var, :Continuous))")
        end
    end

    if verbose
        println("Successfully parsed LP file")
    end

    # Create and return the LPProblem struct
    return LPProblem(
        is_minimize, c, A_sparse, b, constraint_types, l, u, vars, variable_types_vec
    )
end

# Helper function to parse expressions (objective and constraints)
function parse_expression(
    expr::AbstractString,
    coeff_dict::Dict{String,Float64},
    vars_set::Set{String};
    verbose::Bool=false,
)
    tokens = split(expr, r"(?=[+-])")
    constant_term = 0.0  # Initialize constant term

    for token in tokens
        if verbose
            println("Parsing token: $token")
        end
        token = strip(token)
        if isempty(token)
            if verbose
                println("Skipping empty token")
            end
            continue
        end

        # Determine the sign
        sign = 1.0
        if startswith(token, "-")
            sign = -1.0
            token = strip(token[2:end])
        elseif startswith(token, "+")
            token = strip(token[2:end])
        end

        if isempty(token)
            if verbose
                println("Skipping empty token after stripping sign")
            end
            continue
        end

        # Attempt to match variable terms with single variable
        m_var = match(r"^(\d*\.?\d*)\s*([A-Za-z][A-Za-z0-9_]*)$", token)
        if m_var !== nothing
            coeff_str, var = m_var.captures[1], m_var.captures[2]
            coeff = coeff_str == "" ? 1.0 : parse(Float64, coeff_str)
            coeff *= sign
            if verbose
                println("Parsed coefficient: $coeff for variable: $var")
            end
            coeff_dict[var] = get(coeff_dict, var, 0.0) + coeff
            push!(vars_set, var)
        else
            # Attempt to match variable terms with multiple variables (Non-linear)
            m_multivar = match(
                r"^(\d*\.?\d*)\s*([A-Za-z][A-Za-z0-9_]*)\s*([A-Za-z][A-Za-z0-9_]*)$", token
            )
            if m_multivar !== nothing
                # Handle multi-variable term
                coeff_str, var1, var2 = m_multivar.captures
                coeff = coeff_str == "" ? 1.0 : parse(Float64, coeff_str)
                coeff *= sign
                if verbose
                    println("Detected non-linear term: $coeff $var1 $var2")
                end
                # Raise a specific error for non-linear terms
                throw(
                    ArgumentError("Non-linear terms are not supported: $coeff $var1 $var2")
                )
            else
                # Attempt to match constant terms
                m_const = match(r"^([+-]?\d+\.?\d*)$", token)
                if m_const !== nothing
                    const_val = parse(Float64, m_const.captures[1])
                    constant_term += sign * const_val
                    if verbose
                        println("Parsed constant term: $const_val")
                    end
                else
                    throw(ArgumentError("Failed to parse term: $token"))
                end
            end
        end
    end

    return constant_term
end

# Helper function to parse bounds
function parse_bounds(
    line::AbstractString,
    l_bounds::Dict{String,Float64},
    u_bounds::Dict{String,Float64},
    vars_set::Set{String};
    verbose::Bool=false,
)
    tokens = split(line)
    if length(tokens) == 5 &&
        (tokens[2] == "<=" || tokens[2] == ">=") &&
        tokens[4] == tokens[2]
        # Format: lower <= variable <= upper
        lower = parse(Float64, tokens[1])
        var = tokens[3]
        upper = parse(Float64, tokens[5])
        l_bounds[var] = lower
        u_bounds[var] = upper
        push!(vars_set, var)
        if verbose
            println("Parsed bounds for variable $var: $lower <= $var <= $upper")
        end
    elseif length(tokens) == 3 && (tokens[2] == "<=" || tokens[2] == ">=")
        # Determine if tokens[1] is a variable or number
        is_var1 = occursin(r"^[A-Za-z_]", tokens[1])
        is_var3 = occursin(r"^[A-Za-z_]", tokens[3])
        if is_var1 && !is_var3
            # Format: variable <= upper OR variable >= lower
            var = tokens[1]
            bound = parse(Float64, tokens[3])
            if tokens[2] == "<="
                u_bounds[var] = bound
                if verbose
                    println("Parsed upper bound for variable $var: $var <= $bound")
                end
            else  # ">="
                l_bounds[var] = bound
                if verbose
                    println("Parsed lower bound for variable $var: $var >= $bound")
                end
            end
            push!(vars_set, var)
        elseif !is_var1 && is_var3
            # Format: lower <= variable OR upper >= variable
            bound = parse(Float64, tokens[1])
            var = tokens[3]
            if tokens[2] == "<="
                l_bounds[var] = bound
                if verbose
                    println("Parsed lower bound for variable $var: $bound <= $var")
                end
            else  # ">="
                u_bounds[var] = bound
                if verbose
                    println("Parsed upper bound for variable $var: $bound >= $var")
                end
            end
            push!(vars_set, var)
        else
            error("Unrecognized bounds format: $line")
        end
    else
        error("Unsupported bounds format: $line")
    end
end

##########################################################################
## Write LP fields
##########################################################################

"""
write_lp(filename::String, problem::LPProblem)

Writes a linear programming (LP) problem to a file in the LP format, given an `LPProblem` struct.

# Arguments:
- `filename::String`: The name or path of the LP file to write.
- `problem::LPProblem`: The linear programming problem to write. It contains fields for objective function, constraints, bounds, and variable types.

# Writes:
- An LP file formatted with the following sections:
  1. **Objective**: The objective function (either "Maximize" or "Minimize").
  2. **Subject To**: The constraints on the variables, with appropriate relations (`<=`, `>=`, or `=`).
  3. **Bounds**: The bounds for each variable, with "free" indicating no bounds.
  4. **Binary and General**: Specifies binary and integer variables, if any.
  5. **End**: Marks the end of the LP file.

# Example:
```julia
lp = LPProblem(is_minimize, c, A_sparse, b, constraint_types, l, u, vars, variable_types_vec)
write_lp("output.lp", lp)
```
# Notes 
- The objective function coefficents are written in the standard LP format with signs and terms properly spaced.
- Contraints are written based on the contraint matrix and right-hand side vector.
- Bounds are written based on the contraint matrix and right-hand side vector.
- If the problem contains binary of integer varibles, they are listed under the apporapiate sections.
"""
function write_lp(filename::String, problem::LPProblem; tolerance::Float64=1e-10)
    # Validate input dimensions
    n_vars = length(problem.vars)
    n_constraints = size(problem.A, 1)
    
    @assert length(problem.c) == n_vars "Objective coefficient vector length mismatch"
    @assert size(problem.A, 2) == n_vars "Constraint matrix column count mismatch"
    @assert length(problem.b) == n_constraints "RHS vector length mismatch"
    @assert length(problem.constraint_types) == n_constraints "Constraint types length mismatch"
    @assert length(problem.l) == n_vars "Lower bounds vector length mismatch"
    @assert length(problem.u) == n_vars "Upper bounds vector length mismatch"
    @assert length(problem.variable_types) == n_vars "Variable types length mismatch"
    
    # Validate constraint types
    valid_types = ['L', 'G', 'E']
    @assert all(t ∈ valid_types for t in problem.constraint_types) "Invalid constraint type found"
    
    function format_term(coeff::Float64, var::String, is_first::Bool)
        abs_coeff = abs(coeff)
        if abs_coeff < tolerance
            return ""
        elseif abs(abs_coeff - 1.0) < tolerance
            prefix = coeff < 0 ? "- " : (is_first ? "" : "+ ")
            return "$(prefix)$var"
        else
            prefix = coeff < 0 ? "-" : (is_first ? "" : "+")
            return "$(prefix) $abs_coeff $var"
        end
    end

    open(filename, "w") do io
        # Write Objective
        println(io, problem.is_minimize ? "Minimize" : "Maximize")
        print(io, " obj: ")
        
        # Write objective function
        terms = String[]
        first_term = true
        for (i, coeff) in enumerate(problem.c)
            term = format_term(coeff, problem.vars[i], first_term)
            if !isempty(term)
                push!(terms, term)
                first_term = false
            end
        end
        println(io, isempty(terms) ? "0" : join(terms, " "))

        # Write Constraints
        println(io, "Subject To")
        for i in 1:n_constraints
            terms = String[]
            first_term = true
            for (j, coeff) in zip(findnz(problem.A[i, :])...)
                term = format_term(coeff, problem.vars[j], first_term)
                if !isempty(term)
                    push!(terms, term)
                    first_term = false
                end
            end
            
            relation = Dict('L' => "<=", 'G' => ">=", 'E' => "=")[problem.constraint_types[i]]
            println(io, " c$i: ", isempty(terms) ? "0" : join(terms, " "), " $relation $(problem.b[i])")
        end

        # Write Bounds
        println(io, "Bounds")
        for i in 1:n_vars
            var = problem.vars[i]
            lower = problem.l[i]
            upper = problem.u[i]
            
            if abs(lower - upper) < tolerance
                println(io, " $var = $lower")
            elseif lower > -Inf && upper < Inf
                println(io, " $lower <= $var <= $upper")
            elseif lower > -Inf
                println(io, " $var >= $lower")
            elseif upper < Inf
                println(io, " $var <= $upper")
            else
                println(io, " $var free")
            end
        end

        # Write Binary and Integer variables
        for var_type in [:Binary, :Integer]
            vars_of_type = [problem.vars[i] for i in 1:n_vars if problem.variable_types[i] == var_type]
            if !isempty(vars_of_type)
                println(io, var_type == :Binary ? "Binary" : "General")
                for var in vars_of_type
                    println(io, " $var")
                end
            end
        end

        println(io, "End")
    end
end

# end #lp_read_LP
