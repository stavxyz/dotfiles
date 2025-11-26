# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2025-11-25

### Added

**Performance System**:
- Configurable lazy loading for pyenv, direnv, and completions
- Eval result caching with TTL for expensive operations
- Async completion loading (13,000+ lines load in background)
- PATH optimization utilities
- Configuration system via environment variables

**Test Infrastructure**:
- bats-core automated testing framework
- Baseline tests for validation
- Performance benchmarks
- Validation tests run after each change

**New Modules**:
- `bash/utils.sh` - Utility functions (command_exists, safe_source, etc.)
- `bash/config.sh` - Central configuration system
- `bash/cache.sh` - Eval caching infrastructure
- `bash/lazy.sh` - Lazy loading for pyenv/direnv
- `bash/autocomplete-lazy.sh` - Async completion loading
- `bash/path.sh` - PATH management utilities

### Changed

**Performance**:
- Shell startup time: **2-3 seconds → 113ms** (95% improvement)
- Completions now load asynchronously by default
- Homebrew shellenv results cached
- Pyenv initialization deferred until first use
- Direnv initialization deferred until first use

**Documentation**:
- Complete README rewrite with ultra-minimal, modern format
- Added performance metrics
- Added configuration examples
- Added troubleshooting section
- Updated install.sh with clear header documentation

**Configuration**:
- Users can now toggle lazy loading via environment variables:
  - `DOTFILES_LAZY_PYENV` (default: true)
  - `DOTFILES_LAZY_DIRENV` (default: true)
  - `DOTFILES_LAZY_COMPLETIONS` (default: true)
  - `DOTFILES_CACHE_EVALS` (default: true)

### Fixed

**Shell Syntax Bugs**:
- Fixed 6+ unquoted variable expansions in bash_profile and aliases.sh
- Fixed debug() function missing quotes
- Fixed _err() function unquoted parameters
- Fixed autocomplete loop unquoted variables
- Fixed findfile() unquoted parameter
- Fixed jsonvalue() unquoted parameters

**Robustness**:
- Added tool validation before sourcing modules
- Modules gracefully handle missing dependencies (brew, pyenv, direnv)
- Changed trap removal to use 'set +e' for interactive mode
- Fixed typo: "deteced" → "detected" in dotfiles.sh

**Cross-platform**:
- Bash completion now works on macOS (Intel & Apple Silicon) and Linux
- Cache system handles both macOS and Linux stat commands
- Tool validation prevents errors when optional tools missing

### Testing

- All 11 validation tests passing
- Benchmark: 113ms average startup (target was <500ms)
- Tested on macOS with bash 5.3.3

---

## [1.0.0] - Previous

Legacy dotfiles configuration before modernization.
