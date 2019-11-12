set nocompatible
 
filetype off
 
set rtp+=$HOME/.dotfiles/bundle/Vundle.vim
call vundle#begin('$HOME/.dotfiles/bundle')

Plugin 'VundleVim/Vundle.vim'
Plugin 'scrooloose/nerdtree'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'

Plugin 'airblade/vim-gitgutter'
Plugin 'dracula/vim', { 'name': 'dracula' }

Plugin 'davidhalter/jedi-vim'
Plugin 'ctrlpvim/ctrlp.vim'


" Plugin 'valloric/youcompleteme'

call vundle#end()
filetype plugin indent on
syntax on
 

" config nerdtree----------------------------------------------------------

" How can I open a NERDTree automatically when vim starts up if no files were specified?
" Stick this in your vimrc:

autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" Note: Now start vim with plain vim, not vim .

" How can I map a specific key or shortcut to open NERDTree?
" Stick this in your vimrc to open NERDTree with Ctrl+n (you can set whatever key you want):
map <C-n> :NERDTreeToggle<CR>
" How can I close vim if the only window left open is a NERDTree?
"Stick this in your vimrc:
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
" How can I change default arrows?
" Use these variables in your vimrc. Note that below are default arrow symbols
let g:NERDTreeDirArrowExpandable = '▸'
let g:NERDTreeDirArrowCollapsible = '▾'

" config vim airline --------------------------------------------------------------
" This is disabled by default; add the following to your vimrc to enable the extension:
let g:airline#extensions#tabline#enabled = 1

" Separators can be configured independently for the tabline, so here is how you can define "straight" tabs:

let g:airline#extensions#tabline#left_sep = ' '
let g:airline#extensions#tabline#left_alt_sep = '|'

let g:airline#extensions#tabline#formatter = 'default'

let g:airline_theme='badwolf'

" config jedi vim --------------------------------------
