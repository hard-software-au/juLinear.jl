module lp_presolve

using DataStructures
using lp_problem

export lp_detect_and_remove_fixed_variables, presolve_lp, lp_remove_zero_rows, lp_remove_row_singletons, lp_remove_zero_columns, lp_remove_linearly_dependent_rows


##############################################################################
#### lp_detect_and_remove_fixed_variables
##############################################################################

"""
    lp_detect_and_remove_fixed_variables(lp_model::PreprocessedLPProblem; ε::Float64 = 1e-8, verbose::Bool = false)

Detects and removes variables from the LP problem where the lower and upper bounds are equal (fixed variables). 
These fixed variables are removed from the reduced problem, and their values are stored for postsolve.

# Arguments:
- `lp_model::PreprocessedLPProblem`: The preprocessed LP or MIP problem before fixed variable removal.
- `ε::Float64 = 1e-8`: Tolerance for determining if a variable is fixed (i.e., when `|l[i] - u[i]| < ε`).
- `verbose::Bool = false`: If true, debug information is printed during the process.

# Returns:
- `PreprocessedLPProblem`: A new preprocessed LP or MIP problem with the fixed variables removed and stored.

# Behavior:
1. **Fixed Variables**: Variables where the lower bound (`l[i]`) is approximately equal to the upper bound (`u[i]`) are considered fixed and removed from the problem.
2. **Variable Solutions**: The fixed variable values are stored in the `var_solutions` dictionary for postsolve.
3. **Reduced Problem**: The reduced problem is created with the fixed variables removed, adjusting the objective function, constraint matrix, bounds, variable names, and variable types.
4. **Row and Column Adjustments**: Contributions of the fixed variables are subtracted from the right-hand side of the constraints.

# Example:
```julia
lp_model = PreprocessedLPProblem(
    original_problem = original_lp,  # Original problem before preprocessing
    reduced_problem = reduced_lp,    # Reduced problem after preprocessing
    removed_rows = [],               # No rows removed yet
    removed_cols = [],               # No columns removed yet
    row_ratios = Dict(),             # No row reductions
    var_solutions = Dict()           # Variable solutions not yet filled
)

# Call the function to detect and remove fixed variables
lp_detect_and_remove_fixed_variables(lp_model; verbose=true)
```
"""
function lp_detect_and_remove_fixed_variables(lp_model::PreprocessedLPProblem; ε::Float64 = 1e-8, verbose::Bool = false)
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
    fixed_vars = [i for i in 1:length(reduced_lp.vars) if abs(reduced_lp.l[i] - reduced_lp.u[i]) < ε]
    new_removed_cols = setdiff(1:length(reduced_lp.vars), fixed_vars)

    # Store the fixed variable names and their solved values in var_solutions
    for i in fixed_vars
        var_solutions[reduced_lp.vars[i]] = reduced_lp.l[i]  # Store the variable name and its fixed value
    end

    # Debug statements
    if verbose
        println("#" ^ 80)
        println("~" ^ 80)
        println("Fixed Variable Detection")
        println("~" ^ 80)
        println("Total number of variables: ", length(reduced_lp.vars))
        println("Fixed variables: ", fixed_vars)
        println("Non-fixed variables: ", new_removed_cols)
        println("The objective coefficients after removal: ", reduced_lp.c[new_removed_cols])
        println("Fixed variable values (var_solutions): ", var_solutions)
        println("~" ^ 80)
        println("#" ^ 80)
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
    new_A = reduced_lp.A[:, new_removed_cols]
    new_c = reduced_lp.c[new_removed_cols]
    new_l = reduced_lp.l[new_removed_cols]
    new_u = reduced_lp.u[new_removed_cols]
    new_vars = reduced_lp.vars[new_removed_cols]
    new_constraint_types = reduced_lp.constraint_types
    new_variable_types = reduced_lp.variable_types[new_removed_cols]  # Ensure variable types are adjusted too

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
        new_variable_types  # Include variable types in the new LPProblem
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
        is_infeasible
    )
end



##############################################################################
#### lp_remove_zero_rows
##############################################################################

