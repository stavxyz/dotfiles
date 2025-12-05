#!/usr/bin/env bash
# Module: config
# Description: Configuration system for dotfiles features
# Dependencies: none

# User-configurable lazy loading toggles
# Users can override these in ~/.bashrc before sourcing bash_profile

# Language-specific lazy loading toggles
# Precedence: DOTFILES_LAZY_PYTHON (user override) > DOTFILES_LAZY_PYENV (legacy) > true (default)
if [[ -n "${DOTFILES_LAZY_PYTHON+x}" ]]; then
    export DOTFILES_LAZY_PYTHON
elif [[ -n "${DOTFILES_LAZY_PYENV+x}" ]]; then
    export DOTFILES_LAZY_PYTHON="${DOTFILES_LAZY_PYENV}"
else
    export DOTFILES_LAZY_PYTHON="true"
fi

export DOTFILES_LAZY_RUBY=${DOTFILES_LAZY_RUBY:-false}
export DOTFILES_LAZY_ASDF=${DOTFILES_LAZY_ASDF:-true}
export DOTFILES_LAZY_SSH=${DOTFILES_LAZY_SSH:-false}

# Backward compatibility - keep DOTFILES_LAZY_PYENV synchronized
export DOTFILES_LAZY_PYENV=$DOTFILES_LAZY_PYTHON
export DOTFILES_LAZY_COMPLETIONS=${DOTFILES_LAZY_COMPLETIONS:-true}

# Performance toggles
export DOTFILES_CACHE_EVALS=${DOTFILES_CACHE_EVALS:-true}

# Minimal mode - skip expensive features for faster startup
export DOTFILES_MINIMAL=${DOTFILES_MINIMAL:-false}

# Cache directory
export DOTFILES_CACHE_DIR="${HOME}/.cache/dotfiles"
mkdir -p "$DOTFILES_CACHE_DIR"
