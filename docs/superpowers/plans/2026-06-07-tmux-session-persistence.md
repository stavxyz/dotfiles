---
validated:
  sha: 5468123758741fe40418f9f9ab8601ed92bf244a
  date: 2026-06-08T03:32:45Z
  reviewers: [fact-check, solid-hygiene]
  findings:
    critical: 0
    important: 0
    medium: 0
    low: 2
    nitpick: 0
  net_negative_remaining: 0
---

# tmux Session Persistence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make tmux sessions (windows, panes, layout, working directories, scrollback) survive a machine reboot, with Claude Code panes resuming their conversation via `claude --continue`.

**Architecture:** Activate the already-declared-but-unconfigured `tmux-resurrect` + `tmux-continuum` plugins by adding a small block of `set -g @...` options to `tmux/tmux.conf` before the TPM `run` line. continuum auto-saves periodically and auto-restores on the next tmux launch (no launchd boot agent). Claude panes are relaunched via a single inline `@resurrect-processes` rule whose match string is tuned empirically to the real captured command line.

**Tech Stack:** tmux 3.3a, TPM (already bootstrapped), tmux-resurrect, tmux-continuum, bats (test harness).

**Spec:** `docs/superpowers/specs/2026-06-07-tmux-session-persistence-design.md` (blessed).

**Branch note:** This work depends on the TPM bootstrap in PR #31. Decide at execution start whether to stack on `ccc-config-1` or branch fresh off `main` after #31 merges. The commit steps below are branch-agnostic.

---

## File Structure

- **Modify:** `tmux/tmux.conf` — add a "session persistence" block (3 option lines + 1 comment) immediately after the last `set -g @plugin` line (line 53) and before the `# Initialize TMUX plugin manager` comment (line 55). This is the only repo source change.
- **Create:** `tests/test-tmux-persistence.bats` — bats test asserting the persistence options are set when the config is sourced. Mirrors the existing `tests/*.bats` structure (`setup`/`teardown`, `@test` blocks) but derives `DOTFILES_DIR` with a single `..` so it resolves to the repo root — deliberately diverging from the existing three bats files, whose `$(dirname "$BATS_TEST_DIRNAME")/..` form resolves one level *above* the repo. *(Verified 2026-06-07: was incorrect — the new test does not match the existing `DOTFILES_DIR` derivation; it intentionally uses the correct single-`..` form.)*

No new scripts, no hook files: per the spec's Design note (2026-06-07), the Claude-restore behavior has exactly **one** owner — the inline `@resurrect-processes` rule. The post-restore-hook alternative from the spec's fallback ladder is deliberately NOT built unless Task 4 proves the inline rule cannot match (documented limitation, not a second owner).

---

### Task 1: Add core persistence options + failing test

**Files:**
- Create: `tests/test-tmux-persistence.bats`
- Modify: `tmux/tmux.conf` (insert after line 53)

- [ ] **Step 1: Write the failing test**

Create `tests/test-tmux-persistence.bats`:

```bash
#!/usr/bin/env bats
# Test: tmux session persistence
# Description: Assert resurrect/continuum persistence options are set by tmux.conf

setup() {
    # NOTE: single '..' resolves to the repo root. The existing tests/*.bats use
    # $(dirname "$BATS_TEST_DIRNAME")/.. which resolves ABOVE the repo — do not copy that form here.
    export DOTFILES_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    export TMUX_CONF="$DOTFILES_DIR/tmux/tmux.conf"
    export SOCKET="tmux-persistence-test-$$"
    # Unset ITERM_PROFILE so the solarized if-shell source lines are skipped.
    unset ITERM_PROFILE
    tmux -L "$SOCKET" kill-server 2>/dev/null || true
    tmux -L "$SOCKET" new-session -d -x 200 -y 50
    tmux -L "$SOCKET" source-file "$TMUX_CONF"
}

teardown() {
    tmux -L "$SOCKET" kill-server 2>/dev/null || true
}

@test "continuum auto-restore is enabled" {
    run tmux -L "$SOCKET" show-options -gv @continuum-restore
    [ "$status" -eq 0 ]
    [ "$output" = "on" ]
}

@test "resurrect captures pane contents" {
    run tmux -L "$SOCKET" show-options -gv @resurrect-capture-pane-contents
    [ "$status" -eq 0 ]
    [ "$output" = "on" ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bats tests/test-tmux-persistence.bats`
Expected: Both tests FAIL — `show-options -gv @continuum-restore` exits non-zero / empty because the option isn't set yet.

- [ ] **Step 3: Add the persistence block to tmux.conf**

In `tmux/tmux.conf`, insert these lines immediately after `set -g @plugin 'seebi/tmux-colors-solarized'` (line 53) and before the blank line preceding `# Initialize TMUX plugin manager`:

```tmux

# --- session persistence (resurrect + continuum) ---
set -g @continuum-restore 'on'                 # auto-restore sessions when tmux next starts
set -g @resurrect-capture-pane-contents 'on'   # snapshot scrollback so the pre-reboot screen is readable
```

(The `@resurrect-processes` claude rule is added in Task 4 once its match string is known.)

