apt install build-essential cmake python3-dev
if [ ! -d $HOME/.dotfiles/plugged/YouCompleteMe ] ; then
    git clone https://github.com/ycm-core/YouCompleteMe.git $HOME/.dotfiles/plugged/YouCompleteMe
fi
cd ~/.dotfiles/plugged/YouCompleteMe
git submodule update --init --recursive
./install.py --clang-completer
