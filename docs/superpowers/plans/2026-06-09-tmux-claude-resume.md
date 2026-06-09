---
validated:
  sha: e397914ac165f85d1319ccc198623711834a751e
  date: 2026-06-09T19:28:59Z
  reviewers: [fact-check, solid-hygiene]
  findings:
    critical: 0
    important: 0
    medium: 2
    low: 4
    nitpick: 0
  net_negative_remaining: 0
---

# Bulletproof Per-Pane Claude Resume — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After a reboot, each restored tmux pane that was running Claude Code resumes its own exact conversation by session ID (`claude --resume <id>`), eliminating the same-cwd collision.

**Architecture:** A Claude Code `SessionStart` hook records `{tmux pane → session_id, cwd}` to a registry (using `$CLAUDE_CODE_SESSION_ID` + `$TMUX_PANE`). A tmux-resurrect `@resurrect-hook-post-save-all` script rewrites the just-saved file so each claude pane's restore command becomes `claude <flags> --resume <id>` (or `-r` if the id is unavailable). resurrect's normal restore then replays it. A shared `registry.sh` owns the registry schema. Scripts live in `tmux-claude-resume/`, deploy to `~/.config/tmux-claude-resume/` via `dotfiles.yaml`.

**Tech Stack:** bash, tmux 3.3a, tmux-resurrect/continuum, bats, Claude Code hooks, jq (for settings.json merge).

**Spec:** `docs/superpowers/specs/2026-06-09-tmux-claude-resume-design.md` (blessed). Builds on shipped Tasks 1–3 of the persistence plan (continuum-restore + pane-contents capture already in `tmux/tmux.conf`).

**Branch note:** commits land on `ccc-config-1` (current feature branch) unless decided otherwise at execution start. Steps are branch-agnostic.

---

## File Structure

- **Create:** `tmux-claude-resume/registry.sh` — single-owner registry schema (dir, key sanitization, record/lookup/prune). Sourced by both hooks.
- **Create:** `tmux-claude-resume/record-tmux-session.sh` — Claude `SessionStart` hook; records pane→session.
- **Create:** `tmux-claude-resume/resurrect-inject-claude-resume.sh` — resurrect post-save hook; rewrites claude restore commands.
- **Create:** `tmux-claude-resume/install-hook.sh` — idempotent installer; merges the SessionStart hook into `~/.claude/settings.json`.
- **Create:** `tests/test-tmux-claude-registry.bats`, `tests/test-tmux-claude-capture.bats`, `tests/test-tmux-claude-inject.bats`, `tests/test-tmux-claude-install.bats`.
- **Modify:** `tmux/tmux.conf` (persistence block) — add `@resurrect-processes` + `@resurrect-hook-post-save-all`.
- **Modify:** `dotfiles.yaml` — add the `~/.config/tmux-claude-resume/` link entry.

**Dependency order:** Task 1 (spikes) gates Tasks 4–6. Tasks 2–3 (registry + capture hook) are independent of the spike and may proceed regardless. Do **not** build Task 4 (injection) until Task 1 confirms assumption #1.

---

### Task 1: Spikes — confirm the two load-bearing assumptions

No production code. Two throwaway experiments that gate the rest. If either fails, STOP and escalate (the fallback architecture B2 changes Tasks 4–5 wholesale).

- [ ] **Step 1: Spike B — does `@resurrect-hook-post-save-all` fire with a resolvable save file?**

Run:
```bash
S=spike-b; D=/tmp/spike-b-$$; mkdir -p "$D"
tmux -L "$S" kill-server 2>/dev/null
tmux -L "$S" -f /dev/null new-session -d
tmux -L "$S" set -g @resurrect-dir "$D"
tmux -L "$S" set -g @resurrect-hook-post-save-all "echo fired > $D/HOOK_FIRED"
tmux -L "$S" run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh
sleep 1
ls -l "$D/HOOK_FIRED" "$D/last" 2>&1
tmux -L "$S" kill-server 2>/dev/null; rm -rf "$D"
```
Expected: both `HOOK_FIRED` and the `last` symlink exist. → assumption #2 holds.

