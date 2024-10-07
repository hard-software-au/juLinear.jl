# `LpReadMPS` Module

The `LpReadMPS` module provides functions for reading linear programming problems from MPS (Mathematical Programming System) files. 
## Functions

### `read_file_to_string`

```@docs
LpReadMPS.read_file_to_string
```

Reads the contents of a file and returns it as a string. This is often used to read MPS files into a string format before parsing them into a problem structure.

**Usage Example:**

```julia
mps_string = read_file_to_string("path/to/file.mps")
```


### `read_mps`

```@docs
LpReadMPS.read_mps
```

Reads an MPS problem from a file and converts it into an `LPProblem` struct.

**Usage Example:**

```
julia
lp_problem = read_mps_from_file("path/to/file.mps")
```

### `read_mps_from_string`

```@docs
LpReadMPS.read_mps_from_string
```

### `get_variable_type`

```@docs
LpReadMPS.get_variable_type
```

### `read_mps_with_JuMP`

```@docs
LpReadMPS.read_mps_with_JuMP
```

Reads a Linear Programming problem from an MPS file using JuMP and converts it into a `LPProblem` struct. This function relies on the JuMP and MathOptInterface packages for parsing and handling MIP problems.

**Usage Example:**

```julia
lp_problem = read_mps_with_JuMP("path/to/file.mps")
```

## Examples

### Reading an LP Problem from an MPS File

```julia
lp_problem = read_mps("examples/test.mps")
println(lp_problem)
```

## Additional Information

The `lp_read_mps` module provides tools for handling MPS files, which are commonly used in optimization tasks. These files encode linear and mixed integer programming problems in a standard format that can be parsed and processed by solvers.

For more detailed information on the MPS format, refer to [MPS documentation](https://en.wikipedia.org/wiki/MPS_(format)).
