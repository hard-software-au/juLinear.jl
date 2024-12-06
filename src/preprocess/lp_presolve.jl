##############################################################################
#### lp_detect_and_remove_fixed_variables
##############################################################################

"""
lp_detect_and_remove_fixed_variables(lp_model::PreprocessedLPProblem; ε::Float64 = 1e-8, verbose::Bool = false)

Detects and removes fixed variables from an LP or MIP problem within a presolve module. A variable is considered fixed if its lower and upper bounds are approximately equal within a specified tolerance. The function removes these variables from the reduced problem and stores their values for the postsolve phase.

# Parameters
- `lp_model::PreprocessedLPProblem`: The preprocessed LP or MIP problem before fixed variable removal.
- `ε::Float64 = 1e-8`: Tolerance used to determine if a variable is fixed (i.e., when `|l[i] - u[i]| < ε`).
- `verbose::Bool = false`: If `true`, prints detailed debug information during processing.

# Returns
- `PreprocessedLPProblem`: A new `PreprocessedLPProblem` instance with:
  - `reduced_problem`: Updated by removing fixed variables and adjusting related data structures.
  - `var_solutions`: Updated with the fixed variable values for the postsolve phase.
  - `removed_cols`: Updated to include indices of the removed (fixed) variables.
  - Other fields (`removed_rows`, `row_ratios`, `row_scaling`, `col_scaling`, `is_infeasible`) remain unchanged unless affected by this operation.

# Behavior
1. **Fixed Variable Detection**: Identifies variables where `|l[i] - u[i]| < ε` and considers them fixed.
2. **Variable Solutions Storage**: Stores the values of fixed variables in `var_solutions`.
3. **Problem Reduction**: Creates a new `reduced_problem` without the fixed variables, adjusting:
   - Objective function coefficients (`c`).
   - Constraint matrix (`A`).
   - Right-hand side vector (`b`).
   - Variable bounds (`l` and `u`).
   - Variable names (`vars`) and types (`variable_types`).
4. **Constraint Adjustment**: Subtracts the contributions of fixed variables from the right-hand side of constraints.

# Examples
```
using SparseArrays

# Define the original LP problem
c = [1.0, 2.0, 4.0]  # Objective function coefficients
A = sparse([1.0 -3.0 0.0; 2.0 1.0 -5.0])  # Constraint matrix
b = [10.0, 15.0]  # Right-hand side vector
l = [12.0, 0.0, 2.0]  # Lower bounds (x1 and x3 are fixed)
u = [12.0, 1.0, 2.0]  # Upper bounds
vars = ["x1", "x2", "x3"]  # Variable names
constraint_types = ['L', 'L']  # Constraint types ('L' for ≤)
variable_types = [:continuous, :continuous, :continuous]  # Variable types

# Create the original LPProblem
original_lp = LPProblem(
    is_minimize = false,
    c = c,
    A = A,
    b = b,
    constraint_types = constraint_types,
    l = l,
    u = u,
    vars = vars,
    variable_types = variable_types
)

# Initialize the PreprocessedLPProblem
lp_model = PreprocessedLPProblem(
    original_problem = original_lp,
    reduced_problem = original_lp,  # Initially the same as the original
    removed_rows = Int[],           # No rows removed yet
    removed_cols = Int[],           # No columns removed yet
    row_ratios = Dict{Int, Tuple{Int, Float64}}(),  # No row reductions yet
    var_solutions = Dict{String, Float64}(),        # Variable solutions not yet filled
    row_scaling = Float64[],                        # No row scaling applied
    col_scaling = Float64[],                        # No column scaling applied
    is_infeasible = false                           # Problem is feasible initially
)

# Detect and remove fixed variables
new_lp_model = lp_detect_and_remove_fixed_variables(lp_model; verbose = true)

# Output the reduced problem
println("Reduced Problem after fixed variable removal:")
println(new_lp_model.reduced_problem)

# Output the fixed variable solutions
println("Fixed Variable Solutions:")
println(new_lp_model.var_solutions)
```

# Notes
- **In-Place Modification**: This function does not modify `lp_model` in place; it returns a new instance with updated fields.
- **Infeasibility Check**: If removing fixed variables leads to an infeasible problem, the `is_infeasible` flag is set to `true`.
- **Integration**: This function is typically used as part of a sequence of presolve operations to simplify LP/MIP problems before optimization.

# See Also
- `lp_detect_and_remove_row_singletons`
- `lp_detect_and_remove_column_singletons`
- `lp_bound_tightening`
"""
function lp_detect_and_remove_fixed_variables(
    lp_model::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool=false
)
    # Unpack the original and reduced problems
    original_lp = lp_model.original_problem
    reduced_lp = lp_model.reduced_problem
    removed_rows = lp_model.removed_rows
    removed_cols = lp_model.removed_cols
    row_ratios = lp_model.row_ratios
    var_solutions = lp_model.var_solutions
    row_scaling = lp_model.row_scaling
    col_scaling = lp_model.col_scaling
    is_infeasible = lp_model.is_infeasible

    # Detect fixed variables (where l == u)
    fixed_vars = [
        i for i in 1:length(reduced_lp.vars) if abs(reduced_lp.l[i] - reduced_lp.u[i]) < ε
    ]
    remaining_vars_indices = setdiff(1:length(reduced_lp.vars), fixed_vars)

    # Store the fixed variable names and their solved values in var_solutions
    for i in fixed_vars
        var_solutions[reduced_lp.vars[i]] = reduced_lp.l[i]  # Store the variable name and its fixed value
    end

    # Debug statements
    if verbose
        println("#"^80)
        println("~"^80)
        println("Fixed Variable Detection")
        println("~"^80)
        println("Total number of variables: ", length(reduced_lp.vars))
        println("Fixed variables: ", fixed_vars)
        println("Remaining variables: ", remaining_vars_indices)
        println(
            "The objective coefficients after removal: ",
            reduced_lp.c[remaining_vars_indices],
        )
        println("Fixed variable values (var_solutions): ", var_solutions)
        println("~"^80)
        println("#"^80)
        println()
    end

    if isempty(fixed_vars)
        # If no fixed variables are found, return the original problem unchanged
        return lp_model
    end

    # Adjust the right-hand side b by subtracting the contribution of the fixed variables
    contribution = reduced_lp.A[:, fixed_vars] * reduced_lp.l[fixed_vars]  # This returns a vector
    new_b = reduced_lp.b .- contribution  # Subtract the contribution from b

    # Create new LPProblem without fixed variables
    new_A = reduced_lp.A[:, remaining_vars_indices]
    new_c = reduced_lp.c[remaining_vars_indices]
    new_l = reduced_lp.l[remaining_vars_indices]
    new_u = reduced_lp.u[remaining_vars_indices]
    new_vars = reduced_lp.vars[remaining_vars_indices]
    new_constraint_types = reduced_lp.constraint_types
    new_variable_types = reduced_lp.variable_types[remaining_vars_indices]  # Ensure variable types are adjusted too

    # Check for infeasibility after adjusting constraints
    is_infeasible = false
    for i in 1:length(new_b)
        if new_constraint_types[i] == 'E' && norm(new_A[i, :], Inf) < ε
            if abs(new_b[i]) > ε
                is_infeasible = true
                if verbose
                    println(
                        "Infeasibility detected in constraint $i after removing fixed variables.",
                    )
                end
                break
            end
        end
    end

    # Remove zero rows if any
    zero_row_indices = [i for i in 1:size(new_A, 1) if norm(new_A[i, :], Inf) < ε]
    if !isempty(zero_row_indices)
        if verbose
            println("Removing zero rows: ", zero_row_indices)
        end
        new_A = new_A[setdiff(1:end, zero_row_indices), :]
        new_b = new_b[setdiff(1:end, zero_row_indices)]
        new_constraint_types = new_constraint_types[setdiff(1:end, zero_row_indices)]
        # Update removed_rows
        removed_rows = vcat(removed_rows, zero_row_indices)
    end

    # Create the reduced LP problem
    new_reduced_lp = LPProblem(
        reduced_lp.is_minimize,
        new_c,
        new_A,
        new_b,
        new_constraint_types,  # Updated order
        new_l,
        new_u,
        new_vars,
        new_variable_types,  # Include variable types in the new LPProblem
    )

    # Return updated PreprocessedLPProblem
    return PreprocessedLPProblem(
        original_lp,
        new_reduced_lp,
        removed_rows,
        vcat(removed_cols, fixed_vars),
        row_ratios,
        var_solutions,
        row_scaling,
        col_scaling,
        is_infeasible,
    )
