set -e
cd ~/.dotfiles

echo '
set runtimepath+=~/.dotfiles
source ~/.dotfiles/vimrcs/plugin.vim
source ~/.dotfiles/vimrcs/basic.vim
'> ~/.vimrc
ls
rm -rf ~/.vim/bundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim -E +VimEnter +PluginInstall +qall

cd ~/.vim/bundle/YouCompleteMe
python3 install.py --all

echo "Installed Vim configuration successfully ^~^"
