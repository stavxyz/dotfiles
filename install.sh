#!/usr/bin/env bash

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
