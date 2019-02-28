dotfiles
========

### requirements:

[homebrew](https://brew.sh/) (if mac) 
[vim-plug](https://github.com/junegunn/vim-plug)  
python & pip  
[pyenv](https://github.com/pyenv/pyenv)


```bash
# vim-plug for regular vim
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# vim-plug for neovim
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    
# pyenv
curl -L https://raw.githubusercontent.com/pyenv/pyenv-installer/master/bin/pyenv-installer | bash
pyenv update

# pyenv-virtualenv
git clone https://github.com/pyenv/pyenv-virtualenvwrapper.git $(pyenv root)/plugins/pyenv-virtualenvwrapper \
  && cd $(pyenv root)/plugins/pyenv-virtualenvwrapper && git tag --list && git checkout v20140609 && cd 

```

### setup:

```
pip install -U -r requirements.txt
./bin/dotfiles.py --debug unlink
./bin/dotfiles.py --debug link
```
