# juLinear.jl Code Repository

This repository contains a collection of linear programming (LP) prototypes aimed at exploring and understanding various procedures used to solve LP problems. It includes implementations of multiple algorithms, utilities for reading and processing LP data, and interactive Jupyter notebooks for guided learning. The focus is on creating a hands-on, educational resource for anyone interested in linear programming mechanics.

## Table of Contents
1. [Introduction](#introduction)
    - [Key Objectives of This Project](#key-objectives-of-this-project)
2. [Directory Structure](#directory-structure)
    - [Root Directory](#root-directory)
    - [check](#check)
    - [docs](#docs)
    - [nb](#nb)
    - [res](#res)
    - [src](#src)
    - [tools](#tools)
3. [Usage](#usage)
    - [Command Line Options](#command-line-options)
4. [Contribution Guidelines](#contribution-guidelines)
5. [License](#license)

## Introduction

Linear programming is a powerful mathematical optimization technique used to solve problems with a linear objective function and linear constraints. This project serves as a resource for students, researchers, and practitioners who wish to deepen their understanding of LP by implementing and experimenting with various algorithms and techniques.

### Key Objectives of This Project
- **Prototype Development**: Provide prototypes of classic and modern LP algorithms, such as the Simplex method and Interior-Point methods.
- **Educational Resource**: Offer well-documented code and interactive notebooks to facilitate learning and experimentation.
- **Algorithm Exploration**: Enable users to explore different LP techniques, including presolve routines, revised simplex methods, and MPS file parsing.

Whether you're a beginner learning linear programming or an advanced user exploring solver nuances, this repository provides a practical, hands-on experience.

## Directory Structure

### Root Directory
- `.gitignore`: Git ignore file.
- `AUTHORS`: List of contributors to the repository.
- `CODE_OF_CONDUCT.md`: Code of Conduct for contributors.
- `CONTRIBUTING.md`: Guidelines for contributing to the project.
- `LICENSE.txt`: The project's license file.
- `Project.toml`: The Julia project configuration file.
- `README.md`: This readme file.

### check
- **problems**: Contains LP and MPS files used for testing.
  - `lp_files`: LP problem files like `1449a.lp`, `juLinear_ex1.lp`, etc.
  - `mps_files`: MPS problem files like `blend.mps`, `small_mip.mps`, etc.
- **test**: Test scripts for validating functionality.
  - `README.md`: Documentation for the test suite.
  - `test_framework.jl`: Main test framework.
  - `test_helpers.jl`: Helper functions for tests.
  - `test_mps.jl`: Tests for MPS file reading.
  - `test_read_LP.jl`: Tests for LP file reading.
  - `test_read_mps.jl`: Additional tests for MPS file reading.

### docs
- **LaTeX**: LaTeX documentation and reports.
  - `LP_Formulation.tex`, `sources.bib`: LaTeX files for reports.
- **build**: Compiled documentation generated using `Documenter.jl`.
- **src**: Markdown files used for documentation.
  - `lp_presolve.md`, `lp_problem.md`, etc.
- `make.jl`: Script to generate the documentation.

### nb
- **Jupyter Notebooks**: Interactive notebooks exploring LP concepts.
  - `lp_MIP_notebook.ipynb`: Mixed Integer Programming notebook.
  - `lp_revised_simplex_notebook.ipynb`: Revised Simplex method notebook.
  - `lp_interior_point_notebook.ipynb`: Interior point method exploration.
  - `test_o1_revised_simplex.ipynb`: Revised simplex method using OpenAI model.

### res
- **diagrams**: Diagrams used in the project documentation.
  - `Andersons-routine.svg`, `highs_presolve_routine.mmd`: Diagrams and mermaid files for visualizing LP methods.

### src
- **Julia Source Code**: Core modules for LP problem solving.
  - `juLinear.jl`: Main LP solver script with command-line support.
  - `lp_constants.jl`: Constants used across modules.
  - `lp_presolve.jl`: Presolve routines for preprocessing LP problems.
  - `lp_problem.jl`: Defines the LP problem data structure.
  - `lp_read_mps.jl`, `lp_read_LP.jl`: MPS and LP file parsers.
  - `lp_revised_simplex.jl`: Revised simplex solver.
  - `lp_standard_form_converter.jl`: Converts LP problems to standard form.
  - `lp_utils.jl`: Utility functions for LP operations.

### tools
- **Utilities**: Additional scripts supporting the project.
  - `analyse_git_logs.ipynb`: Analysis of git logs.
  - `nb_to_jl.py`: Script to convert Jupyter notebooks to `.jl` files.

## Usage

First, navigate to the `src` folder in the terminal and run the following command:
```bash
  julia juLinear.jl --filename "../check/problems/lp_files/ex_9-7.lp" --simplex  --verbose
```
```bash
  julia juLinear.jl --filename "../check/problems/mps_files/ex_9-7.mps" --simplex  --verbose
```

### Command Line Options
- `--filename`: Path to the MPS or LP file containing the LP problem.
- `--min`: Solve the problem as a minimization (default).
- `--max`: Solve the problem as a maximization.
- `--simplex`: Use the simplex method for solving the LP.
- `--no_presolve`: Skip the presolve step.
- `--verbose`: Enable verbose output.

## Adding to the Repository

### Adding New Modules

To add a new Julia module, place your `.jl` file in the `src` directory and update the `LOAD_PATH` in your scripts or notebooks to include the new module. For example:
```julia
    push!(LOAD_PATH, realpath("../code"))
    using new_module_name
```

### Running Tests

Make sure to add test cases in the `check/test` directory for any new functionality you introduce. You can run the tests using:
```bash
    julia test_framework.jl
```

## Contribution Guidelines

If you'd like to contribute, please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) file for instructions. Additionally, please review the Code of Conduct to ensure you adhere to our community standards.

## License

This project is licensed under the terms of the MIT License. For more details, see the [LICENSE](LICENSE.txt).