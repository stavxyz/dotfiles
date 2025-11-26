#!/usr/bin/env bash
# Module: prompt
# Description: Bash prompt configuration with colors and git integration
# Dependencies: none

force_color_prompt=yes

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

function hpwd {
    echo $HPWD
}

export PS1="${PURPLE}[${BLUE}\$(hpwd)${PURPLE}] ${RED}\u${PURPLE}@${YELLOW}\h${PURPLE}${ICON}\n\$ ${RESET}"
cd  # this is to trigger evaluation of chpwd when shell comes up
#################


# enable system bash completion
# Try various locations based on OS and package manager
_bash_completion_loaded=false

if [[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]]; then
  # macOS with Homebrew (Apple Silicon)
  source "/opt/homebrew/etc/profile.d/bash_completion.sh"
  _bash_completion_loaded=true
elif [[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]]; then
  # macOS with Homebrew (Intel)
  source "/usr/local/etc/profile.d/bash_completion.sh"
  _bash_completion_loaded=true
elif [[ -r "/usr/share/bash-completion/bash_completion" ]]; then
  # Linux (Debian/Ubuntu with bash-completion package)
  source "/usr/share/bash-completion/bash_completion"
  _bash_completion_loaded=true
elif [[ -r "/etc/bash_completion" ]]; then
  # Linux (older systems / alternative location)
  source "/etc/bash_completion"
  _bash_completion_loaded=true
fi

# If no system-wide bash completion, try to load git completion directly
if [[ "$_bash_completion_loaded" == "false" ]]; then
  if [[ -r "/usr/share/bash-completion/completions/git" ]]; then
    source "/usr/share/bash-completion/completions/git"
  fi
fi

unset _bash_completion_loaded