- [ ] **Step 2: Spike A — does resurrect replay the (rewritten) trailing command field for `~`-matched processes?**

Run:
```bash
S=spike-a; D=/tmp/spike-a-$$; mkdir -p "$D"; M="$D/REPLAYED"
tmux -L "$S" kill-server 2>/dev/null
tmux -L "$S" -f /dev/null new-session -d -c /tmp
tmux -L "$S" set -g @resurrect-dir "$D"
tmux -L "$S" set -g @resurrect-processes '~sleep'
# run a long sleep so it's captured as a restorable process
tmux -L "$S" send-keys 'sleep 600' Enter; sleep 1
tmux -L "$S" run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh; sleep 1
echo "--- saved pane line(s) ---"; grep '^pane' "$D/last"
# Rewrite the trailing command field: replace 'sleep 600' with a command that proves replay
sed -i '' "s#:sleep 600#:touch $M && sleep 600#" "$D/last" 2>/dev/null || sed -i "s#:sleep 600#:touch $M \&\& sleep 600#" "$D/last"
tmux -L "$S" kill-server
tmux -L "$S" -f /dev/null new-session -d
tmux -L "$S" set -g @resurrect-dir "$D"
tmux -L "$S" set -g @resurrect-processes '~sleep'
tmux -L "$S" run-shell ~/.tmux/plugins/tmux-resurrect/scripts/restore.sh; sleep 3
ls -l "$M" 2>&1 && echo "REPLAY CONFIRMED (rewritten command field ran)" || echo "REPLAY FAILED"
tmux -L "$S" kill-server 2>/dev/null; rm -rf "$D"
```
Expected: `$M` exists → resurrect ran the **rewritten** trailing command field. This confirms assumption #1 AND identifies that the trailing (last, colon-prefixed) field is the one replayed — the field Task 4 rewrites.

- [ ] **Step 3: Record the outcome**

If both spikes pass, note in the PR/commit message "spikes A+B confirmed" and proceed. If either fails, STOP: the post-save-rewrite architecture (B1) is not viable as specced — escalate to revisit B2 (post-restore keystroke injection) per the spec. Do not start Task 4.

---

### Task 2: Registry helper + tests

**Files:**
- Create: `tmux-claude-resume/registry.sh`
- Test: `tests/test-tmux-claude-registry.bats`

- [ ] **Step 1: Write the failing test**

Create `tests/test-tmux-claude-registry.bats`:
```bash
#!/usr/bin/env bats
# Test: tmux-claude-resume registry helper

setup() {
    export DOTFILES_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    export TMUX_CLAUDE_RESUME_DIR="$(mktemp -d)"
    source "$DOTFILES_DIR/tmux-claude-resume/registry.sh"
}
teardown() { rm -rf "$TMUX_CLAUDE_RESUME_DIR"; }

@test "record then lookup returns the session id" {
    tcr_record "%5" "abc-123" "/tmp/proj"
    run tcr_session_id "%5"
    [ "$status" -eq 0 ]
    [ "$output" = "abc-123" ]
}

@test "lookup of unknown pane prints nothing, exits 0" {
    run tcr_session_id "%9"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "record overwrites the prior mapping for a pane" {
    tcr_record "%5" "old-id" "/tmp/a"
    tcr_record "%5" "new-id" "/tmp/b"
    run tcr_session_id "%5"
    [ "$output" = "new-id" ]
}

@test "prune removes entries whose pane is not in the live set" {
    tcr_record "%1" "s1" "/tmp/1"
    tcr_record "%2" "s2" "/tmp/2"
    tcr_prune "%1"
    run tcr_session_id "%1"; [ "$output" = "s1" ]
    run tcr_session_id "%2"; [ -z "$output" ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bats tests/test-tmux-claude-registry.bats`
