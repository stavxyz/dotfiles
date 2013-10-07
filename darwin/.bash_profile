export PATH=/usr/local/bin:/usr/local/mysql/bin:/usr/local/sbin:/usr/local/lib:/Users/smlstvnh/executables:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin

#for pythonrc
export PYTHONSTARTUP=~/.pystartup/.pythonrc

################
## ANDROID
################
export ANDROID_HOME=/usr/local/opt/android-sdk
export ANDROID_SDK=/usr/local/opt/android-sdk
export ANDROID_NDK=/usr/local/opt/android-ndk
#source /Users/smlstvnh/projects/android-dev/ignifuga/tools/schafer
#source /Users/smlstvnh/projects/android-dev/ignifuga/tools/grossman

export PATH=$PATH:/Users/smlstvnh/projects/android-dev/ignifuga/tools
################

# C
export CC=gcc-4.8

################



source /usr/local/bin/virtualenvwrapper.sh
#export WORKON_HOME=~/.virtualenvs


export WORKON_HOME=$HOME/.virtualenvs
export PIP_VIRTUALENV_BASE=$WORKON_HOME
export PIP_RESPECT_VIRTUALENV=true


# Tell ls to be colourful
export CLICOLOR=1
export LSCOLORS=Exfxcxdxbxegedabagacad

# Tell grep to highlight matches
export GREP_OPTIONS='--color=auto'

#REMOTES
alias smbops2='ssh -p314 sam@smbops2'
alias smbops3='ssh -p314 sam@smbops3'
alias smbops='ssh -p314 sam@smbops'
alias rodeo='ssh sam@rodeo'
alias flexo-csfg='ssh -p314 sam@flexo-csfg'
alias toro='ssh sam@toro'

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
export PS1="${PURPLE}[${BLUE}\W${PURPLE}] ${RED}\u${PURPLE}@${YELLOW}\h ${PURPLE}$ ${RESET}"
#################

# show me the... realpath
realpath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}


source ~/.git-completion.bash
source ~/.hg/.hg-completion.bash

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
