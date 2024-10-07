module LpSimplex

using SparseArrays
using LinearAlgebra
using LpProblem
using LpStandardFormConverter

export revised_simplex_method

"""
    SimplexResult

Structure to encapsulate the result of the Revised Simplex Method.

# Fields
- status::Symbol: Status of the solution (:optimal, :infeasible, :unbounded, :iteration_limit).
- solution::Dict{String, Float64}: Mapping of variable names to their optimal values.
- objective::Float64: Optimal objective function value.
- iterations::Int: Number of iterations performed.
"""
struct SimplexResult
    status::Symbol
    solution::Dict{String,Float64}
    objective::Float64
    iterations::Int
end

"""
    initialize_phase_one(lp_std::LPProblem)

Initializes Phase I by identifying slack and artificial variables and setting up basic and non-basic variable indices.

# Arguments
- lp_std::LPProblem: The LP problem in standard form, including slack and artificial variables.

# Returns
- basic_indices::Vector{Int}: Indices of basic variables (slack and artificial variables).
- nonbasic_indices::Vector{Int}: Indices of non-basic variables.
- artificial_vars::Vector{Int}: Indices of artificial variables.
"""
function initialize_phase_one(lp::LPProblem)
    m, n = size(lp.A)
    slack_vars = [i for i in 1:length(lp.vars) if startswith(lp.vars[i], "s_")]
    artificial_vars = [i for i in 1:length(lp.vars) if startswith(lp.vars[i], "a_")]

    basic_indices = vcat(slack_vars, artificial_vars)
    nonbasic_indices = setdiff(1:n, basic_indices)

    return basic_indices, nonbasic_indices, artificial_vars
end