"""
    lp_remove_zero_rows(preprocessed_problem::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool = false)

Detects and removes rows from the LP problem where all entries in the constraint matrix `A` are effectively zero (based on the threshold `ε`). Variables are preserved unless their entire corresponding columns are zero, which is not the case in this function.

# Arguments:
- `preprocessed_problem::PreprocessedLPProblem`: The LP or MIP problem that has been preprocessed.
- `ε::Float64 = 1e-8`: Tolerance to determine whether an entry in the matrix `A` is considered zero.
- `verbose::Bool = false`: If true, debug information is printed during the row removal process.

# Returns:
- `PreprocessedLPProblem`: The updated preprocessed LP problem after removing zero rows.

# Behavior:
1. **Zero Row Detection**: Identifies rows in the constraint matrix `A` where all elements are effectively zero (within the given tolerance `ε`).
2. **Row Removal**: Removes the identified zero rows from the constraint matrix, the right-hand side `b`, and the constraint types.
3. **Variable Preservation**: Variables (columns) are preserved in the reduced problem unless their entire corresponding columns are zero. In this case, no variables are removed.
4. **Row Ratios Update**: The function updates the `row_ratios` dictionary to keep track of removed rows.

# Example:
```julia
# Create a PreprocessedLPProblem
preprocessed_lp = PreprocessedLPProblem(
    original_problem,  # Original LP or MIP problem
    reduced_problem,  # Reduced problem (initially identical to original)
    Int[],  # No rows removed initially
    Int[],  # No columns removed initially
    Dict{Int, Tuple{Int, Float64}}(),  # No row ratios initially
    Dict{String, Float64}(),  # No variable solutions initially
    Float64[],  # No row scaling initially
    Float64[],  # No column scaling initially
    false  # Problem is not infeasible initially
)

# Run the function to remove zero rows
lp_remove_zero_rows(preprocessed_lp; verbose=true)
```
"""
function lp_remove_zero_rows(preprocessed_problem::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool = false)
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

    # Find non-zero rows
    non_zero_rows = [i for i in 1:size(reduced_lp.A, 1) if any(abs.(reduced_lp.A[i, :]) .> ε)]
    new_removed_rows = setdiff(1:size(reduced_lp.A, 1), non_zero_rows)

    # Debug statements
    if verbose 
        println("#" ^ 80)
        println("~" ^ 80)
        println("Remove rows function")
        println("~" ^ 80)
        println("The number of rows: ", size(reduced_lp.A, 1))
        println("The non-zero rows: ", non_zero_rows)
        println("The removed rows are: ", new_removed_rows)
        println("~" ^ 80)
        println("#" ^ 80)
        println()
    end

    # Update the row ratios dictionary
    for removed_row in new_removed_rows
        row_ratios[removed_row + length(removed_rows)] = (removed_row + length(removed_rows), 0.0)
    end

    # Adjust the problem based on non-zero rows
    new_A = reduced_lp.A[non_zero_rows, :]
    new_b = reduced_lp.b[non_zero_rows]
    new_constraint_types = reduced_lp.constraint_types[non_zero_rows]

    # Here, we do not remove any variables unless their entire column is zero.
    # Ensure all variables are kept unless their entire column is zero in the reduced matrix.
    new_A = new_A[:, :]  # Keep all columns unless explicitly zero across all rows.
    new_c = reduced_lp.c  # Keep original objective coefficients.
    new_l = reduced_lp.l  # Keep original lower bounds.
    new_u = reduced_lp.u  # Keep original upper bounds.
    new_vars = reduced_lp.vars  # Keep original variable names.
    new_variable_types = reduced_lp.variable_types  # Keep original variable types.

    # Construct the reduced LPProblem
    new_reduced_lp = LPProblem(
        reduced_lp.is_minimize, 
        new_c, 
        new_A, 
        new_b, 
        new_constraint_types, 
        new_l, 
        new_u, 
        new_vars, 
        new_variable_types
    )

    # Return the updated PreprocessedLPProblem struct
    return PreprocessedLPProblem(
        original_lp,
        new_reduced_lp,
        vcat(removed_rows, new_removed_rows),
        removed_cols,  # Variables aren't removed in this process
        row_ratios,
        var_solutions,
        row_scaling,
        col_scaling,
        is_infeasible
    )
end



##############################################################################
#### lp_remove_row_singletons
##############################################################################

