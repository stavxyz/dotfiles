#!/usr/bin/env bash

force_color_prompt=yes

# Tell ls to be colorful
export CLICOLOR=1
export LSCOLORS=exFxCxDxBxegedabagaced

#export LSCOLORS=ExFxBxDxCxegedabagacad

# Tell grep to highlight matches
export GREP_OPTIONS='--color=auto'

#name terminal tabs
#export PROMPT_COMMAND='echo -ne "\033]0;${PWD##*/}\007"'
export PROMPT_COMMAND='echo -ne "\033]0;${PWD##*/}-(${VIRTUAL_ENV##*/})\007"'


########################
## COLOR/CUSTOMIZE PROMPT
########################
export RED="\[\e[31m\]"
export GREEN="\[\e[32m\]"
export YELLOW="\[\e[33m\]"
export BLUE="\[\e[34m\]"
export PURPLE="\[\e[35m\]"
export LTBLUE="\[\e[36m\]"
export WHITE="\[\e[37m\]"
export RESET="\[\e[0m\]"

cd () { builtin cd "$@" && chpwd; }
pushd () { builtin pushd "$@" && chpwd; }
popd () { builtin popd "$@" && chpwd; }
chpwd () {
  case $PWD in
    $HOME) HPWD="~";;
    $HOME/*/*) HPWD="${PWD#"${PWD%/*/*}/"}";;
    $HOME/*) HPWD="~/${PWD##*/}";;
    /*/*/*) HPWD="${PWD#"${PWD%/*/*}/"}";;
    *) HPWD="$PWD";;
  esac
}
#PS1='$HPWD \$'

function hpwd {
    echo $HPWD
}

export PS1="${PURPLE}[${BLUE}\$(hpwd)${PURPLE}] ${RED}\u${PURPLE}@${YELLOW}\h ${PURPLE}\n\$ ${RESET}"
cd  # this is to trigger evaluation of chpwd when shell comes up
#################
