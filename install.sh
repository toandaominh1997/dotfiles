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

# vim -E +VimEnter +PluginInstall +qall
# if [ -d ~/.vim/bundle/youcompleteme ] ; then
# echo 'Install youcompleteme'
# cd ~/.vim/bundle/youcompleteme
# python3 install.py --all
# fi

echo "Installed Vim configuration successfully ^~^"

if ! hash zsh; then
sudo apt-get install -y zsh
fi

if [ -d ~/.oh-my-zsh ] ; then
echo 'Install Oh my zsh'
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

cd
if [ ! -d ~/.dotfiles/fonts ] ; then
git clone https://github.com/powerline/fonts.git ~/.dotfiles/fonts
sh ~/.dotfiles/fonts/install.sh
fi


cd
if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ] ; then
echo 'kaka'
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

cd
if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ] ; then
echo 'kaka'
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

echo '
source ~/.dotfiles/zshrcs/basic.zsh
'> ~/.zshrc
