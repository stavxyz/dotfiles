#!/usr/bin/env bash
# Module: ruby
# Description: Ruby/chruby configuration and version management
# Dependencies: brew, chruby

# Only set up chruby if brew and chruby are available
if ! command -v brew &>/dev/null; then
    return 0
fi

chrubypath="$(brew --prefix chruby 2>/dev/null)"

if [[ -z "$chrubypath" ]]; then
    return 0
fi

# Source chruby scripts if they exist
if [[ -f "${chrubypath}/share/chruby/chruby.sh" ]]; then
    source "${chrubypath}/share/chruby/chruby.sh"

    # Load auto-switching support (respects .ruby-version files)
    if [[ -f "${chrubypath}/share/chruby/auto.sh" ]]; then
        source "${chrubypath}/share/chruby/auto.sh"
    fi
fi
