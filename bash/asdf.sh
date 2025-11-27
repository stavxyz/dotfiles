#!/usr/bin/env bash
# Module: asdf
# Description: asdf version manager and direnv integration
# Dependencies: brew, asdf, direnv

eval "$(direnv hook bash)"

source "$(brew --prefix asdf)/asdf.sh"
source "$(brew --prefix asdf)/etc/bash_completion.d/asdf.bash"
