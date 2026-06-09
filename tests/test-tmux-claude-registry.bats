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
