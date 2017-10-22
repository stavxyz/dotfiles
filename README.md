dotfiles
========

### requirements:

[homebrew](https://brew.sh/)  
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
```

### setup:

```
pip install -U -r requirements.txt
./bin/dotfiles.py --debug unlink
./bin/dotfiles.py --debug link
```