Expected: FAIL — `registry.sh` does not exist (`source` errors / functions undefined).

- [ ] **Step 3: Write the implementation**

Create `tmux-claude-resume/registry.sh`:
```bash
#!/usr/bin/env bash
# Single source of truth for the tmux-claude-resume pane->session registry.
# Schema: one file per tmux pane under the registry dir, named by a sanitized
# pane id, containing a single line: "<session_id>\t<cwd>".
# The cwd field is diagnostic/reserved — no consumer reads it today; only field 1
# (session_id) is load-bearing. Override the dir with $TMUX_CLAUDE_RESUME_DIR (tests).
# Prune contract: tcr_prune requires a NON-EMPTY live-pane set (see resurrect-inject).

tcr_registry_dir() {
    echo "${TMUX_CLAUDE_RESUME_DIR:-$HOME/.cache/tmux-claude-resume}"
}

# Map a tmux pane id (e.g. "%5") to a safe filename (e.g. "pane_5").
tcr_pane_key() {
    printf 'pane_%s' "${1//[^A-Za-z0-9]/_}"
}

# Record (overwrite) the mapping for a pane.
tcr_record() {
    local pane="$1" session_id="$2" cwd="$3" dir
    dir="$(tcr_registry_dir)"
    mkdir -p "$dir"
    printf '%s\t%s\n' "$session_id" "$cwd" > "$dir/$(tcr_pane_key "$pane")"
}

# Print the session id recorded for a pane (nothing if absent). Always exits 0.
tcr_session_id() {
    local file
    file="$(tcr_registry_dir)/$(tcr_pane_key "$1")"
    [ -f "$file" ] || return 0
    cut -f1 "$file"
}

# Remove registry files whose pane is not in the given live-pane list.
# Usage: tcr_prune "%1" "%2" ...
tcr_prune() {
    local dir f base; dir="$(tcr_registry_dir)"
    [ -d "$dir" ] || return 0
    declare -A keep=()
    local p; for p in "$@"; do keep["$(tcr_pane_key "$p")"]=1; done
    for f in "$dir"/pane_*; do
        [ -e "$f" ] || continue
        base="$(basename "$f")"
        [ -n "${keep[$base]:-}" ] || rm -f "$f"
    done
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bats tests/test-tmux-claude-registry.bats`
Expected: 4/4 PASS.

- [ ] **Step 5: Commit**

```bash
git add tmux-claude-resume/registry.sh tests/test-tmux-claude-registry.bats
git commit -m "feat(tmux-claude-resume): add single-owner pane->session registry helper"
```

---

### Task 3: Capture hook + tests

**Files:**
- Create: `tmux-claude-resume/record-tmux-session.sh`
- Test: `tests/test-tmux-claude-capture.bats`

- [ ] **Step 1: Write the failing test**

Create `tests/test-tmux-claude-capture.bats`:
```bash
#!/usr/bin/env bats
# Test: tmux-claude-resume SessionStart capture hook

setup() {
    export DOTFILES_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    export TMUX_CLAUDE_RESUME_DIR="$(mktemp -d)"
    export HOOK="$DOTFILES_DIR/tmux-claude-resume/record-tmux-session.sh"
}
teardown() { rm -rf "$TMUX_CLAUDE_RESUME_DIR"; }

@test "records the mapping when in tmux with a session id" {
    run env TMUX="/tmp/x,1,0" TMUX_PANE="%3" CLAUDE_CODE_SESSION_ID="sess-1" \
        PWD="/tmp/proj" TMUX_CLAUDE_RESUME_DIR="$TMUX_CLAUDE_RESUME_DIR" bash "$HOOK"
    [ "$status" -eq 0 ]
    source "$DOTFILES_DIR/tmux-claude-resume/registry.sh"
    run tcr_session_id "%3"
    [ "$output" = "sess-1" ]
}

@test "no-op when not in tmux (TMUX unset)" {
    run env -u TMUX TMUX_PANE="%3" CLAUDE_CODE_SESSION_ID="sess-1" \
        TMUX_CLAUDE_RESUME_DIR="$TMUX_CLAUDE_RESUME_DIR" bash "$HOOK"
    [ "$status" -eq 0 ]
    [ -z "$(ls -A "$TMUX_CLAUDE_RESUME_DIR" 2>/dev/null)" ]
}

@test "no-op when CLAUDE_CODE_SESSION_ID is missing" {
    run env TMUX="/tmp/x,1,0" TMUX_PANE="%3" -u CLAUDE_CODE_SESSION_ID \
        TMUX_CLAUDE_RESUME_DIR="$TMUX_CLAUDE_RESUME_DIR" bash "$HOOK"
    [ "$status" -eq 0 ]
    [ -z "$(ls -A "$TMUX_CLAUDE_RESUME_DIR" 2>/dev/null)" ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bats tests/test-tmux-claude-capture.bats`
