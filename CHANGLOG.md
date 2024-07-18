# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] 2024-07-18

### Changed

- compiling is notably slower but more robust

### Fixed

- deeply nested relative includes are correctly imported (fixes #2)
- duplicate includes are skipped (fixed #3)

## [0.4.2] 2024-01-31

### Changed

- project renamed to escompile, script renamed to escompile.sh

## [0.4.1] 2024-01-05

### Changed

- updated shebang
- updated copyright date

## [0.4.0] 2023-12-27

### Fixed

- better regex matching for include statements

## [0.3.6] 2023-11-08

### Fixed

- fix for unbound variable (`-` added at end of array reference)

## [0.3.5] 2023-11-07

### Fixed

- whitespace wasn't being honored on include files

## [0.3.4] 2023-10-24

### Fixed

- bad variable reference for missing file stderr output
- fix include path search to account for fix in 0.3.3

## [0.3.3] 2023-10-23

### Fixed

- now respects full path for [FILE] arg

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

- script renamed to escompile.sh

### Fixed

- Script now works with files that have an incomplete last line ([Lost string · Issue #1](https://github.com/joshbduncan/escompile/issues/1))

## [0.1.0] - 2022-09-26

### Added

- First official release!
