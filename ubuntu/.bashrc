#!/bin/bash

# Tell ls to be colourful
alias ls="ls --color=auto"

# Tell grep to highlight matches
alias grep="grep --color=auto"



force_color_prompt=yes

PS1="\e[31;1m\u@\h \e[33;1m\w\e[0m $ "