Expected: FAIL — hook script does not exist.

- [ ] **Step 3: Write the implementation**

Create `tmux-claude-resume/record-tmux-session.sh`:
```bash
#!/usr/bin/env bash
# Claude Code SessionStart hook. Records this pane's session id so tmux-resurrect
# can later relaunch the pane with `claude --resume <id>`. No-op outside tmux.
set -euo pipefail

# Need all three identifiers; otherwise we cannot (or should not) record.
[ -n "${TMUX:-}" ] || exit 0
[ -n "${TMUX_PANE:-}" ] || exit 0
[ -n "${CLAUDE_CODE_SESSION_ID:-}" ] || exit 0

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=registry.sh
source "$here/registry.sh"

tcr_record "$TMUX_PANE" "$CLAUDE_CODE_SESSION_ID" "$PWD"
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bats tests/test-tmux-claude-capture.bats`
Expected: 3/3 PASS.

- [ ] **Step 5: Commit**

```bash
git add tmux-claude-resume/record-tmux-session.sh tests/test-tmux-claude-capture.bats
git commit -m "feat(tmux-claude-resume): add SessionStart hook to record pane->session"
```

---

### Task 4: Injection hook + tests  (GATED on Task 1 spike A)

**Files:**
- Create: `tmux-claude-resume/resurrect-inject-claude-resume.sh`
- Test: `tests/test-tmux-claude-inject.bats`

The test stubs `tmux` (a fake on `PATH`) and `~/.claude/projects` so it runs without a live server.

- [ ] **Step 1: Write the failing test**

