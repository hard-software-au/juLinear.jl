# `LpRevisedSimplex` Module

The `LpRevisedSimplex` module provides an implementation of the revised simplex method for solving linear programming (LP) problems.

## Functions

### `RevisedSimplex`

```@docs
LpRevisedSimplex.revised_simplex
```

The `RevisedSimplex` function solves a linear programming problem using the revised simplex method. It takes an `LPProblem` struct as input, converts it to standard form, and iteratively finds the optimal solution using the simplex algorithm.

### Arguments

- `lp::LPProblem`: An `LPProblem` struct representing the linear programming problem to be solved.

### Returns

- `solution::Vector{Float64}`: The optimal values for the decision variables in the LP problem.
- `optimal_value::Float64`: The optimal objective value, calculated from the solution.

### Method Overview

1. Converts the given LP problem to its standard form.
2. Initializes the basis using slack variables.
3. Iteratively adjusts the basis, solving the LP problem.
4. Checks for optimality by evaluating reduced costs.
5. Handles unboundedness, if detected.
6. Returns the optimal solution and objective value when found.

### Usage Example

```julia
lp = LPProblem(
    is_minimize = true,
    c = [-3.0, -2.0],
    A = sparse([1.0 2.0; 1.0 1.0]),
    b = [4.0, 2.0],
    l = [0.0, 0.0],
    u = [Inf, Inf],
    vars = ["x1", "x2"],
    constraint_types = ['L', 'L']
)

solution, optimal_value = revised_simplex(lp)
println("Optimal solution: ", solution)
println("Optimal value: ", optimal_value)
```

### Notes

- This function prints detailed iteration logs, including the current basis, reduced costs, dual variables, and any entering or leaving variables.
- The function assumes that the LP problem is bounded and feasible. If the problem is unbounded or a maximum number of iterations is reached (set at 10 for demonstration purposes), the function will terminate with an error.

## Examples

### Solving a Linear Programming Problem

```julia
lp = LPProblem(
    is_minimize = true,
    c = [-3.0, -2.0],
    A = sparse([1.0 2.0; 1.0 1.0]),
    b = [4.0, 2.0],
    l = [0.0, 0.0],
    u = [Inf, Inf],
    vars = ["x1", "x2"],
    constraint_types = ['L', 'L']
)

solution, optimal_value = revised_simplex(lp)
println("Optimal solution: ", solution)
println("Optimal value: ", optimal_value)
```
In this example, the revised simplex method is used to solve a simple linear programming problem with two decision variables, `x1` and `x2`. The function finds the optimal values of the decision variables and calculates the optimal objective value.