#!/usr/bin/env bash
# Module: homebrew
# Description: Homebrew environment setup with caching support
# Dependencies: cache.sh (optional)

# macOS only
# shellcheck disable=SC2086  # Safe: word splitting doesn't occur in [[ ]]
[[ $OSTYPE != *darwin* ]] && return

# Detect homebrew path (Apple Silicon vs Intel)
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
elif [[ -x "/usr/local/bin/brew" ]]; then
    HOMEBREW_PREFIX="/usr/local"
else
    return 0  # Homebrew not installed
fi

# Use cached eval if available (reduces startup time by ~200ms)
if [[ "$DOTFILES_CACHE_EVALS" == "true" ]] && command -v cache_eval &>/dev/null; then
    cache_eval "brew_shellenv" 3600 "${HOMEBREW_PREFIX}/bin/brew shellenv"
else
    eval "$("${HOMEBREW_PREFIX}"/bin/brew shellenv)"
fi
