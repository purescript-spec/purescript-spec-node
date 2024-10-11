# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.0.3

## Changed

- `runSpecAndExitProcess'` and `runSpecAndGetResults` now work for any test tree
  generator monad, via the new `TestTreeGenerator` class.

## 0.0.2

### Changed

- **Breaking**: `runSpecAndExitProcess'` now takes named parameters
  `defaultConfig` and `parseCLIOptions`, allowing to specify, respectively, the
  default config and whether that config should be used as is or CLI options (if
  any provided) should be applied on top of it.
- Replaced `runSpecT` with `evalSpecT` as the former is now deprecated.

### Added

- Added comments where appropriate.