"""
    lp_remove_zero_columns(preprocessed_lp::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool=false)

Removes columns from the constraint matrix `A` of the `PreprocessedLPProblem` that consist only of zeros.

# Arguments:
- `preprocessed_lp`: The `PreprocessedLPProblem` struct containing the original and reduced problem.
- `ε`: Threshold below which values are considered zero. Defaults to `1e-8`.
- `verbose`: If `true`, prints debugging information. Defaults to `false`.

# Returns:
A new `PreprocessedLPProblem` with columns removed from the reduced problem.
"""
function lp_remove_row_singletons(lp_model::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool = false)
    # Unpack problem
    original_lp = lp_model.original_problem
    reduced_lp = lp_model.reduced_problem
    removed_rows = lp_model.removed_rows
    removed_cols = lp_model.removed_cols
    row_ratios = lp_model.row_ratios
    var_solutions = preprocessed_problem.var_solutions

    # Find row singletons
    # singleton_rows = [i for i in 1:size(reduced_lp.A, 1) if count(!iszero, reduced_lp.A[i, :]) == 1]
    singleton_rows = [i for i in 1:size(reduced_lp.A, 1) if count(!iszero, reduced_lp.A[i, :]) == 1 && reduced_lp.b[i] == 0 && reduced_lp.constraint_types[i] != "<="]
    non_singleton_rows = setdiff(1:size(reduced_lp.A, 1), singleton_rows)
    # non_singleton_rows = [i for i in 1:size(reduced_lp.A, 1) if count(!iszero, reduced_lp.A[i, :]) > 1]
    new_removed_rows = setdiff(1:size(reduced_lp.A, 1), non_singleton_rows)


    # Debug statements
    if verbose
        println("#" ^ 80)
        println("~" ^ 80)
        println("Remove row singletons function")
        println("~" ^ 80)
        println("The number of rows: ", size(reduced_lp.A, 1))
        println("The row singletons: ", singleton_rows)
        println("The removed rows are: ", new_removed_rows)
        println("~" ^ 80)
        println("#" ^ 80)
        println()
    end

    # Update the row ratios dictionary
    for removed_row in new_removed_rows
        row_ratios[removed_row + length(removed_rows)] = (removed_row + length(removed_rows), 0.0)
    end

    # Create new LPProblem with non-row singletons
    new_A = reduced_lp.A[non_singleton_rows, :]
    new_b = reduced_lp.b[non_singleton_rows]
    new_constraint_types = reduced_lp.constraint_types[non_singleton_rows]


    # Construct the reduced LPProblem
    new_reduced_lp = LPProblem(reduced_lp.is_minimize, reduced_lp.c, new_A, new_b, reduced_lp.l, reduced_lp.u, reduced_lp.vars, new_constraint_types)

    # Return the updated PreprocessedLPProblem struct
    return PreprocessedLPProblem(
        original_lp,
        new_reduced_lp,
        vcat(removed_rows, new_removed_rows),
        removed_cols,
        row_ratios,
        var_solutions
    )
end


##############################################################################
#### lp_remove_zero_columns
##############################################################################

