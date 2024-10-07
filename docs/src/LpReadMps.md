# `lp_read_mps` Module

The `lp_read_mps` module provides functions for reading linear programming problems from MPS (Mathematical Programming System) files. These functions support both standard LP problems and Mixed Integer Programming (MIP) problems.

## Functions

### `read_mps_from_string`

```@docs
lp_read_mps.read_mps_from_string
```

Reads an MPS problem from a string input and converts it into an `LPProblem` struct.

**Usage Example:**

```julia
mps_string = """
NAME          TESTPROB
ROWS
 N  OBJ
 L  CON1
 G  CON2
...
ENDATA
"""
lp_problem = read_mps_from_string(mps_string)
```

### `read_mps_from_file`

```@docs
lp_read_mps.read_mps_from_file
```

Reads an MPS problem from a file and converts it into an `LPProblem` struct.

**Usage Example:**

```
julia
lp_problem = read_mps_from_file("path/to/file.mps")
```

### `read_mps_from_string_mip`

```@docs
lp_read_mps.read_mps_from_string_mip
```

Reads a Mixed Integer Programming (MIP) problem from a string input and converts it into a `MIPProblem` struct.

**Usage Example:**

```julia
mps_string_mip = """
NAME          TESTMIP
ROWS
 N  OBJ
 L  CON1
 G  CON2
...
ENDATA
"""
mip_problem = read_mps_from_string_mip(mps_string_mip)
```

### `read_mps_from_file_mip`

```@docs
lp_read_mps.read_mps_from_file_mip
```

Reads a Mixed Integer Programming (MIP) problem from a file and converts it into a `MIPProblem` struct.

**Usage Example:**

```julia
mip_problem = read_mps_from_file_mip("path/to/file.mps")
```

### `read_file_to_string`

```@docs
lp_read_mps.read_file_to_string
```

Reads the contents of a file and returns it as a string. This is often used to read MPS files into a string format before parsing them into a problem structure.

**Usage Example:**

```julia
mps_string = read_file_to_string("path/to/file.mps")
```

### `get_variable_type`

```@docs
lp_read_mps.get_variable_type
```

### `read_mps_with_JuMP_MIP`

```@docs
lp_read_mps.read_mps_with_JuMP_MIP
```

Reads a Mixed Integer Programming (MIP) problem from an MPS file using JuMP and converts it into a `MIPProblem` struct. This function relies on the JuMP and MathOptInterface packages for parsing and handling MIP problems.

**Usage Example:**

```julia
mip_problem = read_mps_with_JuMP_MIP("path/to/file.mps")
```

## Examples

### Reading an LP Problem from an MPS File

```julia
lp_problem = read_mps_from_file("examples/test.mps")
println(lp_problem)
```

### Reading a MIP Problem from a String

```julia
mps_string = """
NAME          BLEND
ROWS
 N  PROFIT
 L  LIMIT1
 G  LIMIT2
...
ENDATA
"""
mip_problem = read_mps_from_string_mip(mps_string)
println(mip_problem)
```

## Additional Information

The `lp_read_mps` module provides tools for handling MPS files, which are commonly used in optimization tasks. These files encode linear and mixed integer programming problems in a standard format that can be parsed and processed by solvers.

For more detailed information on the MPS format, refer to [MPS documentation](https://en.wikipedia.org/wiki/MPS_(format)).

---
For any questions or contributions, please refer to the project's [GitHub repository](https://github.com/your_username/your_project).
