# `LpStandardFormConverter` Module

The `LpStandardFormConverter` module provides functions for converting linear programming (LP) problems into their standard form. The standard form involves adding slack varibles to convert inequalities to equalities and converting problem to a minimisation.

## Functions

### `convert_to_standard_form`

```@docs
LpStandardFormConverter.convert_to_standard_form
```

This function transforms a given `LPProblem` into its standard form, which includes converting the objective function to a minimization problem, ensuring all constraints are inequalities, and handling variable bounds through additional constraints.

### Arguments

- `lp::LPProblem`: A struct representing the Linear Programming problem, containing the objective function, constraints, and bounds.

### Returns

- `new_A::SparseMatrixCSC`: The transformed constraint matrix in standard form.
- `new_b::Vector{Float64}`: The transformed right-hand side of the constraints.
- `new_c::Vector{Float64}`: The transformed objective function coefficients.

### Method Details

- Handles lower and upper bounds for variables by adding additional constraints if necessary.
- Ensures all constraints are in the form of inequalities (either `<=` or `>=`).
- Adjusts the objective function to fit the standard form, which assumes a minimization problem.

### Usage Example

```julia
using lp_standard_form_converter

lp = LPProblem(
    is_minimize = false,  # Maximization problem
    c = [2.0, 3.0],
    A = sparse([1.0 1.0; 2.0 1.0]),
    b = [5.0, 8.0],
    l = [0.0, 0.0],
    u = [Inf, Inf],
    vars = ["x1", "x2"],
    constraint_types = ['L', 'L']
)

new_A, new_b, new_c = convert_to_standard_form(lp)
println("New A: ", new_A)
println("New b: ", new_b)
println("New c: ", new_c)
```

---

## Additional Information

Converting LP and MIP problems to standard form is essential for many solvers, as it ensures that the problem is in a form that the solver can handle efficiently.

---
For any questions or contributions, please refer to the project's [GitHub repository](https://github.com/your_username/your_project).
