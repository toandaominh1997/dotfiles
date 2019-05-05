set nocompatible
 
filetype off
 
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'majutsushi/tagbar'
Plugin 'dracula/vim'
 
call vundle#end()
filetype plugin indent on
 
syntax on
 
color dracula