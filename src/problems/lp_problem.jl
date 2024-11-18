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
- `variable_types::Vector{Symbol}`: Types of variables (e.g., `:Continuous`, `:Integer`, `:Binary`).

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
    variable_types = [:Continuous, :Integer, :Binary]  # Types of variables
)
```
"""
struct LPProblem
    is_minimize::Bool                   # True for minimization, false for maximization
    c::Vector{Float64}                  # Objective coefficients (cᵀX)
    A::SparseMatrixCSC{Float64,Int64}  # Constraint matrix (AX = b)
    b::Vector{Float64}                  # Right-hand side vector
    constraint_types::Vector{Char}      # Constraint types ('L' ≤, 'G' ≥, 'E' =)
    l::Vector{Float64}                  # Lower bounds
    u::Vector{Float64}                  # Upper bounds
    vars::Vector{String}                # Variable names
    variable_types::Vector{Symbol}      # Variable types (:Continuous, :Integer, etc.)
end
