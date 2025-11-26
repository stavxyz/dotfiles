#!/usr/bin/env bash
#
# Dotfiles Installation Script
#
# This script installs prerequisites and symlinks configuration files.
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

# Install vim-plug for Vim
echo "Installing vim-plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim


# pyenv
curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash
pyenv update

export PATH="/root/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"


git clone https://github.com/pyenv/pyenv-virtualenvwrapper.git \
  $(pyenv root)/plugins/pyenv-virtualenvwrapper && \
  cd $(pyenv root)/plugins/pyenv-virtualenvwrapper && \
  git tag --list && git checkout v20140609
