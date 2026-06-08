# Design: tmux session persistence across reboot

**Date:** 2026-06-07
**Status:** Approved
**Branch:** ccc-config-1 (branch/PR strategy decided at implementation time)
**Depends on:** TPM bootstrap (PR #31 / `2026-06-06-tmux-tpm-bootstrap-design.md`)

## Goal

After a machine reboot, the first time the user runs `tmux`, their windows, panes,
layout, and per-pane working directories are restored, and each Claude Code pane
resumes its conversation via `claude --continue`.

Restore trigger (chosen): **restore when tmux is next launched** — no launchd boot
agent, nothing auto-starts. continuum auto-saves in the background; `@continuum-restore`
brings sessions back the moment the tmux server next starts.

## Background

`tmux/tmux.conf` already declares the needed plugins but never configured them:

- `tmux-plugins/tmux-resurrect` (line 49) — save/restore session state.
- `tmux-plugins/tmux-continuum` (line 50) — periodic auto-save + restore-on-launch.

No `@resurrect-*` or `@continuum-*` options are set anywhere. The plugins are also not
yet installed (TPM bootstrap landed in PR #31; plugins install via `prefix + I`).

Claude Code supports resume: `-c, --continue` (continue the most recent conversation in
the current directory) and `-r, --resume [id]`. Because resurrect restores each pane's
cwd, `claude --continue` in a restored pane resumes that directory's latest conversation.

## Design

### 1. Install plugins (one-time, user's machine)

`prefix + I` inside tmux installs all declared TPM plugins, including resurrect and
continuum (and sensible/yank/prefix-highlight/solarized — already declared, expected).

### 2. tmux.conf — session persistence block

Add to the plugins section **before** the `run '$HOME/.tmux/plugins/tpm/tpm'` line (56),
so the plugins read the options at load:

```tmux
# --- session persistence (resurrect + continuum) ---
set -g @continuum-restore 'on'                 # auto-restore on tmux server start
set -g @resurrect-capture-pane-contents 'on'   # snapshot scrollback (read the pre-reboot screen)
# relaunch Claude Code panes as `claude --continue` (exact rule verified in implementation)
set -g @resurrect-processes '"~claude->claude --continue"'
```

- continuum auto-saves every 15 min by default (no extra config). A reboot loses at most
  ~15 min of layout changes — acceptable.
- `@continuum-restore 'on'` provides the chosen "restore on next tmux launch" behavior.

### 3. Claude resume — the experimental piece (must be verified)

Risk: the running pane process reports as its **version string** (e.g. `2.1.167`), not
`claude` or `node`. resurrect relaunches by matching the saved process name, so the
`@resurrect-processes '"~claude->claude --continue"'` rule (resurrect's "match loosely →
restore with custom command" syntax) may not match.

Verification + fallbacks, in order of preference:
1. Confirm the `@resurrect-processes` arrow/tilde rule matches and relaunches
   `claude --continue`. (Verify exact syntax against the resurrect README during
   implementation.)
2. If it doesn't match: a resurrect `@resurrect-hook-post-restore-all` script that
   detects the claude panes and sends `claude --continue`.
3. Worst case: restore shells in the correct cwd only; user runs `claude --continue`
   (or the `/resume` picker) manually.

Known caveat of `--continue`: it picks the most recent conversation for a directory. Two
panes sharing one cwd would both resume the same conversation; distinct project dirs (the
normal case here) map cleanly one-to-one.

## Verification

The real test, not just config review:
1. Save state (`prefix + Ctrl-s`, or let continuum auto-save).
2. `tmux kill-server`.
3. Relaunch `tmux`.
4. Confirm: windows/panes/layout restored, each pane in its prior cwd, scrollback visible,
   and Claude Code panes resume the correct conversation.

Not "done" until a session is observed coming back after a kill-server cycle.

## Scope guard (YAGNI)

- No `@continuum-boot` launchd agent (no auto-start at login).
- No `--resume <session-id>` capture.
- No restoring vim or other programs beyond the claude rule.
- No changes to the other plugins' configuration.
