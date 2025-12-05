#!/usr/bin/env bash
#
# Dotfiles Installation Script
#
# Usage: ./install.sh
#
# This script installs prerequisites for the dotfiles system.
# It is idempotent and can be run multiple times safely.
#
# Prerequisites installed:
# - vim-plug (Vim plugin manager)
# - pyenv (Python version manager via pyenv-installer)
# - pyenv-virtualenvwrapper (Python virtual environment tools)
#
# Note: This script only installs missing components. It does not update
# existing installations. Use the appropriate update method for each tool:
#   - vim-plug: Run :PlugUpdate in Vim
#   - pyenv: Run `pyenv update` (if installed via pyenv-installer) or `brew upgrade pyenv`
#   - pyenv-virtualenvwrapper: `cd $(pyenv root)/plugins/pyenv-virtualenvwrapper && git pull`
#
# After running, execute: ./dot.py link

set -euo pipefail

echo "Installing dotfiles prerequisites..."

# ============================================================================
# Dotfiles Framework Directories
# ============================================================================

echo "Creating dotfiles framework directories..."
mkdir -p "${HOME}/.dot/state"
echo "✓ Created ~/.dot/state/"

# ============================================================================
# Vim Plugin Manager
# ============================================================================

if [[ -f ~/.vim/autoload/plug.vim ]]; then
    echo "✓ vim-plug already installed"
else
    echo "Installing vim-plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# ============================================================================
# Python Environment Manager (pyenv)
# ============================================================================

# Check if pyenv is already working
if command -v pyenv &>/dev/null && [[ -d ~/.pyenv ]]; then
    echo "✓ pyenv already installed"
    export PATH="${HOME}/.pyenv/bin:$PATH"
    eval "$(pyenv init -)" || { echo "Error: pyenv init failed."; exit 1; }
else
    # pyenv not found or incomplete - install via pyenv-installer
    echo "Installing pyenv via pyenv-installer..."
    curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash

    export PATH="${HOME}/.pyenv/bin:$PATH"
    if command -v pyenv &>/dev/null; then
        eval "$(pyenv init -)" || { echo "Error: pyenv init failed."; exit 1; }
    else
        echo "Error: pyenv installation failed"
        exit 1
    fi
fi

# ============================================================================
# Python Virtual Environment Tools
# ============================================================================

VENVWRAPPER_DIR="$(pyenv root)/plugins/pyenv-virtualenvwrapper"
if [[ -d "$VENVWRAPPER_DIR" ]]; then
    echo "✓ pyenv-virtualenvwrapper already installed"
else
    echo "Installing pyenv-virtualenvwrapper..."
    git clone https://github.com/pyenv/pyenv-virtualenvwrapper.git "$VENVWRAPPER_DIR"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (to load pyenv)"
echo "  2. Run: ./dot.py link"
echo ""
