#!/usr/bin/env bash
# Module: asdf
# Description: asdf version manager
# Dependencies: brew, asdf
# Note: direnv integration is handled in bash/direnv.sh

# Check for asdf installation via brew
if command -v brew &>/dev/null; then
    asdf_prefix="$(brew --prefix asdf 2>/dev/null)"

    if [[ -n "$asdf_prefix" ]]; then
        [[ -f "${asdf_prefix}/asdf.sh" ]] && source "${asdf_prefix}/asdf.sh"
        [[ -f "${asdf_prefix}/etc/bash_completion.d/asdf.bash" ]] && \
            source "${asdf_prefix}/etc/bash_completion.d/asdf.bash"
    fi
fi
