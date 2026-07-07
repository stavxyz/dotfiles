#!/usr/bin/env bash
# Module: fzf
# Description: fzf keybindings and completion (any machine, any install method)
# Dependencies: fzf (optional)

# Prefer fzf's built-in loader (fzf >= 0.48, works wherever fzf is on
# PATH); fall back to the legacy install-script file. Cached because the
# loader output only changes when fzf is upgraded.
if command -v fzf &>/dev/null; then
  if [[ "${DOTFILES_CACHE_EVALS:-true}" == "true" ]] && command -v cache_eval &>/dev/null; then
    cache_eval "fzf_bash" 86400 "fzf --bash"
  else
    eval "$(fzf --bash 2>/dev/null)"
  fi
elif [[ -f ~/.fzf.bash ]]; then
  source ~/.fzf.bash
fi

alias vimf='vim "$(fzf)"'
