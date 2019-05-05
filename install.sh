set -e

if [ -d ~/.dotfiles ] ; then
cd ~/.dotfiles
git pull origin master
fi

echo '
set runtimepath+=~/.dotfiles
source ~/.dotfiles/vimrcs/plugin.vim
source ~/.dotfiles/vimrcs/basic.vim
'> ~/.vimrc
if [ -d ~/.vim/bundle ] ; then
echo 'vim bundle exist'
else #if needed #also: elif [new condition] 
echo 'clone vim bundle'
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi

# vim +VimEnter +PluginInstall +qall
if [ -d ~/.vim/bundle/youcompleteme ] ; then
echo 'Install youcompleteme'
cd ~/.vim/bundle/youcompleteme
python3 install.py --all
fi
echo "Installed Vim configuration successfully ^~^"