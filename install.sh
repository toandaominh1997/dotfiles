set +e
set -u

# install git
dpkg -s 'git' &> /dev/null 
if [ $? -ne 0 ]
then
 echo "git is installed"
 
else
  echo "WARNING: \"vim\" command is not found. Install it first\n"
  apt-get install -y git
fi

dpkg -s 'cmake' &> /dev/null
if [ $? -ne 0 ]
then
  echo "cmake is installed"
else
  echo "WARNING: \"cmake\" command is not found. Install it first\n" 
  apt-get install -y cmake 
fi
# install vim
dpkg -s 'vim' &> /dev/null 
if [ $? -ne 0 ]
then
  echo "vim is Installed"  
else
  echo "WARNING: \"vim\" command is not found. Install it first\n"
  apt-get install -y vim 
fi
# install zsh
dpkg -s 'zsh' &> /dev/null 
if [ $? -ne 0 ]
then
  echo "zsh is Installed"  
else
  echo "WARNING: \"zsh\" command is not found. Install it first\n"
  apt-get install -y zsh
fi
# install tmux
dpkg -s 'tmux' &> /dev/null 
if [ $? -ne 0 ]
then
  echo "tmux is Installed"
else
  echo "WARNING: \"tmux\" command is not found. Install it first\n"
  apt-get install -y tmux
fi


if [ -d $HOME/.dotfiles/tool ] ; then
cd $HOME/.dotfiles/tool
git pull origin master
else
  git clone https://github.com/toandaominh1997/dotfiles.git $HOME/.dotfiles/tool
fi

echo '
set runtimepath+=$HOME/.dotfiles/tool
source $HOME/.dotfiles/tool/vimrc/plugin.vim
source $HOME/.dotfiles/tool/vimrc/custom.vim
'> ~/.vimrc

if [ ! -d $HOME/.dotfiles/bundle ] ; then
git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.dotfiles/bundle/Vundle.vim
fi

vim -E +PluginInstall +qall

if [ -d $HOME/.dotfiles/bundle/youcompleteme ] ; then
  echo 'Install youcompleteme'
  cd $HOME/.dotfiles/bundle/youcompleteme
  python3 install.py --all
fi

echo "Installed Vim configuration successfully ^~^"

echo '
source ~/.dotfiles/tool/tmuxrc/tmux.conf
'> ~/.tmux.conf

if [ ! -d $HOME/.dotfiles/.oh-my-zsh ] ; then
echo 'install Oh-my-zsh'
git clone https://github.com/robbyrussell/oh-my-zsh.git $HOME/.dotfiles/.oh-my-zsh
fi

if [ ! -d $HOME/.dotfiles/fonts ] ; then
git clone https://github.com/powerline/fonts.git $HOME/.dotfiles/fonts
sh $HOME/.dotfiles/fonts/install.sh
fi

if [ ! -d $HOME/.dotfiles/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ] ; then
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.dotfiles/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi

if [ ! -d $HOME/.dotfiles/.oh-my-zsh/custom/plugins/zsh-autosuggestions ] ; then
git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.dotfiles/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi

if [ ! -d $HOME/.dotfiles/.oh-my-zsh/custom/plugins/fzf ] ; then
git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.dotfiles/.oh-my-zsh/custom/plugins/fzf
fi
echo '
source $HOME/.dotfiles/tool/zshrc/custom.zsh
'> ~/.zshrc

export ZSH=$HOME/.dotfiles/.oh-my-zsh

sh $HOME/.dotfiles/.oh-my-zsh/tools/install.sh
echo 'Complete OH MY ZSH'

echo "OK: Completed\n"



