# tmux-claude-resume

Make each tmux pane resume **its own** Claude Code conversation after a reboot.

tmux-resurrect/continuum already restore your windows, panes, layout, and working
directories across a reboot. But a restored pane only knows the command that *launched*
it — so a pane started with `claude -r` (the resume picker) just reopens the picker, and
`claude --continue` resumes "the most recent conversation in the directory," which
**collides** when two panes share a working directory. This feature closes that gap: every
restored Claude pane reattaches to the exact session it was on, by session ID.

## How it works

Three small bash units, plus two tmux options:

1. **`record-tmux-session.sh`** — a Claude Code `SessionStart` hook. It runs inside each
   pane (so it sees `$CLAUDE_CODE_SESSION_ID` and `$TMUX_PANE`) and records a
   `pane → session_id` mapping. No-op outside tmux.
2. **`registry.sh`** — the single owner of the registry schema (one file per pane under
   `~/.cache/tmux-claude-resume/`, holding `session_id<TAB>cwd`). Both hooks source it.
3. **`resurrect-inject-claude-resume.sh`** — a tmux-resurrect `@resurrect-hook-post-save-all`
   hook. After each save it rewrites every claude pane's saved command to
   `claude <your-flags> --resume <id>`, looking the ID up by joining the save file's
   `(session, window, pane_index)` to the live panes and then to the registry. Your other
   flags (e.g. `--dangerously-skip-permissions`) are preserved.

Flow: claude starts → hook records the pane's session → continuum auto-saves (every 15 min)
→ the post-save hook bakes `--resume <id>` into the save file → reboot → continuum restores
→ each pane runs `claude … --resume <id>` and resumes its own conversation.

**Fallback:** if a pane's session ID isn't known or its transcript no longer exists
(`~/.claude/projects/<cwd>/<id>.jsonl` is gone — e.g. Claude's 30-day cleanup), that pane
falls back to `claude … -r` (the resume picker). Never the wrong conversation.

## Enable it

Prerequisites: `tmux-resurrect` + `tmux-continuum` installed (via TPM: `prefix + I`), `jq`,
and Claude Code. The persistence options live in `tmux/tmux.conf` already.

```bash
./dot.py link                                       # symlinks scripts into ~/.config/tmux-claude-resume/
bash ~/.config/tmux-claude-resume/install-hook.sh   # registers the SessionStart hook in ~/.claude/settings.json
tmux source-file ~/.tmux.conf
```

`install-hook.sh` is idempotent and only touches the global `~/.claude/settings.json`
(never a repo-local `.claude/settings.json`). That's it — start using Claude in tmux panes
and they'll be recorded automatically.

## Verify

Start `claude` in two panes sharing one directory, then:

```bash
cat ~/.cache/tmux-claude-resume/*   # distinct session ids per pane
tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh
grep claude "$(tmux show-options -gv @resurrect-dir 2>/dev/null || echo ~/.tmux/resurrect)/last"
# each claude pane line ends with its own `--resume <id>`
tmux kill-server && tmux             # continuum auto-restores → each pane resumes its own conversation
```

## Files

| File | Role |
|------|------|
| `registry.sh` | Single-owner registry schema (path, key sanitization, record/lookup/prune) |
| `record-tmux-session.sh` | Claude `SessionStart` hook — records `pane → session_id` |
| `resurrect-inject-claude-resume.sh` | resurrect post-save hook — rewrites restore commands |
| `install-hook.sh` | Idempotent installer for the `SessionStart` hook |

Tests live in `tests/test-tmux-claude-*.bats`. Design docs:
`docs/superpowers/specs/2026-06-09-tmux-claude-resume-design.md` and the matching plan.
