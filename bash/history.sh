#!/usr/bin/env bash

export HISTCONTROL=ignoredups:erasedups
export HISTSIZE=100000
export HISTFILESIZE=100000
shopt -s histappend

# Save and reload the history with the `h` command
function h {
    history -a
    history -c
    history -r
}
