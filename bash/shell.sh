#!/usr/bin/env bash

force_color_prompt=yes

################ BASE16_SHELL #######################
# A shell script to change your shell's default ANSI
# colors but most importantly, colors 17 to 21 of
# your shell's 256 colorspace (if supported by your terminal).
# This script makes it possible to honor the original
# bright colors of your shell (e.g. bright green is still
# green and so on) while providing additional base16 colors
# to applications such as Vim.
# The following sets up autocompletion for base16-shell
BASE16_SHELL=$HOME/.config/base16-shell/
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

# setup iterm / vim / tmux / mac menu bar
# requires 'brew install dark-mode'
function theme-switch {
 echo -e "\033]50;SetProfile=$1\a"
 export ITERM_PROFILE=$1
 if [ $1 = "dark" ]; then
    dark-mode on 2> /dev/null # Prevent error message if dark-mode is not installed
    base16_solarized-dark 2> /dev/null # prevent error message if base16-shell is not installed
    if tmux info &> /dev/null; then
        tmux set-environment ITERM_PROFILE dark
        tmux source-file ~/.tmux/plugins/tmux-colors-solarized/tmuxcolors-dark.conf
    fi
 else
    dark-mode off 2> /dev/null
    base16_solarized-light 2> /dev/null # prevent error message if base16-shell is not installed
    if tmux info &> /dev/null; then
        tmux set-environment ITERM_PROFILE light
        tmux source-file ~/.tmux/plugins/tmux-colors-solarized/tmuxcolors-light.conf
    fi
 fi
}

function go-dark {
  theme-switch dark
}

function let-there-be-light {
  theme-switch light
}


# Tell ls to be colorful
export CLICOLOR=1
export LSCOLORS=exFxCxDxBxegedabagaced

if [[ $OSTYPE == *"linux"* ]]; then
  alias ls='ls --color=auto'
elif [[ $OSTYPE == *"darwin"* ]]; then
  alias ls='ls -aGFh'
  alias la='ls -alsG'
fi


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

if [ -f "/etc/debian_version" ]; then
    export IS_DEBIAN=1
    export ICON="🌀";
fi

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

export PS1="${PURPLE}[${BLUE}\$(hpwd)${PURPLE}] ${RED}\u${PURPLE}@${YELLOW}\h${PURPLE}${ICON}\n\$ ${RESET}"
cd  # this is to trigger evaluation of chpwd when shell comes up
#################