"""
    perform_phase_one(lp_std::LPProblem, basic_indices::Vector{Int}, nonbasic_indices::Vector{Int},
                     artificial_vars::Vector{Int}; verbose::Bool=false, tol_feas::Float64=1e-8,
                     max_iterations::Int=1000)

Performs Phase I of the Revised Simplex Method to find an initial basic feasible solution.

# Arguments
- lp_std::LPProblem: The LP problem in standard form.
- basic_indices::Vector{Int}: Initial basic variable indices (slack and artificial variables).
- nonbasic_indices::Vector{Int}: Initial non-basic variable indices.
- artificial_vars::Vector{Int}: Indices of artificial variables.
- verbose::Bool: Flag for verbose output.
- tol_feas::Float64: Tolerance for feasibility.
- max_iterations::Int: Maximum number of iterations.

# Returns
- status::Symbol: Status after Phase I (:optimal, :infeasible, etc.).
- basic_indices::Vector{Int}: Updated basic variable indices.
- nonbasic_indices::Vector{Int}: Updated non-basic variable indices.
- x_B::Vector{Float64}: Basic variable values.
- iterations::Int: Number of iterations performed.
"""
function perform_phase_one(
    lp_std::LPProblem,
    basic_indices::Vector{Int},
    nonbasic_indices::Vector{Int},
    artificial_vars::Vector{Int};
    verbose::Bool=false,
    tol_feas::Float64=1e-8,
    max_iterations::Int=1000,
)
    m, n = size(lp_std.A)
    iteration = 0
    status = :optimal

    # Objective function for Phase I: minimize sum of artificial variables
    c_phase1 = zeros(n)
    for a_var in artificial_vars
        c_phase1[a_var] = 1.0
    end

    # Convert b to a dense vector if it's not already
    b_dense = Array(vec(lp_std.b))  # Ensures b is a dense Vector{Float64}

    # Initial LU factorization (sparse)
    B = lp_std.A[:, basic_indices]  # Sparse submatrix
    lu_B = try
        lu(B)
    catch e
        error("LU factorization failed during Phase I: $(e.message)")
    end

    x_B = lu_B \ b_dense
    x_N = zeros(length(nonbasic_indices))

    if verbose
        println("Phase I: Starting to find initial feasible solution...")
        println("Initial Basic Variables (indices): ", basic_indices)
        println("Initial Non-Basic Variables (indices): ", nonbasic_indices)
        println("Initial Basic Solution x_B: ", x_B)
        println("-"^80)
    end

    while iteration < max_iterations
        iteration += 1

        # Compute dual variables
        y = lu_B' \ Array(c_phase1[basic_indices])

        # Compute reduced costs
        N = lp_std.A[:, nonbasic_indices]  # Sparse submatrix
        reduced_costs = c_phase1[nonbasic_indices] - Array(N' * y)

        # Check for optimality
        if all(reduced_costs .>= -tol_feas)
            break
        end

        # Determine entering variable using Bland's Rule to prevent cycling
        entering_candidates = findall(reduced_costs .< -tol_feas)
        if isempty(entering_candidates)
            break
        end
        entering_index_in_N = minimum(entering_candidates)
        entering_var = nonbasic_indices[entering_index_in_N]

        # Compute direction d (ensure it's a dense vector)
        A_entering = Array(lp_std.A[:, entering_var])  # Convert to dense
        d = lu_B \ A_entering

        # Determine leaving variable using minimum ratio test
        positive_d_indices = findall(d .> tol_feas)
        if isempty(positive_d_indices)
            status = :unbounded
            break
        end

        ratios = x_B[positive_d_indices] ./ d[positive_d_indices]
        min_ratio, pos = findmin(ratios)
        leaving_index_in_B = positive_d_indices[pos]
        leaving_var = basic_indices[leaving_index_in_B]

        # Update basic and non-basic indices
        basic_indices[leaving_index_in_B] = entering_var
        nonbasic_indices[entering_index_in_N] = leaving_var

        # Update B and LU factorization (sparse)
        B = lp_std.A[:, basic_indices]
        try
            lu_B = lu(B)
        catch e
            error(
                "LU factorization failed during Phase I iteration $(iteration): $(e.message)",
            )
        end

        # Update basic solution
        x_B = lu_B \ b_dense
        x_N = zeros(length(nonbasic_indices))

        if verbose
            println("Phase I Iteration: ", iteration)
            println(
                "Entering Variable: ", entering_var, " (", lp_std.vars[entering_var], ")"
            )
            println("Leaving Variable: ", leaving_var, " (", lp_std.vars[leaving_var], ")")
            println("Basic Indices: ", basic_indices)
            println("Basic Solution x_B: ", x_B)
            println("-"^80)
        end
    end

    # Compute the value of the Phase I objective function
    if !isempty(artificial_vars)
        # Find indices of basic variables that are artificial
        basic_artificial_vars = filter(v -> in(v, artificial_vars), basic_indices)
        phase1_objective = sum(
            x_B[i] for i in 1:length(basic_indices) if basic_indices[i] in artificial_vars
        )
    else
        phase1_objective = 0.0
    end

    if phase1_objective > tol_feas
        status = :infeasible
    end

    return status, basic_indices, nonbasic_indices, x_B, iteration
end

"""
    perform_phase_two(lp_phase2::LPProblem, basic_indices::Vector{Int}, nonbasic_indices::Vector{Int},
                     c_phase2::Vector{Float64}; verbose::Bool=false, tol_opt::Float64=1e-10,
                     max_iterations::Int=1000)

Performs Phase II of the Revised Simplex Method to optimize the original objective function.

# Arguments
- lp_phase2::LPProblem: The LP problem in standard form after removing artificial variables.
- basic_indices::Vector{Int}: Current basic variable indices.
- nonbasic_indices::Vector{Int}: Current non-basic variable indices.
- c_phase2::Vector{Float64}: Original objective coefficients.
- verbose::Bool: Flag for verbose output.
- tol_opt::Float64: Tolerance for optimality.
- max_iterations::Int: Maximum number of iterations.

# Returns
- status::Symbol: Status after Phase II (:optimal, :unbounded, etc.).
- basic_indices::Vector{Int}: Updated basic variable indices.
- nonbasic_indices::Vector{Int}: Updated non-basic variable indices.
- x_B::Vector{Float64}: Basic variable values.
- iterations::Int: Number of iterations performed.
"""
function perform_phase_two(
    lp_phase2::LPProblem,
    basic_indices::Vector{Int},
    nonbasic_indices::Vector{Int},
    c_phase2::Vector{Float64};
    verbose::Bool=false,
    tol_opt::Float64=1e-10,
    max_iterations::Int=1000,
)
    m, n = size(lp_phase2.A)
    iteration = 0
    status = :optimal

    # Ensure that basic_indices and nonbasic_indices are within bounds
    num_columns = size(lp_phase2.A, 2)

    if verbose
        println("Matrix A size: ", size(lp_phase2.A))
    end

    if any(i -> i > num_columns || i < 1, basic_indices) ||
        any(i -> i > num_columns || i < 1, nonbasic_indices)
        error("Indices in basic or non-basic variables are out of bounds")
    end

    # Convert b to a dense vector if it's not already
    b_dense = Array(vec(lp_phase2.b))  # Ensures b is a dense Vector{Float64}

    # Initial LU factorization (sparse)
    B = lp_phase2.A[:, basic_indices]  # Sparse submatrix
    lu_B = try
        lu(B)
    catch e
        error("LU factorization failed during Phase II: $(e.message)")
    end

    # Compute initial basic solution
    x_B = lu_B \ b_dense
    x_N = zeros(length(nonbasic_indices))

    if verbose
        println("Phase II: Starting optimization of original objective function...")
        println("Initial Basic Variables (indices): ", basic_indices)
        println("Initial Non-Basic Variables (indices): ", nonbasic_indices)
        println("Initial Basic Solution x_B: ", x_B)
        println("-"^80)
    end

    while iteration < max_iterations
        iteration += 1

        # Compute dual variables
        c_B = Array(c_phase2[basic_indices])  # Convert to dense vector
        y = lu_B' \ c_B

        # Compute reduced costs
        N = lp_phase2.A[:, nonbasic_indices]  # Sparse submatrix
        reduced_costs = c_phase2[nonbasic_indices] - (N' * y)

        # Check for optimality
        if all(reduced_costs .>= -tol_opt)
            break
        end

        # Determine entering variable using Bland's Rule to prevent cycling
        entering_candidates = findall(reduced_costs .< -tol_opt)
        if isempty(entering_candidates)
            break
        end
        entering_index_in_N = minimum(entering_candidates)
        entering_var = nonbasic_indices[entering_index_in_N]

        # Compute direction d (ensure it's a dense vector)
        A_entering = Array(lp_phase2.A[:, entering_var])  # Convert to dense
        d = lu_B \ A_entering

        # Determine leaving variable using minimum ratio test
        positive_d_indices = findall(d .> tol_opt)
        if isempty(positive_d_indices)
            status = :unbounded
            break
        end

        ratios = x_B[positive_d_indices] ./ d[positive_d_indices]
        min_ratio, pos = findmin(ratios)
        leaving_index_in_B = positive_d_indices[pos]
        leaving_var = basic_indices[leaving_index_in_B]

        # Update basic and non-basic indices
        basic_indices[leaving_index_in_B] = entering_var
        nonbasic_indices[entering_index_in_N] = leaving_var

        # Update B and LU factorization (sparse)
        B = lp_phase2.A[:, basic_indices]
        try
            lu_B = lu(B)
        catch e
            error(
                "LU factorization failed during Phase II iteration $(iteration): $(e.message)",
            )
        end

        # Update basic solution
        x_B = lu_B \ b_dense
        x_N = zeros(length(nonbasic_indices))

        if verbose
            println("Phase II Iteration: ", iteration)
            println(
                "Entering Variable: ", entering_var, " (", lp_phase2.vars[entering_var], ")"
            )
            println(
                "Leaving Variable: ", leaving_var, " (", lp_phase2.vars[leaving_var], ")"
            )
            println("Basic Indices: ", basic_indices)
            println("Basic Solution x_B: ", x_B)
            println("-"^80)
        end
    end

    # Compute the value of the Phase II objective function
    phase2_objective = sum(c_phase2[basic_indices] .* x_B)

    # Check for optimality
    y_final = lu_B' \ Array(c_phase2[basic_indices])
    reduced_costs_final =
        c_phase2[nonbasic_indices] - (lp_phase2.A[:, nonbasic_indices]' * y_final)

    if any(reduced_costs_final .< -tol_opt)
        status = :unbounded
    end

    return status, basic_indices, nonbasic_indices, x_B, iteration
end

"""
    assemble_solution(lp_phase2::LPProblem, basic_indices::Vector{Int}, nonbasic_indices::Vector{Int},
                     x_B::Vector{Float64})::Dict{String, Float64}

Assembles the full solution vector from basic and non-basic variables.

# Arguments
- lp_phase2::LPProblem: The LP problem in standard form after removing artificial variables.
- basic_indices::Vector{Int}: Indices of basic variables.
- nonbasic_indices::Vector{Int}: Indices of non-basic variables.
- x_B::Vector{Float64}: Values of basic variables.

# Returns
- solution::Dict{String, Float64}: Mapping of variable names to their values.
"""
function assemble_solution(
    lp_phase2::LPProblem,
    basic_indices::Vector{Int},
    nonbasic_indices::Vector{Int},
    x_B::Vector{Float64},
)::Dict{String,Float64}
    n_original = length(lp_phase2.c)  # Number of original variables (excluding slack and artificial)
    solution = Dict{String,Float64}()

    # Initialize all original variables to zero
    for j in 1:n_original
        solution[lp_phase2.vars[j]] = 0.0
    end

    # Assign values to basic original variables
    for (i, var_idx) in enumerate(basic_indices)
        if var_idx <= n_original
            solution[lp_phase2.vars[var_idx]] = x_B[i]
        end
    end

    # Non-basic original variables remain zero

    return solution
end

##########################################################################################
## Revised Simplex Method
##########################################################################################

"""
    revised_simplex_method(lp::LPProblem; verbose::Bool=false,
                           tol_opt::Float64=1e-10, tol_feas::Float64=1e-8,
                           max_iterations::Int=1000)::SimplexResult

Solves the linear programming problem defined by lp using the Revised Simplex Method with Phase I and Phase II.

# Arguments
- lp::LPProblem: The linear programming problem.
- verbose::Bool: If true, prints detailed iteration information.
- tol_opt::Float64: Tolerance for optimality conditions.
- tol_feas::Float64: Tolerance for feasibility checks.
- max_iterations::Int: Maximum number of iterations for each phase.

# Returns
- SimplexResult: A structure containing the status, solution vector, optimal objective value, and number of iterations.
"""
function revised_simplex_method(
    lp::LPProblem;
    verbose::Bool=false,
    tol_opt::Float64=1e-10,
    tol_feas::Float64=1e-8,
    max_iterations::Int=1000,
)::SimplexResult
    # Step 1: Convert LP to standard form
    lp_std = convert_to_standard_form(lp; verbose=verbose)
    m, n = size(lp_std.A)

    # Step 2: Initialize Phase I
    basic_indices, nonbasic_indices, artificial_vars = initialize_phase_one(lp_std)

    if verbose
        println("Phase I: Initializing...")
        println("Initial Basic Variables (indices): ", basic_indices)
        println("Initial Non-Basic Variables (indices): ", nonbasic_indices)
        println("Artificial Variables: ", artificial_vars)
        println("-"^80)
    end

    # Step 3: Perform Phase I
    status_phase1, basic_indices, nonbasic_indices, x_B, iterations_phase1 = perform_phase_one(
        lp_std,
        basic_indices,
        nonbasic_indices,
        artificial_vars;
        verbose=verbose,
        tol_feas=tol_feas,
        max_iterations=max_iterations,
    )

    if verbose
        println(
            "Phase I completed in $(iterations_phase1) iterations with status: $(status_phase1)",
        )
        println("-"^80)
    end

    if status_phase1 == :infeasible
        if verbose
            println("Original LP problem is infeasible.")
            println("#"^80)
            println()
        end
        return SimplexResult(:infeasible, Dict{String,Float64}(), 0.0, iterations_phase1)
    end

    # Step 4: Prepare for Phase II by removing artificial variables
    # Identify indices of artificial variables
    artificial_vars = [i for i in 1:length(lp_std.vars) if startswith(lp_std.vars[i], "a_")]

    # Remove artificial variables from the problem
    remaining_vars_indices = setdiff(1:size(lp_std.A, 2), artificial_vars)

    # Adjust basic indices to account for removal of artificial variables
    # Ensure that no basic variable is artificial
    basic_indices = filter(i -> !in(i, artificial_vars), basic_indices)

    # Remove any artificial variables from nonbasic_indices if present
    nonbasic_indices = setdiff(nonbasic_indices, artificial_vars)

    # Subset the matrix and vectors to remove artificial variables
    A_phase2 = lp_std.A[:, remaining_vars_indices]  # Remains sparse
    c_phase2 = lp_std.c[remaining_vars_indices]
    vars_phase2 = lp_std.vars[remaining_vars_indices]
    variable_types_phase2 = lp_std.variable_types[remaining_vars_indices]
    l_phase2 = lp_std.l[remaining_vars_indices]
    u_phase2 = lp_std.u[remaining_vars_indices]

    # Update basic_indices and nonbasic_indices to reflect the removal of artificial variables
    # Mapping from old indices to new indices
    var_mapping = Dict{Int,Int}()
    for (new_idx, old_idx) in enumerate(remaining_vars_indices)
        var_mapping[old_idx] = new_idx
    end

    # Update basic_indices
    basic_indices = [var_mapping[i] for i in basic_indices if haskey(var_mapping, i)]

    # Update nonbasic_indices
    nonbasic_indices = [var_mapping[i] for i in nonbasic_indices if haskey(var_mapping, i)]

    # Create a new LPProblem for Phase II
    lp_phase2 = LPProblem(
        lp_std.is_minimize,
        c_phase2,
        A_phase2,
        lp_std.b,  # Already converted to dense in perform_phase_one
        fill('E', m),
        l_phase2,
        u_phase2,
        vars_phase2,
        variable_types_phase2,
    )

    # Update indices based on Phase II's variable ordering
    # Ensure that basic_indices and nonbasic_indices are within the new variable set
    if any(i -> i > size(lp_phase2.A, 2) || i < 1, basic_indices) ||
        any(i -> i > size(lp_phase2.A, 2) || i < 1, nonbasic_indices)
        error(
            "Basic or non-basic indices are out of bounds after removing artificial variables",
        )
    end

    if verbose
        println(
            "Phase II: Removing artificial variables and setting up original objective."
        )
        println("Updated Basic Variables (indices): ", basic_indices)
        println("Updated Non-Basic Variables (indices): ", nonbasic_indices)
        println("-"^80)
    end

    # Step 5: Perform Phase II
    status_phase2, basic_indices, nonbasic_indices, x_B, iterations_phase2 = perform_phase_two(
        lp_phase2,
        basic_indices,
        nonbasic_indices,
        lp_phase2.c;
        verbose=verbose,
        tol_opt=tol_opt,
        max_iterations=max_iterations,
    )

    if verbose
        println(
            "Phase II completed in $(iterations_phase2) iterations with status: $(status_phase2)",
        )
        println("-"^80)
    end

    if status_phase2 == :unbounded
        if verbose
            println("The LP problem is unbounded.")
            println("#"^80)
            println()
        end
        return SimplexResult(
            :unbounded, Dict{String,Float64}(), 0.0, iterations_phase1 + iterations_phase2
        )
    end

    # Step 6: Assemble the final solution
    solution = assemble_solution(lp_phase2, basic_indices, nonbasic_indices, x_B)
    optimal_value = -lp_phase2.c' * [solution[var] for var in lp_phase2.vars]

    if verbose
        println("Optimal Solution:")
        for (var, val) in sort(collect(solution); by=x -> x[1])
            println("  $(var) = $(val)")
        end
        println("Optimal Objective Value: $(optimal_value)")
        println("Revised Simplex Method completed successfully.")
        println("#"^80)
        println()
    end

    total_iterations = iterations_phase1 + iterations_phase2
    return SimplexResult(:optimal, solution, optimal_value, total_iterations)
end

end # module
