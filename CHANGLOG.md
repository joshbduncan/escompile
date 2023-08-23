# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.2] 2023-08-23

### Changed

- bash execution protection
- processing of arguments

## [0.3.1] 2023-05-10

### Fixed

- bash execution protection flags
    - set -o errexit
    - set -o pipefail
    - set -o nounset

## [0.3.0] 2023-03-13

### Added

- nested 'includes' allow including files from within another include file
- `--version` flag

### FIXED

- `importpath` statements with multiple paths were getting mishandled
- single-quoted ('') `importpath` and `import` statements now allowed

## [0.2.1] 2022-10-03

### Changed

- Updated README.md

## [0.2.0] 2022-09-27

### Added

- -h/--help option
- argument validator
- error checking

### Changed

- script renames to escompile.sh

### Fixed

- Script now works with files that have an incomplete last line ([Lost string · Issue #1](https://github.com/joshbduncan/extendscript-compiler/issues/1))

## [0.1.0] - 2022-09-26

### Added

- First official release!