end

##############################################################################
#### lp_remove_zero_rows
##############################################################################

"""
lp_remove_zero_rows(preprocessed_problem::PreprocessedLPProblem; ε::Float64 = 1e-8, verbose::Bool = false)

Removes zero rows (constraints) from the LP problem where all coefficients are approximately zero. This simplifies the problem by eliminating redundant constraints that do not affect the feasible region.

# Parameters
- `preprocessed_problem::PreprocessedLPProblem`: The LP or MIP problem to process.
- `ε::Float64 = 1e-8`: Tolerance used to determine if a coefficient is considered zero.
- `verbose::Bool = false`: If `true`, prints detailed debug information during processing.

# Returns
- `PreprocessedLPProblem`: A new `PreprocessedLPProblem` instance with:
  - `reduced_problem`: Updated by removing zero rows.
  - `removed_rows`: Updated to include indices of the removed rows.
  - `is_infeasible`: Set to `true` if an infeasibility is detected due to a zero row with a conflicting right-hand side.

# Behavior
1. **Zero Row Detection**: Identifies constraints where all coefficients in `A` are approximately zero within the tolerance `ε`.
2. **Infeasibility Check**: For zero rows corresponding to equality constraints with a non-zero right-hand side (`b`), the problem is marked as infeasible.
3. **Problem Reduction**: Creates a new `reduced_problem` without the zero rows, adjusting:
   - Constraint matrix (`A`).
   - Right-hand side vector (`b`).
   - Constraint types (`constraint_types`).
4. **Variables Unchanged**: Variable-related data (`c`, `l`, `u`, `vars`, `variable_types`) remain unchanged.

# Examples
```
using SparseArrays

# Define the original LP problem
c = [1.0, 2.0]  # Objective function coefficients
A = sparse([0.0 0.0; 1.0 -1.0])  # Constraint matrix with a zero row
b = [0.0, 5.0]  # Right-hand side vector
l = [0.0, 0.0]  # Lower bounds
u = [Inf, Inf]  # Upper bounds
vars = ["x1", "x2"]  # Variable names
constraint_types = ['E', 'L']  # Constraint types ('E' for =, 'L' for ≤)
variable_types = [:continuous, :continuous]  # Variable types

# Create the original LPProblem
original_lp = LPProblem(
    is_minimize = true,
    c = c,
    A = A,
    b = b,
    constraint_types = constraint_types,
    l = l,
    u = u,
    vars = vars,
    variable_types = variable_types
)

# Initialize the PreprocessedLPProblem
lp_model = PreprocessedLPProblem(
    original_problem = original_lp,
    reduced_problem = original_lp,  # Initially the same as the original
    removed_rows = Int[],           # No rows removed yet
    removed_cols = Int[],           # No columns removed yet
    row_ratios = Dict{Int, Tuple{Int, Float64}}(),  # No row reductions yet
    var_solutions = Dict{String, Float64}(),        # Variable solutions not yet filled
    row_scaling = Float64[],                        # No row scaling applied
    col_scaling = Float64[],                        # No column scaling applied
    is_infeasible = false                           # Problem is feasible initially
)

# Remove zero rows
new_lp_model = lp_remove_zero_rows(lp_model; verbose = true)

# Output the reduced problem
println("Reduced Problem after removing zero rows:")
println(new_lp_model.reduced_problem)

# Check for infeasibility
if new_lp_model.is_infeasible
    println("The problem is infeasible due to a zero row with a conflicting RHS.")
else
    println("Zero rows successfully removed.")
end
```

# Notes
- **Infeasibility Detection**: If a zero row corresponds to an equality constraint with a non-zero right-hand side, the problem is infeasible.
- **Sparse Matrix Efficiency**: The function leverages sparse matrix properties for efficient computation.
- **Integration**: This function can be used as part of a presolve routine to simplify LP/MIP problems before optimization.

# See Also
- `lp_detect_and_remove_fixed_variables`
- `lp_detect_and_remove_row_singletons`
- `lp_detect_and_remove_column_singletons`
"""
function lp_remove_zero_rows(
    preprocessed_problem::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool=false
)
    # Unpack problem
    original_lp = preprocessed_problem.original_problem
    reduced_lp = preprocessed_problem.reduced_problem
    removed_rows = preprocessed_problem.removed_rows
    removed_cols = preprocessed_problem.removed_cols
    row_ratios = preprocessed_problem.row_ratios
    var_solutions = preprocessed_problem.var_solutions
    row_scaling = preprocessed_problem.row_scaling
    col_scaling = preprocessed_problem.col_scaling
    is_infeasible = preprocessed_problem.is_infeasible

    A = reduced_lp.A
    b = reduced_lp.b
    constraint_types = reduced_lp.constraint_types

    # Efficiently find non-zero rows using the norm of each row
    non_zero_rows = []
    zero_rows = []

    for i in 1:size(A, 1)
        if norm(A[i, :], Inf) < ε
            push!(zero_rows, i)
        else
            push!(non_zero_rows, i)
        end
    end

    # Debug statements
    if verbose
        println("#"^80)
        println("~"^80)
        println("Remove Zero Rows Function")
        println("~"^80)
        println("Total number of rows: ", size(reduced_lp.A, 1))
        println("Non-zero rows: ", non_zero_rows)
        println("Removed zero rows: ", zero_rows)
        println("~"^80)
        println("#"^80)
        println()
    end

    # Check for infeasibility in zero rows
    for idx in zero_rows
        if constraint_types[idx] == 'E' && abs(b[idx]) > ε
            is_infeasible = true
            if verbose
                println(
                    "Infeasibility detected due to zero row at index $idx with non-zero RHS.",
                )
            end
            break
        end
    end

    if is_infeasible
        # Return early if problem is infeasible
        return PreprocessedLPProblem(
            original_lp,
            reduced_lp,
            vcat(removed_rows, zero_rows),
            removed_cols,
            row_ratios,
            var_solutions,
            row_scaling,
            col_scaling,
            true,  # is_infeasible set to true
        )
    end

    # Adjust the problem based on non-zero rows
    new_A = A[non_zero_rows, :]
    new_b = b[non_zero_rows]
    new_constraint_types = constraint_types[non_zero_rows]

    # Construct the reduced LPProblem (variables remain unchanged)
    new_reduced_lp = LPProblem(
        reduced_lp.is_minimize,
        reduced_lp.c,
        new_A,
        new_b,
        new_constraint_types,
        reduced_lp.l,
        reduced_lp.u,
        reduced_lp.vars,
        reduced_lp.variable_types,
    )

    # Return the updated PreprocessedLPProblem struct
    return PreprocessedLPProblem(
        original_lp,
        new_reduced_lp,
        vcat(removed_rows, zero_rows),
        removed_cols,  # Variables aren't removed in this process
        row_ratios,    # Update if necessary
        var_solutions,
        row_scaling,
        col_scaling,
        is_infeasible,
    )
