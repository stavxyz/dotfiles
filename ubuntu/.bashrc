#!/bin/bash

#virtualenvwrapper
source /usr/local/bin/virtualenvwrapper.sh
export WORKON_HOME=$HOME/.virtualenvs
export PIP_VIRTUALENV_BASE=$WORKON_HOME
export PIP_RESPECT_VIRTUALENV=true

#python
export PYTHONSTARTUP=~/.pystartup.pythonrc

#scm
export VISUAL=vim

# Tell ls to be colourful
alias ls="ls --color=auto"

# Tell grep to highlight matches
alias grep="grep --color=auto"

#yep
force_color_prompt=yes

PS1="\e[31;1m\u@\h \e[33;1m\w\e[0m $ "
