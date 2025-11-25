#!/usr/bin/env bats
# Test: Baseline Capture
# Description: Capture current state before modernization

setup() {
    export DOTFILES_DIR="/Users/stavxyz/dotfiles"
    export RESULTS_FILE="${HOME}/.cache/dotfiles/baseline-results.txt"
    mkdir -p "$(dirname "$RESULTS_FILE")"
}

@test "bash profile loads without errors" {
    run bash -l -c 'exit'
    [ "$status" -eq 0 ]
}

@test "shell startup completes in reasonable time" {
    # Capture startup time (should complete in <5s even before optimization)
    run timeout 5s bash -l -c 'exit'
    [ "$status" -eq 0 ]
}

@test "aliases are defined" {
    run bash -l -c 'alias | wc -l'
    [ "$status" -eq 0 ]
    [ "$output" -gt 0 ]
}

@test "PATH is set correctly" {
    run bash -l -c 'echo "$PATH" | grep -q homebrew'
    [ "$status" -eq 0 ]
}

@test "git completion is available" {
    run bash -l -c 'type __git_wrap__git_main'
    [ "$status" -eq 0 ]
}

@test "vim is available" {
    run bash -l -c 'command -v vim'
    [ "$status" -eq 0 ]
}

@test "DOTFILES_DIR is set" {
    run bash -l -c 'echo "$DOTFILES_DIR"'
    [ "$status" -eq 0 ]
    [[ "$output" == *"dotfiles"* ]]
}

@test "no errors in bash profile loading" {
    run bash -l -c 'exit' 2>&1
    [[ ! "$output" =~ "error" ]]
}