- [ ] **Step 4: Run the test to verify it passes**

Run: `bats tests/test-tmux-persistence.bats`
Expected: Both tests PASS.

- [ ] **Step 5: Run the full bats suite to confirm no regressions**

Run: `bats tests/`
Expected: All tests pass (existing baseline/benchmark/validate suites unaffected).

- [ ] **Step 6: Commit**

```bash
git add tmux/tmux.conf tests/test-tmux-persistence.bats
git commit -m "feat(tmux): enable continuum restore + resurrect pane-contents capture"
```

---

### Task 2: Install the plugins and verify they load

This task touches only the local machine (no repo change, no commit). TPM was bootstrapped already (`~/.tmux/plugins/tpm` exists).

**Files:** none (environment setup + verification).

- [ ] **Step 1: Install all declared TPM plugins headlessly**

Run: `~/.tmux/plugins/tpm/bin/install_plugins`
Expected: Output lines cloning `tmux-resurrect`, `tmux-continuum`, `tmux-sensible`, `tmux-yank`, `tmux-prefix-highlight`, `tmux-colors-solarized`, ending with `TMUX environment reloaded.` or `Done.`

- [ ] **Step 2: Verify resurrect and continuum are installed**

Run: `ls -d ~/.tmux/plugins/tmux-resurrect ~/.tmux/plugins/tmux-continuum`
Expected: Both directories exist (no "No such file or directory").

- [ ] **Step 3: Verify the resurrect save script exists (needed by Task 3 & 4)**

Run: `ls ~/.tmux/plugins/tmux-resurrect/scripts/save.sh ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh`
Expected: Both scripts listed.

- [ ] **Step 4: Confirm the plugins actually load in a real tmux server**

Run:
```bash
tmux -L loadcheck kill-server 2>/dev/null; tmux -L loadcheck new-session -d
tmux -L loadcheck source-file ~/dotfiles/tmux/tmux.conf
tmux -L loadcheck show-options -gv @continuum-restore
tmux -L loadcheck show-hooks -g | grep -i continuum || echo "no continuum hook yet (expected before first interval)"
tmux -L loadcheck kill-server 2>/dev/null
```
Expected: `@continuum-restore` prints `on`; no errors sourcing the config.

---

### Task 3: Verify baseline save/restore (layout + cwd + scrollback)

Prove the core "survive a reboot" behavior — windows, panes, and working directories come back — using resurrect's own save/restore scripts on a throwaway socket (a `kill-server` stands in for the reboot).

**Files:** none (verification only; no commit).

- [ ] **Step 1: Build a known multi-window session on a test socket**

Run:
```bash
S=persist-e2e
tmux -L "$S" kill-server 2>/dev/null
tmux -L "$S" new-session -d -s main -c /tmp
tmux -L "$S" new-window -t main -c /usr/local
tmux -L "$S" new-window -t main -c "$HOME"
tmux -L "$S" source-file ~/dotfiles/tmux/tmux.conf
tmux -L "$S" list-windows -a -F '#{window_index} #{pane_current_path}'
```
Expected: three windows listed with paths `/tmp`, `/usr/local`, and your home dir.

- [ ] **Step 2: Save session state with resurrect**

Run: `tmux -L "$S" run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh`
Then locate the save file:
```bash
ls -l ~/.local/share/tmux/resurrect/last 2>/dev/null || ls -l ~/.tmux/resurrect/last
```
Expected: a `last` symlink pointing to a timestamped `tmux_resurrect_*.txt` file. Note which directory it's in (used in Task 4).

- [ ] **Step 3: Simulate the reboot**

Run: `tmux -L "$S" kill-server`
Expected: server gone (`tmux -L "$S" list-windows` errors with "no server running").

- [ ] **Step 4: Start a fresh server and restore**

Run:
```bash
tmux -L "$S" new-session -d
tmux -L "$S" source-file ~/dotfiles/tmux/tmux.conf
tmux -L "$S" run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh
sleep 2
tmux -L "$S" list-windows -a -F '#{window_index} #{pane_current_path}'
```
Expected: the three windows with paths `/tmp`, `/usr/local`, and home are restored.

- [ ] **Step 5: Tear down**

Run: `tmux -L "$S" kill-server 2>/dev/null`
Expected: clean exit. If Steps 1–4 showed the windows/paths returning, baseline persistence works.

---

### Task 4: Tune and commit the Claude-restore rule (single owner)

