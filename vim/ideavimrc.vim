let mapleader = " "

" Fast saving
nmap <leader>w :w!<cr>

" Always show current position
set ruler

" Height of the command bar
set cmdheight=1

" A buffer becomes hidden when it is abandoned
set hid

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Highlight search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw while executing macros (good performance config)
set lazyredraw

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch

" How many tenths of a second to blink when matching brackets
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500


" Mapping 
" map <leader>fg <Action>(GotoFile)


set ideajoin
set surround
set easymotion

" Window Navigation
nnoremap <c-\> :action SplitVertically<CR>
nnoremap <c--> :action SplitHorizontally<CR>
nnoremap <c-=> :action Unsplit<CR>
nnoremap <c-m> :action MoveEditorToOppositeTabGroup<CR>
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <TAB> :action PreviousTab<CR>
nnoremap <s-TAB> :action NextTab<CR>

" Comment code
set commentary
vnoremap gc :action CommentByLineComment<CR>
" nnoremap <c-r> :action RecentFiles<CR>


set NERDTree
let g:NERDTreeMapActivateNode='l'
let g:NERDTreeMapJumpParent='h'

" Fast saving
nmap <leader>w :w!<cr>

" Quick scope
set quickscope

" Telescope
nmap <leader>ff :action FindInPath<CR>

