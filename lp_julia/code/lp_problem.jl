module lp_problem

using SparseArrays

# Export the LPProblem struct
export LPProblem

# Define a struct to represent a Linear Programming problem

struct LPProblem
    is_minimize::Bool  # True if the objective is to minimize
    c::Vector{Float64}  # Objective function coefficients
    A::SparseMatrixCSC{Float64, Int64}  # Constraint matrix
    b::Vector{Float64}  # Right-hand side of constraints
    l::Vector{Float64}  # Variable lower bounds
    u::Vector{Float64}  # Variable upper bounds
    vars::Vector{String}  # Variable names
    constraint_types::Vector{Char}  # Constraint types
end

end # module
