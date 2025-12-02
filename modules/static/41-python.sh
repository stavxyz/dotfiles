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
        [[ -d "$(pyenv root)/plugins/pyenv-virtualenvwrapper" ]] && \
            eval "$(pyenv sh-virtualenvwrapper_lazy)"

        pyenv() {
            unset -f pyenv
            eval "$(command pyenv init -)"
            pyenv "$@"
        }
    elif command_exists pyenv; then
        # Eager mode: load everything immediately
        eval "$(pyenv init -)"
        [[ -d "$(pyenv root)/plugins/pyenv-virtualenvwrapper" ]] && \
            eval "$(pyenv sh-virtualenvwrapper_lazy)"
    fi
}

setup_python
