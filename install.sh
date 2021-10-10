command_exists() {
    hash "$1" &>/dev/null
}
# install brew
if command_exists brew; then
    echo "brew is installed"
elif [ "$(uname)" == "Darwin" ]; then
    echo "WARNING: \"brew\" command is not found. Install it first"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo "WARNING: \"brew\" command is not found. Install it first"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ls -l /home/linuxbrew/.linuxbrew/bin/brew
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi

# install git
if command_exists git; then
    echo "git is installed"
    if [[ $1 == "upgrade" ]]; then
        echo "upgrade git package"
        brew reinstall git
    fi
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"git\" command is not found. Install it first"
    brew install git
fi 

# install curl
if command_exists curl; then
    echo "curl is installed"
    if [[ $1 == "upgrade" ]]; then
        echo "upgrade curl package"
        brew reinstall curl
    fi
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"curl\" command is not found. Install it first"
    brew install curl
fi 

# install wget
if command_exists wget; then
    echo "wget is installed"
    if [[ $1 == "upgrade" ]]; then
        echo "upgrade wget package"
        brew reinstall wget
    fi
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"curl\" command is not found. Install it first"
    brew install wget
fi 

# install vim stable
if command_exists vim; then
    echo "vim is installed"
    if [[ $1 == "upgrade" ]]; then
        echo "upgrade vim package"
        brew reinstall vim
    fi
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"vim\" command is not found. Install it first"
    brew install vim
fi 

if command_exists nvim; then
    echo "nvim is installed"
    if [[ $1 == "upgrade" ]]; then
        echo "upgrade nvim package"
        brew reinstall neovim
    fi
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"nvim\" command is not found. Install it first"
    brew install neovim
fi 

# install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "vim-plug installed"

# install zsh stable
if command_exists zsh; then
    echo "zsh is installed"
    if [[ $1 == "upgrade" ]]; then
        echo "upgrade zsh package"
        brew reinstall zsh
    fi
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"zsh\" command is not found. Install it first"
    brew install zsh
fi 

# install tmux stable
if command_exists tmux; then
    echo "tmux is installed"
    if [[ $1 == "upgrade" ]]; then
        echo "upgrade tmux package"
        brew reinstall tmux
    fi
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"tmux\" command is not found. Install it first"
    brew install tmux
fi 

# install node lts
if command_exists node; then
    echo "nodejs is installed"
    if [[ $1 == "upgrade" ]]; then
        echo "upgrade node package"
        brew reinstall node
    fi
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"node\" command is not found. Install it first"
    brew install node
fi 
