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

Represents a linear programming (LP) or mixed integer programming (MIP) problem.

# Fields:
- `is_minimize::Bool`: True if the objective is to minimize, False for maximization problems.
- `c::Vector{Float64}`: Coefficients of the objective function (c^T * X).
- `A::SparseMatrixCSC{Float64, Int64}`: Constraint matrix (A in AX = b).
- `b::Vector{Float64}`: Right-hand side of constraints (b in AX = b).
- `constraint_types::Vector{Char}`: Types of constraints ('L' for ≤, 'G' for ≥, 'E' for =).
- `l::Vector{Float64}`: Lower bounds for variables (l in l ≤ X).
- `u::Vector{Float64}`: Upper bounds for variables (u in X ≤ u).
- `vars::Vector{String}`: Names of variables (e.g., ["x1", "x2", "x3"]).
- `variable_types::Vector{Symbol}`: Types of variables (e.g., `:continuous`, `:integer`, `:binary`).

# Example:
```julia
lp = LPProblem(
    is_minimize = false,  # Maximization problem
    c = [3.0, 5.0, 7.0],  # Coefficients for the objective function
    A = sparse([1.0, 2.0, 3.0; 4.0, 5.0, 6.0]),  # Constraint matrix
    b = [10.0, 20.0],  # Right-hand side of constraints
    constraint_types = ['L', 'L'],  # Less than or equal constraints
    l = [0.0, 0.0, 0.0],  # Lower bounds for variables
    u = [Inf, Inf, 1.0],  # Upper bounds (third variable is binary)
    vars = ["x1", "x2", "x3"],  # Variable names
    variable_types = [:continuous, :integer, :binary]  # Types of variables
)
```
"""
struct LPProblem
    is_minimize::Bool             # True if the objective is to minimize (if false, it's a maximization problem)
    c::Vector{Float64}            # Objective function coefficients (c^T * X)
    A::SparseMatrixCSC{Float64, Int64}  # Constraint matrix (A in AX = b)
    b::Vector{Float64}            # Right-hand side of constraints (b in AX = b)
    constraint_types::Vector{Char}  # Constraint types ('L' for <=, 'G' for >=, 'E' for =)
    l::Vector{Float64}            # Lower bounds (l in l ≤ X)
    u::Vector{Float64}            # Upper bounds (u in X ≤ u)
    vars::Vector{String}          # Variable names (X_B, X_N)
    variable_types::Vector{Symbol}  # Variable types (:continuous, :integer, :binary)
end



##############################################################################
#### PreprocessedLPProblem Struct
##############################################################################

"""
    struct PreprocessedLPProblem

Represents a linear programming (LP) or mixed integer programming (MIP) problem after preprocessing steps.

# Fields:
- `original_problem::LPProblem`: The original problem before any preprocessing.
- `reduced_problem::LPProblem`: The problem after preprocessing steps, such as removing fixed variables or redundant constraints.
- `removed_rows::Vector{Int}`: Indices of the rows that were removed during preprocessing (e.g., redundant constraints).
- `removed_cols::Vector{Int}`: Indices of the columns (variables) that were removed during preprocessing (e.g., fixed or dominated variables).
- `row_ratios::Dict{Int, Tuple{Int, Float64}}`: Stores information about row reductions, where the key is the row index, and the value is a tuple containing the original row index and a ratio used during row elimination.
- `var_solutions::Dict{String, Float64}`: A dictionary mapping the names of removed variables to their fixed values during preprocessing (e.g., variables fixed due to bounds or presolve procedures).
- `row_scaling::Vector{Float64}`: Scaling factors applied to the rows (optional, if scaling was used for numerical stability).
- `col_scaling::Vector{Float64}`: Scaling factors applied to the columns (optional, if scaling was used for numerical stability).
- `is_infeasible::Bool`: A flag indicating whether the problem was detected as infeasible during preprocessing.

# Example:
```julia
preprocessed_lp = PreprocessedLPProblem(
    original_problem = lp,  # The original LP or MIP problem
    reduced_problem = reduced_lp,  # The reduced problem after preprocessing
    removed_rows = [2, 5],  # Rows that were removed
    removed_cols = [1, 3],  # Columns (variables) that were removed
    row_ratios = Dict(5 => (2, 0.5)),  # Ratio for row 5 being reduced from row 2
    var_solutions = Dict("x1" => 1.0, "x3" => 2.0),  # Solution values for removed variables
    row_scaling = [1.0, 0.5, 0.25],  # Scaling factors for rows
    col_scaling = [1.0, 2.0, 0.75],  # Scaling factors for columns
    is_infeasible = false  # No infeasibility detected
)
```
"""

end # module

