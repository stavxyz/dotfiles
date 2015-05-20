#!/bin/bash

VUNDLE_VERSION='v0.10.2'

# make all necessary dirs first
mkdir -v -p ~/.autocomplete

# fetch autocomplete scripts
echo -e "\n *** Fetching git autocomplete script. ***"
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash \
  -o ~/.autocomplete/git-completion.bash

echo -e "\n *** Fetching mercurial autocomplete script. ***"
curl http://www.selenic.com/hg/raw-file/tip/contrib/bash_completion \
  -o ~/.autocomplete/hg-completion.bash

echo -e "\n *** Fetching tmux autocomplete script. ***"
curl https://raw.githubusercontent.com/ThomasAdam/tmux/master/examples/bash_completion_tmux.sh \
  -o ~/.autocomplete/tmux-completion.bash

#
# links
#

# tmux
echo -e "\n *** Creating link ~/.tmux.conf ***"
ln -v -nf -s ~/dotfiles/tmux/tmux.conf ~/.tmux.conf

# git
echo -e "\n *** Creating link ~/.gitconfig ***"
ln -v -nf -s ~/dotfiles/git/gitconfig ~/.gitconfig

# python
echo -e "\n *** Creating link ~/.pystartup ***"
ln -v -nf -s ~/dotfiles/python/pystartup ~/.pystartup
echo -e "\n *** Creating link ~/.pystartup/.pythonrc ***"
ln -v -nf -s ~/dotfiles/python/pystartup/pythonrc ~/.pystartup/.pythonrc
echo -e "\n *** Creating link ~/.pdbrc.py ***"
ln -v -nf -s ~/dotfiles/python/pdbrc.py ~/.pdbrc.py

# profile
#for f in ~/dotfiles/bash/.bash*; do
echo -e "\n *** Linking autocomplete scripts. ***"
ln -v -nf -s ~/dotfiles/bash/bash_profile ~/.bash_profile
ln -v -nf -s ~/dotfiles/bash/bashrc ~/.bashrc
ln -v -nf -s ~/dotfiles/bash/bash_aliases ~/.bash_aliases

# vim & vundle
VUNDLEPATH=~/.vim/bundle
echo -e "\n *** Creating link ~/.vim ***"
ln -v -nf -s ~/dotfiles/.vim ~/.vim
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
ln -v -nf -s ~/dotfiles/.vimrc ~/.vimrc

# install Vundle plugins
echo -e "\n *** Installing Vundle plugins and restarting session... ***"
vim +PluginInstall +qall
exec bash --login
