# `lLpProblem` Module

The `LpProblem` module defines data structures that represent linear programming (LP) and mixed integer programming (MIP) problems. It also provides a structure for handling preprocessed LP problems.

## Structs

### `LPProblem`

```@docs
LpProblem.LPProblem
```

### `PreprocessedLPProblem`

```@docs
LpProblem.PreprocessedLPProblem
```

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