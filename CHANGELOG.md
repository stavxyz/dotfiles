# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

**Dot Extensions** (`lib/dot-extensions.sh`):
- Extensions are repos cloned (or symlinked) into `~/.dot/extensions/<name>/` that mirror
  this repo's shape — manifest, modules, optional `install.sh`, payload — every part
  optional. Discovered in lexical order and loaded *after* the host (last writer wins)
- `bash_profile` loads extension modules via the shared `load_dotfiles_modules` loader
  (which also replaced the four duplicated host module-loading loops); `install.sh`
  bootstraps and links every extension idempotently, isolating per-extension failures so
  one broken extension never blocks the rest
- `run_if_changed` state names support per-extension subdirectories
  (`~/.dot/state/<ext>/<module>.hash`); host state names unchanged
- See the README "Extensions" section for the contract, load order, override semantics,
  and trust model

**Tmux Plugin Bootstrap**:
- `install.sh` now installs TPM (Tmux Plugin Manager) into `~/.tmux/plugins/tpm` if missing,
  so the plugins declared in `tmux.conf` actually load (run `prefix + I` to install them)
- Hardened the Solarized colorscheme source lines with `source -q` so a missing plugin no
  longer errors on tmux startup

**Tmux Session Persistence** (tmux-resurrect + tmux-continuum):
- `@continuum-restore` — sessions auto-restore the next time you start tmux after a reboot
- `@resurrect-capture-pane-contents` — pre-reboot scrollback is restored too
- Restores windows, panes, layout, and per-pane working directories

**Per-Pane Claude Code Resume** (`tmux-claude-resume/`):
- After a reboot, each restored tmux pane resumes *its own* Claude Code conversation by
  session ID — eliminating the same-directory collision that `claude --continue` suffers
- A `SessionStart` hook records `pane → session_id`; a resurrect post-save hook rewrites each
  claude pane's restore command to `claude <your-flags> --resume <id>` (or the `-r` picker if
  the session is gone). Your launch flags (e.g. `--dangerously-skip-permissions`) are preserved
- Idempotent installer wires the hook into `~/.claude/settings.json`; scripts deploy via
  `dotfiles.yaml` to `~/.config/tmux-claude-resume/`
- See `tmux-claude-resume/README.md` for setup and how it works

**Development Infrastructure**:
- Claude Code GitHub workflows (`claude-on-mention`, `claude-pr-review`)
- `docs/ENGINEERING_STANDARDS.md` and `CONTRIBUTING.md`
- bats test suites for the tmux persistence and Claude-resume features

### Changed

**direnv Integration**:
- direnv now loads immediately by default instead of lazy loading
- Removed `DOTFILES_LAZY_DIRENV` configuration option
- Rationale: Lazy loading broke direnv's core auto-loading feature
- Performance impact: ~4-5ms overhead per command (negligible)

### Fixed

**Completions actually register now**:
- Lazy mode sourced completion files in a backgrounded subshell and eager mode inside a
  command substitution — in both cases the `complete` registrations were made in a child
  process and silently lost. Lazy mode now loads via a one-shot `PROMPT_COMMAND` hook in
  the parent shell at first prompt (startup stays fast); eager mode sources directly
- `install.sh` now fetches the completion scripts (`bin/fetch_autocompleters.sh` was never
  wired in, so fresh machines had no git/docker/brew completions to load)
- Validation tests exercise the mechanism hermetically plus a real end-to-end login-shell
  test; fixed the `autocomplete/.gitignore` whitelist naming the wrong file

### Removed

**BREAKING — Claude Code config moved to a private extension**:
- `claude/` (settings.json, global CLAUDE.md, skills/, agents/, commands/) and its
  symlink-guard module no longer live in this public repo; they moved to the private
  `dotfiles-private` extension. On a machine that pulls this change, the five
  `~/.claude/*` symlinks dangle until you clone your private extension to
  `~/.dot/extensions/private` and re-run `./install.sh`

## [dot 1.1.0] - 2026-07-07

- Relative link sources now resolve against the manifest: the `dotfiles`
  config key (previously ignored) when present, else the config file's
  directory. Previously they resolved against the process cwd, so
  `dot.py --config <path> link` only worked when run from the manifest's
  directory.
- New `link --force-relink` flag repoints existing symlinks that point at
  a different source, with a loud `Repointing <target>: was -> X, now -> Y`
  warning. Without the flag such symlinks are warned about and skipped;
  previously they aborted the entire run.
- Targets that exist as regular files or directories remain hard refusals.
- Glob-target directories that don't exist yet are now created on first link
  (previously "already exists and is not a directory" aborted a fresh bootstrap).
- A dangling symlink at a glob-target path now aborts with the clean error
  (`lexists`) instead of an unhandled traceback.
- Repointing under `--force-relink` is atomic (temp symlink + rename), so an
  interrupt can never leave the target missing.
- Packaging version in `pyproject.toml` synced to 1.1.0 (guarded by a test).

## [2.0.0] - 2025-11-25

### Added

**Performance System**:
- Configurable lazy loading for pyenv and completions
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

**Documentation**:
- Complete README rewrite with ultra-minimal, modern format
- Added performance metrics
- Added configuration examples
- Added troubleshooting section
- Updated install.sh with clear header documentation

**Configuration**:
- Users can now toggle lazy loading via environment variables:
  - `DOTFILES_LAZY_PYENV` (default: true)
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
