module lp_revised_simplex


using SparseArrays
using LinearAlgebra
# Local modules
using lp_problem
using lp_standard_form_converter

# Export the revised_simplex function to make it available outside the module
export revised_simplex


function revised_simplex(lp::LPProblem)
    println("Converting problem to standard form...")
    A, b, c = convert_to_standard_form(lp)
    m, n = size(A)
    
    println("\nStandard form problem:")
    println("  Objective function coefficients c: ", c)
    println("  Constraint matrix A: ", A)
    println("  Right-hand side b: ", b)
    println("  Variables: ", [lp.vars; ["s$i" for i in 1:(n-length(lp.vars))]])
    println("  Optimization type: ", lp.is_minimize ? "Minimize" : "Maximize")
    println("  constraint_types = $(lp.constraint_types)")
    
    # Initialize basis with slack variables
    B = collect((length(lp.vars)+1):n)
    N = collect(1:length(lp.vars))
    
    println("\nInitial basis: ", B)
    println("Initial non-basic variables: ", N)

    # Initialize B_factor outside the loop
    B_matrix = A[:, B]
    B_factor = lu(B_matrix)    
    
    iteration = 0
    while true
        iteration += 1
        println("\nIteration ", iteration)
        
        # Step 1: Compute basic solution
        B_matrix = A[:, B]
        x_B = B_matrix \ b
        println("  Basic solution x_B: ", x_B)
        
        # Step 2: Compute reduced costs
        y = (c[B]' / B_matrix)'
        c_N = c[N] - A[:, N]' * y
        println("  Dual variables y: ", y)
        println("  Reduced costs c_N: ", c_N)
        
        # Step 3: Check optimality
        if all(c_N .>= -1e-10)
            x = zeros(n)
            x[B] = x_B
            println("\nOptimal solution found:")
            obj_value = dot(lp.is_minimize ? c : -c, x)
            return x[1:length(lp.vars)], obj_value
        end
        
        # Step 4: Choose entering variable
        e = argmin(c_N)
        q = N[e]
        println("  Entering variable: ", q)
        
        # Step 5: Compute direction
        aq = A[:, q]  # Extract q-th column of A
        d = Vector(B_factor \ Vector(aq))  # Convert to dense, solve, and convert back
        println("  Direction d: ", d)
        
        # Step 6 & 7: Check unboundedness and choose leaving variable
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
        println("  Leaving variable: ", p)

        # Step 8: Update basis
        B[l] = q
        N[e] = p
        println("  New basis: ", B)
        println("  New non-basic variables: ", N)
        
        # Update B_factor when the basis changes
        B_matrix = A[:, B]
        B_factor = lu(B_matrix)
        
        if iteration > 10  # FIXME: Add a better termination criterion
            error("Maximum iterations reached")
        end
    end
end

end #module lp_revised_simplex