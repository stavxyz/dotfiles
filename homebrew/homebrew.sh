#!/usr/bin/env bash

# requires python-keyring
export HOMEBREW_GITHUB_API_TOKEN=`keyring get homebrew github_api_token`
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  source $(brew --prefix)/etc/bash_completion
fi
