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
    # -u must precede name=value pairs on macOS env
    run env -u CLAUDE_CODE_SESSION_ID TMUX="/tmp/x,1,0" TMUX_PANE="%3" \
        TMUX_CLAUDE_RESUME_DIR="$TMUX_CLAUDE_RESUME_DIR" bash "$HOOK"
    [ "$status" -eq 0 ]
    [ -z "$(ls -A "$TMUX_CLAUDE_RESUME_DIR" 2>/dev/null)" ]
}
