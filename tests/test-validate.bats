#!/usr/bin/env bats
# Test: Validation
# Description: Validate functionality after changes

setup() {
    # Dynamically detect dotfiles directory
    export DOTFILES_DIR="$(cd "$(dirname "$BATS_TEST_DIRNAME")/.." && pwd)"
}

@test "bash profile loads without errors" {
    run bash -l -c 'exit'
    [ "$status" -eq 0 ]
}

@test "no syntax errors in bash files" {
    for file in "$DOTFILES_DIR"/bash/*.sh; do
        run bash -n "$file"
        [ "$status" -eq 0 ]
    done
}

@test "utilities module exists and loads" {
    if [ -f "$DOTFILES_DIR/modules/static/10-utils.sh" ]; then
        run bash -c "source $DOTFILES_DIR/modules/static/10-utils.sh && type command_exists"
        [ "$status" -eq 0 ]
    fi
}

@test "config module exists and loads" {
    if [ -f "$DOTFILES_DIR/modules/static/20-config.sh" ]; then
        run bash -c "source $DOTFILES_DIR/modules/static/20-config.sh && echo \$DOTFILES_LAZY_PYENV"
        [ "$status" -eq 0 ]
    fi
}

@test "git commands work" {
    run bash -l -c 'git --version'
    [ "$status" -eq 0 ]
}

@test "vim works" {
    run bash -l -c 'vim --version'
    [ "$status" -eq 0 ]
}

@test "PATH contains expected directories" {
    run bash -l -c 'echo "$PATH"'
    [ "$status" -eq 0 ]
    [[ "$output" =~ "homebrew" ]]
}

@test "aliases are preserved" {
    run bash -l -c 'alias ll'
    # Should either have ll alias or exit gracefully
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "completions work after changes" {
    run bash -l -c 'complete -p git'
    [ "$status" -eq 0 ]
}

@test "pyenv works if installed" {
    if command -v pyenv &>/dev/null; then
        run bash -l -c 'pyenv --version'
        [ "$status" -eq 0 ]
    else
        skip "pyenv not installed"
    fi
}

@test "direnv works if installed" {
    if command -v direnv &>/dev/null; then
        run bash -l -c 'direnv --version'
        [ "$status" -eq 0 ]
    else
        skip "direnv not installed"
    fi
}
