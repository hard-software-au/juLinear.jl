module lpPresolve

using SparseArrays

# Define the LPProblem type
struct LPProblem
    is_minimize::Bool
    c::Vector{Float64}
    A::SparseMatrixCSC{Float64, Int}
    b::Vector{Float64}
    vars::Vector{String}
    constraint_types::Vector{Char}
end

# Define the presolve function
function presolve(lp::LPProblem; eps::Float64=1e-8, verbose::Bool=false)
    is_minimize, c, A, b = lp.is_minimize, lp.c, sparse(lp.A), lp.b
    vars, constraint_types = lp.vars, lp.constraint_types
    m, n = size(A)

    # Initialize masks for rows and columns to keep
    keep_rows = trues(m)
    keep_cols = trues(n)

    # Step 1: Remove zero columns
    for j in 1:n
        if nnz(A[:, j]) == 0 && abs(c[j]) < eps
            keep_cols[j] = false
        end
    end

    # Step 2: Remove zero rows
    for i in 1:m
        if nnz(A[i, :]) == 0
            if abs(b[i]) < eps
                keep_rows[i] = false
            else
                error("Infeasible problem: zero row with non-zero RHS")
            end
        end
    end

    # Step 3: Remove duplicate rows
    for i in 1:m
        if !keep_rows[i]
            continue
        end
        for j in (i+1):m
            if !keep_rows[j]
                continue
            end
            if A[i, :] ≈ A[j, :] && abs(b[i] - b[j]) < eps && constraint_types[i] == constraint_types[j]
                keep_rows[j] = false
            elseif A[i, :] ≈ -A[j, :] && abs(b[i] + b[j]) < eps && 
                   ((constraint_types[i] == '≤' && constraint_types[j] == '≥') || 
                    (constraint_types[i] == '≥' && constraint_types[j] == '≤'))
                keep_rows[j] = false
            end
        end
    end

    # Step 4: Fix variables and tighten bounds
    fixed_vars = Dict{String, Float64}()
    for j in 1:n
        col = A[:, j]
        if nnz(col) == 1
            i = findfirst(!iszero, col)
            if abs(col[i]) ≈ 1 && constraint_types[i] == '='
                val = b[i] / col[i]
                fixed_vars[vars[j]] = val
                keep_cols[j] = false
                b .-= val * col
            end
        end
    end

    # Apply the reductions
    A_new = A[keep_rows, keep_cols]
    b_new = b[keep_rows]
    c_new = c[keep_cols]
    vars_new = vars[keep_cols]
    constraint_types_new = constraint_types[keep_rows]

    # Adjust the objective for fixed variables
    obj_adjust = isempty(fixed_vars) ? 0.0 : sum(c[j] * fixed_vars[vars[j]] for j in 1:n if haskey(fixed_vars, vars[j]))

    if verbose
        println("\nPresolve summary:")
        println("  Original problem size: $(m) x $(n)")
        println("  Reduced problem size: $(sum(keep_rows)) x $(sum(keep_cols))")
        println("  Number of fixed variables: $(length(fixed_vars))")
        println("  Objective adjustment: $obj_adjust")
    end

    return LPProblem(is_minimize, c_new, A_new, b_new, vars_new, constraint_types_new), fixed_vars, obj_adjust
end

end # module

