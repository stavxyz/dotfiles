#!/usr/bin/env bash

if ! [[ $OSTYPE == *"darwin"* ]]; then
  return
fi

# Use cached eval if caching is enabled, otherwise run directly
if [[ "$DOTFILES_CACHE_EVALS" == "true" ]] && command -v cache_eval &>/dev/null; then
  cache_eval "brew_shellenv" 3600 "/opt/homebrew/bin/brew shellenv"
else
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
