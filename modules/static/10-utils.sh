#!/usr/bin/env bash
# Module: utils
# Description: Utility functions for dotfiles
# Dependencies: none

# Check if a command exists in PATH
# Usage: command_exists <command>
# Arguments:
#   $1 - Command name to check
# Returns: 0 if command exists, 1 otherwise
command_exists() {
    command -v "$1" &>/dev/null
}

# Source a file only if it exists and is readable
# Usage: safe_source <file_path>
# Arguments:
#   $1 - Path to file to source
# Returns: 0 if sourced successfully or file not readable, non-zero on source error
safe_source() {
    [[ -r "$1" ]] && source "$1"
}

# Source a module file only if its associated command exists
# Usage: source_if_command_exists <command> <file_path>
# Arguments:
#   $1 - Command name to check
#   $2 - Path to file to source if command exists
# Returns: 0 if command exists and file sourced, 1 if command doesn't exist
source_if_command_exists() {
    local cmd="$1"
    local file="$2"
    command_exists "$cmd" && safe_source "$file"
}

# Check if running on macOS
# Usage: is_macos
# Returns: 0 if running on macOS, 1 otherwise
is_macos() {
    [[ "$OSTYPE" == darwin* ]]
}

# Check if running on Linux
# Usage: is_linux
# Returns: 0 if running on Linux, 1 otherwise
is_linux() {
    [[ "$OSTYPE" == linux* ]]
}

# Cache architecture detection (uname -m doesn't change during shell session)
# Only compute if not already set (avoids redundant calls in nested/child shells)
if [[ -z "${DOTFILES_ARCH+x}" ]]; then
    DOTFILES_ARCH="$(uname -m)"
fi
export DOTFILES_ARCH

# Check if running on Apple Silicon (M1/M2/M3)
# Usage: is_apple_silicon
# Returns: 0 if running on Apple Silicon, 1 otherwise
is_apple_silicon() {
    [[ "$DOTFILES_ARCH" == "arm64" ]]
}

# Check if running on Intel/AMD64
# Usage: is_x86_64
# Returns: 0 if running on Intel/AMD64, 1 otherwise
is_x86_64() {
    [[ "$DOTFILES_ARCH" == "x86_64" ]]
}
