#!/usr/bin/env bash
# Module: autocomplete-lazy
# Description: Deferred completion loading system
# Dependencies: config.sh

# Source every completion file into the CURRENT shell. Must never run in a
# subshell — `complete` registrations made in a subshell are lost, which is
# exactly the bug the old implementation had (background job in lazy mode,
# command substitution in eager mode).
_dotfiles_source_completions() {
    local f
    for f in "${DOTFILES_DIR}/autocomplete"/*.bash; do
        if [[ -f "$f" ]]; then
            debug "sourcing $f"
            if ! source "$f" 2>/dev/null; then
                debug "failed to source $f"
            fi
        fi
    done
    return 0
}

# One-shot PROMPT_COMMAND hook: loads completions in the parent shell right
# before the first prompt renders, keeping startup fast without losing the
# registrations. Guarded so it is a cheap no-op if self-removal ever fails
# (e.g. another integration rewrites PROMPT_COMMAND around it).
_dotfiles_deferred_completions() {
    if [[ -z "${_dotfiles_completions_loaded:-}" ]]; then
        _dotfiles_completions_loaded=1
        _dotfiles_source_completions
        # Best-effort self-removal (we prepended ourselves, so the two
        # patterns below cover both the alone and the composed case)
        if [[ "$PROMPT_COMMAND" == "_dotfiles_deferred_completions" ]]; then
            unset PROMPT_COMMAND
        else
            PROMPT_COMMAND="${PROMPT_COMMAND#_dotfiles_deferred_completions; }"
        fi
    fi
    return 0
}

# Load completions based on configuration
load_completions() {
    if [[ "$DOTFILES_LAZY_COMPLETIONS" == "true" ]]; then
        # Deferred loading: registration happens at first prompt, in THIS
        # shell. Non-interactive shells never render a prompt and never pay
        # the cost (completions are meaningless there anyway).
        PROMPT_COMMAND="_dotfiles_deferred_completions${PROMPT_COMMAND:+; ${PROMPT_COMMAND}}"
    else
        # Eager loading - load synchronously at startup
        _dotfiles_source_completions
    fi
    return 0
}
