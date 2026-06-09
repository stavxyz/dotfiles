---
validated:
  sha: 8dc69ad81c2e54591b3d6c08d8a4f0c6fcf3a048
  date: 2026-06-09T19:15:31Z
  reviewers: [fact-check, solid-hygiene]
  findings:
    critical: 0
    important: 2
    medium: 2
    low: 9
    nitpick: 0
  net_negative_remaining: 0
---

# Design: bulletproof per-pane Claude Code resume across reboot

**Date:** 2026-06-09
**Status:** Approved
**Branch:** ccc-config-1 (branch/PR strategy decided at implementation time)
**Builds on:** tmux session persistence (`2026-06-07-tmux-session-persistence-design.md`, Tasks 1–3 shipped: continuum restore + resurrect pane-contents capture). Supersedes the parked Claude-resume work — Tasks 4–5 of the *implementation plan* derived from that spec, not the design doc.

## Goal

After a reboot, each restored tmux pane that was running Claude Code resumes **its own exact
conversation** by session ID — not "the most recent conversation in the directory." This
eliminates the same-cwd collision (two panes in one directory must resume two different
sessions).

## Why the obvious approaches don't work

- **`claude --continue`** resumes the most-recent conversation *per directory* → two panes
  sharing a cwd collide. (Real in the user's layout: multiple panes in
  `/Users/stavxyz/src/stavxyz-agent`.)
- **tmux-resurrect alone** only records the command that *launched* each pane. Panes launched
  with `-r` (interactive picker) don't carry a session ID, so resurrect can only replay `-r`.
- **`lsof`** on a running claude pid shows no open session `.jsonl` → can't map pane→session
  that way.

## Key enabling facts (verified)

- `CLAUDE_CODE_SESSION_ID` IS present in the environment of Claude Code child processes
  (confirmed: it equals the live session UUID). A Claude Code **hook** runs as a child, so it
  can read both `$CLAUDE_CODE_SESSION_ID` and `$TMUX_PANE`.
- `claude --resume <id>` deterministically reattaches to exactly that session.
- Sessions are stored at `~/.claude/projects/<encoded-cwd>/<session-uuid>.jsonl`; existence of
  that file confirms a session is resumable.
- tmux-resurrect's save file records each pane's full command line (e.g.
  `:claude --dangerously-skip-permissions -r` — empirically confirmed in a real save, not just
  the bare command name) and identifies panes by `(session_name, window_index, pane_index)`.
  That the command field carries the full launch line (with flags) is part of load-bearing
  assumption #1 below.

## Architecture (B1: post-save rewrite)

Capture the live pane→session mapping via a Claude hook; at resurrect save time, rewrite the
save file so each claude pane's restore command becomes `claude <flags> --resume <id>`.
resurrect's normal restore then replays it — the ID is baked into the saved artifact, so there
are no restore-time races.

Alternatives rejected: a PATH wrapper shadowing `claude` (too invasive; affects every
invocation; create≠resume translation), and post-restore keystroke injection (timing-fragile;
must re-map freshly-assigned pane IDs).

### Components

All scripts live together in one repo feature directory `tmux-claude-resume/` (public, generic)
— grouped so the feature's files and their shared contract sit in one place, and named
distinctly from the repo's existing *project-local* `.claude/` tooling dir to avoid confusion.
They deploy to stable paths under `~/.config/tmux-claude-resume/` via a `dotfiles.yaml` symlink
entry (`~/.config/tmux-claude-resume/: tmux-claude-resume/*`), matching the repo's existing
`~/.config/...` link convention — so nothing references a hardcoded repo-checkout path.

The hook registration is injected into the user's **global** `~/.claude/settings.json` by an
idempotent installer. That file is personal and is **never committed**. Note: the repo also
contains an *untracked, unrelated* project-local `.claude/settings.json` (this repo's own Claude
config) — a distinct file at a different path. The installer targets the absolute
`~/.claude/settings.json` and must not be conflated with the repo-local one.

**Registry helper — `tmux-claude-resume/registry.sh` (single owner of the registry contract).**
Defines, in exactly one place, the registry directory (`~/.cache/tmux-claude-resume/`), the
`pane_id → filename` sanitization, the `session_id<TAB>cwd` line format, and read/write/prune
functions. Both hooks source it, so a format change can't silently desync the two scripts into
universal `-r` fallback.

1. **Capture hook — `tmux-claude-resume/record-tmux-session.sh`** (deployed to
   `~/.config/tmux-claude-resume/record-tmux-session.sh`)
   - Registered as a `SessionStart` hook (matchers `startup`, `resume`).
   - If `$TMUX` is unset → no-op (not in tmux).
   - Else records `{pane_id → session_id, cwd}` **via the shared registry helper**, reading
     `$CLAUDE_CODE_SESSION_ID`, `$TMUX_PANE`, `$PWD`. (Does not hand-roll the path/format.)
   - Idempotent; overwrites on every start/resume so the entry is always current.
   - Inputs: env vars. Output: one registry file. Independently testable.

