#!/usr/bin/env bash

errcho() {
  >&2 echo "$@"
}

## git aliases
alias gitst='git status -uno'
alias gits='git status'
alias gs='git status'
alias g='git'

# vim
alias vimp='vim -c ":PlugInstall|q|q"'

# misc. aliases
alias rgrep='grep --exclude .babel.json --exclude-dir vendor --exclude-dir build --exclude-dir .terraform --exclude-dir node_modules --exclude-dir dist --exclude-dir .git --exclude-dir .tox -I -r -n -i -e'
findfile () {
  >&2 echo -e "Looking for regular file $1, ignoring hidden directories.\n"
  find . -not -path '*/\.*' -type f -iname "$1"
}

# jason is a person

jsonvalue ()
{
    if [ -z "$1" ]; then
        errcho 'Usage: jsonvalue <jsondata> <key>';
        return 1;
    fi
    if [ -z "$2" ]; then
        errcho 'Usage: jsonvalue <jsondata> <key>';
        return 1;
    fi
    echo "$1" | jq -r --arg KEY "$2" '. as $DATA|($KEY|split(".")|reduce .[] as $subkey ($DATA; .[$subkey])) // empty'
}

# openssl

# display certs from an https url
getcert() {
  local url="$1"
  local parsed_url=$(printf "%s" "${url}" | sed 's|https://||g')
  printf '\n' | openssl s_client -connect "$parsed_url":443 -showcerts | openssl x509 -noout -text
}


# dates

ago ()
{
  __ago=$1;
  __ago=${__ago:-24};
  date -j -f "%a %b %d %T %Z %Y" "$(date -v -${__ago}H)" "+%s"
}

######################
#### LOCAL aliases ###
######################

if [ -d ~/.aliases ]; then
  for f in ~/.aliases/*; do source "$f"; done
fi


