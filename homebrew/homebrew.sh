#!/usr/bin/env bash

# requires python-keyring
export HOMEBREW_GITHUB_API_TOKEN=`keyring get homebrew github_api_token`
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  source $(brew --prefix)/etc/bash_completion
fi

#### From `brew info python` ###
#
# Unversioned symlinks `python`, `python-config`, `pip` etc. pointing to
# `python3`, `python3-config`, `pip3` etc., respectively, have been installed into
#  /usr/local/opt/python/libexec/bin
#
################################

export PATH=/usr/local/opt/python/libexec/bin:$PATH
