#!/usr/bin/env bash

eval "$(direnv hook bash)"

source "$(brew --prefix asdf)/asdf.sh"
source "$(brew --prefix asdf)/etc/bash_completion.d/asdf.bash"