end

##############################################################################
#### lp_remove_row_singletons
##############################################################################

"""
lp_remove_row_singletons(lp_model::PreprocessedLPProblem; ε::Float64 = 1e-8, verbose::Bool = false)

Identifies and processes row singletons in an LP or MIP problem. A row singleton is a constraint involving only one variable. The function adjusts variable bounds or fixes variables as appropriate, simplifies the problem, and updates the `PreprocessedLPProblem` struct.

# Parameters
- `lp_model::PreprocessedLPProblem`: The preprocessed LP or MIP problem before processing row singletons.
- `ε::Float64 = 1e-8`: Tolerance used to handle numerical precision issues.
- `verbose::Bool = false`: If `true`, prints detailed debug information during processing.

# Returns
- `PreprocessedLPProblem`: A new `PreprocessedLPProblem` instance with:
  - `reduced_problem`: Updated by processing row singletons.
  - `removed_rows`: Updated with indices of the removed singleton rows.
  - `removed_cols`: Updated with indices of variables removed (if any).
  - `var_solutions`: Updated with values of any variables fixed during processing.
  - `is_infeasible`: Set to `true` if an infeasibility is detected.

# Behavior
1. **Row Singleton Detection**: Identifies constraints involving only one variable.
2. **Processing**:
   - For **equality constraints ('E')**:
     - Solves for the variable and fixes its value.
     - Removes the variable and the constraint from the problem.
   - For **less-than-or-equal constraints ('L')**:
     - Adjusts the variable's upper or lower bound depending on the coefficient.
     - Removes the constraint from the problem.
   - For **greater-than-or-equal constraints ('G')**:
     - Adjusts the variable's lower or upper bound depending on the coefficient.
     - Removes the constraint from the problem.
3. **Infeasibility Check**: If variable bounds become inconsistent after processing, the problem is marked as infeasible.
4. **Problem Reduction**: Updates the constraint matrix, right-hand side vector, variable bounds, objective function, and removes processed variables and constraints.

# Examples
```
using SparseArrays

# Define the original LP problem
c = [2.0, 3.0, 1.0]
A = sparse([
    1.0  0.0  0.0;  # Singleton row involving x1
    0.0  1.0  1.0;
    0.0  0.0  1.0   # Singleton row involving x3
])
b = [5.0, 10.0, 3.0]
l = [0.0, 0.0, 0.0]
u = [Inf, Inf, Inf]
vars = ["x1", "x2", "x3"]
constraint_types = ['E', 'L', 'E']
variable_types = [:continuous, :continuous, :continuous]

# Create the original LPProblem
original_lp = LPProblem(
    is_minimize = true,
    c = c,
    A = A,
    b = b,
    constraint_types = constraint_types,
    l = l,
    u = u,
    vars = vars,
    variable_types = variable_types
)

# Initialize the PreprocessedLPProblem
lp_model = PreprocessedLPProblem(
    original_problem = original_lp,
    reduced_problem = original_lp,  # Initially the same as the original
    removed_rows = Int[],           # No rows removed yet
    removed_cols = Int[],           # No columns removed yet
    row_ratios = Dict{Int, Tuple{Int, Float64}}(),  # No row reductions yet
    var_solutions = Dict{String, Float64}(),        # Variable solutions not yet filled
    row_scaling = Float64[],                        # No row scaling applied
    col_scaling = Float64[],                        # No column scaling applied
    is_infeasible = false                           # Problem is feasible initially
)

# Process row singletons
new_lp_model = lp_remove_row_singletons(lp_model; verbose = true)

# Output the reduced problem
println("Reduced Problem after processing row singletons:")
println(new_lp_model.reduced_problem)

# Output fixed variable solutions
println("Fixed Variable Solutions:")
println(new_lp_model.var_solutions)
```

# Notes
- **Infeasibility Detection**: If variable bounds conflict after processing, the problem is marked as infeasible.
- **Variable Removal**: Variables fixed during processing are removed from the problem.
- **Integration**: This function is part of a presolve routine to simplify LP/MIP problems before optimization.

# See Also
- `lp_detect_and_remove_fixed_variables`
- `lp_remove_zero_rows`
- `lp_detect_and_remove_column_singletons`
"""
function lp_remove_row_singletons(
    lp_model::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool=false
)
    # Unpack problem
    original_lp = lp_model.original_problem
    reduced_lp = lp_model.reduced_problem
    removed_rows = lp_model.removed_rows
    removed_cols = lp_model.removed_cols
    row_ratios = lp_model.row_ratios
    var_solutions = lp_model.var_solutions
    is_infeasible = lp_model.is_infeasible

    # Create copies to modify
    A = copy(reduced_lp.A)
    b = copy(reduced_lp.b)
    c = copy(reduced_lp.c)
    l = copy(reduced_lp.l)
    u = copy(reduced_lp.u)
    vars = copy(reduced_lp.vars)
    variable_types = copy(reduced_lp.variable_types)
    constraint_types = copy(reduced_lp.constraint_types)

    # Initialize lists to keep track of removals
    rows_to_remove = Int[]
    removed_vars_indices = Int[]
    singleton_rows = Int[]

    # Identify and process row singletons
    for row in 1:size(A, 1)
        # Find non-zero coefficients in the row
        nz_indices = findnz(A[row, :])[1]
        if length(nz_indices) == 1
            push!(singleton_rows, row)
            var_index = nz_indices[1]
            coef = A[row, var_index]
            rhs = b[row]
            constr_type = constraint_types[row]

            if abs(coef) < ε
                continue  # Skip if coefficient is effectively zero
            end

            if constr_type == 'E'
                # Equality constraint: Fix the variable
                var_value = rhs / coef
                l[var_index] = var_value
                u[var_index] = var_value
                var_solutions[vars[var_index]] = var_value

                # Remove the variable and constraint from the problem
                push!(removed_vars_indices, var_index)
                push!(rows_to_remove, row)

            elseif constr_type == 'L'
                # Less-than-or-equal constraint: Adjust upper or lower bound
                new_bound = rhs / coef
                if coef > 0
                    u[var_index] = min(u[var_index], new_bound)
                else
                    l[var_index] = max(l[var_index], new_bound)
                end
                push!(rows_to_remove, row)

            elseif constr_type == 'G'
                # Greater-than-or-equal constraint: Adjust lower or upper bound
                new_bound = rhs / coef
                if coef > 0
                    l[var_index] = max(l[var_index], new_bound)
                else
                    u[var_index] = min(u[var_index], new_bound)
                end
                push!(rows_to_remove, row)
            else
                continue  # Skip other constraint types
            end

            # Check for infeasibility
            if l[var_index] > u[var_index] + ε
                is_infeasible = true
                if verbose
                    println(
                        "Infeasibility detected at variable $(vars[var_index]) after processing row singleton at row $row.",
                    )
                end
                break
            end
        end
    end

    if is_infeasible
        return PreprocessedLPProblem(
            original_lp,
            reduced_lp,
            vcat(removed_rows, rows_to_remove),
            vcat(removed_cols, removed_vars_indices),
            row_ratios,
            var_solutions,
            lp_model.row_scaling,
            lp_model.col_scaling,
            true,
        )
    end

    # Remove rows and columns from the problem
    remaining_rows = setdiff(1:size(A, 1), rows_to_remove)
    remaining_cols = setdiff(1:size(A, 2), removed_vars_indices)

    # Compute remaining variables before modifying vars
    remaining_vars = vars[remaining_cols]

    # Verbose output matching previous functions
    if verbose
        println("#"^80)
        println("~"^80)
        println("Row Singleton Removal")
        println("~"^80)
        println("Total number of constraints: ", size(reduced_lp.A, 1))
        println("Singleton rows identified: ", singleton_rows)
        println("Removed rows: ", rows_to_remove)
        println("Variables fixed (if any): ", [vars[i] for i in removed_vars_indices])
        println("Variable solutions (var_solutions): ", var_solutions)
        println("Remaining variables: ", remaining_vars)
        println("Remaining constraints: ", length(remaining_rows))
        println("~"^80)
        println("#"^80)
        println()
    end

    # Now modify A, b, c, l, u, vars, variable_types, constraint_types
    A = A[remaining_rows, remaining_cols]
    b = b[remaining_rows]
    constraint_types = constraint_types[remaining_rows]
    c = c[remaining_cols]
    l = l[remaining_cols]
    u = u[remaining_cols]
    vars = vars[remaining_cols]
    variable_types = variable_types[remaining_cols]

    # Construct the new LPProblem
    new_reduced_lp = LPProblem(
        reduced_lp.is_minimize, c, A, b, constraint_types, l, u, vars, variable_types
    )

    # Update removed rows and columns
    removed_rows = vcat(removed_rows, rows_to_remove)
    removed_cols = vcat(removed_cols, removed_vars_indices)

    # Return the updated PreprocessedLPProblem
    return PreprocessedLPProblem(
        original_lp,
        new_reduced_lp,
        removed_rows,
        removed_cols,
        row_ratios,
        var_solutions,
        lp_model.row_scaling,
        lp_model.col_scaling,
        is_infeasible,
    )
