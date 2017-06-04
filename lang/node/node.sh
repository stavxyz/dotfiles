#!/usr/bin/env bash

alias npm-exec='PATH=$(npm bin):$PATH'
alias nom="rm -rf node_modules && npm cache clear && npm install"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" # This loads nvm
