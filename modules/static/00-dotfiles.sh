#!/usr/bin/env bash
# Module: dotfiles (core framework)
# Description: Core dotfiles utilities and framework functions
# Dependencies: none

# ============================================================================
# Hash-Based Idempotency Utility
# ============================================================================

# Run command only if file hash has changed since last run
# Usage: run_if_changed "name" "/path/to/file" "command to run"
run_if_changed() {
  local name="$1"
  local file="$2"
  local command="$3"

  local state_dir="${HOME}/.dot/state"
  local hash_file="${state_dir}/${name}.hash"

  # Ensure state directory exists
  mkdir -p "$state_dir"

  # Calculate current hash
  local current_hash
  current_hash=$(shasum "$file" 2>/dev/null | cut -d' ' -f1)

  # Skip if file doesn't exist
  if [[ -z "$current_hash" ]]; then
    debug "run_if_changed: file not found: $file"
    return 1
  fi

  # Check if hash changed
  if [[ -f "$hash_file" ]]; then
    local stored_hash
    stored_hash=$(cat "$hash_file")
    if [[ "$current_hash" == "$stored_hash" ]]; then
      debug "run_if_changed: no changes detected for $name"
      return 0  # No change, skip
    fi
  fi

  # Hash changed or first run - execute command
  debug "run_if_changed: executing $name (hash changed)"
  if eval "$command"; then
    echo "$current_hash" > "$hash_file"
    return 0
  else
    errcho "run_if_changed: command failed for $name"
    return 1
  fi
}

# ============================================================================
# Git Status Check (Opt-In)
# ============================================================================

# Only check git status if explicitly enabled
# User can enable by setting: export DOTFILES_CHECK_GIT=true
if [[ "${DOTFILES_CHECK_GIT:-false}" == "true" ]]; then
  DOTFILES_GIT_DIFF="$(git -C "${DOTFILES_DIR}" status --short)"
  if [[ -n "$DOTFILES_GIT_DIFF" ]]; then
    errcho "Changes detected in your dotfiles directory."
    errcho "Please review and git commit these changes:"
    echo "$DOTFILES_GIT_DIFF"
  fi
fi
