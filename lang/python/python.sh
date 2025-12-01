#!/usr/bin/env bash
# Module: python
# Description: Python/pyenv configuration and virtualenvwrapper setup
# Dependencies: pyenv, pyenv-virtualenvwrapper

export PYENV_ROOT="$HOME/.pyenv"

if command -v pyenv &>/dev/null; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"

    export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"
    export WORKON_HOME="$HOME/.virtualenvs"

    # Only load virtualenvwrapper if plugin is installed
    if [[ -d "$(pyenv root)/plugins/pyenv-virtualenvwrapper" ]]; then
        pyenv virtualenvwrapper_lazy
    fi
fi
