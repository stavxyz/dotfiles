#!/usr/bin/env bash

errcho() {
  printf '%s\n' "$@" >&2
}

DOTFILES_GIT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || true)
DOTFILES_DIR=${DOTFILES_GIT_DIR:-${DOTFILES_DIR}}

if [[ ! -d "${DOTFILES_DIR}" ]]; then
  errcho 'dotfiles directory not found'
  exit 1
fi

# Ensure autocomplete directory exists
AUTOCOMPLETE_DIR="$DOTFILES_DIR/autocomplete"
mkdir -p "$AUTOCOMPLETE_DIR" || {
  errcho "Failed to create autocomplete directory"
  exit 1
}

# Function to download with error handling
download_completion() {
  local name="$1"
  local url="$2"
  local output="$3"

  printf '\n*** Fetching %s autocomplete script ***\n' "$name"
  if curl -fsSL "$url" -o "$output"; then
    printf '✓ Downloaded %s\n' "$name"
  else
    errcho "✗ Failed to download $name completion"
    return 1
  fi
}

download_completion "git" \
  "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash" \
  "$AUTOCOMPLETE_DIR/git-completion.bash"

download_completion "docker" \
  "https://raw.githubusercontent.com/docker/cli/master/contrib/completion/bash/docker" \
  "$AUTOCOMPLETE_DIR/docker-completion.bash"

download_completion "docker-compose" \
  "https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose" \
  "$AUTOCOMPLETE_DIR/docker-compose-completion.bash"

download_completion "virtualenvwrapper" \
  "https://raw.githubusercontent.com/python-virtualenvwrapper/virtualenvwrapper/refs/heads/main/virtualenvwrapper_lazy.sh" \
  "$AUTOCOMPLETE_DIR/virtualenvwrapper-completion.bash"

# shellcheck disable=SC2086  # Safe: word splitting doesn't occur in [[ ]]
if [[ $OSTYPE == *"darwin"* ]]; then
  download_completion "homebrew" \
    "https://raw.githubusercontent.com/Homebrew/brew/refs/heads/main/completions/bash/brew" \
    "$AUTOCOMPLETE_DIR/homebrew-completion.bash"
fi

printf '\n✓ Autocomplete scripts updated\n'
