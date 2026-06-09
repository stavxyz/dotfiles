# Design: bulletproof per-pane Claude Code resume across reboot

**Date:** 2026-06-09
**Status:** Approved
**Branch:** ccc-config-1 (branch/PR strategy decided at implementation time)
**Builds on:** tmux session persistence (`2026-06-07-tmux-session-persistence-design.md`, Tasks 1–3 shipped: continuum restore + resurrect pane-contents capture). Supersedes that plan's parked Tasks 4–5.

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
  `:claude --dangerously-skip-permissions -r`) and identifies panes by
  `(session_name, window_index, pane_index)`.

## Architecture (B1: post-save rewrite)

Capture the live pane→session mapping via a Claude hook; at resurrect save time, rewrite the
save file so each claude pane's restore command becomes `claude <flags> --resume <id>`.
resurrect's normal restore then replays it — the ID is baked into the saved artifact, so there
are no restore-time races.

Alternatives rejected: a PATH wrapper shadowing `claude` (too invasive; affects every
invocation; create≠resume translation), and post-restore keystroke injection (timing-fragile;
must re-map freshly-assigned pane IDs).

### Components

All scripts live in the dotfiles repo (public, generic). The hook registration is injected into
`~/.claude/settings.json` by an idempotent installer — that file is personal and is **never
committed**.

1. **Capture hook — `claude/hooks/record-tmux-session.sh`**
   - Registered as a `SessionStart` hook (matchers `startup`, `resume`).
   - If `$TMUX` is unset → no-op (not in tmux).
   - Else write `~/.cache/tmux-claude-resume/<sanitized-pane-id>` containing
     `session_id<TAB>cwd` from `$CLAUDE_CODE_SESSION_ID`, `$TMUX_PANE`, `$PWD`.
   - Idempotent; overwrites on every start/resume so the entry is always current.
   - Inputs: env vars. Output: one registry file. Independently testable.

2. **Injection hook — `tmux/resurrect-inject-claude-resume.sh`**
   - Wired via `@resurrect-hook-post-save-all`. Runs after resurrect writes its save file.
   - Resolves the save file (`<@resurrect-dir>/last`).
   - Builds a live join table: `tmux list-panes -a -F
     '#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_id}'`.
   - For each save-file `pane` line whose command field contains `claude`:
     - Find `pane_id` via the join on `(session_name, window_index, pane_index)`.
     - Look up `session_id` in the registry by `pane_id`.
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
   - `set -g @resurrect-hook-post-save-all 'bash <repo>/tmux/resurrect-inject-claude-resume.sh'`.

4. **Installer** — idempotently merges the `SessionStart` hook entry into
   `~/.claude/settings.json` (jq or python), skipping if already present. Does not commit
   settings.json.

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
after the spikes, not speculatively.

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
