#!/usr/bin/env bash
# Module: path
# Description: PATH management utilities
# Dependencies: none

# Add directory to PATH only if it exists and isn't already in PATH
# Usage: add_to_path "/some/directory"
add_to_path() {
    local dir="$1"

    # Check if directory exists
    [[ ! -d "$dir" ]] && return 1

    # Check if already in PATH
    # shellcheck disable=SC2086  # Safe: pattern matching in [[ ]]
    if [[ ":$PATH:" == *":$dir:"* ]]; then
        return 0  # Already in PATH
    fi

    # Add to PATH
    export PATH="$dir:$PATH"
}

# Add directory to end of PATH (lower priority)
append_to_path() {
    local dir="$1"

    # Check if directory exists
    [[ ! -d "$dir" ]] && return 1

    # Check if already in PATH
    # shellcheck disable=SC2086  # Safe: pattern matching in [[ ]]
    if [[ ":$PATH:" == *":$dir:"* ]]; then
        return 0  # Already in PATH
    fi

    # Append to PATH
    export PATH="$PATH:$dir"
}