end

##############################################################################
#### lp_remove_zero_columns
##############################################################################

"""
    lp_remove_zero_columns(preprocessed_lp::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool=false)

Removes variables corresponding to zero columns in the constraint matrix `A` from an LP or MIP problem. Variables that do not appear in any constraints are analyzed and set to values that optimize the objective function or satisfy bounds. The function updates the `PreprocessedLPProblem` accordingly.

# Parameters
- `preprocessed_lp::PreprocessedLPProblem`: The preprocessed LP or MIP problem before zero column removal.
- `ε::Float64=1e-8`: Tolerance used to determine if a coefficient is considered zero.
- `verbose::Bool=false`: If `true`, prints detailed debug information during processing.

# Returns
- `PreprocessedLPProblem`: A new `PreprocessedLPProblem` instance with:
  - `reduced_problem`: Updated by removing zero columns and adjusting variable values.
  - `removed_cols`: Updated to include indices of the removed columns (variables).
  - `var_solutions`: Updated with the values of variables corresponding to zero columns.
  - `is_infeasible`: Set to `true` if an infeasibility is detected due to unbounded variables.

# Behavior
1. **Zero Column Detection**: Identifies variables (columns) where all coefficients in `A` are approximately zero within the tolerance `ε`.
2. **Variable Processing**:
   - For each zero column variable, determines its value based on:
     - Objective function coefficient (`c[j]`).
     - Variable bounds (`l[j]` and `u[j]`).
     - Problem type (minimization or maximization).
   - Updates `var_solutions` with the variable's value.
   - Removes the variable from the problem.
3. **Infeasibility Check**: If a variable can improve the objective unboundedly and is unbounded in that direction, the problem is marked as infeasible.
4. **Problem Reduction**: Updates the constraint matrix `A`, objective coefficients `c`, variable bounds, and other relevant data structures by removing zero columns.

# Examples
```
using SparseArrays

# Define the original LP problem
c = [1.0, -2.0, 0.0]  # Objective function coefficients
A = sparse([1.0 2.0 0.0; 0.0 -1.0 0.0])  # Constraint matrix (third column is zero)
b = [4.0, -1.0]  # Right-hand side
l = [0.0, 0.0, 0.0]  # Lower bounds
u = [Inf, Inf, Inf]  # Upper bounds
vars = ["x1", "x2", "x3"]  # Variable names
constraint_types = ['L', 'G']  # Constraint types
variable_types = [:continuous, :continuous, :continuous]  # Variable types

# Create the original LPProblem
original_lp = LPProblem(
    is_minimize = true,
    c = c,
    A = A,
    b = b,
    constraint_types = constraint_types,
    l = l,
    u = u,
    vars = vars,
    variable_types = variable_types
)

# Initialize the PreprocessedLPProblem
preprocessed_lp = PreprocessedLPProblem(
    original_problem = original_lp,
    reduced_problem = original_lp,
    removed_rows = Int[],
    removed_cols = Int[],
    row_ratios = Dict{Int, Tuple{Int, Float64}}(),
    var_solutions = Dict{String, Float64}(),
    row_scaling = Float64[],
    col_scaling = Float64[],
    is_infeasible = false
)

# Remove zero columns
new_preprocessed_lp = lp_remove_zero_columns(preprocessed_lp; verbose = true)

# Output the reduced problem
println("Reduced Problem after removing zero columns:")
println(new_preprocessed_lp.reduced_problem)

# Output variable solutions
println("Variable solutions:")
println(new_preprocessed_lp.var_solutions)
```

# Notes
- **Unbounded Variables**: Variables with zero columns and unbounded in the direction of improving the objective function can lead to unboundedness. The problem is marked as infeasible in such cases.
- **Integration**: This function is typically used as part of a sequence of presolve operations to simplify LP/MIP problems before optimization.
- **Variable Removal**: Variables corresponding to zero columns are removed from the problem and their values are stored in `var_solutions`.

# See Also
- `lp_detect_and_remove_fixed_variables`
- `lp_remove_zero_rows`
- `lp_remove_row_singletons`
- `lp_detect_and_remove_column_singletons`
"""
function lp_remove_zero_columns(
    preprocessed_lp::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool=false
)
    # Unpack the reduced problem
    reduced_lp = preprocessed_lp.reduced_problem
    A = reduced_lp.A
    c = reduced_lp.c
    l = reduced_lp.l
    u = reduced_lp.u
    vars = reduced_lp.vars
    variable_types = reduced_lp.variable_types
    var_solutions = copy(preprocessed_lp.var_solutions)
    is_minimize = reduced_lp.is_minimize
    is_infeasible = preprocessed_lp.is_infeasible  # Initialize is_infeasible

    # Efficiently find non-zero columns using sparse matrix properties
    col_nnz = diff(A.colptr)
    non_zero_columns = findall(col_nnz .> 0)
    zero_columns = findall(col_nnz .== 0)

    # Initialize lists for variables to remove and their solutions
    vars_to_remove = Int[]
    new_var_solutions = Dict{String,Float64}()

    # Process zero columns
    for idx in zero_columns
        var_name = vars[idx]
        lb = l[idx]
        ub = u[idx]
        coef = c[idx]

        # Assume we will remove this variable
        push!(vars_to_remove, idx)

        # Handle unbounded variables
        if isinf(lb) || isinf(ub)
            if is_minimize
                if (coef > 0 && isinf(lb)) || (coef < 0 && isinf(ub))
                    # Objective can decrease unboundedly
                    is_infeasible = true
                    break
                else
                    # Set variable to bound that optimizes objective
                    var_value = (coef ≥ 0) ? lb : ub
                end
            else
                # Maximization problem
                if (coef > 0 && isinf(ub)) || (coef < 0 && isinf(lb))
                    # Objective can increase unboundedly
                    is_infeasible = true
                    break
                else
                    # Set variable to bound that optimizes objective
                    var_value = (coef ≥ 0) ? ub : lb
                end
            end
        else
            # Variable is bounded
            # Set variable to bound that optimizes objective
            if is_minimize
                var_value = (coef ≥ 0) ? lb : ub
            else
                var_value = (coef ≥ 0) ? ub : lb
            end
        end

        # Record variable value if not infeasible
        if !is_infeasible
            new_var_solutions[var_name] = var_value
        end
    end

    if verbose
        println("#"^80)
        println("~"^80)
        println("Zero Column Removal")
        println("~"^80)
        println("Total number of variables: ", length(vars))
        println("Zero columns identified: ", [vars[i] for i in zero_columns])
        println("Variables removed: ", [vars[i] for i in vars_to_remove])
        if is_infeasible
            println("Infeasibility detected during zero column removal.")
        else
            println("Variables fixed (if any): ", keys(new_var_solutions))
            println("Variable solutions (var_solutions): ", new_var_solutions)
            println("Remaining variables: ", vars[setdiff(1:end, vars_to_remove)])
        end
        println("~"^80)
        println("#"^80)
        println()
    end

    if is_infeasible
        # Return without modifying the problem further
        return PreprocessedLPProblem(
            preprocessed_lp.original_problem,
            reduced_lp,
            preprocessed_lp.removed_rows,
            vcat(preprocessed_lp.removed_cols, vars_to_remove),
            preprocessed_lp.row_ratios,
            var_solutions,  # Do not merge new_var_solutions as they may be invalid
            preprocessed_lp.row_scaling,
            preprocessed_lp.col_scaling,
            is_infeasible,
        )
    end

    # Update variables by removing zero columns
    remaining_vars_indices = setdiff(1:length(vars), vars_to_remove)
    new_c = c[remaining_vars_indices]
    new_A = A[:, remaining_vars_indices]
    new_l = l[remaining_vars_indices]
    new_u = u[remaining_vars_indices]
    new_vars = vars[remaining_vars_indices]
    new_variable_types = variable_types[remaining_vars_indices]

    # Construct the new LPProblem
    new_reduced_lp = LPProblem(
        is_minimize,
        new_c,
        new_A,
        reduced_lp.b,
        reduced_lp.constraint_types,
        new_l,
        new_u,
        new_vars,
        new_variable_types,
    )

    # Return the updated PreprocessedLPProblem struct
    return PreprocessedLPProblem(
        preprocessed_lp.original_problem,
        new_reduced_lp,
        preprocessed_lp.removed_rows,
        vcat(preprocessed_lp.removed_cols, vars_to_remove),
        preprocessed_lp.row_ratios,
        merge(var_solutions, new_var_solutions),
        preprocessed_lp.row_scaling,
        preprocessed_lp.col_scaling,
        is_infeasible,
    )
