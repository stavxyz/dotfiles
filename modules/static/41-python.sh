#!/usr/bin/env bash
# Module: python
# Description: Python/pyenv configuration with lazy loading
# Dependencies: config.sh, utils.sh

export PYENV_ROOT="$HOME/.pyenv"
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"
export WORKON_HOME="$HOME/.virtualenvs"

# Add pyenv binary and shims to PATH
# Shims must be first in PATH for pyenv to intercept python/pip commands
[[ -d "$PYENV_ROOT/shims" ]] && export PATH="$PYENV_ROOT/shims:$PATH"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# Helper function to load virtualenvwrapper via pyenv plugin
_load_pyenv_virtualenvwrapper() {
    if [[ -d "$(command pyenv root)/plugins/pyenv-virtualenvwrapper" ]]; then
        eval "$(command pyenv sh-virtualenvwrapper_lazy)"
    fi
}

# Shared lazy loader for pyenv - can be triggered by any command
_lazy_load_pyenv() {
    # Only load once
    if [[ -n "${PYENV_LAZY_LOADED:-}" ]]; then
        return 0
    fi

    # Unset all lazy wrapper functions
    unset -f pyenv python pip workon mkvirtualenv deactivate 2>/dev/null

    # Initialize pyenv (rehash shims, install sh dispatcher)
    eval "$(command pyenv init - bash)"

    # Load virtualenvwrapper
    _load_pyenv_virtualenvwrapper

    # Mark as loaded
    export PYENV_LAZY_LOADED=1
}

setup_python() {
    local lazy_mode="${DOTFILES_LAZY_PYTHON:-${DOTFILES_LAZY_PYENV:-true}}"

    if [[ "$lazy_mode" == "true" ]] && command_exists pyenv; then
        # Lazy load pyenv: defer full initialization to first use for faster startup
        # Create wrapper functions that trigger initialization on first use
        pyenv() { _lazy_load_pyenv && pyenv "$@"; }
        python() { _lazy_load_pyenv && python "$@"; }
        pip() { _lazy_load_pyenv && pip "$@"; }

        # Virtualenvwrapper commands (if plugin is installed)
        if [[ -d "$(command pyenv root)/plugins/pyenv-virtualenvwrapper" ]]; then
            workon() { _lazy_load_pyenv && workon "$@"; }
            mkvirtualenv() { _lazy_load_pyenv && mkvirtualenv "$@"; }
            deactivate() { _lazy_load_pyenv && deactivate "$@"; }
        fi
    elif command_exists pyenv; then
        # Eager mode: load everything immediately
        eval "$(command pyenv init - bash)"

        # Load virtualenvwrapper via pyenv plugin if available
        _load_pyenv_virtualenvwrapper
    fi
    
    # Fallback to raw virtualenvwrapper if pyenv plugin is not available
    # This allows virtualenvwrapper to work independently of pyenv
    if ! command_exists workon; then
        # Try system virtualenvwrapper installation
        if [[ -f "/usr/local/bin/virtualenvwrapper_lazy.sh" ]]; then
            source "/usr/local/bin/virtualenvwrapper_lazy.sh"
        elif [[ -f "/usr/bin/virtualenvwrapper_lazy.sh" ]]; then
            source "/usr/bin/virtualenvwrapper_lazy.sh"
        # Try pip user install location
        elif [[ -f "$HOME/.local/bin/virtualenvwrapper_lazy.sh" ]]; then
            source "$HOME/.local/bin/virtualenvwrapper_lazy.sh"
        fi
    fi
}

setup_python
