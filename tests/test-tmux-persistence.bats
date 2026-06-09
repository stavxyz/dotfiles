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
    tmux -L "$SOCKET" -f /dev/null new-session -d -x 200 -y 50
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
