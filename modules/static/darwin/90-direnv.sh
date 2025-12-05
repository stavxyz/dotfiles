#!/usr/bin/env bash
# Module: direnv
# Description: direnv integration for automatic environment loading
# Dependencies: utils.sh

setup_direnv() {
    if command_exists direnv; then
        eval "$(direnv hook bash)"

        # iTerm2 integration uses bash-preexec which manages precmd_functions.
        # bash-preexec declares the array during profile load but doesn't install until first prompt.
        # We can safely append to the array just like iTerm2 does with preexec_functions.
        # The array will be declared by now if iTerm2 integration loaded (85-iterm2.sh).
        if declare -p precmd_functions &>/dev/null 2>&1 || declare -p preexec_functions &>/dev/null 2>&1; then
            precmd_functions+=(_direnv_hook)
        fi
        # Otherwise direnv hook bash already added to PROMPT_COMMAND
    fi
}

setup_direnv
