" jsx and es6

let g:jsx_ext_required = 0

set nocompatible
filetype plugin on

set synmaxcol=10000

" map F9 to toggle line numbers
nnoremap <L> :<C-U>exe "set invnumber"<CR>
vnoremap <L> :<C-U>exe "set invnumber"<CR>

"easier split navigations
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" map :Q! to quit
command! -bar -bang Q quit<bang>

" highlight .ipy files
au BufRead,BufNewFile *.ipy set filetype=python
" syntax highlighting - try harder
autocmd BufEnter * :syntax sync fromstart
let c_minlines=1000
syntax sync minlines=1000


"
" change indent depending on filetype
" -----------------------------------

autocmd FileType javascript setlocal shiftwidth=2 tabstop=2
autocmd FileType coffeescript setlocal shiftwidth=2 tabstop=2
autocmd FileType xhtml setlocal shiftwidth=2 tabstop=2
autocmd FileType html setlocal shiftwidth=2 tabstop=2
autocmd FileType htm setlocal shiftwidth=2 tabstop=2
autocmd FileType php setlocal shiftwidth=2 tabstop=2
autocmd FileType xml setlocal shiftwidth=2 tabstop=2
autocmd FileType ipython setlocal shiftwidth=4 tabstop=4
autocmd FileType ipy setlocal shiftwidth=4 tabstop=4
autocmd FileType python setlocal shiftwidth=4 tabstop=4
autocmd FileType c setlocal cindent
autocmd FileType h setlocal cindent

"dont ask me about changes when I switch buffers
"automatically set the file with changes as 'hidden'
set hidden

"highlight search terms
set hlsearch

"show search matches as you type
set incsearch

" This shows what you are typing as a command.  I love this!
set showcmd

" trying to get yy, D and P to work with system clipboard
set clipboard=unnamed

" Who doesn't like autoindent? me?
"set autoindent

" Spaces are better than a tab character
set expandtab
set smarttab

" display line numbers
set number

" Use case insensitive search, except when using capital letters
set ignorecase
set smartcase

" Instead of failing a command because of unsaved changes, instead raise a
" dialogue asking if you wish to save changed files.
set confirm

" Enable use of the mouse for all modes
set mouse=n

" make backspace work like most other apps
set backspace=2

" Set the command window height to 2 lines, to avoid many cases of having to
" 'press <Enter> to continue'
set cmdheight=2

"always show status line (filename)
"set ls=2

" Add the cool little dots for spaces while in Insert mode
set list
set listchars=tab:>.,trail:⋮,extends:#,nbsp:.

" show line/column
set ruler

" golang (fatih/vim-go)
let g:go_fmt_command = "goimports"
let g:go_metalinter_autosave = 1

" single quotes over double quotes
" Prettier default: false
let g:prettier#config#single_quote = 'true'

" ************ Status Line *************

"set statusline=%t       "tail of the filename
"set statusline+=%=      "left/right separator
"set statusline+=%c,     "cursor column
"set statusline+=%l/%L   "cursor line/total lines
"set statusline+=\ %P    "percent through file

" ************************************

" statusline / airline conf
if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif
let g:airline_symbols.space = "\ua0"

let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
let g:airline_section_x = '%{PencilMode()}'

let g:airline_theme='base16'

augroup pencil
  autocmd!
  autocmd FileType markdown,mkd call pencil#init()
  autocmd FileType text         call pencil#init({'wrap': 'soft'})
augroup END

"""""""""""""""""""""""""""""""""""""""""""


"""""""""" match iterm / colors

let iterm_profile = $ITERM_PROFILE
if iterm_profile == "dark"
    set background=dark
else
    set background=light
endif

if filereadable(expand("~/.vimrc_background"))
  let base16colorspace=256
  source ~/.vimrc_background
endif

"""""""""""" end iterm /colors

if $TMUX == ''
    set clipboard+=unnamed
else
    set clipboard=unnamed
endif
