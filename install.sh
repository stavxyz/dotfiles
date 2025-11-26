#!/usr/bin/env bash
#
# Dotfiles Installation Script
#
# This script installs prerequisites for the dotfiles system.
# Run: ./install.sh
#
# Prerequisites installed:
# - vim-plug (Vim plugin manager)
# - pyenv (Python version manager)
# - pyenv-virtualenvwrapper (Python virtual environment tools)
#
# After running, execute: ./bin/dotfiles.py link

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

echo "Installing vim-plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# ============================================================================
# Python Environment Manager (pyenv)
# ============================================================================

echo "Installing pyenv..."
curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash

echo "Updating pyenv..."
pyenv update

# Setup pyenv for this session
export PATH="${HOME}/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# ============================================================================
# Python Virtual Environment Tools
# ============================================================================

echo "Installing pyenv-virtualenvwrapper..."
git clone https://github.com/pyenv/pyenv-virtualenvwrapper.git \
  "$(pyenv root)/plugins/pyenv-virtualenvwrapper"

echo ""
echo "✅ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (to load pyenv)"
echo "  2. Run: ./bin/dotfiles.py link"
echo ""