"""
    lp_remove_linearly_dependent_rows(preprocessed_lp::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool=false)

Removes linearly dependent rows from the constraint matrix `A` of the `PreprocessedLPProblem`. Detects and eliminates rows that are linear combinations of other rows.

# Arguments:
- `preprocessed_lp`: The `PreprocessedLPProblem` struct containing the original and reduced problem.
- `ε`: Threshold below which values are considered zero. Defaults to `1e-8`.
- `verbose`: If `true`, prints debugging information. Defaults to `false`.

# Returns:
A new `PreprocessedLPProblem` with linearly dependent rows removed.
"""
function lp_remove_zero_columns(preprocessed_lp::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool=false)
    # Find non-zero columns
    non_zero_columns = [j for j in 1:size(preprocessed_lp.reduced_problem.A, 2) if any(abs.(preprocessed_lp.reduced_problem.A[:, j]) .> ε)]
    new_removed_columns = setdiff(1:size(preprocessed_lp.reduced_problem.A, 2), non_zero_columns)

    # Debug statements
    if debug
        println("#" ^ 80)
        println("~" ^ 80)
        println("Remove columns function")
        println("~" ^ 80)
        println("The number of columns: ", size(preprocessed_lp.reduced_problem.A, 2))
        println("The non-zero columns: ", non_zero_columns)
        println("The removed columns are: ", new_removed_columns)
        println("~" ^ 80)
        println("#" ^ 80)
        println()
    end

    # Create new LPProblem without zero columns
    new_c = preprocessed_lp.reduced_problem.c[non_zero_columns]
    new_A = preprocessed_lp.reduced_problem.A[:, non_zero_columns]
    new_l = preprocessed_lp.reduced_problem.l[non_zero_columns]
    new_u = preprocessed_lp.reduced_problem.u[non_zero_columns]
    new_vars = preprocessed_lp.reduced_problem.vars[non_zero_columns]
    var_solutions = preprocessed_problem.var_solutions

    # Construct the reduced LPProblem
    new_reduced_lp = LPProblem(preprocessed_lp.reduced_problem.is_minimize, new_c, new_A, preprocessed_lp.reduced_problem.b, new_l, new_u, new_vars, preprocessed_lp.reduced_problem.constraint_types)

    # Return the updated PreprocessedLPProblem struct
    return PreprocessedLPProblem(
        preprocessed_lp.original_problem,
        new_reduced_lp,
        preprocessed_lp.removed_rows,
        new_removed_columns,
        preprocessed_lp.row_ratios,
        var_solutions
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
function lp_remove_linearly_dependent_rows(preprocessed_lp::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool=false)
    # Create the augmented matrix [A b]
    augmented_matrix = hcat(preprocessed_lp.reduced_problem.A, preprocessed_lp.reduced_problem.b)
    
    rows_to_check = collect(1:size(augmented_matrix, 1))  # Start with all rows to check
    removed_rows = Vector{Int}()  # List of removed rows
    row_ratios = Dict{Int, Tuple{Int, Float64}}()  # Store ratios of removed rows

    
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
    row_ratios = SortedDict(row_ratios)

    # Debug statments
    if verbose
        # Debug block
        println("#" ^ 80)
        println("~" ^ 80)
        println("Remove linearly dependent rows function")
        println("~" ^ 80)
        println("Removed rows: ", removed_rows)
        println()
        println("The row ratios: ")
        for (row, ratio) in row_ratios
            println("    ", row, " => ", ratio)
        end
        println("~" ^ 80)
        println("#" ^ 80)
        println()
    end
    
    # Create the reduced matrix and vectors by excluding the removed rows
    non_removed_rows = setdiff(1:size(preprocessed_lp.reduced_problem.A, 1), removed_rows)
    reduced_A = preprocessed_lp.reduced_problem.A[non_removed_rows, :]
    reduced_b = preprocessed_lp.reduced_problem.b[non_removed_rows]
    reduced_constraint_types = preprocessed_lp.reduced_problem.constraint_types[non_removed_rows]

    # Construct the reduced LPProblem
    reduced_lp = LPProblem(
        preprocessed_lp.reduced_problem.is_minimize,
        preprocessed_lp.reduced_problem.c,
        reduced_A,
        reduced_b,
        preprocessed_lp.reduced_problem.l,
        preprocessed_lp.reduced_problem.u,
        preprocessed_lp.reduced_problem.vars,
        reduced_constraint_types
    )

    var_solutions = preprocessed_problem.var_solutions
    
    # Return the updated PreprocessedLPProblem struct
    return PreprocessedLPProblem(
        preprocessed_lp.original_problem,
        reduced_lp,
        vcat(preprocessed_lp.removed_rows, removed_rows),
        preprocessed_lp.removed_cols,
        row_ratios,
        var_solutions 
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
    preprocessed_lp = PreprocessedLPProblem(lp_problem, lp_problem, Int[], Int[], Dict())

    # Preprocessing methods
    preprocessed_lp = lp_detect_and_remove_fixed_variables(preprocessed_lp; verbose=verbose)

    preprocessed_lp = lp_remove_zero_rows(preprocessed_lp; verbose=verbose)
    preprocessed_lp = lp_remove_row_singletons(preprocessed_lp, verbose=verbose)


    preprocessed_lp = lp_remove_zero_columns(preprocessed_lp; verbose=verbose)


    preprocessed_lp = lp_remove_linearly_dependent_rows(preprocessed_lp, verbose=verbose)

    
    return preprocessed_lp
end

end # module lp_presolve