#!/usr/bin/env bash

errcho() {
  >&2 echo $@
}

# tell ls to be colorful
if [[ $OSTYPE == *"linux"* ]]; then
  alias ls='ls --color=auto'
elif [[ $OSTYPE == *"darwin"* ]]; then
  alias ls='ls -aGFh'
  alias la='ls -alsG'
fi


## git aliases
alias gitst='git status'
alias gits='git status'
alias gs='git status'
alias g='git'

# vim
alias vimp='vim -c ":PlugInstall|q|q"'

# misc. aliases
alias rgrep='grep --exclude .babel.json --exclude-dir .terraform --exclude-dir node_modules --exclude-dir dist --exclude-dir .git --exclude-dir .tox -I -r -n -i -e'
findfile () {
  echo -e "Looking for regular file $1, ignoring hidden directories.\n"
  find . -not -path '*/\.*' -type f -iname $1
}

######################
#### LOCAL aliases ###
######################

if [ -d ~/.aliases ]; then
  for f in ~/.aliases/*; do source $f; done
fi
