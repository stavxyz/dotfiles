#!/usr/bin/env bash
# Module: version
# Description: Version information for dotfiles
# Dependencies: git

# Get dotfiles version (git commit SHA)
dotfiles_version() {
    if [[ -d "${DOTFILES_DIR}/.git" ]]; then
        git -C "${DOTFILES_DIR}" rev-parse --short HEAD 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

# Display version with additional info
dotfiles_info() {
    echo "Dotfiles v$(dotfiles_version)"
    echo "Location: ${DOTFILES_DIR}"
    echo "Shell: ${SHELL} (${BASH_VERSION})"
    echo "Platform: $(uname -s) $(uname -m)"
}
