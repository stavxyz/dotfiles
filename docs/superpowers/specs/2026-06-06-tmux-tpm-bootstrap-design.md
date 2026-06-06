# Design: Bootstrap TPM and harden tmux plugin sourcing

**Date:** 2026-06-06
**Status:** Approved
**Branch:** ccc-config-1

## Problem

On tmux startup the following error appears:

```
/Users/stavxyz/dotfiles/tmux/tmux.conf:61: /Users/stavxyz/.tmux/plugins/tmux-colors-solarized/tmuxcolors-dark.
 No such file or directory
```

Root cause: the dotfiles bootstrap never installs TPM (tmux plugin manager).
`tmux/tmux.conf` declares 8 plugins via TPM (including `seebi/tmux-colors-solarized`)
and runs `'$HOME/.tmux/plugins/tpm/tpm'`, but `~/.tmux/` does not exist. None of the
plugins load. Line 61 then unconditionally `source`s a solarized colorscheme file from a
plugin that was never downloaded, producing the error. `install.sh` and `dotfiles.yaml`
contain no TPM setup, so this breaks on every fresh machine.

## Scope

Fix the root cause (bootstrap) and the visible symptom (unguarded source). Two files:

1. `install.sh` — bootstrap TPM.
2. `tmux/tmux.conf` — guard the solarized `source` lines.

### Out of scope (YAGNI)

- Auto-running `tpm/bin/install_plugins` (plugins install via `prefix + I`, TPM's standard UX).
- Reordering `install.sh` vs `./dot.py link`.
- Touching the other 7 declared plugins or unrelated tmux config.

## Design

### 1. `tmux/tmux.conf` — guard the source lines

tmux is 3.3a; `source-file -q` (suppress error if file is missing, tmux 3.0+) is available.

Change lines 61–62 from `source ...` to `source -q ...`:

```
if '[ "$ITERM_PROFILE" = "dark" ]'  'source -q $HOME/.tmux/plugins/tmux-colors-solarized/tmuxcolors-dark.conf'  ''
if '[ "$ITERM_PROFILE" = "light" ]' 'source -q $HOME/.tmux/plugins/tmux-colors-solarized/tmuxcolors-light.conf' ''
```

Result: no error whether or not the solarized plugin is installed. Once installed
(`prefix + I`), the colorscheme still applies normally.

### 2. `install.sh` — bootstrap TPM

Add an idempotent block mirroring the existing vim-plug block, placed after the
Vim Plugin Manager section:

```bash
# ============================================================================
# TMUX Plugin Manager (TPM)
# ============================================================================

if [[ -d ~/.tmux/plugins/tpm ]]; then
    echo "✓ TPM (tmux plugin manager) already installed"
else
    echo "Installing TPM (tmux plugin manager)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
```

Also:
- Update the header comment block ("Prerequisites installed" + update-method notes) to
  mention TPM.
- Update the closing "Next steps" to note that inside tmux, `prefix + I` installs the
  declared plugins.

### 3. Local fix-up (this machine)

Run the same clone now so the current machine works, then the user presses `prefix + I`
once and reloads tmux.

## Testing

- `bash -n install.sh` (syntax) and `shellcheck install.sh` (lint — note: root
  `install.sh` is not in CI's shellcheck path, so run locally).
- Idempotency: the new block prints the ✓ branch on a second run.
- Reload tmux (`tmux source-file ~/.tmux.conf`) and confirm the line-61 error is gone.

## Commit / PR

Commit on existing feature branch `ccc-config-1` (not main).
