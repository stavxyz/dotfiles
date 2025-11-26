#!/usr/bin/env bash
# Module: homebrew
# Description: Homebrew environment setup with caching support
# Dependencies: cache.sh (optional)

# macOS only
[[ $OSTYPE != *darwin* ]] && return

# Use cached eval if available (reduces startup time by ~200ms)
if [[ "$DOTFILES_CACHE_EVALS" == "true" ]] && command -v cache_eval &>/dev/null; then
  cache_eval "brew_shellenv" 3600 "/opt/homebrew/bin/brew shellenv"
else
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
