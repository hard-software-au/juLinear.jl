# How to Contribute to juLinear.jl

Welcome! This document outlines how you can contribute to juLinear.jl. We appreciate your interest in improving our package.

## Code of Conduct

All contributors are expected to adhere to the [Code of Conduct](https://github.com/juLinear/juLinear.jl/blob/master/CODE_OF_CONDUCT.md). Please take a moment to review it before contributing.

## Communication

For general inquiries, bug reports, and discussion about the project, feel free to reach out via [GitHub Issues](https://github.com/juLinear/juLinear.jl/issues) or contact the maintainers directly.

## Improving Documentation

If you find any issues with the documentation or have ideas to improve it, contributions are welcome. For small changes like typo fixes or brief corrections, please fork the repository and create a pull request. For larger changes affecting multiple files, consider raising an issue first to outline your proposal before starting any work.

## Raising Issues

You can raise issues in the normal way via [GitHub Issues](https://github.com/juLinear/juLinear.jl/issues). If you're reporting a bug, providing detailed steps to reproduce the issue will help us resolve it faster.

## Contributing Code to juLinear.jl

**juLinear.jl** is an open-source project, and contributions from the community are encouraged! Whether you're fixing a bug, adding a feature, or improving documentation, we welcome your involvement.

### How to Contribute

#### 1. Fork the Repository
- Navigate to the [juLinear.jl repository](https://github.com/YOUR-REPO-LINK) and click the "Fork" button in the top-right corner.
- Clone your fork locally:

   ```bash
   git clone https://github.com/YOUR-USERNAME/juLinear.jl.git
   cd juLinear.jl
#### 2. Create a New Branch
- Use a descriptive branch name following the format `initials/short-description`, for example:

   ```bash
   git checkout -b ry/fix-typo
#### 3. Make Your Changes
- Ensure your changes align with the project's coding standards. See Coding Guidelines below for details.
- Keep commits focused: Make sure each commit represents a single change or improvement. If you're working on multiple changes, split them into separate commits.
- Run all relevant tests to ensure your changes don't introduce new bugs.

#### 4. Testing Your Changes
- Ensure all tests pass before submitting. We rely on tests to verify the stability of the project. You can run the test suite using:

   ```bash
   julia --project test/runtests.jl
- If you're adding new functionality, please include corresponding tests to validate your contributions.

#### 5. Submit a Pull Request (PR)
- Once you're ready, push your changes to your fork and open a PR to the main branch of the original repository.


   ```bash
   git push origin YOUR-BRANCH-NAME

- After pushing, follow these steps to open a Pull Request (PR) to the main branch of the original repository:

  - Go to your forked repository on GitHub (https://github.com/YOUR-USERNAME/juLinear.jl).
  - You should see a prompt at the top of the repository page suggesting to compare and open a Pull Request for the recently pushed branch. Click **"Compare & pull request"**.
  - On the "Open a Pull Request" page, ensure the base repository is set to the original repository (ORIGINAL-REPO-NAME/main), and the compare branch is your forked branch (YOUR-USERNAME/YOUR-BRANCH-NAME).
- In your PR description, provide:
  - A summary of what your changes address (linking any related issues if applicable).
  - Any additional context or details that may be helpful for reviewers.
  - Steps to reproduce the issue (if it's a bug fix).
  - Details on any new tests or validation done for the changes.
  - Click **"Create pull request"** to submit your PR for review.

#### 6. Review Process
- After opening a pull request, one of the project maintainers will review it. You may receive feedback or requests for changes, so be prepared for a collaborative process.
- Once approved, your changes will be merged into the main branch.

#### 7. Updating Your PR
- If changes are requested in your PR, make the necessary updates and push the revised code to your branch.

   ```bash
   git push origin YOUR-BRANCH-NAME
- GitHub will automatically update your pull request with the new changes.

### Branching Conventions
Please follow these branch-naming conventions:

- **Bugfixes**: `initials/fix-description`, e.g., `ab/fix-boundary-condition`
- **Features**: `initials/feature-description`, e.g., `xy/feature-dual-simplex`
- **Documentation**: `initials/docs-description`, e.g., `mn/docs-api-updates`

### Coding Guidelines

- **Code Style**: Follow [BlueStyle](https://github.com/invenia/BlueStyle), the Julia code style guide, to ensure consistent and readable code. Use the project JuliaFormatter configuration file `.JuliaFormatter.toml` and apply the formatting to your code prior to creating any Pull Requests.
- **Comments**: Use comments to explain non-obvious code, especially complex logic. Keep comments clear and concise.
- **Function Names**: Follow Julia naming conventions, i.e., use lowercase function names with words separated by underscores (`_`).
- **Documentation**: If your contribution includes new functionality, ensure the relevant parts of the code are documented with clear usage examples.

### License Agreement

By contributing to juLinear.jl, you agree to assign the rights of your contributions under the terms of the MIT License.