Create `tests/test-tmux-claude-inject.bats`:
```bash
#!/usr/bin/env bats
# Test: tmux-claude-resume resurrect post-save injection

setup() {
    export DOTFILES_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    export WORK="$(mktemp -d)"
    export TMUX_CLAUDE_RESUME_DIR="$WORK/registry"
    export RESDIR="$WORK/resurrect"
    export FAKE_HOME="$WORK/home"
    mkdir -p "$RESDIR" "$FAKE_HOME/.claude/projects/-tmp-proj"
    export INJECT="$DOTFILES_DIR/tmux-claude-resume/resurrect-inject-claude-resume.sh"

    # Stub tmux: answer the two queries the script makes.
    mkdir -p "$WORK/bin"
    cat > "$WORK/bin/tmux" <<EOF
#!/usr/bin/env bash
case "\$*" in
  "show-options -gv @resurrect-dir") echo "$RESDIR" ;;
  "list-panes -a -F #{pane_id}") printf '%%1\n%%2\n' ;;          # bare pane-id query (prune)
  "list-panes -a -F"*) printf 'main\t1\t0\t%%1\nmain\t1\t1\t%%2\n' ;;  # 4-field join query
  *) exit 0 ;;
esac
EOF
    chmod +x "$WORK/bin/tmux"
    export PATH="$WORK/bin:$PATH"

    # Registry: pane %1 -> known session WITH a jsonl; pane %2 -> session WITHOUT jsonl.
    source "$DOTFILES_DIR/tmux-claude-resume/registry.sh"
    tcr_record "%1" "live-sess" "/tmp/proj"
    tcr_record "%2" "dead-sess" "/tmp/proj"
    : > "$FAKE_HOME/.claude/projects/-tmp-proj/live-sess.jsonl"   # exists
    # dead-sess.jsonl intentionally absent

    # Save file: pane %1 (session exists), pane %2 (session gone), and a non-claude pane.
    printf 'pane\tmain\t1\t0\t:\t0\t title\t:/tmp/proj\t1\t2.1.168\t:claude --dangerously-skip-permissions -r\n'  > "$RESDIR/last"
    printf 'pane\tmain\t1\t0\t:\t1\t title\t:/tmp/proj\t0\t2.1.168\t:claude --dangerously-skip-permissions -r\n' >> "$RESDIR/last"
    printf 'pane\tmain\t1\t0\t:\t2\t title\t:/tmp/proj\t0\tvim\t:vim\n'                                          >> "$RESDIR/last"
}
teardown() { rm -rf "$WORK"; }

@test "pane with a live session is rewritten to --resume <id>, flags preserved" {
    HOME="$FAKE_HOME" run bash "$INJECT"
    [ "$status" -eq 0 ]
    run grep -c ':claude --dangerously-skip-permissions --resume live-sess$' "$RESDIR/last"
    [ "$output" = "1" ]
}

@test "pane whose session is gone falls back to -r, flags preserved" {
    HOME="$FAKE_HOME" run bash "$INJECT"
    run grep -c ':claude --dangerously-skip-permissions -r$' "$RESDIR/last"
    [ "$output" = "1" ]
}

@test "non-claude pane line is left untouched" {
    HOME="$FAKE_HOME" run bash "$INJECT"
    run grep -c ':vim$' "$RESDIR/last"
    [ "$output" = "1" ]
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bats tests/test-tmux-claude-inject.bats`
Expected: FAIL — injection script does not exist.

- [ ] **Step 3: Write the implementation**

Create `tmux-claude-resume/resurrect-inject-claude-resume.sh`:
```bash
#!/usr/bin/env bash
# tmux-resurrect @resurrect-hook-post-save-all hook.
# Rewrites each claude pane's restore command in the just-saved file to
# `claude <preserved-flags> --resume <id>` (or `... -r` if the id is unavailable),
# so a restore reattaches each pane to its own Claude Code session.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=registry.sh
source "$here/registry.sh"

res_dir="$(tmux show-options -gv @resurrect-dir 2>/dev/null || true)"
# Fallback mirrors tmux-resurrect's own default; Task 1 confirms the live dir.
res_dir="${res_dir:-$HOME/.tmux/resurrect}"
save="$res_dir/last"
[ -f "$save" ] || exit 0
real="$(readlink "$save" 2>/dev/null || true)"; real="${real:-$save}"
case "$real" in /*) ;; *) real="$res_dir/$real" ;; esac

# Live (session|window|pane_index) -> pane_id map.
declare -A paneid=()
while IFS=$'\t' read -r s w p id; do
    paneid["$s|$w|$p"]="$id"
done < <(tmux list-panes -a -F '#{session_name}	#{window_index}	#{pane_index}	#{pane_id}')

projects="$HOME/.claude/projects"

# Given the original full command + pane_id, produce the restore command.
rewrite_cmd() {
    local cmd="$1" pane_id="$2" flags sid
    # Strip any existing resume/continue flags; keep the rest (e.g. --dangerously-skip-permissions).
    flags="$(printf '%s' "$cmd" \
        | sed -E 's/(^| )(-r|--resume([= ][^ ]+)?|-c|--continue)( |$)/ /g; s/  +/ /g; s/ +$//')"
    sid="$(tcr_session_id "$pane_id")"
    if [ -n "$sid" ] && compgen -G "$projects/*/$sid.jsonl" > /dev/null; then
        printf '%s --resume %s' "$flags" "$sid"
    else
        printf '%s -r' "$flags"
    fi
}

# --- Phase 1: rewrite each claude pane's restore command in the save file ---
tmp="$(mktemp)"
while IFS= read -r line || [ -n "$line" ]; do
    if [ "${line%%$'\t'*}" = "pane" ]; then
        IFS=$'\t' read -r -a f <<< "$line"
        last=$(( ${#f[@]} - 1 ))
        cmd="${f[$last]#:}"   # trailing field = the full command resurrect replays
        # Anchor on the COMMAND field, not the whole line: a pane whose cwd merely
        # contains "claude" must not be misclassified as a claude pane.
        if [[ "$cmd" == "claude" || "$cmd" == claude\ * ]]; then
            s="${f[1]}"; w="${f[2]}"; pidx="${f[5]}"
            pane_id="${paneid["$s|$w|$pidx"]:-}"
            if [ -n "$pane_id" ]; then
                f[$last]=":$(rewrite_cmd "$cmd" "$pane_id")"
                line="$(printf '%s\t' "${f[@]}")"; line="${line%$'\t'}"
            fi
        fi
    fi
    printf '%s\n' "$line"
done < "$real" > "$tmp"
mv "$tmp" "$real"

# --- Phase 2: prune registry entries for panes that no longer exist ---
# Guard: never call tcr_prune with zero live panes (that would wipe the registry).
mapfile -t live < <(tmux list-panes -a -F '#{pane_id}')
# Full `if` (not `&&`): as the script's last statement, a false `&&` would exit 1
# under `set -e` in exactly the no-live-panes case the guard handles.
if [ "${#live[@]}" -gt 0 ]; then
    tcr_prune "${live[@]}"
fi
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bats tests/test-tmux-claude-inject.bats`
Expected: 3/3 PASS.

