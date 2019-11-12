"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" => General
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Sets how many lines of history VIM has to remember
set history=500

" Enable filetype plugins
filetype plugin on
filetype indent on

" Set to auto read when a file is changed from the outside
set autoread

" With a map leader it's possible to do extra key combinations
" like <leader>w saves the current file
let mapleader = ","

" Fast saving
nmap <leader>w :w!<cr>

" :W sudo saves the file 
" (useful for handling the permission-denied error)
command W w !sudo tee % > /dev/null


" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf-8

" 1 tab == 4 spaces
set shiftwidth=4
set tabstop=4


if !has("gui_running")
    set t_Co=256
    set term=screen-256color
endif
set mouse=a
set clipboard=unnamed
set number

:vmap <C-C> "+y
nnoremap <c-z> :u<CR>      " Avoid using this**
inoremap <c-z> <c-o>:u<CR>
nnoremap <c-t> :tabnew<CR>
inoremap <c-t> <c-o>:tabnew<CR>

let &t_SI = "\<esc>[5 q"  " blinking I-beam in insert mode
let &t_SR = "\<esc>[5 q"  " blinking underline in replace mode
let &t_EI = "\<esc>[5 q"  " default cursor (usually blinking block) otherwise

let NERDTreeMapOpenInTab='\r'