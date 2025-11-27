#!/usr/bin/env bash
# Module: aliases
# Description: Shell aliases and utility functions
# Dependencies: jq (for jsonvalue)

# ============================================================================
# Git Aliases
# ============================================================================

alias g='git'
alias gs='git status'
alias gits='git status'
alias gitst='git status -uno'

# ============================================================================
# Editor Aliases
# ============================================================================

alias vimp='vim -c ":PlugInstall|q|q"'

# ============================================================================
# Search Utilities
# ============================================================================

# Enable colored grep output
alias grep='grep --color=auto'

# Recursive grep with common excludes
alias rgrep='grep \
  --exclude .babel.json \
  --exclude-dir vendor \
  --exclude-dir build \
  --exclude-dir .terraform \
  --exclude-dir node_modules \
  --exclude-dir dist \
  --exclude-dir .git \
  --exclude-dir .tox \
  -I -r -n -i -e'

findfile() {
  echo "Looking for regular file: $1 (ignoring hidden directories)" >&2
  find . -not -path '*/\.*' -type f -iname "$1"
}

# ============================================================================
# JSON Utilities
# ============================================================================

# Extract value from JSON string using dot-notation key path
# Supports nested keys like "user.profile.name"
#
# Usage: jsonvalue <json_data> <key_path>
# Arguments:
#   $1 - JSON data as string
#   $2 - Key path in dot notation (e.g., "user.name" or "data.items.0.id")
# Returns:
#   0 - Success (prints extracted value)
#   1 - Error (missing arguments)
# Example:
#   json='{"user":{"name":"alice"}}'
#   jsonvalue "$json" "user.name"  # outputs: alice
jsonvalue() {
  if [[ -z "$1" || -z "$2" ]]; then
    echo "Usage: jsonvalue <jsondata> <key>" >&2
    return 1
  fi
  echo "$1" | jq -r --arg KEY "$2" '. as $DATA|($KEY|split(".")|reduce .[] as $subkey ($DATA; .[$subkey])) // empty'
}

# ============================================================================
# SSL/TLS Utilities
# ============================================================================

# Display SSL/TLS certificate details from HTTPS URL
# Connects to server and displays certificate information in human-readable format
#
# Usage: getcert <url>
# Arguments:
#   $1 - URL or hostname (https:// prefix optional)
# Returns: 0 on success, non-zero on connection error
# Example:
#   getcert github.com
#   getcert https://api.example.com
getcert() {
  local url="${1#https://}"  # Strip https:// prefix if present
  printf '\n' | openssl s_client -connect "$url":443 -showcerts | openssl x509 -noout -text
}

# ============================================================================
# Date Utilities
# ============================================================================

# Get Unix timestamp N hours ago (macOS only)
ago() {
  local hours="${1:-24}"
  date -j -f "%a %b %d %T %Z %Y" "$(date -v -"${hours}"H)" "+%s"
}

# ============================================================================
# Local Extensions
# ============================================================================

# Load user-specific aliases from ~/.aliases/
if [[ -d ~/.aliases ]]; then
  for f in ~/.aliases/*; do
    [[ -f "$f" ]] && source "$f"
  done
fi


