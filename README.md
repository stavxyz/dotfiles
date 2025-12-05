# dotfiles

Fast, stable shell configuration for macOS and Linux.

**Performance**: 113ms average shell startup time ⚡️

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
- **Tmux**: Vim keybindings, session persistence, Solarized colors
- **Tools**: pyenv, direnv, fzf, volta integration

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