end

##############################################################################
#### lp_remove_linearly_dependent_rows
##############################################################################

"""
    lp_remove_linearly_dependent_rows(preprocessed_lp::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool=false)

Removes linearly dependent rows from the constraint matrix `A` of the `PreprocessedLPProblem`. Detects and eliminates rows that are linear combinations of other rows.

# Arguments:
- `preprocessed_lp`: The `PreprocessedLPProblem` struct containing the original and reduced problem.
- `ε`: Threshold below which values are considered zero. Defaults to `1e-8`.
- `verbose`: If true, prints debugging information. Defaults to `false`.

# Returns:
A new `PreprocessedLPProblem` with linearly dependent rows removed.
"""
function lp_remove_linearly_dependent_rows(
    preprocessed_lp::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool=false
)
    # Unpack the reduced problem
    reduced_lp = preprocessed_lp.reduced_problem

    # Create the augmented matrix [A b]
    augmented_matrix = @views hcat(reduced_lp.A, reduced_lp.b)

    rows_to_check = collect(1:size(augmented_matrix, 1))  # Start with all rows to check
    removed_rows = Vector{Int}()  # List of removed rows
    row_ratios = Dict{Int,Tuple{Int,Float64}}()  # Store ratios of removed rows

    while length(rows_to_check) > 1
        current_row_index = rows_to_check[1]
        current_row = augmented_matrix[current_row_index, :]

        for i in rows_to_check[2:end]
            compare_row = augmented_matrix[i, :]

            # Find the first non-zero index in the current_row
            non_zero_idx = findfirst(abs.(current_row) .> ε)

            if non_zero_idx !== nothing && compare_row[non_zero_idx] != 0
                ratio = current_row[non_zero_idx] / compare_row[non_zero_idx]

                # Check if multiplying the compare_row by ratio gives the current_row
                if all(abs.(current_row .- ratio .* compare_row) .< ε)
                    push!(removed_rows, i)  # Mark the row for removal
                    row_ratios[i] = (current_row_index, ratio)  # Store the row index and ratio
                end
            end
        end

        rows_to_check = setdiff(rows_to_check, [current_row_index; removed_rows])  # Remove current and dependent rows
    end

    # Sort row information
    removed_rows = sort(removed_rows)

    # Debug statements
    if verbose
        println("#"^80)
        println("~"^80)
        println("Remove Linearly Dependent Rows Function")
        println("~"^80)
        println("Removed rows: ", removed_rows)
        println("Row Ratios: ", row_ratios)
        println("~"^80)
        println("#"^80)
        println()
    end

    # Create the reduced matrix and vectors by excluding the removed rows
    non_removed_rows = setdiff(1:size(reduced_lp.A, 1), removed_rows)
    reduced_A = reduced_lp.A[non_removed_rows, :]
    reduced_b = reduced_lp.b[non_removed_rows]
    reduced_constraint_types = reduced_lp.constraint_types[non_removed_rows]

    # Construct the reduced LPProblem
    reduced_lp_problem = LPProblem(
        reduced_lp.is_minimize,
        reduced_lp.c,
        reduced_A,
        reduced_b,
        reduced_constraint_types,
        reduced_lp.l,
        reduced_lp.u,
        reduced_lp.vars,
        reduced_lp.variable_types,
    )

    # Return the updated PreprocessedLPProblem struct
    return PreprocessedLPProblem(
        preprocessed_lp.original_problem,
        reduced_lp_problem,
        vcat(preprocessed_lp.removed_rows, removed_rows),
        preprocessed_lp.removed_cols,
        merge(preprocessed_lp.row_ratios, row_ratios),
        preprocessed_lp.var_solutions,
        preprocessed_lp.row_scaling,
        preprocessed_lp.col_scaling,
        preprocessed_lp.is_infeasible,
    )
