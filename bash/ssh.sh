#!/usr/bin/env bash

eval "$(ssh-agent -s)" > /dev/null

if ! [[ -d "${HOME}/.ssh" ]]; then
  errcho "${HOME}/.ssh dir DNE, skipping."
else
  for _key in $(ls -1A ~/.ssh/*.pub); do
      # %???? removes '.pub' to target
      # corresponding private key
      _priv="${_key%????}"
      [[ -f "${_priv}" ]] && ssh-add -q "${_priv}"
  done
fi
