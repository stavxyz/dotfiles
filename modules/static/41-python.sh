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

# Function: load_pyenv_virtualenvwrapper
# Description: Load virtualenvwrapper through the pyenv-virtualenvwrapper plugin
# Usage: load_pyenv_virtualenvwrapper
# Returns: 0 (no-op when the plugin is not installed)
# No leading underscore on this helper or lazy_load_pyenv: Claude Code rebuilds
# its tool shell from a snapshot of the login shell's functions that drops
# every underscore-prefixed name, and the public wrappers below call these.
load_pyenv_virtualenvwrapper() {
    if [[ -d "$(command pyenv root)/plugins/pyenv-virtualenvwrapper" ]]; then
        eval "$(command pyenv sh-virtualenvwrapper_lazy)"
    fi
}

# Function: lazy_load_pyenv
# Description: Initialize pyenv and virtualenvwrapper in this shell, once; the
#              pyenv/python/pip/workon wrappers call it on first use
# Usage: lazy_load_pyenv
# Returns: 0 once pyenv is initialized in this shell
lazy_load_pyenv() {
    # Only load once
    if [[ -n "${PYENV_LAZY_LOADED:-}" ]]; then
        return 0
    fi

    # Unset all lazy wrapper functions
    unset -f pyenv python pip workon mkvirtualenv deactivate 2>/dev/null

    # Initialize pyenv (rehash shims, install sh dispatcher)
    # Detect shell type for cross-shell compatibility
    local shell_type
    shell_type="$(basename "${SHELL:-bash}")"
    eval "$(command pyenv init - "$shell_type")"

    # Load virtualenvwrapper
    load_pyenv_virtualenvwrapper

    # Mark as loaded. Not exported: the flag describes this shell's function
    # table, and a child shell starts over with the wrappers redefined.
    PYENV_LAZY_LOADED=1
}

setup_python() {
    local lazy_mode="${DOTFILES_LAZY_PYTHON:-${DOTFILES_LAZY_PYENV:-true}}"

    if [[ "$lazy_mode" == "true" ]] && command_exists pyenv; then
        # Lazy load pyenv: defer full initialization to first use for faster startup
        # Create wrapper functions that trigger initialization on first use
        # The wrappers are fresh in this shell, so a loaded flag inherited from a
        # parent shell's environment is wrong here: it would skip loading and
        # make every wrapper call itself until bash segfaults.
        unset PYENV_LAZY_LOADED
        pyenv() { lazy_load_pyenv && pyenv "$@"; }
        python() { lazy_load_pyenv && python "$@"; }
        pip() { lazy_load_pyenv && pip "$@"; }

        # Virtualenvwrapper commands (if plugin is installed)
        if [[ -d "$(command pyenv root)/plugins/pyenv-virtualenvwrapper" ]]; then
            workon() { lazy_load_pyenv && workon "$@"; }
            mkvirtualenv() { lazy_load_pyenv && mkvirtualenv "$@"; }
            deactivate() { lazy_load_pyenv && deactivate "$@"; }
        fi
    elif command_exists pyenv; then
        # Eager mode: load everything immediately
        # Detect shell type for cross-shell compatibility
        local shell_type
        shell_type="$(basename "${SHELL:-bash}")"
        eval "$(command pyenv init - "$shell_type")"

        # Load virtualenvwrapper via pyenv plugin if available
        load_pyenv_virtualenvwrapper
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
