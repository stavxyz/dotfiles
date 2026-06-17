# dotfiles

Fast, stable shell configuration for macOS and Linux, plus a zero-dependency dotfiles manager.

**Performance**: 113ms average shell startup time ⚡️

## Why This Project?

This repository serves **two purposes**:

1. **Production-ready dotfiles** - Fast, tested configs for Bash, Vim, Git, and Tmux
2. **Standalone dotfiles manager** - `dot.py`, a zero-dependency Python tool (published to PyPI)

Most dotfiles repositories force you to choose between **speed** and **features**. This project proves you can have both.

### The Dotfiles

**The Problem**: Traditional shell configurations are slow (500ms+ startup), fragile (break across systems), or bloated (load everything eagerly).

**This Solution**:
- ⚡️ **Fast**: 113ms startup via lazy loading, async completions, and eval caching
- 🔧 **Practical**: Battle-tested configs for Bash, Vim, Git, and Tmux that actually work
- 🌍 **Cross-platform**: Same config works on macOS and Linux without conditionals everywhere
- ✅ **Tested**: Automated tests for functionality and performance (keeps startup <150ms)

### The Tool (`dot.py`)

**The Problem**: Existing dotfiles managers like GNU Stow are powerful but complex, or they require heavy dependencies like Click/PyYAML.

**This Solution**:
- 📦 **Zero dependencies**: Pure Python stdlib (argparse, json, os, sys)
- 🐍 **Universal compatibility**: Works with Python 2.7+ and 3.6+ (old servers to modern systems)
- 📄 **Single file**: Compact implementation you can curl and run directly
- 🎯 **Simple**: Just creates symlinks with glob pattern support
- 🔧 **Standalone**: Use it for ANY dotfiles repo, not just this one

See [README-dot.md](README-dot.md) for `dot.py` documentation.

**Who is this for?**
- Developers who want a fast, reliable shell environment
- Anyone tired of 1-second shell startup times
- People managing configs across multiple machines/platforms
- Anyone who needs a lightweight dotfiles manager without dependencies

**What makes it different?**
Unlike other dotfiles repos, this prioritizes **performance metrics** and **cross-platform compatibility** as first-class features, not afterthoughts. Every change is benchmarked. Every module is tested on both macOS and Linux. And it includes a reusable tool (`dot.py`) that you can use with any dotfiles repository.

## Quick Start

```bash
git clone https://github.com/stavxyz/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Restart your terminal.

## What's Included

- **Bash**: Fast startup, git-aware prompt, cross-platform completions
- **Vim**: Modern config with vim-plug, Go/Ruby/JavaScript support
- **Git**: Powerful aliases (fpush, reup, changelog, main sync)
- **Tmux**: Vim keybindings, TPM plugins, session persistence across reboot, per-pane Claude Code resume, Solarized colors
- **Tools**: pyenv, direnv, fzf, volta integration

### Tmux session persistence

Tmux plugins are managed by [TPM](https://github.com/tmux-plugins/tpm), which `install.sh`
bootstraps automatically — run `prefix + I` inside tmux once to install the declared plugins.
With [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) +
[tmux-continuum](https://github.com/tmux-plugins/tmux-continuum), your windows, panes, layout,
working directories, and scrollback survive a reboot.

If you run Claude Code in tmux panes, [`tmux-claude-resume/`](tmux-claude-resume/README.md)
makes each restored pane resume **its own** conversation by session ID (no same-directory
collision). See its README to enable it.

## Requirements

**macOS**:
- Homebrew
- Bash 5+ (install via `brew install bash`)

**Linux**:
- Bash 4.3+
- Build tools for pyenv (optional)

## Platform Support

| Feature | macOS | Linux |
|---------|-------|-------|
| Bash config | ✓ | ✓ |
| Vim/Git/Tmux | ✓ | ✓ |
| Karabiner | ✓ | - |
| iTerm2 integration | ✓ | - |

## Configuration

Customize in `~/.bashrc` (before dotfiles load):

```bash
# Performance toggles (defaults shown)
export DOTFILES_LAZY_PYENV=true           # Lazy load pyenv
export DOTFILES_LAZY_COMPLETIONS=true     # Async completion loading
export DOTFILES_CACHE_EVALS=true          # Cache expensive evals

# Disable lazy loading for immediate availability
export DOTFILES_LAZY_PYENV=false          # Load pyenv eagerly
```

## Troubleshooting

**Slow startup?**
- Lazy loading is enabled by default for 113ms startup
- Check: `echo $DOTFILES_LAZY_COMPLETIONS` should be `true`

**Missing completion?**
- Completions load asynchronously (takes ~1 second after shell start)
- Check tool is installed: `which pyenv direnv brew`

**Command not found after setup?**
- Restart terminal completely
- Check PATH: `echo $PATH | grep homebrew`

## Development

### Dependencies

For local development and testing:

**Required:**
- [bats-core](https://github.com/bats-core/bats-core) - Bash automated testing
- [shellcheck](https://www.shellcheck.net/) - Shell script linting

**Optional:**
- [shfmt](https://github.com/mvdan/sh) - Shell script formatting

**Install on macOS:**
```bash
brew install bats-core shellcheck shfmt
```

**Install on Linux:**
```bash
# Debian/Ubuntu
sudo apt-get install bats shellcheck shfmt

# Arch
sudo pacman -S bats shellcheck shfmt
```

### Local Testing

Before submitting changes:

```bash
# Run full test suite
bats tests/

# Run validation tests only
bats tests/test-validate.bats

# Run performance benchmarks
bats tests/test-benchmark.bats

# Lint all shell scripts
find . -type f \( -name "*.sh" -o -name "bash_profile" -o -name "bashrc" -o -name "bash_aliases" \) \
  -exec shellcheck {} +

# Test shell startup
time bash -l -c exit
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed development guidelines.

## Testing

Run automated tests:

```bash
# Validate all functionality
bats tests/test-validate.bats

# Benchmark startup performance
bats tests/test-benchmark.bats
```

## Git Aliases

Powerful git shortcuts included:

- `git fpush` - Force push with lease (safe force push)
- `git reup` - Rebase onto origin/main
- `git main` - Sync with main branch
- `git changelog` - Generate changelog since last tag

Full list: see `git/gitconfig`
