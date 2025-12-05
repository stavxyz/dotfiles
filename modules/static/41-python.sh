#!/usr/bin/env bash
# Module: python
# Description: Python/pyenv configuration with lazy loading
# Dependencies: config.sh, utils.sh

export PYENV_ROOT="$HOME/.pyenv"
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"
export WORKON_HOME="$HOME/.virtualenvs"

[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# Helper function to load virtualenvwrapper via pyenv plugin
_load_pyenv_virtualenvwrapper() {
    if [[ -d "$(command pyenv root)/plugins/pyenv-virtualenvwrapper" ]]; then
        eval "$(command pyenv sh-virtualenvwrapper_lazy)"
    fi
}

setup_python() {
    local lazy_mode="${DOTFILES_LAZY_PYTHON:-${DOTFILES_LAZY_PYENV:-true}}"

    if [[ "$lazy_mode" == "true" ]] && command_exists pyenv; then
        # Lazy load pyenv: defer full initialization to first use for faster startup
        pyenv() {
            unset -f pyenv
            eval "$(command pyenv init - bash)"
            _load_pyenv_virtualenvwrapper
            pyenv "$@"
        }
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
