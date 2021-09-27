#!/usr/bin/env bash

eval "$(ssh-agent -s)" > /dev/null

if ! [[ -d "${HOME}/.ssh" ]]; then
  errcho "${HOME}/.ssh dir DNE, skipping."
else
  for _key in $(ls -1A ~/.ssh/*.pub); do
      # %???? removes '.pub' to target
      # corresponding private key
      _priv="${_key%????}"
      if [ -f "${_priv}" ]; then
        ssh-add -q "${_priv}"
      else
        errcho "corresponding private key ${_priv} does not exist"
      fi
  done
fi
