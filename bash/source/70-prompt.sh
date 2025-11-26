#!/usr/bin/env bash
# Module: prompt
# Description: Bash prompt configuration with colors and git integration
# Dependencies: none

# ============================================================================
# Color Configuration
# ============================================================================

force_color_prompt=yes

# ls colors
export CLICOLOR=1
export LSCOLORS=exFxCxDxBxegedabagaced

# Platform-specific ls aliases
if [[ $OSTYPE == *linux* ]]; then
  alias ls='ls --color=auto'
elif [[ $OSTYPE == *darwin* ]]; then
  alias ls='ls -aGFh'
  alias la='ls -alsG'
fi

# grep colors (GREP_OPTIONS is deprecated, but still works)
export GREP_OPTIONS='--color=auto'

# ============================================================================
# Terminal Title
# ============================================================================

# Set terminal tab title to: current_dir-(virtualenv)
export PROMPT_COMMAND='echo -ne "\033]0;${PWD##*/}-(${VIRTUAL_ENV##*/})\007"'

# ============================================================================
# Prompt Colors
# ============================================================================

export RED="\[\e[31m\]"
export GREEN="\[\e[32m\]"
export YELLOW="\[\e[33m\]"
export BLUE="\[\e[34m\]"
export PURPLE="\[\e[35m\]"
export LTBLUE="\[\e[36m\]"
export WHITE="\[\e[37m\]"
export RESET="\[\e[0m\]"

# Platform-specific icon
[[ -f "/etc/debian_version" ]] && export IS_DEBIAN=1 ICON="🌀"

# ============================================================================
# Smart Path Shortening
# ============================================================================

# Shorten pwd to show only last 2 directories
# Examples: ~/foo/bar/baz → bar/baz, ~/projects → ~/projects, ~ → ~
chpwd() {
  case $PWD in
    "$HOME")      HPWD="~" ;;
    "$HOME"/*/*)  HPWD="${PWD#"${PWD%/*/*}/"}" ;;
    "$HOME"/*)    HPWD="~/${PWD##*/}" ;;
    /*/*/*)       HPWD="${PWD#"${PWD%/*/*}/"}" ;;
    *)            HPWD="$PWD" ;;
  esac
}

hpwd() { echo "$HPWD"; }

# Wrap cd/pushd/popd to update HPWD automatically
cd()    { builtin cd "$@" && chpwd; }
pushd() { builtin pushd "$@" && chpwd; }
popd()  { builtin popd "$@" && chpwd; }

# ============================================================================
# Prompt String
# ============================================================================

# Format: [path] user@host
# $
export PS1="${PURPLE}[${BLUE}\$(hpwd)${PURPLE}] ${RED}\u${PURPLE}@${YELLOW}\h${PURPLE}${ICON}\n\$ ${RESET}"

# Initialize HPWD
cd
# ============================================================================
# Bash Completion
# ============================================================================

# Try to load system bash completion from various locations
_completion_paths=(
  "/opt/homebrew/etc/profile.d/bash_completion.sh"      # macOS Homebrew (Apple Silicon)
  "/usr/local/etc/profile.d/bash_completion.sh"         # macOS Homebrew (Intel)
  "/usr/share/bash-completion/bash_completion"          # Linux (Debian/Ubuntu)
  "/etc/bash_completion"                                # Linux (older systems)
)

for path in "${_completion_paths[@]}"; do
  if [[ -r "$path" ]]; then
    source "$path"
    _bash_completion_loaded=true
    break
  fi
done

# Fallback: load git completion directly if nothing else worked
if [[ "${_bash_completion_loaded:-false}" == "false" ]]; then
  [[ -r "/usr/share/bash-completion/completions/git" ]] && source "/usr/share/bash-completion/completions/git"
fi

unset _bash_completion_loaded _completion_paths
