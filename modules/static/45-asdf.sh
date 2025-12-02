#!/usr/bin/env bash
# Module: asdf
# Description: asdf version manager with lazy loading
# Dependencies: utils.sh

setup_asdf() {
    if ! command_exists brew; then
        return 0
    fi

    local asdf_prefix
    asdf_prefix="$(brew --prefix asdf 2>/dev/null)"
    [[ -z "$asdf_prefix" ]] && return 0

    [[ -f "${asdf_prefix}/asdf.sh" ]] && source "${asdf_prefix}/asdf.sh"
    [[ -f "${asdf_prefix}/etc/bash_completion.d/asdf.bash" ]] && \
        source "${asdf_prefix}/etc/bash_completion.d/asdf.bash"
}

if [[ "$DOTFILES_LAZY_ASDF" == "true" ]] && command_exists brew; then
    asdf() {
        unset -f asdf
        setup_asdf
        asdf "$@"
    }
else
    setup_asdf
fi
