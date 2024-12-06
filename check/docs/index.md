# Unit Tests and Problems

## Modules
- [Test Framework](TestFramework.md)
- [TestHelpers](TestHelpers.md)


## Indiviual Unit Tests
Each unit test file targets a specific component of the `juLinear` codebase:

- **`RunAllTests.jl`**: Executes all the test files in one go. This is useful for continuous integration (CI) setups or general checks before deployment.
- **`TestFramework.jl`**: The main framework for creating and running tests. This file should not be modified unless adding new testing capabilities.
- **`TestHelpers.jl`**: Contains utility functions and helper methods used across multiple tests, such as generating sample data or common assertions.
- **`TestReadMps.jl`**: Tests for reading MPS files. This file ensures that the MPS parser functions correctly and can handle various MPS formats.
- **`TestReadLP.jl`**: Tests for reading LP files. These tests validate that the LP file reader correctly interprets LP problem definitions.
- **`TestStandardFormConverter.jl`**: Tests for converting LP problems into their standard forms. It verifies the correctness of transformations applied to constraints and variables.

The `RunAllTests.jl` file can be used to run all the unit test