#!/usr/bin/env bash

export GOPATH=$HOME/go
export GOBIN=$GOPATH/bin
mkdir -p "$GOBIN"

if [[ $OSTYPE =~ "darwin" ]]; then
  :
  # for brew installed go
  #export GOROOT="$(brew --prefix go)/libexec"
  #export PATH=$PATH:$GOROOT/bin
  # commented because I dont think this is necessary
fi

export PATH=$PATH:$GOPATH/bin

# rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Toggle module support
export GO111MODULE='auto'

# gore
alias gore='gore -autoimport'
