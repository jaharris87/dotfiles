" Use pathogen to incorporate ~/.vim/bundle packages into runtime path
execute pathogen#infect()

" vim-plug managed plugins
"call plug#begin()
"Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
"Plug 'menisadi/kanagawa.vim', { 'as': 'kanagawa' }
"call plug#end()

" Not sure what this one is for
set nocompatible

" This is actually a custom-version of zenburn
colorscheme zenburn

" The above colors scheme does not support true colors
set notermguicolors

" Turn on syntax highlighting
if has("syntax")
    syntax on
endif

" Remove swaps and backups from working directory
set backupdir=~/.vim/backups
set directory=~/.vim/swaps
if exists("&undodir")
    set undodir=~/.vim/undo
    set undofile
endif

" Enable filetype detection, plugins, and indent
filetype plugin indent on

" Use 's' for the <leader> key
let mapleader = "s"

" Quickly open a vertical split of my VIMRC and source my VIMRC
nnoremap <silent> <leader>ev :vs $MYVIMRC<CR>
nnoremap <silent> <leader>sv :so $MYVIMRC<CR>

" use leader to interact with the system clipboard
nnoremap <Leader>p "*]p
nnoremap <Leader>P "*]P

nnoremap <Leader>y :y*<cr>
nnoremap <Leader>c ^"*c$
nnoremap <Leader>d ^"*d$

vnoremap <Leader>y "*y
vnoremap <Leader>c "*c
vnoremap <Leader>d "*d

" place whole file on the system clipboard (and return cursor to where it was)
" nmap <Leader>a maggVG"*y`a
nnoremap <Leader>a :%y*<cr>

" Create new 'X' operator, which deletes like 'd', but sends to black-hole
" registry _ instead of default---i.e. delete without overwriting registry
nmap X "_d
nmap XX "_dd
vmap X "_d
vmap x "_d

" have x (removes single character) not go into the default registry
nnoremap x "_x

" Don't remember what this is for
set nomodeline

" Let backspace delete most things
set backspace=indent,eol,start

" Don't move cursor to the start of the line for most navigation
set nostartofline

" Line numbers
"set relativenumber
set number

" Show line and column number in bottom right
set ruler

" For editing binary files?
set binary

" No end-of-line at the end of a file when writing
set noeol

" Sets sizes of several buffers when switcing between files
set viminfo='100,<1000,s100,:10000,h,n~/.vim/cache/.viminfo
"set viminfo=%,<800,'100,/50,:100,h,f0,n~/.vim/cache/.viminfo
"           | |    |    |   |    | |  + viminfo file path
"           | |    |    |   |    | + file marks 0-9,A-Z 0=NOT stored
"           | |    |    |   |    + disable 'hlsearch' loading viminfo
"           | |    |    |   + command-line history saved
"           | |    |    + search history saved
"           | |    + files marks saved
"           | + lines saved each register (old name for <, vi6.2)
"           + save/restore buffer list

" Replace tabs with spaces
set expandtab

" Try to get the indentation right
set smarttab

" Have the indent commands re-highlight the last visual selection to make
" multiple indentations easier
vnoremap > >gv
vnoremap < <gv

" ignore case unless you uppercase a letter, search as you type
set ignorecase
set smartcase
"set incsearch

" Highlight previous search pattern
set hlsearch

" ./ to clear highlighted search instead of /asdfasdf
nnoremap <silent> ./ :nohlsearch<CR>

" Default spaces per indent
set shiftwidth=2

" Add some extra lines to pad while scrolling
set scrolloff=5

" Don't wrap lines
"set nowrap

" map control + l to commentary toggle comment for one line or visual
" selection
nmap <C-l> gcc
vmap <C-l> gcgv
imap <C-l> <ESC>gcc

" Configure vim-smooth-scroll
"noremap <silent> <c-u> :call smooth_scroll#up(&scroll, 10, 2)<CR>
"noremap <silent> <c-d> :call smooth_scroll#down(&scroll, 10, 2)<CR>
"noremap <silent> <c-b> :call smooth_scroll#up(&scroll*2, 10, 4)<CR>
"noremap <silent> <c-f> :call smooth_scroll#down(&scroll*2, 10, 4)<CR>

" Don't remember what this was for
if has("autocmd")
    autocmd BufReadPost *
        \ if line("'\"") > 0 && line("'\"") <= line("$") |
        \  exe "normal g`\"" |
        \ endif
    filetype on
endif

" Let's vim know that Do/EndDo loops are structured and can be indented
let fortran_do_enddo=1
"au! BufRead,BufNewFile *.f90 let b:fortran_do_enddo=1

" Filetype-specific indents
au! BufRead,BufNewFile *.f90 set shiftwidth=2
"au! BufRead,BufNewFile *.f   set shiftwidth=3
"au! BufRead,BufNewFile *.xml set shiftwidth=2
au! BufRead,BufNewFile *.py  set shiftwidth=4

" Change some syntax highlightning
au! BufRead,BufNewFile *.d   hi clear Label Error

" Interpret these as fortran syntax
au! BufRead,BufNewFile controls_* set filetype=fortran

" Use tabs instead of spaces for python
"au! BufRead,BufNewFile *.py set noexpandtab

" Makefile headers
au! BufRead,BufNewFile [mM]akefile.h* set filetype=make

" Don't use fixed-line width syntax or pattern matching... ever
let b:fortran_fixed_source = 0
nmap <S-F> :set syntax=fortran<CR>:let b:fortran_fixed_source=!b:fortran_fixed_source<CR>:set syntax=text<CR>:set syntax=fortran<CR>

" Use backtick for escape
":imap ` <Esc>

"let g:DiffUnit='Char'
"let g:DiffPairVisible=2

" Default to not read-only in vimdiff
"set noro

" ignore these files when completing names and in Ex
set wildignore=.svn,CVS,.git,*.o,*.a,*.class,*.mo,*.la,*.so,*.obj,*.swp,*.jpg,*.png,*.xpm,*.gif,*.pdf,*.bak,*.beam
" set of file name suffixes that will be given a lower priority when it comes to matching wildcards
set suffixes+=.old,.bak,.backup,.tmp