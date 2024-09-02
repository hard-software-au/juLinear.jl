module lp_problem

using SparseArrays

# Export the LPProblem struct
export LPProblem
export MIPProblem

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

# Define a struct to represent A Mixed Integer Program

struct MIPProblem
    is_minimize::Bool  # True if the objective is to minimize
    c::Vector{Float64}  # Objective function coefficients
    A::SparseMatrixCSC{Float64, Int64}  # Constraint matrix
    b::Vector{Float64}  # Right-hand side of constraints
    l::Vector{Float64}  # Variable lower bounds
    u::Vector{Float64}  # Variable upper bounds
    vars::Vector{String}  # Variable names
    variable_types::Vector{Symbol}  # Array of variable types, same length as vars
    constraint_types::Vector{Char}  # Constraint types
end

end # module
