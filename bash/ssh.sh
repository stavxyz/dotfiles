#!/usr/bin/env bash
# Module: ssh
# Description: SSH agent and key management
# Dependencies: ssh-agent, ssh-add

if command -v ssh-agent &>/dev/null; then
    eval "$(ssh-agent -s)" > /dev/null
fi

if ! [[ -d "${HOME}/.ssh" ]]; then
  errcho "${HOME}/.ssh dir DNE, skipping."
else
  for _key in ~/.ssh/*.pub; do
      # Skip if glob didn't match any files
      [[ -f "$_key" ]] || continue

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
