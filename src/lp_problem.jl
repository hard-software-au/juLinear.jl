module lp_problem

using SparseArrays

# Export the LPProblem struct
export LPProblem
export MIPProblem
export PreprocessedLPProblem

##############################################################################
#### LPProblem Struct
##############################################################################

"""
    struct LPProblem

Represents a standard Linear Programming (LP) problem.

# Fields:
- `is_minimize::Bool`: `true` if the objective is to minimize, `false` if it is to maximize.
- `c::Vector{Float64}`: The objective function coefficients.
- `A::SparseMatrixCSC{Float64, Int64}`: The sparse constraint matrix.
- `b::Vector{Float64}`: The right-hand side values of the constraints.
- `l::Vector{Float64}`: The lower bounds for the decision variables.
- `u::Vector{Float64}`: The upper bounds for the decision variables.
- `vars::Vector{String}`: The names of the decision variables.
- `constraint_types::Vector{Char}`: The types of constraints (e.g., `<=`, `>=`, `=`).
"""
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

##############################################################################
#### MIPProblem Struct
##############################################################################

"""
    struct MIPProblem

Represents a Mixed Integer Programming (MIP) problem. Extends the `LPProblem` struct to include variable types.

# Fields:
- `is_minimize::Bool`: `true` if the objective is to minimize, `false` if it is to maximize.
- `c::Vector{Float64}`: The objective function coefficients.
- `A::SparseMatrixCSC{Float64, Int64}`: The sparse constraint matrix.
- `b::Vector{Float64}`: The right-hand side values of the constraints.
- `l::Vector{Float64}`: The lower bounds for the decision variables.
- `u::Vector{Float64}`: The upper bounds for the decision variables.
- `vars::Vector{String}`: The names of the decision variables.
- `variable_types::Vector{Symbol}`: The types of variables (e.g., `:Binary`, `:Integer`, `:Continuous`).
- `constraint_types::Vector{Char}`: The types of constraints (e.g., `<=`, `>=`, `=`).
"""
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

##############################################################################
#### PreprocessedLPProblem Struct
##############################################################################

"""
    struct PreprocessedLPProblem

Stores the original and reduced versions of an LP problem during preprocessing, as well as information about removed rows and columns.

# Fields:
- `original_problem::LPProblem`: The original LP problem before preprocessing.
- `reduced_problem::LPProblem`: The reduced LP problem after preprocessing.
- `removed_rows::Vector{Int}`: Indices of rows removed during preprocessing.
- `removed_cols::Vector{Int}`: Indices of columns removed during preprocessing.
- `row_ratios::Dict{Int, Tuple{Int, Float64}}`: Maps removed rows to their corresponding row and the ratio between them.
- `var_solutions::Dict{String, Float64}}`: Maps solved varibles to their corresponding values.
"""
struct PreprocessedLPProblem
    original_problem::LPProblem  # The original LP problem before preprocessing
    reduced_problem::LPProblem   # The reduced LP problem after preprocessing
    removed_rows::Vector{Int}    # Indices of removed rows
    removed_cols::Vector{Int}    # Indices of removed columns (if applicable)
    row_ratios::Dict{Int, Tuple{Int, Float64}}  # Mapping of removed rows to their corresponding row and ratio
    var_solutions::Dict{String, Float64}  # Mapping of variable names to their solution values
end

end # module

