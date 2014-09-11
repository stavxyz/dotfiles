#!/bin/bash

VUNDLE_VERSION='v0.10.2'

# make all necessary dirs first
mkdir -v -p ~/.autocomplete

# fetch autocomplete scripts
echo "Fetching git autocomplete script."
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash \
  -o ~/.autocomplete/git-completion.bash

echo "Fetching mercurial autocomplete script."
curl http://www.selenic.com/hg/raw-file/tip/contrib/bash_completion \
  -o ~/.autocomplete/hg-completion.bash

echo "Fetching tmux autocomplete script."
curl https://raw.githubusercontent.com/ThomasAdam/tmux/master/examples/bash_completion_tmux.sh \
  -o ~/.autocomplete/tmux-completion.bash


# links

# tmux
echo "Creating link ~/.tmux.conf"
ln -v -hf -s ~/dotfiles/tmux/tmux.conf ~/.tmux.conf

# git
echo "Creating link ~/.gitconfig"
ln -v -hf -s ~/dotfiles/git/.gitconfig ~/.gitconfig

# python
echo "Creating link ~/.pystartup"
ln -v -hf -s ~/dotfiles/.pystartup ~/.pystartup

# profile
#for f in ~/dotfiles/bashrc/.bash*; do
echo "Linking autocomplete scripts."
ln -v -hf -s ~/dotfiles/bashrc/.bash* ~

# vim & vundle
VUNDLEPATH=~/.vim/bundle
echo "Creating link ~/.vim"
ln -v -hf -s ~/dotfiles/.vim ~/.vim
echo "Cloning gmarik/Vundle.vim"
git clone https://github.com/gmarik/Vundle.vim.git ${VUNDLEPATH}/Vundle.vim.temp
rm -rf ${VUNDLEPATH}/Vundle.vim
mv -v -f ${VUNDLEPATH}/Vundle.vim.temp ${VUNDLEPATH}/Vundle.vim
echo "Fetching Vundle versions..."
git --work-tree ${VUNDLEPATH}/Vundle.vim --git-dir ${VUNDLEPATH}/Vundle.vim/.git fetch --all
echo "Checking out Vundle $VUNDLE_VERSION"
git --work-tree ${VUNDLEPATH}/Vundle.vim --git-dir ${VUNDLEPATH}/Vundle.vim/.git reset --hard $VUNDLE_VERSION

ln -v -hf -s ~/dotfiles/.vimrc ~/.vimrc

# install Vundle plugins
vim +PluginInstall +qall

exec bash -l
