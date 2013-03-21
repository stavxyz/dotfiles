"PEP standards vimrc
"so /Users/samu1044/.vim/vimrcs/.pyPEPvimrc

"set syntax for sphinx (restructured text) when extension = .rst
syntax on
filetype on
au BufNewFile,BufRead *.rst set filetype=rst

" This shows what you are typing as a command.  I love this!
set showcmd

" Who doesn't like autoindent?
"set autoindent

" Spaces are better than a tab character
set expandtab
set smarttab

" Who wants an 8 character tab?  Not me!
set shiftwidth=4
set softtabstop=4


set number	"display line numbers on the left

" Use case insensitive search, except when using capital letters
set ignorecase
set smartcase

" Instead of failing a command because of unsaved changes, instead raise a
" dialogue asking if you wish to save changed files.
set confirm

" Enable use of the mouse for all modes
set mouse=a

" Set the command window height to 2 lines, to avoid many cases of having to
" 'press <Enter> to continue'
set cmdheight=2

set ls=2	"always show status line (filename)

colorscheme wombat256mod

set statusline=%t       "tail of the filename
set statusline+=%=      "left/right separator
set statusline+=%c,     "cursor column
set statusline+=%l/%L   "cursor line/total lines
set statusline+=\ %P    "percent through file
