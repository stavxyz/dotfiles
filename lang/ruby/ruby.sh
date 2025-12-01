#!/usr/bin/env bash
# Module: ruby
# Description: Ruby/chruby configuration and version management
# Dependencies: brew, chruby

# Only set up chruby if brew and chruby are available
if ! command -v brew &>/dev/null; then
    return 0
fi

# Use HOMEBREW_PREFIX if already set by homebrew.sh module
# Otherwise detect using architecture-aware logic
if [[ -z "$HOMEBREW_PREFIX" ]]; then
    if is_apple_silicon; then
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        HOMEBREW_PREFIX="/usr/local"
    fi
fi

# Try standard Homebrew location first to avoid slow 'brew --prefix chruby' call
if [[ -d "${HOMEBREW_PREFIX}/opt/chruby" ]]; then
    chrubypath="${HOMEBREW_PREFIX}/opt/chruby"
else
    # Fallback to brew --prefix if not in standard location
    chrubypath="$(brew --prefix chruby 2>/dev/null)"
fi

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
