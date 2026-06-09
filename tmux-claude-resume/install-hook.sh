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
