#!/usr/bin/env bash
# Module: python
# Description: Python/pyenv configuration with lazy loading
# Dependencies: config.sh, utils.sh

export PYENV_ROOT="$HOME/.pyenv"
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"
export WORKON_HOME="$HOME/.virtualenvs"

[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"

setup_python() {
    local lazy_mode="${DOTFILES_LAZY_PYTHON:-${DOTFILES_LAZY_PYENV:-true}}"

    if [[ "$lazy_mode" == "true" ]] && command_exists pyenv; then
        # Lazy load pyenv, but load virtualenvwrapper immediately
        eval "$(command pyenv init - --path)"
        
        # Load virtualenvwrapper via pyenv plugin if available
        if [[ -d "$(pyenv root)/plugins/pyenv-virtualenvwrapper" ]]; then
            eval "$(command pyenv sh-virtualenvwrapper_lazy)"
        fi

        pyenv() {
            unset -f pyenv
            eval "$(command pyenv init -)"
            pyenv "$@"
        }
    elif command_exists pyenv; then
        # Eager mode: load everything immediately
        eval "$(command pyenv init -)"
        
        # Load virtualenvwrapper via pyenv plugin if available
        if [[ -d "$(pyenv root)/plugins/pyenv-virtualenvwrapper" ]]; then
            eval "$(command pyenv sh-virtualenvwrapper_lazy)"
        fi
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
        # Try downloaded script from autocomplete directory
        # Note: Despite the filename, this provides full virtualenvwrapper_lazy.sh functionality
        elif [[ -f "${DOTFILES_DIR:-$HOME/.dotfiles}/autocomplete/virtualenvwrapper-completion.bash" ]]; then
            source "${DOTFILES_DIR:-$HOME/.dotfiles}/autocomplete/virtualenvwrapper-completion.bash"
        fi
    fi
}

setup_python
