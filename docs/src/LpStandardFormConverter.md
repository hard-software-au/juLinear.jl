# `lp_standard_form_converter` Module

The `lp_standard_form_converter` module provides functions for converting linear programming (LP) and mixed integer programming (MIP) problems into their standard form. The standard form is necessary for the simplex method, it involved adding slack varibles to convert inequalities to equalities.

## Functions

### `convert_to_standard_form`

```@docs
lp_standard_form_converter.convert_to_standard_form
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

### `convert_to_standard_form_mip`

```@docs
lp_standard_form_converter.convert_to_standard_form_mip
```

This function transforms a given `MIPProblem` into its standard form, which includes converting the objective function to a minimization problem, ensuring all constraints are inequalities, and handling variable bounds and types through additional constraints and slack variables.

### Arguments

- `mip::MIPProblem`: A struct representing the Mixed Integer Programming problem, containing the objective function, constraints, bounds, and variable types.

### Returns

- `new_A::SparseMatrixCSC`: The transformed constraint matrix in standard form.
- `new_b::Vector{Float64}`: The transformed right-hand side of the constraints.
- `new_c::Vector{Float64}`: The transformed objective function coefficients.
- `new_variable_types::Vector{Symbol}`: The updated variable types, including any slack variables added during the transformation.

### Method Details

- Adds constraints to handle lower and upper bounds by introducing slack variables.
- Ensures all constraints are in standard form (inequalities) and adjusts the right-hand side accordingly.
- Adjusts the objective function if the problem is a maximization (standard form assumes minimization).

### Usage Example

```julia
using lp_standard_form_converter

mip = MIPProblem(
    is_minimize = false,  # Maximization problem
    c = [4.0, 5.0],
    A = sparse([3.0 2.0; 4.0 1.0]),
    b = [6.0, 5.0],
    l = [0.0, 0.0],
    u = [Inf, Inf],
    vars = ["x1", "x2"],
    variable_types = [:Binary, :Integer],
    constraint_types = ['L', 'L']
)

new_A, new_b, new_c, new_variable_types = convert_to_standard_form_mip(mip)
println("New A: ", new_A)
println("New b: ", new_b)
println("New c: ", new_c)
println("New variable types: ", new_variable_types)
```

## Additional Information

Converting LP and MIP problems to standard form is essential for many solvers, as it ensures that the problem is in a form that the solver can handle efficiently.

---
For any questions or contributions, please refer to the project's [GitHub repository](https://github.com/your_username/your_project).
