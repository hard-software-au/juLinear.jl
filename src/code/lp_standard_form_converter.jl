module lp_standard_form_converter

using SparseArrays
import lp_problem: LPProblem, MIPProblem

# Export the functions
export convert_to_standard_form
export convert_to_standard_form_mip

#=
    convert_to_standard_form(lp::LPProblem)

Converts a given `LPProblem` to its standard form.

Arguments:
- `lp`: An `LPProblem` struct representing the Linear Programming problem.

Returns:
- A tuple `(new_A, new_b, new_c)` representing the standard form of the LP problem.
=#
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

#=
    convert_to_standard_form_mip(mip::MIPProblem)

Converts a given `MIPProblem` to its standard form.

Arguments:
- `mip`: A `MIPProblem` struct representing the Mixed Integer Programming problem.

Returns:
- A tuple `(new_A, new_b, new_c, new_variable_types)` representing the standard form of the MIP problem.
=#
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
