module lp_revised_simplex

using SparseArrays
using LinearAlgebra
# Local modules
using lp_problem
using lp_standard_form_converter

# Export the revised_simplex function
export revised_simplex

"""
    revised_simplex(pp::PreprocessedLPProblem) -> (solution::Dict{String, Float64}, optimal_value::Float64)

Solves a linear programming (LP) problem using the revised simplex method. It uses the reduced problem from
the `PreprocessedLPProblem` struct and updates the original solution based on the preprocessing steps.

# Arguments
- `pp::PreprocessedLPProblem`: A `PreprocessedLPProblem` struct that contains the reduced LP problem, along with
  information about removed rows and columns and any variable solutions from preprocessing.

# Returns
- `solution::Dict{String, Float64}`: The solution as a dictionary mapping variable names to their solution values.
- `optimal_value::Float64`: The optimal value of the objective function.

# Raises
- Throws an error if `is_infeasible == true`.

# Method Overview
1. Converts the reduced LP problem to standard form (minimization, equality constraints).
2. Initializes the basis using slack variables.
3. Iteratively computes the basic solution, reduced costs, and adjusts the basis.
4. If the solution is optimal, maps the results back to the original variables.
"""
function revised_simplex(pp::PreprocessedLPProblem; verbose::Bool = false)
    if verbose
        println()
        println("#" ^ 80)
        println("~" ^ 80)
        println("revised_simplex")
        println("~" ^ 80)
    end

    # Check for infeasibility
    if pp.is_infeasible
        error("The problem is flagged as infeasible.")
    end

    # Extract the reduced problem to work with
    lp = pp.reduced_problem

    # Convert the reduced LP problem to standard form
    lp = convert_to_standard_form(lp, verbose = verbose)
    
    # Initialize variables
    m, n = size(lp.A)
    B = collect(1:m)  # Convert the basis to a mutable vector
    N = collect(m+1:n)  # Convert the non-basic variables to a mutable vector
    c = lp.c
    A = lp.A
    b = lp.b

    # Set up initial basis matrix and LU factorization
    B_matrix = A[:, B]
    B_factor = lu(B_matrix)
    
    iteration = 0
    max_iterations = 100  # Set an appropriate iteration limit
    while iteration < max_iterations
        iteration += 1
        if verbose
            println("~" ^ 80)
            println("Iteration ", iteration)
            println("~" ^ 80)
        end

        # Step 1: Compute basic solution
        B_matrix = A[:, B]
        x_B = B_factor \ b
        if verbose
            println("Basic solution x_B: ", x_B)
        end

        # Step 2: Compute reduced costs
        y = (c[B]' / B_matrix)'
        c_N = c[N] - A[:, N]' * y
        if verbose
            println("~ "^40)
            println("Dual variables y: ", y)
            println("Reduced costs c_N: ", c_N)
        end

        # Step 3: Check optimality
        if all(c_N .>= -1e-10)
            # The solution is optimal
            x = zeros(n)
            x[B] = x_B

            if verbose
                println("~ "^40)
                println("Optimal solution found!")
            end

            # Step 4: Calculate objective value
            # Revert the sign of the objective value if the original problem was a maximization
            obj_value = dot(c, x)
            if !pp.original_problem.is_minimize
                obj_value = -obj_value  # Reverse the sign for maximization problems
            end

            # Step 5: Map solution back to original variables
            final_solution = Dict{String, Float64}()
            for i in 1:length(lp.vars)
                final_solution[lp.vars[i]] = x[i]
            end

            # Combine with pre-solved variables if any
            for (var, value) in pp.var_solutions
                final_solution[var] = value
            end

            if verbose
                println("~ "^40)
                println("Final solution and objective value")
                println("Optimal solution: ", final_solution)
                println("Optimal objective value: ", obj_value)
                println("~" ^ 80)
                println("#" ^ 80)
                println()
            end

            return final_solution, obj_value
        end

        # Step 4: Choose entering variable
        e = argmin(c_N)
        q = N[e]
        if verbose
            println("~ "^40)
            println("Entering variable: ", q)
        end

        # Step 5: Compute direction
        aq = A[:, q]  # Extract q-th column of A
        d = Vector(B_factor \ Vector(aq))  # Convert to dense, solve, and convert back
        if verbose
            println("~ "^40)
            println("Direction d: ", d)
        end

        # Step 6: Check unboundedness and choose leaving variable
        if all(d .<= 1e-10)
            error("Problem is unbounded")
        end

        ratios = x_B ./ d
        ratios[d .<= 1e-10] .= Inf
        valid_ratios = filter(x -> x > 0, ratios)
        if isempty(valid_ratios)
            error("Problem is unbounded")
        end
        l = argmin(valid_ratios)
        p = B[l]
        if verbose
            println("~ "^40)
            println("Leaving variable: ", p)
        end

        # Step 7: Update basis
        B[l] = q  # Update the basis with the entering variable
        N[e] = p  # Update the non-basic variables with the leaving variable
        if verbose
            println("~ "^40)
            println("Updated basis and non-basic variables")
            println("New basis: ", B)
            println("New non-basic variables: ", N)
        end

        # Update LU factorization when the basis changes
        B_matrix = A[:, B]
        B_factor = lu(B_matrix)

        if iteration > max_iterations  # Better termination criterion
            error("Maximum iterations reached")
        end
    end

    error("Maximum iterations reached without finding an optimal solution.")
end



end # module lp_revised_simplex
