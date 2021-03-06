#!/usr/bin/env bash

export GOPATH=$HOME/go
# for brew installed go
export GOROOT=/usr/local/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

# Toggle module support
export GO111MODULE='on'

# gore
alias gore='gore -autoimport'
