module lp_problem

using SparseArrays

# Export the LPProblem struct
export LPProblem
export MIPProblem
export PreprocessedLPProblem


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


# Define a struct for preprocessing lp problem

struct PreprocessedLPProblem
    original_problem::LPProblem  # The original LP problem before preprocessing
    reduced_problem::LPProblem   # The reduced LP problem after preprocessing
    removed_rows::Vector{Int}    # Indices of removed rows
    removed_cols::Vector{Int}    # Indices of removed columns (if applicable)
    row_ratios::Dict{Int, Tuple{Int, Float64}}  # Mapping of removed rows to their corresponding row and ratio
end

end # module
