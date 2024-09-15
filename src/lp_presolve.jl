module lp_presolve

using DataStructures
using lp_problem

export presolve_lp, lp_remove_zero_rows, lp_remove_row_singletons, lp_remove_zero_columns, lp_remove_linearly_dependent_rows



##############################################################################
#### lp_remove_zero_rows
##############################################################################

"""
    lp_remove_zero_rows(preprocessed_problem::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool=false)

Removes rows from the constraint matrix `A` of the `PreprocessedLPProblem` that consist only of zeros. 

# Arguments:
- `preprocessed_problem`: The `PreprocessedLPProblem` struct that contains the original and reduced problem.
- `ε`: Threshold below which values are considered zero. Defaults to `1e-8`.
- `verbose`: If `true`, prints debugging information. Defaults to `false`.

# Returns:
A new `PreprocessedLPProblem` with rows removed from the reduced problem.
"""
function lp_remove_zero_rows(preprocessed_problem::PreprocessedLPProblem; ε::Float64=1e-8, verbose::Bool = false)
    # Unpack problem
    original_lp = preprocessed_problem.original_problem
    reduced_lp = preprocessed_problem.reduced_problem
    removed_rows = preprocessed_problem.removed_rows
    removed_cols = preprocessed_problem.removed_cols
    row_ratios = preprocessed_problem.row_ratios

    # Find non-zero rows
    non_zero_rows = [i for i in 1:size(reduced_lp.A, 1) if any(abs.(reduced_lp.A[i, :]) .> ε)]
    new_removed_rows = setdiff(1:size(reduced_lp.A, 1), non_zero_rows)

    # debug statements
    if verbose 
        println("#" ^ 80)
        println("~" ^ 80)
        println("Remove rows function")
        println("~" ^ 80)
        println("The number of rows: ",size(reduced_lp.A, 1))
        println("The non-zero rows: ", non_zero_rows)
        println("The removed rows are: ",new_removed_rows)
        println("~" ^ 80)
        println("#" ^ 80)
        println()
    end

    # Update the row ratios dictionary
    for removed_row in new_removed_rows
        row_ratios[removed_row + length(removed_rows)] = (removed_row + length(removed_rows), 0.0)
    end

    # Create new LPProblem with non-zero rows
    new_A = reduced_lp.A[non_zero_rows, :]
    new_b = reduced_lp.b[non_zero_rows]
    new_constraint_types = reduced_lp.constraint_types[non_zero_rows]

    # Construct the reduced LPProblem
    new_reduced_lp = LPProblem(reduced_lp.is_minimize, 
            reduced_lp.c, new_A, new_b, 
            reduced_lp.l, reduced_lp.u, reduced_lp.vars, 
            new_constraint_types)

    # Return the updated PreprocessedLPProblem struct
    return PreprocessedLPProblem(
        original_lp,
        new_reduced_lp,
        vcat(removed_rows, new_removed_rows),
        Int[],
        row_ratios
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
        Int[],
        row_ratios
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

    # Construct the reduced LPProblem
    new_reduced_lp = LPProblem(preprocessed_lp.reduced_problem.is_minimize, new_c, new_A, preprocessed_lp.reduced_problem.b, new_l, new_u, new_vars, preprocessed_lp.reduced_problem.constraint_types)

    # Return the updated PreprocessedLPProblem struct
    return PreprocessedLPProblem(
        preprocessed_lp.original_problem,
        new_reduced_lp,
        preprocessed_lp.removed_rows,
        new_removed_columns,
        preprocessed_lp.row_ratios
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
    #row_ratios = sort(collect(row_ratios), by=x->x[1])
    #row_ratios = Dict(k => row_ratios[k] for k in sort(collect(keys(row_ratios))))
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
    
    # Return the updated PreprocessedLPProblem struct
    return PreprocessedLPProblem(
        preprocessed_lp.original_problem,
        reduced_lp,
        vcat(preprocessed_lp.removed_rows, removed_rows),
        preprocessed_lp.removed_cols,
        row_ratios
    )
end


##############################################################################
##### Main Function #####
##############################################################################

"""
    presolve_lp(lp_problem::LPProblem; debug::Bool=false)

Applies presolve routines to the given `LPProblem` to reduce the problem size by removing redundant rows and columns.

# Arguments:
- `lp_problem`: The `LPProblem` to be presolved.
- `debug`: If `true`, prints debugging information for each presolve step. Defaults to `false`.

# Returns:
A `PreprocessedLPProblem` with a reduced problem that excludes zero rows, zero columns, singleton rows, and linearly dependent rows.
"""
function presolve_lp(lp_problem::LPProblem; verbose::Bool=false)
    # Initialize PreprocessedLPProblem
    preprocessed_lp = PreprocessedLPProblem(lp_problem, lp_problem, Int[], Int[], Dict())

    # Preprocessing methods
    preprocessed_lp = lp_remove_zero_rows(preprocessed_lp; verbose=verbose)
    preprocessed_lp = lp_remove_row_singletons(preprocessed_lp, verbose=verbose)


    preprocessed_lp = lp_remove_zero_columns(preprocessed_lp; verbose=verbose)


    preprocessed_lp = lp_remove_linearly_dependent_rows(preprocessed_lp, verbose=verbose)

    
    return preprocessed_lp
end

end # module lp_presolve