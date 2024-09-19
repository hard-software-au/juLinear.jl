module lp_standard_form_converter

using SparseArrays
using lp_problem

# Export the functions
export convert_to_standard_form

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
function convert_to_standard_form(lp::LPProblem; verbose::Bool = false)::LPProblem
    if verbose
        println()
        println("#" ^ 80)
        println("~" ^ 80)
        println("convert_to_standard_form")
        println("~" ^ 80)
    end

    is_minimize = lp.is_minimize
    c = lp.c
    A = lp.A
    b = lp.b
    constraint_types = copy(lp.constraint_types)
    l = lp.l
    u = lp.u
    vars = lp.vars
    variable_types = lp.variable_types
    
    m, n = size(A)
    
    # Initialize new sparse matrix for slack variables
    new_A_rows = spzeros(Float64, m, 0)  # Start with no slack variables
    new_b = copy(b)
    new_constraint_types = copy(constraint_types)
    slack_var_count = 0

    if verbose
        println("Initial problem details:")
        println("Objective function: ", c)
        println("Constraints matrix (A): ", A)
        println("Right-hand side (b): ", b)
        println("Constraint types: ", constraint_types)
    end

    # Handle less-than-or-equal-to (L) constraints by adding slack variables
    for i in 1:m
        if constraint_types[i] == 'L'
            slack_var_count += 1
            # Add a new slack variable
            slack_column = sparsevec([i], [1.0], m)  # Slack variable only affects the current row
            new_A_rows = hcat(new_A_rows, slack_column)  # Add slack variable to the matrix
            
            # Update variable names and types
            push!(vars, "s_$slack_var_count")
            push!(variable_types, :Continuous)
        end
    end
    
    # Combine original matrix A with the new slack variables matrix
    A_with_slack = hcat(A, new_A_rows)
    
    # Adjust the objective function to account for slack variables (with coefficient 0)
    new_c = vcat(c, zeros(slack_var_count))
    
    # If the original problem was a maximization, negate the objective coefficients
    if !is_minimize
        new_c = -new_c
        if verbose
            println("~" ^ 80)
            println("Maximization converted to minimization:")
            println("New objective: ", new_c)
        end
    end
    
    # Convert all constraints to equalities
    new_constraint_types .= 'E'

    if verbose
        println("~" ^ 80)
        println("Final problem in standard form:")
        println("Objective function: ", new_c)
        println("Constraints matrix (A): ", A_with_slack)
        println("Right-hand side (b): ", new_b)
        println("~" ^ 80)
        println("#" ^ 80)
        println()
    end

    # Return the modified LP problem in standard form
    return LPProblem(
        true,  # Standard form requires minimization
        new_c,  # Updated objective function
        A_with_slack,  # Updated constraint matrix with slack variables
        new_b,  # Right-hand side vector remains the same
        new_constraint_types,  # All constraints are now equalities
        l,  # Lower bounds for original variables
        fill(Inf, n + slack_var_count),  # Upper bounds (infinity for all variables)
        vars,  # Variable names including slack variables
        variable_types  # Variable types
    )
end



end # module