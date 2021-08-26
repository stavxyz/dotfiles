#!/usr/bin/env bash

export WORKON_HOME=$HOME/.virtualenvs            #
mkdir -p "$WORKON_HOME"
export PIP_VIRTUALENV_BASE=$WORKON_HOME          #
export PIP_RESPECT_VIRTUALENV=true               #

                                                #
# for pythonrc
#export PYTHONSTARTUP=~/.pystartup/.pythonrc
alias plint="pylint --msg-template='{path}:{line}: [{msg_id}({symbol}), {obj}] {msg}' --output-format=colorized -r n"
alias pipi="pip install --upgrade --force-reinstall --no-cache-dir $1"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"
pyenv global 3.6.14
#pyenv virtualenvwrapper


if [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
  source /usr/local/bin/virtualenvwrapper.sh
elif [ -f "$(dirname "$(pyenv which python)")/virtualenvwrapper.sh" ]; then
  source "$(dirname "$(pyenv which python)")/virtualenvwrapper.sh"
else
  echo 'virtualenvwrapper.sh not found'
fi
