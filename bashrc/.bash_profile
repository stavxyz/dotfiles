export PATH=/usr/local/bin:/usr/local/sbin:/usr/local/lib:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:~/bin

#for pythonrc
export PYTHONSTARTUP=~/.pystartup/.pythonrc

#################################################
##### python virtualenv & virtualenvwrapper #####
#################################################
                                                #
if [ -f /usr/local/bin/virtualenvwrapper.sh ];  #
  then                                          #
    source /usr/local/bin/virtualenvwrapper.sh  #
  else                                          #
    echo "Didn't find virtualenvwrapper.sh"     #
fi                                              #
export WORKON_HOME=$HOME/.virtualenvs           #
export PIP_VIRTUALENV_BASE=$WORKON_HOME         #
export PIP_RESPECT_VIRTUALENV=true              #
                                                #
#################################################

# Tell ls to be colourful
export CLICOLOR=1
export LSCOLORS=Exfxcxdxbxegedabagacad

## git aliases
alias gitst='git status'
alias gits='git status'

# Tell grep to highlight matches
export GREP_OPTIONS='--color=auto'

#name terminal tabs
#export PROMPT_COMMAND='echo -ne "\033]0;${PWD##*/}\007"'
export PROMPT_COMMAND='echo -ne "\033]0;${PWD##*/}-(${VIRTUAL_ENV##*/})\007"'

# autocomplete scm, tmux
for f in ~/.autocomplete/*; do source $f; done

# tell me more
alias la="ls -alsG"
alias ls="ls -AG"

# install Vundle plugins
#vim +PluginInstall +qall

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

alias reset='. ~/dotfiles/runme.sh && reset'

eval "$(rbenv init -)"
