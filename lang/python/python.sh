#!/usr/bin/env bash
# Module: python
# Description: Python/pyenv configuration and virtualenvwrapper setup
# Dependencies: pyenv, pyenv-virtualenvwrapper

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"
export WORKON_HOME=$HOME/.virtualenvs
pyenv virtualenvwrapper_lazy
