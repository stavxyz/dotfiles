#!/usr/bin/env bash

errcho() {
  >&2 echo $@
}

# tell ls to be colorful
alias ls='ls -aGFh'
alias la="ls -alsG"

## git aliases
alias gitst='git status'
alias gits='git status'
alias gs='git status'
alias g='git'


# misc. aliases
alias rgrep='grep --exclude .babel.json --exclude-dir .terraform --exclude-dir node_modules --exclude-dir dist --exclude-dir .git --exclude-dir .tox -I -r -n -i -e'
findfile () {
  echo -e "Looking for regular file $1, ignoring hidden directories.\n"
  find . -not -path '*/\.*' -type f -iname $1
}

######################
#### LOCAL aliases ###
######################

if [ -d ~/.aliases ];
  then
    for f in ~/.aliases/*; do source $f; done
  else
    errcho "Found no ~/.aliases directory"
fi
