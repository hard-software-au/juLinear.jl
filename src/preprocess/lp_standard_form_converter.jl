"""
    convert_to_standard_form(lp::LPProblem; verbose::Bool=false) -> LPProblem

Convert a general linear programming (LP) problem into standard form.

### Standard Form:
In the standard form of an LP problem:
- The objective function is always **minimized**.
- All constraints are **equalities** (i.e., of the form `Ax = b`).
- All variables are **non-negative** (i.e., `x ≥ 0`).

### Arguments:
- `lp::LPProblem`: The original linear programming problem to be converted. 
    - This problem can be a maximization or minimization problem.
    - Constraints can be inequalities (`≤`, `≥`) or equalities (`=`).
    - Variables can have bounds (upper and lower), including negative lower bounds.
- `verbose::Bool=false`: Optional flag to enable detailed output during the conversion process. 
    - If `true`, prints step-by-step information about the conversion, including:
        - Initial problem details.
        - Conversion of maximization to minimization (if applicable).
        - Transformation of inequalities into equalities.
        - Final problem details in standard form.

### Returns:
- A new `LPProblem` in standard form:
    - The objective function will be converted to a **minimization** problem.
    - All inequality constraints (`≤`, `≥`) are converted to **equalities** by adding slack or surplus variables.
    - Variables with negative lower bounds will be shifted to ensure **non-negativity**.
    - Slack variables are introduced as new non-negative variables for each `≤` constraint, and surplus variables for each `≥` constraint.

### Process:
1. **Objective Function**: 
   - If the original problem is a maximization problem, the objective function is negated to convert it into a minimization problem.
   
2. **Constraints**: 
   - For each `≤` constraint, a slack variable is added to convert it into an equality.
   - For each `≥` constraint, a surplus variable is added to convert it into an equality.
   - All equality constraints remain unchanged.
   
3. **Variables**:
   - Variables with negative lower bounds are shifted to ensure they are non-negative in the standard form.
   - Slack and surplus variables are introduced and added to the constraint matrix.

### Verbose Output:
If `verbose=true`, the function will print:
1. Initial problem details (objective function, constraints matrix, right-hand side, and constraint types).
2. Information on the conversion of a maximization problem to minimization (if applicable).
3. Details about the introduction of slack and surplus variables for each inequality constraint.
4. The final problem representation in standard form, including the new objective function, updated constraint matrix, and right-hand side.

### Example:
```julia
# Original problem with 2 variables and 3 constraints
lp = LPProblem(
    false,  # Maximize
    [3.0, 2.0],  # Objective function coefficients
    sparse([1, 2, 1, 3], [1, 1, 2, 2], [1.0, 1.0, 1.0, 1.0], 3, 2),  # Constraint matrix
    [4.0, 2.0, 3.0],  # Right-hand side
    ['L', 'L', 'L'],  # Constraints: less-than-or-equal-to
    [0.0, 0.0],  # Lower bounds
    [Inf, Inf],  # Upper bounds
    ["x1", "x2"],  # Variable names
    [:Continuous, :Continuous]  # Variable types
)

# Convert to standard form
standard_lp = convert_to_standard_form(lp)
```
In the example, the original mazimization problem is converted to a minimization problem, whith slack varibles for each ≤ contraint to convert the problem into standard form.
"""
function convert_to_standard_form(lp::LPProblem; verbose::Bool=false)::LPProblem
    if verbose
        println()
        println("#"^80)
        println("~"^80)
        println("Starting conversion to standard form...")
        println("~"^80)
    end

    # Unpack LP problem components
    is_minimize = lp.is_minimize
    c = copy(lp.c)
    A = copy(lp.A)
    b = copy(lp.b)
    constraint_types = copy(lp.constraint_types)
    l = copy(lp.l)
    u = copy(lp.u)
    vars = copy(lp.vars)
    variable_types = copy(lp.variable_types)

    m, n = size(A)  # Number of constraints and variables

    # Initialize counts and new structures
    slack_var_count = 0      # Counter for slack variables
    surplus_var_count = 0    # Counter for surplus variables
    artificial_var_count = 0 # Counter for artificial variables (if needed)
    new_vars = String[]      # Names of new variables
    new_variable_types = Symbol[]  # Types of new variables
    new_l = Float64[]        # Lower bounds for new variables
    new_u = Float64[]        # Upper bounds for new variables
    new_A_cols = spzeros(Float64, m, 0)  # Columns to be added to A

    if verbose
        println("Initial problem details:")
        println("Objective function coefficients (c): ", c)
        println("Constraint matrix (A):\n", Matrix(A))
        println("Right-hand side vector (b): ", b)
        println("Constraint types: ", constraint_types)
        println("Variable lower bounds (l): ", l)
        println("Variable upper bounds (u): ", u)
        println("-"^80)
    end

    # Step 1: Convert maximization to minimization (if necessary)
    if !is_minimize
        c = -c
        is_minimize = true
        if verbose
            println(
                "Converted maximization problem to minimization by negating the objective coefficients.",
            )
            println("New objective function coefficients (c): ", c)
            println("-"^80)
        end
    end

    # Step 2: Adjust variables with negative lower bounds to ensure non-negativity
    for j in 1:n
        if l[j] < 0
            shift_amount = -l[j]
            # Adjust the bounds
            l[j] += shift_amount  # l[j] becomes 0
            if isfinite(u[j])
                u[j] += shift_amount
            end
            # Adjust the corresponding column in A and the RHS vector b
            A_col = A[:, j]
            b -= A_col * shift_amount
            if verbose
                println("Variable $(vars[j]) has negative lower bound.")
                println("Shifting variable by ", shift_amount, " to make it non-negative.")
                println("Updated lower bound l[$j]: ", l[j])
                println("Updated upper bound u[$j]: ", u[j])
                println("Adjusted RHS vector (b): ", b)
                println("-"^80)
            end
        end
    end

    # Step 3: Add slack or surplus variables to convert inequalities to equalities
    new_constraint_types = fill('E', m)  # All constraints will be equalities
    for i in 1:m
        ct = constraint_types[i]
        if ct == 'L'
            # Initialize once before the loop (if known or can be estimated)
            rows, cols, vals = Int[], Int[], Float64[]

            # Add slack variable
            slack_var_count += 1
            slack_var_name = "s_$slack_var_count"
            append!(rows, i)  # Row index
            append!(cols, slack_var_count)  # Column index
            append!(vals, 1.0)  # Value

            push!(new_vars, slack_var_name)
            push!(new_variable_types, :Continuous)
            push!(new_l, 0.0)
            push!(new_u, Inf)

            if verbose
                println("Added slack variable '$slack_var_name' to constraint $i (<=).")
            end

            # After all slack variables are added
            new_A_cols = sparse(rows, cols, vals, m, slack_var_count)  # Final sparse matrix

        elseif ct == 'G'
            # Add surplus variable
            surplus_var_count += 1
            surplus_var_name = "r_$surplus_var_count"
            append!(rows, i)  # Row index
            append!(cols, slack_var_count + surplus_var_count)  # Column index (increment appropriately)
            append!(vals, -1.0)  # Value for surplus variable

            # Update metadata for the surplus variable
            push!(new_vars, surplus_var_name)
            push!(new_variable_types, :Continuous)
            push!(new_l, 0.0)
            push!(new_u, Inf)

            if verbose
                println("Added surplus variable '$surplus_var_name' to constraint $i (>=).")
            end
        elseif ct == 'E'
            # Equality constraint; no variable needed
            if verbose
                println("Constraint $i is an equality; no slack or surplus variable added.")
            end
        else
            error("Unknown constraint type: $(ct)")
        end
    end

    # Step 4: Update the constraint matrix A and objective function coefficients c
    A = hcat(A, new_A_cols)
    c = vcat(c, zeros(length(new_vars)))

    # Step 5: Update variable lists and bounds
    vars = vcat(vars, new_vars)
    variable_types = vcat(variable_types, new_variable_types)
    l = vcat(l, new_l)
    u = vcat(u, new_u)

    # Step 6: Ensure all variables are non-negative
    # At this point, all variables should be non-negative due to the earlier adjustments

    # Final verbose output
    if verbose
        println("-"^80)
        println("Final problem in standard form:")
        println("Objective function coefficients (c): ", c)
        println("Constraint matrix (A):\n", Matrix(A))
        println("Right-hand side vector (b): ", b)
        println("Constraint types: ", new_constraint_types)
        println("Variable names: ", vars)
        println("Variable types: ", variable_types)
        println("Variable lower bounds (l): ", l)
        println("Variable upper bounds (u): ", u)
        println("~"^80)
        println("Conversion to standard form completed.")
        println("#"^80)
        println()
    end

    # Return the modified LP problem in standard form
    return LPProblem(
        is_minimize,          # Objective is now minimization
        c,                    # Updated objective function coefficients
        A,                    # Updated constraint matrix
        b,                    # Updated RHS vector
        new_constraint_types, # All constraints are equalities
        l,                    # Updated lower bounds
        u,                    # Updated upper bounds
        vars,                 # Updated variable names
        variable_types,        # Updated variable types
    )
end
