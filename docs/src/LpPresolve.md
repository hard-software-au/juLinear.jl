# LpPresolve Module

The `LpPresolve` module provides several utility functions for preprocessing linear programming problems by removing redundant rows, columns, and detecting linearly dependent constraints.

## Functions

### `lp_remove_zero_rows`

```@docs
LpPresolve.lp_remove_zero_rows
```

### `lp_remove_row_singletons`

```@docs
LpPresolve.lp_remove_row_singletons
```

### `lp_detect_and_remove_fixed_varibles`

```@docs
LpPresolve.lp_detect_and_remove_fixed_variables
```

### `lp_remove_zero_columns`

```@docs
LpPresolve.lp_remove_zero_columns
```

### `lp_remove_linearly_dependent_rows`

```@docs
LpPresolve.lp_remove_linearly_dependent_rows
```

### `presolve_lp`

```@docs
LpPresolve.presolve_lp
```

## Examples

Here’s an example of how to use the `lp_presolve` module:

```julia
using lp_presolve

# Create an LP problem (lp_problem)
preprocessed_lp = presolve_lp(lp_problem, debug=true)

# Check the results after presolve
println("Preprocessed Problem: ", preprocessed_lp)
```