Determine, empirically, the substring that resurrect captures for a Claude Code pane, set ONE inline `@resurrect-processes` rule using it, and lock it in with a test + a `tmux.conf` comment naming the chosen mechanism (honors the spec's Design note: exactly one owner).

**Files:**
- Modify: `tmux/tmux.conf` (add the `@resurrect-processes` line inside the persistence block from Task 1)
- Modify: `tests/test-tmux-persistence.bats` (add a third assertion)

- [ ] **Step 1: Capture how a real Claude pane is saved**

In a tmux pane, start Claude Code (`claude`) in some project dir. In another shell, save and inspect:
```bash
RESDIR=~/.local/share/tmux/resurrect; [ -d "$RESDIR" ] || RESDIR=~/.tmux/resurrect
tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh
grep -n -i 'claude\|node\|cli' "$RESDIR/last"
```
Expected: one or more `pane` lines containing the Claude pane's saved command line. Identify a substring that is present for the Claude pane and NOT present for plain shell panes (likely `claude` from the binary/script path; if absent, fall back to `cli.js` or the resolved node script path).

- [ ] **Step 2: Decide the match string**

- If the saved Claude pane line contains `claude` → match string is `claude`.
- If it does not, but contains a unique identifier (e.g. `cli.js` under a claude path) → use that exact substring.
- If the Claude pane is indistinguishable from other `node` panes (no unique token) → STOP and record a limitation: keep only the Task-1 options, do NOT add a `node`-wide rule (it would relaunch every node pane as claude). Note this in the commit and skip Steps 3–6; baseline persistence (Task 3) still ships. This is the spec's "worst case: manual `claude --continue`" outcome.

Set `MATCH` to the chosen substring for the next steps (e.g. `MATCH=claude`).

- [ ] **Step 3: Write the failing assertion**

Add this test to `tests/test-tmux-persistence.bats` (after the existing tests):

```bash
@test "resurrect relaunches claude panes with --continue" {
    run tmux -L "$SOCKET" show-options -gv @resurrect-processes
    [ "$status" -eq 0 ]
    [[ "$output" == *"claude --continue"* ]]
}
```

- [ ] **Step 4: Run it to verify it fails**

Run: `bats tests/test-tmux-persistence.bats`
Expected: the new test FAILS (`@resurrect-processes` unset); the first two still pass.

- [ ] **Step 5: Add the single inline rule + naming comment**

In `tmux/tmux.conf`, inside the persistence block, append (replace `claude` with the `MATCH` substring from Step 2 if different):

```tmux
# claude-restore lives HERE — single owner is this inline @resurrect-processes rule.
# '~claude' loosely matches the saved command line; '->' gives the relaunch command.
set -g @resurrect-processes '"~claude->claude --continue"'
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `bats tests/test-tmux-persistence.bats`
Expected: all three tests PASS.

- [ ] **Step 7: Empirically confirm the rule relaunches claude (real save/restore)**

Run, with a Claude pane open:
```bash
S=persist-claude
# (do this in your interactive tmux; resurrect operates on the current server)
tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh
tmux kill-server   # WARNING: kills your tmux; run only when ready
# then in a new terminal:
tmux new-session -d; tmux source-file ~/dotfiles/tmux/tmux.conf
tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh; sleep 3
tmux list-panes -s -F '#{window_index} #{pane_current_command} #{pane_current_path}'
```
Expected: the pane that was running Claude shows `claude` (or `node`/version) running again in its original directory — i.e., `claude --continue` was launched. If it comes back as a bare shell, the match string was wrong → return to Step 2.

- [ ] **Step 8: Commit**

```bash
git add tmux/tmux.conf tests/test-tmux-persistence.bats
git commit -m "feat(tmux): relaunch claude panes with --continue on restore"
```

---

### Task 5: Final end-to-end verification on the real machine

The genuine test of "survive a reboot." This is manual — it needs your actual session and a real `kill-server` (or reboot). Document the result in the PR.

**Files:** none.

- [ ] **Step 1: Enable continuum auto-save in your live session**

Reload your real config: `tmux source-file ~/.tmux.conf`. continuum auto-saves every 15 min once loaded. To not wait, force a save now: `prefix + Ctrl-s` (resurrect manual save).

- [ ] **Step 2: Confirm a save file exists and is recent**

Run: `ls -lt ~/.local/share/tmux/resurrect/ 2>/dev/null || ls -lt ~/.tmux/resurrect/ | head`
Expected: a `tmux_resurrect_*.txt` from the last minute.

- [ ] **Step 3: Simulate the reboot**

Run: `tmux kill-server` (closes all sessions — make sure work is saved).
Expected: back at the bare shell prompt, no tmux running.

- [ ] **Step 4: Relaunch tmux and confirm auto-restore**

Run: `tmux`
Expected: because `@continuum-restore 'on'`, your windows/panes/layout/cwds reappear automatically; scrollback is visible; Claude panes have relaunched with `claude --continue` and show the resumed conversation.

- [ ] **Step 5: Record the outcome**

Note in the PR description what restored correctly (layout, cwd, scrollback, claude resume) and any gaps. Per the spec, the feature is "done" only once a session is observed coming back after this cycle.

---

## Notes for the implementer

- **resurrect save dir** differs by version: newer resurrect uses `~/.local/share/tmux/resurrect`, older uses `~/.tmux/resurrect`. Steps that touch the save file detect both.
- **Do not** add a `@resurrect-hook-post-restore-all` script. The spec's Design note mandates a single owner for claude-restore; the inline rule is it. The hook is only a documented contingency if Step 2 of Task 4 proves no unique match substring exists — and in that case the chosen outcome is "manual `claude --continue`", not a second mechanism.
- **`prefix` is `Ctrl-b`**, `mode-keys` is `vi` (unchanged by this work).
- continuum's 15-min auto-save default is intentionally left as-is (spec YAGNI guard).
