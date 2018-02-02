#!/usr/bin/env bash

export WORKON_HOME=$HOME/.virtualenvs            #
export PIP_VIRTUALENV_BASE=$WORKON_HOME          #
export PIP_RESPECT_VIRTUALENV=true               #

                                                 #
# for pythonrc
export PYTHONSTARTUP=~/.pystartup/.pythonrc
alias plint="pylint --msg-template='{path}:{line}: [{msg_id}({symbol}), {obj}] {msg}' --output-format=colorized -r n"
alias pipi="pip install --upgrade --force-reinstall --no-cache-dir $1"

# pyenv
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
pyenv virtualenvwrapper
