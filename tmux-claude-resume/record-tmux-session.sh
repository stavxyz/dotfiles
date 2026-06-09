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
