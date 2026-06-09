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
if [ "${#live[@]}" -gt 0 ]; then
    tcr_prune "${live[@]}"
fi
