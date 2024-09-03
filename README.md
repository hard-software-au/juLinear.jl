# Linear Programming Code Repository

This repository contains a collection of linear programming (LP) prototypes aimed at understanding and exploring different procedures used in solving LP problems. The project includes implementations of various algorithms, utilities for reading and processing LP data, and interactive Jupyter notebooks that guide you through the intricacies of these methods. The primary focus is on providing a hands-on, educational resource for anyone interested in the mechanics of linear programming.

## Introduction

Linear programming is a powerful mathematical method used to optimize a linear objective function, subject to linear equality and inequality constraints. This project serves as a comprehensive resource for students, researchers, and practitioners who wish to deepen their understanding of LP by exploring and implementing various LP procedures.

### Key Objectives of This Project:
- **Prototype Development**: Provide prototype implementations of classic and modern LP algorithms, such as the Simplex method and Interior-Point methods.
- **Educational Resource**: Offer well-documented code and interactive notebooks to facilitate learning and experimentation with LP techniques.
- **Algorithm Exploration**: Allow users to experiment with different approaches to LP, including presolve techniques, revised simplex methods, and MPS file parsing.

Whether you're a beginner trying to grasp the basics of linear programming or an advanced user exploring the nuances of LP solvers, this repository offers a practical, hands-on experience.

### Directories

- **LaTeX**: Contains LaTeX documents related to the project. This may include reports, documentation, or any other typesetting related files.

- **check**: This directory contains test scripts and benchmark MPS files.

  - **benchmarks/mps_files**: Contains various MPS files used for benchmarking the LP algorithms.
  
  - **test**: Contains test scripts to validate the functionality of various modules in the repository.
  
- **docs**: Documentation and diagrams related to the project.

  - **diagrams**: Contains visual representations, including PNGs and SVGs, that support the project's documentation.

- **src**: The primary directory for the Julia programming files and Jupyter notebooks related to linear programming.

  - **code**: Contains Julia scripts that define constants, utility functions, problem definitions, and MPS file reading utilities.
  
    - `lp_constants.jl`: Contains constants used across various modules.
    - `lp_problem.jl`: Defines the structure and methods for representing linear programming problems.
    - `lp_read_mps.jl`: Functions for reading and parsing MPS files.
    - `lp_read_mps_mip.jl`: Functions for reading and parsing MPS files for MIP problems.
    - `lp_utils.jl`: Utility functions used throughout the project.
  
  - **notebooks**: Jupyter notebooks used for interactive exploration, development, and demonstration of linear programming concepts and algorithms.
  
    - `lp_claude_revised_simplex.ipynb`: Notebook demonstrating the revised simplex method.
    - `lp_read_mps_notebook.ipynb`: Notebook for reading and parsing MPS files interactively.
    - `lp_revised_simplex_notebook.ipynb`: Exploration of the revised simplex method.
    - `lp_llama_ipm.ipynb`: Implementation of an interior-point method for solving LP problems.
    - `lp_presolve_notebook.ipynb`: Notebook focused on presolve techniques in linear programming.
    - `lp_simplex_tableau.ipynb`: First exploration of tableau.
  
  - **tools**: Contains additional scripts and tools that support the main codebase, such as analysis scripts.

## Usage

### Adding New Modules

To add a new Julia module, place your `.jl` file in the `src/code` directory and update the `LOAD_PATH` in your scripts or notebooks to include the new module. Example:

```julia
push!(LOAD_PATH, realpath("../code"))
using new_module_name

