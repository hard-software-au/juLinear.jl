# Project Documentation

Welcome to the documentation for this project, which provides tools and utilities for solving linear programming (LP) and mixed integer programming (MIP) problems in julia. The project is organized into different modules, each focusing on specific aspects of problem-solving, including preprocessing, problem formulation, and solution techniques.

## Modules

- [lp\_presolve](lp_presolve.md): This module provides functions for preprocessing LP problems, such as removing zero rows, zero columns, and linearly dependent rows.
  
- [lp\_problem](lp_problem.md): This module defines the data structures for representing LP and MIP problems, including the `LPProblem`, `MIPProblem`, and `PreprocessedLPProblem` structs.

- [lp\_read\_mps](lp_read_mps.md): This module contains functions for reading linear programming (LP) and mixed integer programming (MIP) problems from MPS (Mathematical Programming System) files. It supports reading from both file and string formats.

- [lp\_revised\_simplex](lp_revised_simplex.md): This module implements the revised simplex method for solving LP problems. It handles problem conversion to standard form, iteration over basis variables, and optimization checks.

- [lp\_standard\_form\_converter](lp_standard_form_converter.md): This module provides functions for converting LP and MIP problems into their standard forms, including handling constraints and slack variables.

- [lp\_solver](lp_solver.md): This module implements a commandline inteface for this linear program solver.
## Getting Started

To begin using the tools in this project, follow these steps:

1. **Install the required dependencies**: You will need to install Julia and any required packages for this project (e.g., `SparseArrays`, `JuMP`, `Documenter`).
   
2. **Explore the Modules**: Visit the module pages linked above to learn more about the functions and data structures provided by each module.

3. **Examples**: Each module page provides examples on how to create LP/MIP problems, preprocess them, and solve them.

## About the Project

This project focuses on solving optimization problems using linear programming and mixed integer programming techniques. It includes modules that help preprocess problems, formulate them, and solve them using various methods such as the revised simplex algorithm and MPS file readers.

For more detailed information, explore the individual modules and example usage.

---

For any questions or contributions, please refer to the project's [GitHub repository](https://github.com/your_username/your_project).

This is a code repository of HARDsoftware 

![HARDsoftware](hslogo_presentation.png)

