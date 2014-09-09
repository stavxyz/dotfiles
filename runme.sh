#!/bin/bash

# make all necessary dirs first
mkdir -v -p ~/.autocomplete

# fetch autocomplete scripts
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash \
  -o ~/.autocomplete/git-completion.bash

curl http://www.selenic.com/hg/raw-file/tip/contrib/bash_completion \
  -o ~/.autocomplete/hg-completion.bash


# links

# git
ln -v -hf -s ~/dotfiles/git/.gitconfig ~/.gitconfig

# python
ln -v -hf -s ~/dotfiles/.pystartup ~/.pystartup

# profile
#for f in ~/dotfiles/bashrc/.bash*; do
ln -v -hf -s ~/dotfiles/bashrc/.bash* ~

# vim
ln -v -hf -s ~/dotfiles/.vim ~/.vim
git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim

# install Vundle plugins
vim +PluginInstall +qall

ln -v -hf -s ~/dotfiles/.vimrc ~/.vimrc

source ~/.bash_profile
