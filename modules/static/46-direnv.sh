#!/usr/bin/env bash
# Module: direnv
# Description: direnv integration with lazy loading
# Dependencies: utils.sh

setup_direnv() {
    if [[ "$DOTFILES_LAZY_DIRENV" == "true" ]] && command_exists direnv; then
        direnv() {
            unset -f direnv
            eval "$(command direnv hook bash)"
            direnv "$@"
        }
    elif command_exists direnv; then
        eval "$(direnv hook bash)"
    fi
}

setup_direnv
