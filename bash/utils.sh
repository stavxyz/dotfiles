#!/usr/bin/env bash
# Module: utils
# Description: Utility functions for dotfiles
# Dependencies: none

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Source file only if it exists and is readable
safe_source() {
    [[ -r "$1" ]] && source "$1"
}

# Source module only if command exists
source_if_command_exists() {
    local cmd="$1"
    local file="$2"
    command_exists "$cmd" && safe_source "$file"
}

# Check if running on macOS
is_macos() {
    [[ "$OSTYPE" == darwin* ]]
}

# Check if running on Linux
is_linux() {
    [[ "$OSTYPE" == linux* ]]
}
