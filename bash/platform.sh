#!/usr/bin/env bash
# Module: platform
# Description: Platform detection utilities
# Dependencies: none

# Note: is_macos() and is_linux() are defined in modules/static/10-utils.sh

# Check if running on Apple Silicon (M1/M2/M3)
is_apple_silicon() {
    [[ "$(uname -m)" == "arm64" ]]
}

# Check if running on Intel/AMD64
is_x86_64() {
    [[ "$(uname -m)" == "x86_64" ]]
}