- [ ] **Step 5: Run shellcheck on all three scripts**

Run: `shellcheck tmux-claude-resume/registry.sh tmux-claude-resume/record-tmux-session.sh tmux-claude-resume/resurrect-inject-claude-resume.sh`
Expected: clean (source directives already annotated).

- [ ] **Step 6: Commit**

```bash
git add tmux-claude-resume/resurrect-inject-claude-resume.sh tests/test-tmux-claude-inject.bats
git commit -m "feat(tmux-claude-resume): rewrite resurrect save file to resume each claude pane by id"
```

---

### Task 5: Wire tmux.conf + dotfiles.yaml deployment

**Files:**
- Modify: `tmux/tmux.conf` (persistence block)
- Modify: `dotfiles.yaml` (links)
- Test: extend `tests/test-tmux-persistence.bats`

- [ ] **Step 1: Write the failing test**

Append to `tests/test-tmux-persistence.bats` (after the existing tests):
```bash
@test "resurrect treats claude as a restorable process" {
    run tmux -L "$SOCKET" show-options -gv @resurrect-processes
    [ "$status" -eq 0 ]
    [[ "$output" == *"~claude"* ]]
}

@test "resurrect post-save hook points at the deployed injection script" {
    run tmux -L "$SOCKET" show-options -gv @resurrect-hook-post-save-all
    [ "$status" -eq 0 ]
    [[ "$output" == *"tmux-claude-resume/resurrect-inject-claude-resume.sh"* ]]
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `bats tests/test-tmux-persistence.bats`
Expected: the two new tests FAIL (options unset); the earlier ones still pass.

- [ ] **Step 3: Add the tmux.conf options**

In `tmux/tmux.conf`, inside the `# --- session persistence (resurrect + continuum) ---` block (immediately after the `@resurrect-capture-pane-contents` line), add:
```tmux
# relaunch each claude pane on restore; the post-save hook rewrites the saved
# command to `claude --resume <id>` per pane (see tmux-claude-resume/).
set -g @resurrect-processes '~claude'
set -g @resurrect-hook-post-save-all 'bash ~/.config/tmux-claude-resume/resurrect-inject-claude-resume.sh'
```

