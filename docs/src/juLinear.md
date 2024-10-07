# `juLinear` Module

The `juLinear` module provides functionality to load, parse, and solve linear programming (LP) problems from MPS files. It supports different methods for solving LP problems, including the simplex method, and allows for command-line argument parsing to configure the solver.

## Functions

### `parse_commandline`

```@docs
juLinear.parse_commandline
```

Parses command-line arguments using the ArgParse package. The following options are supported:

- `--filename, -f`: Path to the problem file in MPS format (required).
- `--interior, -i`: Use the interior point method (LP only).
- `--min`: Minimize the objective function (default).
- `--max`: Maximize the objective function.
- `--no_presolve`: Skip the presolve step (default is false).
- `--simplex, -s`: Use the simplex method (default).
- `--verbose, -v`: Enable verbose output.

### Example Usage

```
bash
julia juLinear.jl --filename problem.mps --simplex --min --verbose
```

---

### `load_lp_problem`

```@docs
juLinear.load_lp_problem
```

### Example Usage

```julia
lp = load_lp_problem("problem.mps")
println(lp)
```

---

### `handle_lp_operations`

```@docs
juLinear.handle_lp_operations
```

This function processes the LP problem based on the parsed command-line arguments and decides whether to run the simplex method, skip presolve, or use an interior point method (if implemented).

### Example Usage

```julia
handle_lp_operations(parsed_args)
```

### main
```@docs 
juLinear.main 
```

The main execution function for the lp_solver module. It parses command-line arguments, handles the problem type (minimization or maximization), and calls the appropriate solving method.

Example Command
Run the solver with the following command:

```bash 
julia juLinear.jl --filename "../check/problems/mps_files/ex_9-7.mps" --min --simplex --no_presolve --verbose
```

Additional Information

The `juLinear` module is designed to be used with command-line tools and can load and solve linear programming problems in MPS format. By using the various arguments, you can customize how the problem is solved and which method is used.