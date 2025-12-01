#!/usr/bin/env bash
# Module: asdf
# Description: asdf version manager and direnv integration
# Dependencies: brew, asdf, direnv

# Check for direnv (may be redundant with lazy loading)
if command -v direnv &>/dev/null; then
    eval "$(direnv hook bash)"
fi

# Check for asdf installation via brew
if command -v brew &>/dev/null; then
    asdf_prefix="$(brew --prefix asdf 2>/dev/null)"

    if [[ -n "$asdf_prefix" ]]; then
        [[ -f "${asdf_prefix}/asdf.sh" ]] && source "${asdf_prefix}/asdf.sh"
        [[ -f "${asdf_prefix}/etc/bash_completion.d/asdf.bash" ]] && \
            source "${asdf_prefix}/etc/bash_completion.d/asdf.bash"
    fi
fi
