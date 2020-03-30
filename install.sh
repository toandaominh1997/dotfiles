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

# install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim


# instzall vim
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


if [ -d $HOME/.dotfiles/config ] ; then
cd $HOME/.dotfiles/config
git pull origin master
else
  git clone https://github.com/toandaominh1997/dotfiles.git $HOME/.dotfiles/config
fi

if [ ! -d $HOME/.dotfiles/plugged/YouCompleteMe ] ; then
git clone https://github.com/ycm-core/YouCompleteMe.git $HOME/.dotfiles/plugged/YouCompleteMe
cd $HOME/.dotfiles/plugged/YouCompleteMe
git submodule update --init --recursive
python3 $HOME/.dotfiles/plugged/YouCompleteMe/install.py --all
fi

echo 'source $HOME/.dotfiles/tool/vim/config.vim'> ~/.vimrc

echo "Installed Vim configuration successfully ^~^"

echo 'source ~/.dotfiles/tool/tmux/config.tmux'> ~/.tmux.conf

echo "Installed Tmux configuration successfully ^~^"

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

if [ ! -d $HOME/.dotfiles/.oh-my-zsh/custom/themes/spaceship-prompt ] ; then
git clone https://github.com/denysdovhan/spaceship-prompt.git $HOME/.dotfiles/.oh-my-zsh/custom/themes/spaceship-prompt
ln -s "$HOME/.dotfiles/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "$HOME/.dotfiles/.oh-my-zsh/custom/themes/spaceship.zsh-theme"
fi

if [ ! -d $HOME/.dotfiles/.oh-my-zsh/custom/plugins/zsh-autosuggestions ] ; then
git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.dotfiles/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi


if [ ! -d $HOME/.dotfiles/.oh-my-zsh/custom/plugins/fzf ] ; then
git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.dotfiles/.oh-my-zsh/custom/plugins/fzf
$HOME/.dotfiles/.oh-my-zsh/custom/plugins/fzf/install
fi

echo 'source $HOME/.dotfiles/tool/zsh/config.zsh'> ~/.zshrc

export ZSH=$HOME/.dotfiles/.oh-my-zsh

sh $HOME/.dotfiles/.oh-my-zsh/tools/install.sh
echo 'Complete OH MY ZSH'

echo "OK: Completed\n"



