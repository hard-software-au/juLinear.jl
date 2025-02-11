# Unit Tests for juLinear

This directory contains all the unit tests for the juLinear program, ensuring the reliability and correctness of its components.


## Table of Contents
- [Overview](#overview)
- [Test Files](#test-files)
- [Running the Unit Tests](#running-the-unit-tests)
  - [Running All Unit Tests](#running-all-unit-tests)
  - [Running Individual Unit Tests](#running-individual-unit-tests)
  - [Interpreting the Results](#interpreting-the-results)
- [Creating Unit Tests](#creating-unit-tests)
- [Manually Creating Unit Tests](#)


## Overview
The unit tests for juLinear are designed to validate the functionality of various components, ensuring that:

- MPS and LP files are read and parsed correctly.
- The program correctly identifies and handles non-linear or non-standard terms by
raising appropriate errors.
- The internal representation (`LPProblem` structure) matches expected outcomes for given input files.

## Test Files
- `TestFramework.jl`: Contains the main framework module for running the unit tests and creating new test files.
- `run_all_tests.jl`: This file runs all the tests.
- `test_helpers`: Provides utility functions and helpers used across multiple test cases.
- `test_read_mps.jl`: Contains unit tests for the MPS file reader.
- `test_read_lp.jl`: Contains unit tests for the LP file reader.
- `test_standard_form_converter.jl" :  Contains unit tests for the standard form converter.


## Running the Unit Tests

First, navigate to the test directory:

```bash
  cd /check/test
```

### Running All Unit Tests

To run all the unit tests, use the following command:

```bash
  julia run_all_tests.jl
```

### Running Individual Unit Tests

1. First open the julia REPL inside the test directory:
```bash
  push!(LOAD_PATH, ".")
  using TestFramework
  run_tests(["method_A", "method_B", ... ])
```

2. Next load the path and import the TestFramework module:
```julia
push!(LOAD_PATH, ".")
using TestFramework
```
3. Now the tests can be run using the run_tests function:
```julia
run_tests(["ReadMPS", "ReadLp"])
```
- Additonally, there is a option for the verbose of test:
```julia
run_tests([test_modules],verbose=true)
```
### Example Unit Test Output

For demostrative purposes the test logs of a passed and failed test can be seen below.

#### Example of Passed test
```julia
Test Summary: | Pass  Total  Time
All Tests     |   88     88  0.5s
```

#### Example of Failed Test
```julia
Test Summary:                           | Pass  Fail  Total  Time
All Tests                               |  151     1    152  6.6s
  MPS Reader Tests                      |  151     1    152  0.6s
    Tests for ex4-3.mps                 |   23           23  0.3s
    Tests for ex_9-7.mps                |   32           32  0.0s
    Tests for problem.mps               |   20           20  0.1s
    Tests for simple.mps                |   20           20  0.0s
    Tests for test.mps                  |   24           24  0.0s
    Tests for blend.mps                 |   32     1     33  0.3s
      LPProblem Structure Tests         |   24           24  0.0s
      Specific values                   |    8     1      9  0.3s
        LPProblem Specific Values Tests |    8     1      9  0.3s
ERROR: Some tests did not pass: 151 passed, 1 failed, 0 errored, 0 broken.
```

### Interpeting the Results
- Pass: Number of tests that succeeded.
- Fail: Number of tests that failed assertions.
- Error: Number of tests that encountered unexpected errors.
- Total: Total number of tests executed.
- Time: Duration taken to run the tests.

## Creating Unit Tests

New unit tests can be created either manually or using a function from the `TestFrameworks module`.

### Using TestFrameworks Module to Create Unit Tests

First navigate to the test directory in your julia REPL.

Then Run the following Command:
```julia
using TestFrameworks
create_module_tests(module_name)
```

This will create a template for the unit test. Which can be expanded with module specific tests occording to the functionality of the module it is testing.

###  Manually

Copy the formatting of the other unit tests.


<!-- ## Issues -->


