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
