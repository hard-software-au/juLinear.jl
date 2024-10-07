module LpRevisedSimplex

using SparseArrays
using LinearAlgebra
# Local modules
using LpProblem
using LpStandardFormConverter

# Export the revised_simplex function
export revised_simplex

"""
    revised_simplex(pp::PreprocessedLPProblem; verbose::Bool=false) -> (solution::Dict{String, Float64}, optimal_value::Float64)

Solves a linear programming (LP) problem using the revised simplex method. This method works with the reduced problem 
from the `PreprocessedLPProblem` struct and updates the original solution based on the preprocessing steps.

### Arguments
- `pp::PreprocessedLPProblem`: A `PreprocessedLPProblem` struct that contains the reduced LP problem, along with
  information about removed rows and columns, any variable solutions from preprocessing, and flags for infeasibility.
- `verbose::Bool=false`: Optional flag to enable detailed output during each iteration of the simplex process. 
    - If `true`, prints step-by-step details of each iteration, including:
        - Basic solution at each iteration.
        - Dual variables and reduced costs.
        - Entering and leaving variables for the basis.
        - Updates to the basis and non-basic variables.
        - Final optimal solution and objective value.

### Returns
- `solution::Dict{String, Float64}`: The solution as a dictionary mapping variable names to their solution values.
- `optimal_value::Float64`: The optimal value of the objective function, adjusted based on whether the original problem 
  was a maximization or minimization.

### Raises
- Throws an error if `pp.is_infeasible == true`, indicating that the problem has been flagged as infeasible during preprocessing.
- Throws an error if the problem is unbounded or if no optimal solution is found within the maximum number of iterations.

### Method Overview
1. **Convert to Standard Form**: 
   - Converts the reduced LP problem to standard form, ensuring minimization and equality constraints.
   - Slack and surplus variables are added as needed.
   
2. **Initialization**: 
   - Initializes the basis with the slack variables and sets up the LU factorization for solving the system.
   
3. **Iteration Process**:
   - Computes the basic solution by solving the system of equations.
   - Calculates reduced costs and identifies the entering and leaving variables based on the direction of improvement.
   - Adjusts the basis and continues iterating until an optimal solution is found, or the problem is determined to be unbounded.

4. **Optimal Solution and Mapping**:
   - Once the optimal solution is found, the result is mapped back to the original variable names.
   - If any variables were pre-solved during preprocessing, their solutions are included.
   - The final objective value is adjusted based on whether the original problem was a maximization or minimization.

### Verbose Output:
If `verbose=true`, the function will print:
1. Iteration details (basic solution, reduced costs, dual variables).
2. Information about entering and leaving variables at each step.
3. Updates to the basis and non-basic variables after each iteration.
4. The final solution and the optimal objective value.

"""
function revised_simplex(pp::PreprocessedLPProblem; verbose::Bool=false)
    if verbose
        println()
        println("#"^80)
        println("~"^80)
        println("revised_simplex")
        println("~"^80)
    end

    # Check for infeasibility
    if pp.is_infeasible
        error("The problem is flagged as infeasible.")
    end

    # Extract the reduced problem to work with
    lp = pp.reduced_problem

    # Convert the reduced LP problem to standard form
    lp = convert_to_standard_form(lp; verbose=verbose)

    # Initialize variables
    m, n = size(lp.A)
    B = collect(1:m)  # Convert the basis to a mutable vector
    N = collect((m + 1):n)  # Convert the non-basic variables to a mutable vector
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
            println("~"^80)
            println("Iteration ", iteration)
            println("~"^80)
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
            final_solution = Dict{String,Float64}()
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
                println("~"^80)
                println("#"^80)
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

    return error("Maximum iterations reached without finding an optimal solution.")
end

end # module lp_revised_simplex
