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

@test "corrupt settings.json: clear error, exits non-zero, file left untouched" {
    printf 'this is { not json' > "$FAKE_HOME/.claude/settings.json"
    HOME="$FAKE_HOME" run bash "$INSTALL"
    [ "$status" -ne 0 ]
    [[ "$output" == *"not valid JSON"* ]]
    # original (corrupt) content is preserved, not clobbered
    run cat "$FAKE_HOME/.claude/settings.json"
    [ "$output" = "this is { not json" ]
}
