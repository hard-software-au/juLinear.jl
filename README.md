<a id="readme-top"></a>
# juLinear.jl Code Repository

This repository contains a collection of linear programming (LP) prototypes aimed at exploring and understanding various procedures used to solve LP problems. It includes implementations of multiple algorithms, utilities for reading and processing LP data, and interactive Jupyter notebooks for guided learning. The focus is on creating a hands-on, educational resource for anyone interested in linear programming mechanics.


<p align="right">(<a href="#readme-top">back to top</a>)</p>

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
4. [Adding to the Repository](#adding-to-the-repository)
    - [Adding New Modules](#adding-new-modules)
    - [Running Tests](#running-tests)
5. [Contribution Guidelines](#contribution-guidelines)
6. [Documentation](#documentation)
7. [License](#license)


<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Introduction

Linear programming is a powerful mathematical optimization technique used to solve problems with a linear objective function and linear constraints. This project serves as a resource for students, researchers, and practitioners who wish to deepen their understanding of LP by implementing and experimenting with various algorithms and techniques.

### Key Objectives of This Project
- **Prototype Development**: Provide prototypes of classic and modern LP algorithms, such as the Simplex method and Interior-Point methods.
- **Educational Resource**: Offer well-documented code and interactive notebooks to facilitate learning and experimentation.
- **Algorithm Exploration**: Enable users to explore different LP techniques, including presolve routines, revised simplex methods, and MPS file parsing.

Whether you're a beginner learning linear programming or an advanced user exploring solver nuances, this repository provides a practical, hands-on experience.


<p align="right">(<a href="#readme-top">back to top</a>)</p>

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
  - [`README.md`](check/Test/README.md): Documentation for the test suite.
  - `TestFramework.jl`: Main test framework.
  - `TestHelpers.jl`: Helper functions for tests.
  - `TestMPS.jl`: Tests for MPS file reading.
  - `TestReadLP.jl`: Tests for LP file reading.
  - `TestReadMPS.jl`: Additional tests for MPS file reading.

### docs
- **LaTeX**: LaTeX documentation and reports.
  - `LP_Formulation.tex`, `sources.bib`: LaTeX files for reports.
  - [`README`](docs/LaTeX/README.md): Contains documentation for LaTeX reports.
- **build**: Compiled documentation generated using `Documenter.jl`.
- **src**: Markdown files used for documentation.
  - `LpPresolve.md`, `lp_problem.md`, etc.
  - [`README.md`](docs/src/README.md): Contains documentation for julia documentation.
- `make.jl`: Script to generate the documentation.

### nb
- **Jupyter Notebooks**: Interactive notebooks exploring LP concepts.
  - [`LpSimplexTableau.ipynb`](nb/LpSimplexTableau.ipynb): First exploration of simplex tableau.
  - [`LpClaudeRevisedSimplex.ipynb`](nb/LpClaudeRevisedSimplex.ipynb): First exploration of linear programming using Anthropic's Claude AI.
  - [`LpLlamalpm.ipynb`](nb/LpLlamaIpm.ipynb): Use of Meta's Llama AI for linear programming methods and extends the LPClaudeRevisedSimplex code.
  - [`TestO1RevisedSimplex.ipynb`](nb/TestO1RevisedSimplex.ipynb): Revised simplex method using OpenAI model.
  - [`LpPresolveNotebook.ipynb`](nb/LpPresolveNotebook.ipynb): This notebook explores several presolving methods used to reduce the size of a linear programming problem.
  <!-- `LpMIPNotebook.ipynb`: Mixed Integer Programming notebook. -->
  - [`LpRevisedSimplexNotebook.ipynb`](nb/LpRevisedSimplexNotebook.ipynb): Revised Simplex method notebook.
  - [`LpReadLP`](nb/LpReadLPNotebook.ipynb): This notebook explores reading and writing cplex lp files.
  - [`LpReadMPS`](nb/LpReadMpsNotebook.ipynb): This notebook explores IBMs Mathematical Programming Files(MPS).
  <!-- `LpInteriorPointNotebook.ipynb`: Interior point method exploration. -->

### res
- **diagrams**: Diagrams used in the project documentation.
  - `Andersons-routine.svg`, `highs_presolve_routine.mmd`: Diagrams and mermaid files for visualizing LP methods.

### src
- **file_formats**: Modules for reading and writing LP problem files.
  - `lp_file_formater.jl`, `lp_read_lp.jl`, `lp_read_mps.jl`: Modules for handling different LP file formats.
- **preprocess**: Preprocessing routines for LP problems.
  - `lp_presolve.jl`: Presolve routines for preprocessing LP problems.
  - `lp_standard_form_converter.jl`: Converts LP problems to standard form.
- **problems**: Modules defining LP problems.
  - `lp_problem.jl`, `lp_problem_structs.jl`, `pre_lp_problem.jl`: Structs and data types for representing LP problems.
- **solvers**: Solvers for LP problems.
  - `lp_revised_simplex.jl`: Revised simplex solver.
- **utils**: Utility modules.
  - `lp_constants.jl`, `lp_utils.jl`: Constants and utility functions used throughout the project.
- `juLinear.jl`: Main LP solver script with command-line support.


### tools
- **Utilities**: Additional scripts supporting the project.
  - `AnalyseGitLogs.ipynb`: Analysis of git logs.
  - `NbToJl.py`: Script to convert Jupyter notebooks to `.jl` files.


<p align="right">(<a href="#readme-top">back to top</a>)</p>  

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


<p align="right">(<a href="#readme-top">back to top</a>)</p>

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
    julia check/test/RunAllTests.jl
```
For more information see this [README](check/test/README.md).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ## Documentation

The documentation for this Repository can be found in the [GitHub Pages](https://hard-software-au.github.io/juLinear.jl/docs/build/).

<p align="right">(<a href="#readme-top">back to top</a>)</p> -->

## Contribution Guidelines

If you'd like to contribute, please refer to the [CONTRIBUTING.md](CONTRIBUTING.md) file for instructions. Additionally, please review the Code of Conduct to ensure you adhere to our community standards.


<p align="right">(<a href="#readme-top">back to top</a>)</p>

## License

This project is licensed under the terms of the MIT License. For more details, see the [LICENSE](LICENSE.txt).
