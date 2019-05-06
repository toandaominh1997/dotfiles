set +e
set -u

if ! hash git; then
  printf "WARNING: \"git\" command is not found. \
Install it first\n"
  apt-get install -y git
fi

if [ -d $HOME/.dotfiles/.dotfiles ] ; then
cd $HOME/.dotfiles/.dotfiles
git pull origin master
fi

if ! hash vim; then
  printf "WARNING: \"vim\" command is not found. \
Install it first\n"
  apt-get install -y vim
fi

echo '
set runtimepath+=$HOME/.dotfiles/tool
source $HOME/.dotfiles/tool/vimrcs/plugin.vim
source $HOME/.dotfiles/tool/vimrcs/basic.vim
'> ~/.vimrc

if [ ! -d $HOME/.dotfiles/bundle ] ; then
git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.dotfiles/bundle/Vundle.vim
fi

cd
vim -E +PluginInstall +qall
cd
if [ -d $HOME/.dotfiles/bundle/youcompleteme ] ; then
echo 'Install youcompleteme'
cd $HOME/.dotfiles/bundle/youcompleteme
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
source ~/.dotfiles/.dotfiles/tmuxs/tmux.conf
'> ~/.tmux.conf

if ! hash zsh; then
apt-get install -y zsh
fi
cd 
if [ ! -d $HOME/.dotfiles/.oh-my-zsh ] ; then
echo 'Install Oh my zsh'
# sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
git clone https://github.com/robbyrussell/oh-my-zsh.git $HOME/.dotfiles/.oh-my-zsh
fi

cd
if [ ! -d $HOME/.dotfiles/fonts ] ; then
git clone https://github.com/powerline/fonts.git $HOME/.dotfiles/fonts
sh $HOME/.dotfiles/fonts/install.sh
fi


cd
if [ ! -d $HOME/.dotfiles/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ] ; then
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.dotfiles/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi

cd
if [ ! -d $HOME/.dotfiles/.oh-my-zsh/custom/plugins/zsh-autosuggestions ] ; then
git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.dotfiles/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi

echo '
source $HOME/.dotfiles/.dotfiles/zshrcs/basic.zsh
'> ~/.zshrc
cd
export ZSH=$HOME/.dotfiles/tools/install.sh
cd 
sh $HOME/.dotfiles/.oh-my-zsh/tools/install.sh
echo 'Complete OH MY ZSH'

printf "OK: Completed\n"



