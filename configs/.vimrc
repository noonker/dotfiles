set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" alternatively, pass a path where Vundle should install plugins
"call vundle#begin('~/some/path/here')

" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'

" Supertab is a vim plugin which allows you to use <Tab> for all your insert
" completion needs (:help ins-completion).
Plugin 'ervandew/supertab.git'
" Tag List plugin is a source code browser plugin for Vim
Plugin 'vim-scripts/taglist.vim'
" syntax checking plugin for Vim
Plugin 'vim-syntastic/syntastic'
" Filesystem Explorer
Plugin 'scrooloose/nerdtree'
" status/tableine for vim 
Plugin 'vim-airline/vim-airline'
" plugin on GitHub repo
Plugin 'tpope/vim-fugitive'
" Better JSON for VIM
Plugin 'elzr/vim-json'
" Rest Console for vim
Plugin 'diepm/vim-rest-console'

" All of your Plugins must be added before the following line
call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line

" Enable syntax highlighting
syntax on

" Specify the tags file
set tags+=~/ts/src/qa/trunk/pylib/tags

"set background=dark
"colorscheme solarized

set hidden

" Better command-line completion
set wildmenu

" Show partial commands in the last line of the screen
set showcmd

" Highlight searches (use <C-L> to temporarily turn off highlighting; see the
" mapping of <C-L> below)
set hlsearch

" Use case insensitive search, except when using capital letters
set ignorecase
set smartcase

" Allow backspacing over autoindent, line breaks and start of insert action
set backspace=indent,eol,start

" When opening a new line and no filetype-specific indenting is enabled, keep
" the same indent as the line you're currently on. Useful for READMEs, etc.
set autoindent

" Display the cursor position on the last line of the screen or in the status
" line of a window
set ruler

" Always display the status line, even if only one window is displayed
set laststatus=2

" Instead of failing a command because of unsaved changes, instead raise a
" dialogue asking if you wish to save changed files.
" set confirm

" Use visual bell instead of beeping when doing something wrong
set visualbell

" Enable use of the mouse for all modes
set mouse=a

" Set the command window height to 2 lines, to avoid many cases of having to
" "press <Enter> to continue"
set cmdheight=2

" Display line numbers on the left
set number

" Quickly time out on keycodes, but never time out on mappings
set notimeout ttimeout ttimeoutlen=200

" Use <F11> to toggle between 'paste' and 'nopaste'
set pastetoggle=<F11>


" Indentation settings for using 2 spaces instead of tabs.
" Do not change 'tabstop' from its default value of 8 with this setup.
set shiftwidth=4
set softtabstop=4
set expandtab
set colorcolumn=80
highlight colorcolumn ctermbg=red guibg=red

set spell spelllang=en_us
set nospell 
" Checks for changes to file even if it's not open
set autoread

" Shows matching brackets when highlighted
set showmatch

map \ :set invnumber<CR>
map = :tn <CR>
map <C-\> :set ft=rest<CR>
map <C-n> :tabe $PWD<CR>
map <C-e> :tabnext<CR>
"
"The following are LaTeX Files
"
"

" REQUIRED. This makes vim invoke Latex-Suite when you open a tex file.
filetype plugin on
"
" " IMPORTANT: win32 users will need to have 'shellslash' set so that latex
" " can be called correctly.
" set shellslash
"
"" IMPORTANT: grep will sometimes skip displaying the file name if you
" " search in a singe file. This will confuse Latex-Suite. Set your grep
" " program to always generate a file-name.
set grepprg=grep\ -nH\ $*
"
" " OPTIONAL: This enables automatic indentation as you type.
" filetype indent on
"
" " OPTIONAL: Starting with Vim 7, the filetype of empty .tex files defaults
" to
" " 'plaintex' instead of 'tex', which results in vim-latex not being loaded.
" " The following changes the default filetype back to 'tex':
" let g:tex_flavor='latex'

set clipboard=unnamedplus,unnamed,autoselect

nmap <F1> :set paste<CR>:r !upaste<CR>:set nopaste<CR>
imap <F1> <Esc>:set paste<CR>:r !upaste<CR>:set nopaste<CR>
nmap <F2> :.w !ucopy<CR><CR>
vmap <F2> :w !ucopy<CR><CR>
