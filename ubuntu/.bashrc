#!/bin/bash

#virtualenvwrapper
#source /usr/local/bin/virtualenvwrapper.sh
# installed as /etc/bash_completion.d/virtualenvwrapper on debian-based
export WORKON_HOME=$HOME/.virtualenvs
export PIP_VIRTUALENV_BASE=$WORKON_HOME
export PIP_RESPECT_VIRTUALENV=true

#python
export PYTHONSTARTUP=~/.pystartup/.pythonrc

#scm
export VISUAL=vim
export GIT_EDITOR=vim

# Tell ls to be colourful
alias ls="ls --color=auto"

# Tell grep to highlight matches
alias grep="grep --color=auto"

export GIT_EDITOR=vim

#yep
force_color_prompt=yes

#####################################################
## COLOR/CUSTOMIZE PROMPT (also solves clobberage) #
####################################################
export RED="\[\e[31m\]"
export GREEN="\[\e[32m\]"
export YELLOW="\[\e[33m\]"
export BLUE="\[\e[34m\]"
export PURPLE="\[\e[35m\]"
export LTBLUE="\[\e[36m\]"
export WHITE="\[\e[37m\]"
export RESET="\[\e[0m\]"
export PS1="${PURPLE}[${BLUE}\W${PURPLE}] ${RED}\u${PURPLE}@${YELLOW}\h ${PURPLE}$ ${RESET}"
#################

#looking for a solution to long command clobberage
#LTGREEN="\[\033[31;1;32m\]"
#LTBLUE="\[\033[40;1;34m\]"
#CLEAR="\[\033[0m\]"
#LIGHT_GRAY="\[\033[40;1;33m\]"
#WHAT="\[\033[31;1;31m\]"
#export PS1="$LTGREEN\u$LTBLUE@\h:$LIGHT_GRAY\w$CLEAR $ "
#export PS1="$WHAT\u$LTGREEN@$WHAT\h:$LTGREEN\w$CLEAR $ "

#EOF
