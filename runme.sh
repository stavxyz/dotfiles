#!/bin/bash

VUNDLE_VERSION='v0.10.2'

# make all necessary dirs first
mkdir -v -p ~/.autocomplete

# fetch autocomplete scripts
./bash/fetch_autocompleters.sh

#
# links
#

# tmux
echo -e "\n *** Creating link ~/.tmux.conf ***"
ln -v -nf -s ~/dotfiles/tmux/tmux.conf ~/.tmux.conf

# git
echo -e "\n *** Creating link ~/.gitconfig ***"
ln -v -nf -s ~/dotfiles/git/gitconfig ~/.gitconfig
echo -e "\n *** Creating link ~/.gitignore_global ***"
ln -v -nf -s ~/dotfiles/git/gitignore_global ~/.gitignore_global

# python
echo -e "\n *** Creating link ~/.pystartup ***"
ln -v -nf -s ~/dotfiles/python/pystartup ~/.pystartup
echo -e "\n *** Creating link ~/.pystartup/.pythonrc ***"
ln -v -nf -s ~/dotfiles/python/pystartup/pythonrc ~/.pystartup/.pythonrc
echo -e "\n *** Creating link ~/.pdbrc.py ***"
ln -v -nf -s ~/dotfiles/python/pdbrc.py ~/.pdbrc.py

# profile
#for f in ~/dotfiles/bash/.bash*; do
echo -e "\n *** Linking bash scripts. ***"
ln -v -nf -s ~/dotfiles/bash/bash_profile ~/.bash_profile
ln -v -nf -s ~/dotfiles/bash/bashrc ~/.bashrc
ln -v -nf -s ~/dotfiles/bash/bash_aliases ~/.bash_aliases
ln -v -nf -s ~/dotfiles/bash/bash_gpg ~/.bash_gpg

# vim & vundle
VUNDLEPATH=~/.vim/bundle
echo -e "\n *** Creating link ~/.vim ***"
ln -v -nf -s ~/dotfiles/vim/vim ~/.vim
echo -e "\n *** Cloning git repo: gmarik/Vundle.vim ***"
git clone --progress --verbose https://github.com/gmarik/Vundle.vim.git \
    ${VUNDLEPATH}/Vundle.vim.temp
rm -rf ${VUNDLEPATH}/Vundle.vim
mv -v -f ${VUNDLEPATH}/Vundle.vim.temp ${VUNDLEPATH}/Vundle.vim
echo -e "\n *** Fetching Vundle versions... ***"
git --work-tree ${VUNDLEPATH}/Vundle.vim --git-dir ${VUNDLEPATH}/Vundle.vim/.git fetch --force --update-head-ok --verbose --all --tags
echo -e "\n *** Checking out Vundle $VUNDLE_VERSION ***"
git --work-tree ${VUNDLEPATH}/Vundle.vim --git-dir ${VUNDLEPATH}/Vundle.vim/.git reset --hard $VUNDLE_VERSION


echo -e "\n *** Creating link ~/.vimrc ***"
ln -v -nf -s ~/dotfiles/vim/vimrc ~/.vimrc

# install Vundle plugins
echo -e "\n *** Installing Vundle plugins and restarting session... ***"
vim +PluginInstall +qall
exec bash --login
