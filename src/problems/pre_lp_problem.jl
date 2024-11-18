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
struct PreprocessedLPProblem
    original_problem::LPProblem       # The original LP or MIP problem before preprocessing
    reduced_problem::LPProblem        # The reduced problem after preprocessing
    removed_rows::Vector{Int}         # Indices of removed rows
    removed_cols::Vector{Int}         # Indices of removed columns (if applicable)
    row_ratios::Dict{Int,Tuple{Int,Float64}}  # Mapping of removed rows to their corresponding row and ratio
    var_solutions::Dict{String,Float64}  # Mapping of variable names to their solution values from any presolve procedure
    row_scaling::Vector{Float64}  # Scaling factors for rows (optional, if scaling is applied)
    col_scaling::Vector{Float64}  # Scaling factors for columns (optional, if scaling is applied)
    is_infeasible::Bool  # Flag for infeasibility detection
end
