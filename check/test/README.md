# Unit tests for juLinear

This directory contains all the unit tests for the juLinear program, ensuring the reliability and correctness of its components, including the MPS and LP file readers.


## Table of Contents
- [Overview](#overview)
- [Test Files](#test-files)
- [Running the Unit Tests](#running-the-unit-tests)
   - [Interpreting the Results](#interpeting-the-results)


## Overview
The unit tests for juLinear are designed to validate the functionality of various components, ensuring that:

- MPS and LP files are read and parsed correctly.
- The program correctly identifies and handles non-linear or non-standard terms by
raising appropriate errors.
- The internal representation (`LPProblem` structure) matches expected outcomes for given input files.

## Test Files
- `test_framework`: Contains the main framework for running the unit tests, including setup and teardown processes.
- `test_helpers`: Provides utility functions and helpers used across multiple test cases.
- `test_read_mps.jl`: Contains unit tests specifically for the MPS file reader.
- `test_read_LP.jl`: Contains unit tests for the LP file reader, including tests for both valid and corrupt LP files.


## Running the Unit Tests

```bash
cd /path/to/your/project/check/test
julia
```

```julia
push!(LOAD_PATH, ".")
using test_framework
```
```julia
run_tests(["ReadMPS","ReadLp"])
```
Additonally, there is a option for the verbose of test:
```julia
run_tests([test_modules],verbose=true)
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
#### Example of Passed test
```julia
Test Summary: | Pass  Total  Time
All Tests     |   88     88  0.5s
```

### Interpeting the Results
- Pass: Number of tests that succeeded.
- Fail: Number of tests that failed assertions.
- Error: Number of tests that encountered unexpected errors.
- Total: Total number of tests executed.
- Time: Duration taken to run the tests.