end

##############################################################################
##### Main Function #####
##############################################################################

"""
    presolve_lp(lp_problem::LPProblem; verbose::Bool=false)

Applies presolve routines to the given `LPProblem` to reduce the problem size by removing redundant rows and columns.

# Arguments:
- `lp_problem`: The `LPProblem` to be presolved.
- `verbose`: If `true`, prints debugging information for each presolve step. Defaults to `false`.

# Returns:
A `PreprocessedLPProblem` with a reduced problem that excludes zero rows, zero columns, singleton rows, and linearly dependent rows.
"""
function presolve_lp(lp_problem::LPProblem; verbose::Bool=false)
    # Initialize PreprocessedLPProblem
    preprocessed_lp = PreprocessedLPProblem(
        lp_problem,       # Original problem
        lp_problem,       # Reduced problem (initially same as original)
        Int[],            # No removed rows initially
        Int[],            # No removed columns initially
        Dict{Int,Tuple{Int,Float64}}(),  # No row ratios initially
        Dict{String,Float64}(),  # Empty variable solutions
        Vector{Float64}(),  # Empty row scaling
        Vector{Float64}(),  # Empty column scaling
        false,               # No infeasibility detected initially
    )

    # Apply preprocessing methods
    preprocessed_lp = lp_detect_and_remove_fixed_variables(preprocessed_lp; verbose=verbose)
    preprocessed_lp = lp_remove_zero_rows(preprocessed_lp; verbose=verbose)
    preprocessed_lp = lp_remove_row_singletons(preprocessed_lp; verbose=verbose)
    preprocessed_lp = lp_remove_zero_columns(preprocessed_lp; verbose=verbose)
    preprocessed_lp = lp_remove_linearly_dependent_rows(preprocessed_lp; verbose=verbose)

    return preprocessed_lp
end
