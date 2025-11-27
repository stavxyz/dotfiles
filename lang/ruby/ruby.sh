#!/usr/bin/env bash
# Module: ruby
# Description: Ruby/chruby configuration and version management
# Dependencies: brew, chruby

#eval "$(rbenv init -)"

chrubypath="$(brew --prefix chruby)"
source "${chrubypath}/share/chruby/chruby.sh"
source "${chrubypath}/share/chruby/auto.sh"

echo "ruby-2.6.3" > ~/.ruby-version
