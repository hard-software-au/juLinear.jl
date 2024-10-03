# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of `juLinear.jl` with core features including LP problem parsing, revised simplex implementation, and MPS file support.
- Added `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md` files to guide new contributors.
- Added presolve routines for preprocessing LP problems.
- `lp_read_mps.jl` and `lp_read_LP.jl` for reading MPS and LP file formats.
- `lp_revised_simplex.jl` for solving LP problems using the revised simplex method.
- `lp_standard_form_converter.jl` for converting problems into standard form.
- Test cases and problem examples in `check/problems/` directory.

### Changed
- Improved the accuracy of `lp_simplex.jl` with better error handling and precision.
- Enhanced the documentation structure under `docs/`, including new sections for presolve routines.

### Fixed
- Fixed parsing errors in `lp_read_LP.jl` for files with missing newline at EOF.
- Corrected bug in the revised simplex method when detecting unbounded solutions.

## [0.1.0] - YYYY-MM-DD

### Added
- Initial release with support for reading LP and MPS files, solving linear programs using revised simplex, and testing framework for validating core functions.
