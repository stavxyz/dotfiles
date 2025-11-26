#!/usr/bin/env bash
# Module: config
# Description: Configuration system for dotfiles features
# Dependencies: none

# User-configurable lazy loading toggles
# Users can override these in ~/.bashrc before sourcing bash_profile
export DOTFILES_LAZY_PYENV=${DOTFILES_LAZY_PYENV:-true}
export DOTFILES_LAZY_DIRENV=${DOTFILES_LAZY_DIRENV:-true}
export DOTFILES_LAZY_COMPLETIONS=${DOTFILES_LAZY_COMPLETIONS:-true}

# Performance toggles
export DOTFILES_CACHE_EVALS=${DOTFILES_CACHE_EVALS:-true}

# Minimal mode - skip expensive features for faster startup
export DOTFILES_MINIMAL=${DOTFILES_MINIMAL:-false}

# Cache directory
export DOTFILES_CACHE_DIR="${HOME}/.cache/dotfiles"
mkdir -p "$DOTFILES_CACHE_DIR"
