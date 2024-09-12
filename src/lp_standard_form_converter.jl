module lp_standard_form_converter

using SparseArrays
import lp_problem: LPProblem, MIPProblem

# Export the functions
export convert_to_standard_form
export convert_to_standard_form_mip

"""
    convert_to_standard_form(lp::LPProblem) -> (new_A::SparseMatrixCSC, new_b::Vector{Float64}, new_c::Vector{Float64})

Converts a given `LPProblem` to its standard form, transforming the constraints and objective function to fit the requirements of the standard linear programming form.

# Arguments
- `lp::LPProblem`: A struct representing the Linear Programming problem, containing the objective function, constraints, and bounds.

# Returns
- `new_A::SparseMatrixCSC`: The transformed constraint matrix in standard form.
- `new_b::Vector{Float64}`: The transformed right-hand side of the constraints.
- `new_c::Vector{Float64}`: The transformed objective function coefficients.

# Method Details
- Handles lower and upper bounds for variables by adding additional constraints if necessary.
- Transforms the problem to ensure all constraints are in the form of inequalities.
- Adjusts the objective function if the problem is a maximization (standard form assumes minimization).
"""
function convert_to_standard_form(lp::LPProblem)
    c, A, b, l, u = lp.c, lp.A, lp.b, lp.l, lp.u
    m, n = size(A)
    
    ##### Handle lower and upper bounds for variables #####
    for i in 1:n
        if l[i] > -Inf
            # Add a new constraint for the lower bound
            A = [A; zeros(1, n)]
            A[end, i] = -1
            push!(b, -l[i])
            push!(lp.constraint_types, 'L')
        end
        if u[i] < Inf
            # Add a new constraint for the upper bound
            A = [A; zeros(1, n)]
            A[end, i] = 1
            push!(b, u[i])
            push!(lp.constraint_types, 'L')
        end
    end
    
    m, n = size(A)
    new_A = spzeros(eltype(A), m, n + m)
    new_b = copy(b)
    new_c = [c; zeros(m)]
    
    ##### Transform constraints into standard form #####
    for i in 1:m
        if lp.constraint_types[i] == 'L'
            new_A[i, :] = [A[i, :]; zeros(i-1); 1; zeros(m-i)]
        elseif lp.constraint_types[i] == 'G'
            new_A[i, :] = [-A[i, :]; zeros(i-1); 1; zeros(m-i)]
            new_b[i] = -new_b[i]
        elseif lp.constraint_types[i] == 'E'
            new_A[i, :] = [A[i, :]; zeros(m)]
        end
    end
    
    ##### Adjust objective function if it's a maximization problem #####
    if !lp.is_minimize
        new_c = -new_c
    end
    
    return new_A, new_b, new_c
end

###################################################################################
## MIP code
###################################################################################

"""
    convert_to_standard_form_mip(mip::MIPProblem) -> (new_A::SparseMatrixCSC, new_b::Vector{Float64}, new_c::Vector{Float64}, new_variable_types::Vector{Symbol})

Converts a given `MIPProblem` to its standard form, transforming the constraints and objective function to fit the requirements of the standard mixed integer programming form.

# Arguments
- `mip::MIPProblem`: A struct representing the Mixed Integer Programming problem, containing the objective function, constraints, bounds, and variable types.

# Returns
- `new_A::SparseMatrixCSC`: The transformed constraint matrix in standard form.
- `new_b::Vector{Float64}`: The transformed right-hand side of the constraints.
- `new_c::Vector{Float64}`: The transformed objective function coefficients.
- `new_variable_types::Vector{Symbol}`: The updated variable types, including new slack variables added during the transformation.

# Method Details
- Adds constraints to handle lower and upper bounds by introducing slack variables.
- Ensures all constraints are in standard form (inequalities) and adjusts the right-hand side appropriately.
- Adjusts the objective function if the problem is a maximization (standard form assumes minimization).
"""
function convert_to_standard_form_mip(mip::MIPProblem)
    c, A, b, l, u = mip.c, mip.A, mip.b, mip.l, mip.u
    variable_types = mip.variable_types
    m, n = size(A)
    
    ##### Handle lower and upper bounds for variables #####
    for i in 1:n
        if l[i] > -Inf
            # Add a new constraint for the lower bound
            A = [A; zeros(1, n)]
            A[end, i] = -1
            push!(b, -l[i])
            push!(mip.constraint_types, 'L')
            push!(variable_types, :Continuous)  # New slack variable is continuous
        end
        if u[i] < Inf
            # Add a new constraint for the upper bound
            A = [A; zeros(1, n)]
            A[end, i] = 1
            push!(b, u[i])
            push!(mip.constraint_types, 'L')
            push!(variable_types, :Continuous)  # New slack variable is continuous
        end
    end
    
    m, n = size(A)
    new_A = spzeros(eltype(A), m, n + m)
    new_b = copy(b)
    new_c = [c; zeros(m)]
    new_variable_types = copy(variable_types)
    
    ##### Transform constraints into standard form #####
    for i in 1:m
        if mip.constraint_types[i] == 'L'
            new_A[i, :] = [A[i, :]; zeros(i-1); 1; zeros(m-i)]
        elseif mip.constraint_types[i] == 'G'
            new_A[i, :] = [-A[i, :]; zeros(i-1); 1; zeros(m-i)]
            new_b[i] = -new_b[i]
        elseif mip.constraint_types[i] == 'E'
            new_A[i, :] = [A[i, :]; zeros(m)]
        end
        push!(new_variable_types, :Continuous)  # The added slack variables are continuous
    end
    
    ##### Adjust objective function if it's a maximization problem #####
    if !mip.is_minimize
        new_c = -new_c
    end
    
    return new_A, new_b, new_c, new_variable_types
end

end # module