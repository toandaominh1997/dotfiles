command_exists() {
    hash "$1" &>/dev/null
}
# install brew
if command_exists git; then
    echo "brew is installed"
elif [ "$(uname)" == "Darwin" ]; then
    echo "WARNING: \"brew\" command is not found. Install it first"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    echo "WARNING: \"brew\" command is not found. Install it first"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    sudo ln -sfn /home/linuxbrew/.linuxbrew/bin/brew /usr/local/bin/brew
fi



if [ ! -d $HOME/.dotfiles/development ]; then
    echo "Neovim setup"
    mkdir $HOME/.dotfiles/development
fi
# install git
if command_exists git; then
    echo "git is installed"
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"git\" command is not found. Install it first"
    brew install git
fi 

# install curl
if command_exists curl; then
    echo "curl is installed"
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"curl\" command is not found. Install it first"
    brew install curl
fi 

# install wget
if command_exists wget; then
    echo "wget is installed"
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"curl\" command is not found. Install it first"
    brew install wget
fi 

# install vim stable
if command_exists vim; then
    echo "vim is installed"
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"vim\" command is not found. Install it first"
    brew install vim
fi 

if command_exists nvim; then
    echo "nvim is installed"
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
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"zsh\" command is not found. Install it first"
    brew install zsh
fi 

# install tmux stable
if command_exists tmux; then
    echo "tmux is installed"
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"tmux\" command is not found. Install it first"
    brew install tmux
fi 

# install node lts
if command_exists node; then
    echo "nodejs is installed"
elif [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
    echo "WARNING: \"node\" command is not found. Install it first"
    brew install node
fi 