2. **Injection hook — `tmux-claude-resume/resurrect-inject-claude-resume.sh`** (deployed to
   `~/.config/tmux-claude-resume/resurrect-inject-claude-resume.sh`)
   - Wired via `@resurrect-hook-post-save-all`. Runs after resurrect writes its save file.
   - Resolves the save file (`<@resurrect-dir>/last`).
   - Builds a live join table: `tmux list-panes -a -F
     '#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_id}'`.
   - For each save-file `pane` line whose command field contains `claude`:
     - Find `pane_id` via the join on `(session_name, window_index, pane_index)`.
     - Look up `session_id` **via the shared registry helper**, keyed by `pane_id`.
     - If found AND `~/.claude/projects/<slug>/<session_id>.jsonl` exists → rewrite command to
       `claude <preserved-flags> --resume <session_id>`.
     - Else → rewrite to `claude <preserved-flags> -r` (the chosen fallback).
     - "Preserved flags" = the saved command minus any existing `-r`/`--resume <x>`/`-c`/
       `--continue` (e.g. `--dangerously-skip-permissions` is kept).
   - Prunes registry entries whose pane no longer exists.
   - Inputs: save file + live panes + registry. Output: rewritten save file. Testable with
     fixtures.

3. **tmux.conf additions** (in the existing persistence block):
   - `set -g @resurrect-processes '~claude'` (so resurrect restores claude panes at all).
   - `set -g @resurrect-hook-post-save-all 'bash ~/.config/tmux-claude-resume/resurrect-inject-claude-resume.sh'`
     — the deployed symlink path, so the committed `tmux.conf` carries no hardcoded
     repo-checkout location (consistent with the rest of the file using `$HOME`/`~` paths).

4. **Installer** — idempotently merges the `SessionStart` hook entry into the absolute
   `~/.claude/settings.json` (jq or python), skipping if already present; never a relative
   `.claude/settings.json` (which would hit the repo-local file). Does not commit settings.json.
   Deployment of the scripts themselves is handled by the new `dotfiles.yaml` link entry
   (`~/.config/tmux-claude-resume/: tmux-claude-resume/*`) run via `./dot.py link`, keeping
   deployment single-mechanism rather than an installer-managed side path.

> **Design note (2026-06-09, validate):** Reviewer feedback tightened three seams in this
> section: (1) the registry is now a **single-owner contract** (`registry.sh` sourced by both
> hooks) instead of a format duplicated across two scripts; (2) script **deployment is defined**
> — one feature dir `tmux-claude-resume/` symlinked to `~/.config/tmux-claude-resume/` via
> `dotfiles.yaml`, with no hardcoded repo-checkout path in the committed `tmux.conf`; (3) the
> installer targets the **absolute** `~/.claude/settings.json`, explicitly distinct from the
> repo's untracked project-local `.claude/settings.json`.

### Data flow

claude starts/resumes in a pane → capture hook records `pane→session_id` → continuum auto-saves
(every 15 min) or manual save → post-save hook bakes `--resume <id>` (or `-r`) per claude pane →
reboot → continuum-restore replays the save file → each pane runs `claude … --resume <id>` and
resumes its own conversation.

### Edge cases / error handling

- Not in tmux → capture hook no-ops.
- No captured id, or session `.jsonl` aged out (Claude's 30-day cleanup) → restore command is
  `claude <flags> -r` (picker).
- Stale registry entries (closed panes) → pruned at save time.
- Multiple sessions over a pane's life → registry holds the latest (the active one). Correct.
- A saved `--resume <id>` whose session disappears between save and reboot → claude opens the
  picker. Acceptable.

## Load-bearing assumptions to verify first (spikes, before building)

1. tmux-resurrect replays the save file's command field for `~`-matched processes (so rewriting
   the field changes what gets launched).
2. `@resurrect-hook-post-save-all` fires after save, with the save file resolvable.

If either is false, fall back to architecture B2 (post-restore keystroke injection) — but only
after the spikes, not speculatively. Switching to B2 discards Components 2–3 (the injection hook
and the `@resurrect-*` wiring) and changes the testing strategy; the capture hook (Component 1)
and the registry helper survive unchanged. Therefore do NOT build Components 2–3 until
assumption #1 is confirmed — the spike gates a possible redesign, not a tweak.

## Testing

- **Capture hook:** invoke with `TMUX`, `TMUX_PANE`, `CLAUDE_CODE_SESSION_ID`, `PWD` set; assert
  the registry file contents. Assert no-op when `$TMUX` unset.
- **Injection hook:** fixture a synthetic resurrect save file + a synthetic registry + a stub
  pane-join; assert mapped claude lines become `--resume <id>`, unmapped become `-r`, non-claude
  lines untouched, and other flags preserved.
- **Installer:** run twice; assert the hook is present once (idempotent) and unrelated
  settings.json keys are untouched.
- bats tests under `tests/`.
- **Manual gated E2E:** real claude panes (incl. two sharing a cwd) → save → `tmux kill-server`
  → restart → verify each pane resumed its *own* session.

## Scope / YAGNI

- tmux + Claude Code only. No cross-machine sync. No GUI.
- `~/.claude/settings.json` is injected idempotently, never committed.
- Reuses the continuum/resurrect machinery already enabled in Tasks 1–3; does not re-implement
  save/restore.
