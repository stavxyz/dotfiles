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

`install.sh` also checks that your login shell is a modern bash (the dotfiles
only load under bash) and offers to switch it — it always asks first, and
prints the manual `chsh` commands instead when run non-interactively.

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

## Extensions

Layer private, work, or experimental config on top of these dotfiles without
forking them. An extension is any repo cloned (or symlinked) into
`~/.dot/extensions/<name>/` that mirrors this repo's shape — every part
optional:

    <extension>/
      dotfiles.json        # symlink manifest (dot.py); omit the "dotfiles"
                           # key so sources resolve against the extension
      modules/static/      # NN-*.sh, sourced every shell, after host modules
      modules/static/<platform>/
      modules/dynamic/     # run-once-on-change, after host
      modules/dynamic/<platform>/
      install.sh           # optional idempotent bootstrap
      <payload>/           # whatever the manifest links to

Setup on a new machine:

    git clone git@github.com:you/dotfiles-private ~/.dot/extensions/private
    cd ~/dotfiles && ./install.sh   # discovers, bootstraps, and links it

Rules:

- Extensions load **after** the host, in lexical order (`10-work` before
  `50-private`) — last writer wins.
- Extension links may repoint host-owned symlinks; the extension loop passes
  `--force-relink`, and every repoint is warned loudly. Prefer layering via
  native includes (git `[include]`, bash source order) over link overrides.
- Modules must be ERR-trap-clean (never end a file with a possibly-false
  bare conditional — use `if` statements): one bad module breaks every
  shell startup, host and extension alike.
- `DOTFILES_EXTENSIONS_DIR` overrides the parent directory. Symlinked
  extension dirs work (clone anywhere, `ln -s` into place).
- **Trust model:** an extension is arbitrary shell code, sourced into every
  login shell and executed by `install.sh` with your full user privileges.
  Only place repos you trust in `~/.dot/extensions/`.
- One extension's failure never blocks the others: `install.sh` reports the
  failing extension loudly and continues bootstrapping the rest.
- Bootstrap ordering: if an app has already created a *real file* at a path
  an extension wants to link (e.g. Claude Code writing
  `~/.claude/settings.json` before the extension is cloned), the link phase
  refuses loudly rather than overwrite it. Move the file aside (or absorb
  its contents into the extension) and re-run `./install.sh`.

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
