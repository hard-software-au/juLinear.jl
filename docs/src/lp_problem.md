# `lp_problem` Module

The `lp_problem` module defines data structures that represent linear programming (LP) and mixed integer programming (MIP) problems. It also provides a structure for handling preprocessed LP problems.

## Structs

### `LPProblem`

```@docs
lp_problem.LPProblem
```

The `LPProblem` struct is used to represent a linear programming problem. It contains the following fields:

- **`is_minimize::Bool`**: Whether the problem is a minimization problem (`true`) or maximization (`false`).
- **`c::Vector{Float64}`**: The coefficients of the objective function.
- **`A::SparseMatrixCSC{Float64, Int64}`**: The sparse matrix of constraints.
- **`b::Vector{Float64}`**: The right-hand side values of the constraints.
- **`l::Vector{Float64}`**: The lower bounds for the decision variables.
- **`u::Vector{Float64}`**: The upper bounds for the decision variables.
- **`vars::Vector{String}`**: The names of the decision variables.
- **`constraint_types::Vector{Char}`**: The types of constraints (e.g., `<=`, `>=`, `=`).

### `MIPProblem`

```@docs
lp_problem.MIPProblem
```

The `MIPProblem` struct extends `LPProblem` to include information about the variable types, making it suitable for mixed integer programming problems. It contains the following additional field:

- **`variable_types::Vector{Symbol}`**: The types of the variables, which can be `:Binary`, `:Integer`, or `:Continuous`.

### `PreprocessedLPProblem`

```@docs
lp_problem.PreprocessedLPProblem
```

The `PreprocessedLPProblem` struct is used to store both the original and preprocessed versions of a linear programming problem during preprocessing. It also keeps track of rows and columns that have been removed.

- **`original_problem::LPProblem`**: The original LP problem.
- **`reduced_problem::LPProblem`**: The reduced LP problem after preprocessing.
- **`removed_rows::Vector{Int}`**: The indices of rows removed during preprocessing.
- **`removed_cols::Vector{Int}`**: The indices of columns removed during preprocessing.
- **`row_ratios::Dict{Int, Tuple{Int, Float64}}`**: Maps removed rows to their corresponding row and ratio.

## Examples

### Creating an LP Problem

To create a linear programming problem using the `LPProblem` struct:

```julia
using lp_problem

c = [1.0, 2.0, 3.0]
A = sparse([1.0, 0.0, 0.0, 1.0, 1.0, 1.0], 2, 3)
b = [4.0, 6.0]
l = [0.0, 0.0, 0.0]
u = [10.0, 10.0, 10.0]
vars = ["x1", "x2", "x3"]
constraint_types = ['L', 'L']

lp = LPProblem(true, c, A, b, l, u, vars, constraint_types)
```