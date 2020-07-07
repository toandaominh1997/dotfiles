command_exists() {
    hash "$1" &>/dev/null
}
# install git
if command_exists git; then
    echo "git is installed"
else
    echo "WARNING: \"git\" command is not found. Install it first"
    apt-get install -y git
fi

# install curl
if command_exists curl; then
    echo "curl is installed"
else
    echo "WARNING: \"curl\" command is not found. Install it first"
    apt-get install -y curl
fi

# install wget
if command_exists wget; then
    echo "wget is installed"
else
    echo "require wget but it's not installed. Install it first"
    apt-get install -y wget
fi

# install vim stable
if command_exists vim; then
    echo "vim is installed"
else
    echo "require vim but it's not installed. Install it first"
    add-apt-repository ppa:jonathonf/vim
    apt-get update
    apt-get install -y vim
    apt-get install vim-gnome
fi

# install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# install zsh stable
if command_exists zsh; then
    echo "zsh is installed"
else
    echo "require zsh but it's not installed. Install it first"
    apt-get install -y zsh
fi

# install tmux stable
if command_exists tmux; then
    echo "tmux is installed"
else
    echo "require tmux but it's not installed. Install it first"
    apt-get install -y tmux
fi

# install nodejs
#snap install node --channel=12/stable --classic
curl -sL install-node.now.sh/lts | bash -s -- --prefix=$HOME/.dotfiles/nodejs --version=lts --verbose
rm -rf node_lts.sh
if command_exists snap; then
    echo "Snap install"
    snap install --beta nvim --classic
fi

