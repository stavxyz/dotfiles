#!/usr/bin/env bash

export GOPATH=$HOME/go
# for brew installed go
#export GOROOT=/usr/local/opt/go/libexec
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin

# rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Toggle module support
#export GO111MODULE='on'

# gore
alias gore='gore -autoimport'