- [ ] **Step 4: Add the dotfiles.yaml link entry**

In `dotfiles.yaml`, under `links:`, add (matching the existing `~/.config/...` indentation style):
```yaml
    ~/.config/tmux-claude-resume/:          tmux-claude-resume/*
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bats tests/test-tmux-persistence.bats`
Expected: all tests PASS (old + 2 new).

- [ ] **Step 6: Commit**

```bash
git add tmux/tmux.conf dotfiles.yaml tests/test-tmux-persistence.bats
git commit -m "feat(tmux): wire claude-resume injection hook + deploy scripts via dotfiles.yaml"
```

---

### Task 6: Idempotent settings.json installer + tests  (GATED on Task 1)

**Files:**
- Create: `tmux-claude-resume/install-hook.sh`
- Test: `tests/test-tmux-claude-install.bats`

- [ ] **Step 1: Write the failing test**

Create `tests/test-tmux-claude-install.bats`:
```bash
#!/usr/bin/env bats
# Test: tmux-claude-resume settings.json hook installer (idempotent merge)

setup() {
    export DOTFILES_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    export FAKE_HOME="$(mktemp -d)"
    mkdir -p "$FAKE_HOME/.claude"
    # pre-existing unrelated settings to prove we don't clobber
    printf '{"model":"opus","hooks":{}}\n' > "$FAKE_HOME/.claude/settings.json"
    export INSTALL="$DOTFILES_DIR/tmux-claude-resume/install-hook.sh"
}
teardown() { rm -rf "$FAKE_HOME"; }

@test "adds the SessionStart hook and preserves unrelated keys" {
    HOME="$FAKE_HOME" run bash "$INSTALL"
    [ "$status" -eq 0 ]
    run jq -r '.model' "$FAKE_HOME/.claude/settings.json"
    [ "$output" = "opus" ]
    run jq '[.hooks.SessionStart[].hooks[].command] | map(select(test("record-tmux-session.sh"))) | length' "$FAKE_HOME/.claude/settings.json"
    [ "$output" = "1" ]
}

@test "running twice is idempotent (hook present exactly once)" {
    HOME="$FAKE_HOME" bash "$INSTALL"
    HOME="$FAKE_HOME" run bash "$INSTALL"
    [ "$status" -eq 0 ]
    run jq '[.. | objects | .command? // empty | select(test("record-tmux-session.sh"))] | length' "$FAKE_HOME/.claude/settings.json"
    [ "$output" = "1" ]
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `bats tests/test-tmux-claude-install.bats`
Expected: FAIL — installer does not exist.

- [ ] **Step 3: Write the implementation**

Create `tmux-claude-resume/install-hook.sh`:
```bash
#!/usr/bin/env bash
# Idempotently register the tmux-claude-resume SessionStart hook in the user's
# GLOBAL ~/.claude/settings.json. Never touches any repo-local .claude/settings.json.
set -euo pipefail

settings="$HOME/.claude/settings.json"
cmd="$HOME/.config/tmux-claude-resume/record-tmux-session.sh"

mkdir -p "$(dirname "$settings")"
[ -f "$settings" ] || echo '{}' > "$settings"

# Already present? Then this is a no-op.
if jq -e --arg c "$cmd" \
    '[.. | objects | .command? // empty] | any(. == $c)' "$settings" > /dev/null; then
    echo "tmux-claude-resume hook already installed"
    exit 0
fi

tmp="$(mktemp)"
jq --arg c "$cmd" '
    .hooks //= {} |
    .hooks.SessionStart //= [] |
    .hooks.SessionStart += [{
        "matcher": "startup|resume",
        "hooks": [{ "type": "command", "command": $c }]
    }]
