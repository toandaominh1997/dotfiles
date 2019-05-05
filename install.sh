set +e
set -u

if [ -d ~/.toandaominh1997/.dotfiles ] ; then
cd ~/.toandaominh1997/.dotfiles
git pull origin master
fi

echo '
set runtimepath+=~/.toandaominh1997/.dotfiles
source ~/.toandaominh1997/.dotfiles/vimrcs/plugin.vim
source ~/.toandaominh1997/.dotfiles/vimrcs/basic.vim
'> ~/.vimrc

if [ ! -d ~/.toandaominh1997/bundle ] ; then
git clone https://github.com/VundleVim/Vundle.vim.git ~/.toandaominh1997/bundle/Vundle.vim
fi

vim -E +PluginInstall +qall
if [ -d ~/.toandaominh1997/bundle/youcompleteme ] ; then
echo 'Install youcompleteme'
cd ~/.toandaominh1997/bundle/youcompleteme
python3 install.py --all
fi

echo "Installed Vim configuration successfully ^~^"

if ! hash zsh; then
sudo apt-get install -y zsh
fi
cd 
if [ ! -d ~/.toandaominh1997/.oh-my-zsh ] ; then
echo 'Install Oh my zsh'
# sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.toandaominh1997/.oh-my-zsh
fi

cd
if [ ! -d ~/.toandaominh1997/.dotfiles/fonts ] ; then
git clone https://github.com/powerline/fonts.git ~/.toandaominh1997/.dotfiles/fonts
sh ~/.toandaominh1997/.dotfiles/fonts/install.sh
fi


cd
if [ ! -d ~/.toandaominh1997/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ] ; then
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.toandaominh1997/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi

cd
if [ ! -d ~/~/.toandaominh1997/.oh-my-zsh/custom/plugins/zsh-autosuggestions ] ; then
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.toandaominh1997/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi

echo '
source ~/.dotfiles/zshrcs/basic.zsh
'> ~/.zshrc
cd
echo 'Complete!'