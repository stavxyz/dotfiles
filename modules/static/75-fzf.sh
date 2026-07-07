#!/usr/bin/env bash
# Module: fzf
# Description: fzf keybindings and completion (any machine, any install method)
# Dependencies: fzf (optional)

# fzf's keybinding/completion script isn't clean under the strict
# set -E + ERR trap that bash_profile keeps active while static modules
# load, so suspend strict handling around it and restore afterwards.
_fzf_prev_err_trap="$(trap -p ERR)"
trap - ERR
set +E

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

set -E
if [[ -n "$_fzf_prev_err_trap" ]]; then
  eval "$_fzf_prev_err_trap"
fi
unset _fzf_prev_err_trap

alias vimf='vim "$(fzf)"'
