#!/usr/bin/env bash
# Module: homebrew
# Description: Homebrew environment setup with caching support
# Dependencies: cache.sh (optional)

# macOS only
# shellcheck disable=SC2086  # Safe: word splitting doesn't occur in [[ ]]
[[ $OSTYPE != *darwin* ]] && return

# Add common homebrew paths to PATH to find brew command (avoid duplicates)
[[ ":$PATH:" != *":/opt/homebrew/bin:"* ]] && export PATH="/opt/homebrew/bin:$PATH"
[[ ":$PATH:" != *":/usr/local/bin:"* ]] && export PATH="/usr/local/bin:$PATH"

# Check if brew is available
if ! command -v brew &>/dev/null; then
    return 0  # Homebrew not installed
fi

# Use cached eval if available (reduces startup time by ~200ms)
if [[ "$DOTFILES_CACHE_EVALS" == "true" ]] && command -v cache_eval &>/dev/null; then
    cache_eval "brew_shellenv" 3600 "brew shellenv"
else
    eval "$(brew shellenv)"
fi
