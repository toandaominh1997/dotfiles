set nocompatible
 
filetype off
 
set rtp+=$HOME/.dotfiles/bundle/Vundle.vim
call vundle#begin('$HOME/.dotfiles/bundle')

Plugin 'VundleVim/Vundle.vim'
Plugin 'scrooloose/nerdtree' " file list

Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'

Plugin 'airblade/vim-gitgutter'

Plugin 'davidhalter/jedi-vim' " jedi for python

Plugin 'NLKNguyen/copy-cut-paste.vim'
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
map <C-o> :NERDTreeToggle<CR>
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

" All these mappings work only for python code:
let g:jedi#goto_command = "<leader>d"
let g:jedi#goto_assignments_command = "<leader>g"
let g:jedi#goto_definitions_command = ""
let g:jedi#documentation_command = "K"
let g:jedi#usages_command = "<leader>n"
let g:jedi#completions_command = "<C-Space>"
let g:jedi#rename_command = "<leader>r"
" Go to definition in new tab
nmap ,D :tab split<CR>:call jedi#goto()<CR>

" config deoplete 
let g:deoplete#enable_at_startup = 1

" config copy-cut-paste -----------------------------
let g:copy_cut_paste_no_mappings = 1
" Use your keymap
nmap QC <Plug>CCP_CopyLine
vmap QC <Plug>CCP_CopyText

nmap QX <Plug>CCP_CutLine
vmap QX <Plug>CCP_CutText

nmap QV <Plug>CCP_PasteText