' "$settings" > "$tmp"
mv "$tmp" "$settings"
echo "tmux-claude-resume hook installed in $settings"
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bats tests/test-tmux-claude-install.bats`
Expected: 2/2 PASS.

- [ ] **Step 5: Commit**

```bash
git add tmux-claude-resume/install-hook.sh tests/test-tmux-claude-install.bats
git commit -m "feat(tmux-claude-resume): idempotent ~/.claude/settings.json hook installer"
```

---

### Task 7: Deploy + manual end-to-end verification (gated, on the live machine)

No repo changes. This is the real proof; it touches the user's live tmux and global settings, so it is run by the user at a checkpoint.

- [ ] **Step 1: Full suite + shellcheck green**

Run: `bats tests/ && shellcheck tmux-claude-resume/*.sh`
Expected: new suites pass; pre-existing baseline failures unchanged; shellcheck clean.

- [ ] **Step 2: Deploy the scripts and register the hook**

Run:
```bash
./dot.py link                                   # symlinks ~/.config/tmux-claude-resume/ -> repo
ls -l ~/.config/tmux-claude-resume/             # expect the 4 scripts
bash ~/.config/tmux-claude-resume/install-hook.sh
jq '.hooks.SessionStart' ~/.claude/settings.json
```
Expected: scripts present; SessionStart hook registered once.

- [ ] **Step 3: Prime the registry**

Reload tmux config (`tmux source-file ~/.tmux.conf`). In two panes sharing one cwd, start `claude` (your normal alias). Confirm the capture hook fired:
```bash
ls -l ~/.cache/tmux-claude-resume/    # one file per claude pane
cat ~/.cache/tmux-claude-resume/*     # each: <session_id><TAB><cwd>
```
Expected: distinct session ids for the two same-cwd panes.

- [ ] **Step 4: Save → simulate reboot → restore**

Run (when ready — `kill-server` ends your sessions):
```bash
tmux run-shell ~/.tmux/plugins/tmux-resurrect/scripts/save.sh
grep claude "$(tmux show-options -gv @resurrect-dir 2>/dev/null || echo ~/.tmux/resurrect)/last"
# expect each claude pane line ends with `--resume <its own id>`
tmux kill-server
tmux            # continuum auto-restores
```
Expected after restart: each pane resumed its **own** conversation; the two same-cwd panes show different conversations (collision gone).

- [ ] **Step 5: Record the outcome**

Note in the PR what restored correctly (per-pane resume, same-cwd disambiguation, `-r` fallback for any pane whose session was gone). Per the spec, "done" requires observing distinct same-cwd sessions resume after this cycle.

---

## Notes for the implementer

- **resurrect save dir** varies: `~/.local/share/tmux/resurrect` (newer) or `~/.tmux/resurrect`. The injection script reads `@resurrect-dir` (default `~/.tmux/resurrect`); confirm which your install uses during Task 1.
- **The trailing command field** is the one resurrect replays — Task 1 spike A confirms this and that rewriting it changes what launches. The injection script rewrites the last tab field of each claude `pane` line.
- **`jq` is required** by the installer; it is already on this machine (`/opt/homebrew/bin/jq`, and listed in `dotfiles.yaml` brew installs).
- **Do not build Tasks 4 or 6 before Task 1 passes.** If a spike fails, stop and revisit architecture B2 (post-restore keystroke injection) per the spec — that invalidates Tasks 4–5.
- `prefix` is `Ctrl-b`; continuum auto-save interval is the 15-min default (unchanged).

> **Design note (2026-06-09, validate):** Plan tightened after review — the injection
> script now (a) anchors the claude match to the **command field** (not the whole line, so a
> cwd containing "claude" isn't misclassified), (b) is split into clearly-commented Phase 1
> (rewrite) / Phase 2 (prune) sections, and (c) guards `tcr_prune` against an empty live-pane
> set (which would otherwise wipe the registry). `registry.sh` documents that `cwd` is
> diagnostic/reserved and that prune requires a non-empty set. Task 4's `tmux` test stub now
> answers the bare `#{pane_id}` prune query distinctly from the 4-field join query. All
> reviewer-confirmed facts (resurrect field order, trailing-field replay, `~` match,
> `CLAUDE_CODE_SESSION_ID`) verified true.
