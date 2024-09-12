# Linear Programming Code Repository

This repository contains a collection of linear programming (LP) prototypes aimed at understanding and exploring different procedures used in solving LP problems. The project includes implementations of various algorithms, utilities for reading and processing LP data, and interactive Jupyter notebooks that guide you through the intricacies of these methods. The primary focus is on providing a hands-on, educational resource for anyone interested in the mechanics of linear programming.

## Introduction

Linear programming is a powerful mathematical method used to optimize a linear objective function, subject to linear equality and inequality constraints. This project serves as a comprehensive resource for students, researchers, and practitioners who wish to deepen their understanding of LP by exploring and implementing various LP procedures.

### Key Objectives of This Project:
- **Prototype Development**: Provide prototype implementations of classic and modern LP algorithms, such as the Simplex method and Interior-Point methods.
- **Educational Resource**: Offer well-documented code and interactive notebooks to facilitate learning and experimentation with LP techniques.
- **Algorithm Exploration**: Allow users to experiment with different approaches to LP, including presolve techniques, revised simplex methods, and MPS file parsing.

Whether you're a beginner trying to grasp the basics of linear programming or an advanced user exploring the nuances of LP solvers, this repository offers a practical, hands-on experience.

### Directory Structure

- **check**: This directory contains test scripts and example MPS problem files.
  - **problems/mps_files**: Various MPS files used for testing and benchmarking LP algorithms.
  - **test**: Test scripts for validating the functionality of modules in the repository.

- **docs**: Documentation and diagrams related to the project.
  - **diagrams**: Visual representations, including PNGs and SVGs, supporting the project's documentation.
  - **LaTeX**: LaTeX files for reports, documentation, or other typesetting-related content.

- **src**: Julia source code for the LP solver.
  - `lp_constants.jl`: Constants used across various modules.
  - `lp_presolve.jl`: Functions for presolving LP problems.
  - `lp_problem.jl`: Defines the data structure of linear programming problems.
  - `lp_read_mps.jl`: Functions for reading and parsing MPS files.
  - `lp_read_mps_mip.jl`: Functions for reading and parsing MPS files for MIP problems.
  - `lp_revised_simplex.jl`: Revised simplex solver implementation.
  - `lp_standard_form_converter.jl`: Converts LP problems to standard form by adding slack variables.
  - `lp_utils.jl`: Utility functions used throughout the project.
  - `lp_solver.jl`: Main LP solver script with command-line argument support.

- **notebooks**: Jupyter notebooks for interactive exploration, development, and demonstration of LP concepts and algorithms.
  - `lp_claude_revised_simplex.ipynb`: Demonstration of the revised simplex method.
  - `lp_interior_point_notebook.ipynb`: Exploration of the interior point method.
  - `lp_llama_ipm.ipynb`: Implementation of an interior-point method for solving LP problems.
  - `lp_presolve_notebook.ipynb`: Notebook focused on presolve techniques in LP.
  - `lp_read_LP_notebook.ipynb`: Notebook for reading and parsing LP files.
  - `lp_read_mps_notebook.ipynb`: Interactive notebook for reading and parsing MPS files.
  - `lp_revised_simplex_notebook.ipynb`: Exploration of the revised simplex method.
  - `lp_simplex_tableau.ipynb`: First exploration of the simplex tableau.

- **tools**: Additional scripts and tools supporting the main codebase, such as analysis scripts.

## Usage

First, navigate to the `src` folder in the terminal and run the following command:
```bash
    julia we_need_a_name.jl --filename "../check/problems/mps_files/ex_9-7.mps" --min --simplex --no_presolve --verbose
```


### Command Line Options
- `--filename`: Path to the MPS file containing the LP problem.
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
    julia test_script.jl
```