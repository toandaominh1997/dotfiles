set +e
set -u

if ! is_app_installed vim; then
  printf "WARNING: \"git\" command is not found. \
Install it first\n"
  apt-get install -y git
fi

if [ -d ~/.toandaominh1997/.dotfiles ] ; then
cd ~/.toandaominh1997/.dotfiles
git pull origin master
fi

if ! is_app_installed vim; then
  printf "WARNING: \"vim\" command is not found. \
Install it first\n"
  apt-get install -y vim
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


is_app_installed() {
  type "$1" &>/dev/null
}

REPODIR="$(cd "$(dirname "$0")"; pwd -P)"
cd "$REPODIR";

if ! is_app_installed tmux; then
  printf "WARNING: \"tmux\" command is not found. \
Install it first\n"
  apt-get insatll -y tmux
fi

echo '
source ~/.toandaominh1997/.dotfiles/tmuxs/tmux.conf
'> ~/.tmux.conf

if ! hash zsh; then
apt-get install -y zsh
fi
cd 
if [ ! -d ~/.toandaominh1997/.oh-my-zsh ] ; then
echo 'Install Oh my zsh'
# sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.toandaominh1997/.oh-my-zsh
fi

cd
if [ ! -d ~/.toandaominh1997/fonts ] ; then
git clone https://github.com/powerline/fonts.git ~/.toandaominh1997/fonts
sh ~/.toandaominh1997/fonts/install.sh
fi


cd
if [ ! -d ~/.toandaominh1997/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ] ; then
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.toandaominh1997/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi

cd
if [ ! -d ~/.toandaominh1997/.oh-my-zsh/custom/plugins/zsh-autosuggestions ] ; then
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.toandaominh1997/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi

echo '
source ~/.toandaominh1997/.dotfiles/zshrcs/basic.zsh
'> ~/.zshrc
cd
export ZSH=~/.toandaominh1997/tools/install.sh
sh ~/.toandaominh1997/.oh-my-zsh/tools/install.sh
echo 'Complete OH MY ZSH'

printf "OK: Completed\n"



