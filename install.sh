command_exists() {
    hash "$1" &>/dev/null
}
# install git
if command_exists git; then
    echo "git is installed"
elif [ "$(uname)" == "Darwin" ]; then
    echo "WARNING: \"git\" command is not found. Install it first"
    brew install -y git
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo "WARNING: \"git\" command is not found. Install it first"
    apt-get install -y git
fi

# install curl
if command_exists curl; then
    echo "curl is installed"
elif [ "$(uname)" == "Darwin" ]; then
    echo "WARNING: \"curl\" command is not found. Install it first"
    brew install -y curl
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo "WARNING: \"curl\" command is not found. Install it first"
    apt-get install -y curl
fi

# install wget
if command_exists wget; then
    echo "wget is installed"
elif [ "$(uname)" == "Darwin" ]; then
    echo "WARNING: \"wget\" command is not found. Install it first"
    brew install -y wget
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo "WARNING: \"wgetl\" command is not found. Install it first"
    apt-get install -y wget
fi

# install vim stable
if command_exists vim; then
    echo "vim is installed"
elif [ "$(uname)" == "Darwin" ]; then
    echo "WARNING: \"vim\" command is not found. Install it first"
    brew install -y vim
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo "require vim but it's not installed. Install it first"
    add-apt-repository -y ppa:jonathonf/vim
    apt-get update -y
    apt-get install -y vim
    apt-get install -y vim-gnome
fi

if command_exists nvim; then
    echo "nvim is installed"
elif [ "$(uname)" == "Darwin" ]; then
    echo "WARNING: \"wget\" command is not found. Install it first"
    brew install -y neovim
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo "require nvim but it's not installed. Install it first"
    add-apt-repository -y ppa:neovim-ppa/stable
    apt-get update -y
    apt-get install -y neovim
fi

# install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "vim-plug installed"

# install zsh stable
if command_exists zsh; then
    echo "zsh is installed"
elif [ "$(uname)" == "Darwin" ]; then
    echo "WARNING: \"zsh\" command is not found. Install it first"
    brew install -y zsh
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo "WARNING: \"zsh\" command is not found. Install it first"
    apt-get install -y zsh
fi

# install tmux stable
if command_exists tmux; then
    echo "tmux is installed"
elif [ "$(uname)" == "Darwin" ]; then
    echo "WARNING: \"zsh\" command is not found. Install it first"
    brew install -y tmux
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo "WARNING: \"tmux\" command is not found. Install it first"
    apt-get install -y tmux
fi

# install node lts
if command_exists node; then
    echo "nodejs is installed"
else
    echo "require nodejs but it's not installed. Install it first"
    wget install-node.now.sh/lts
    bash lts
    rm -rf lts
fi
