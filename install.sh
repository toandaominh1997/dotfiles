set +e
set -u

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

# config vim
echo 'source $HOME/.dotfiles/tool/vim/config.vim' >$HOME/.vimrc
if [ ! -d $HOME/.config/nvim ]; then
    echo "Neovim setup"
    mkdir $HOME/.config/nvim
fi
echo -e "set runtimepath^=~/.vim runtimepath+=~/.vim/after\nlet &packpath = &runtimepath\nsource $HOME/.dotfiles/tool/vim/config.vim" >$HOME/.config/nvim/init.vim
vim +'PlugInstall --sync' +qa
echo "Installed Vim/Nvim configuration successfully ^~^"

# config tmux
echo 'source ~/.dotfiles/tool/tmux/config.tmux' >$HOME/.tmux.conf
echo "Installed Tmux configuration successfully ^~^"

# install oh-my-zsh
if [ ! -d $HOME/.dotfiles/oh-my-zsh ]; then
    echo "install Oh-my-zsh"
    git clone https://github.com/robbyrussell/oh-my-zsh.git $HOME/.dotfiles/oh-my-zsh
else
    echo "Oh-my-zsh is installed"
fi
# install powerlevel9k
if [ ! -d $HOME/.dotfiles/oh-my-zsh/themes/powerlevel9k ]; then
    echo "install powerlevel9k"
    git clone https://github.com/Powerlevel9k/powerlevel9k.git $HOME/.dotfiles/oh-my-zsh/themes/powerlevel9k
else
    echo "Powerlevel9k is installed"
fi
# install fonts
if [ ! -d $HOME/.dotfiles/fonts ]; then
    echo "install fonts"
    git clone https://github.com/powerline/fonts.git $HOME/.dotfiles/fonts
    sh $HOME/.dotfiles/fonts/install.sh
else
    echo "fonts is installed"
fi
# install syntax-highlighting
if [ ! -d $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
    echo "install syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-syntax-highlighting
else
    echo "syntax_highlighting is installed"
fi
# autosuggestions
if [ ! -d $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then
    echo "install autosuggestions"
    git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-autosuggestions
else
    echo "autosuggestions is installed"
fi
# fzf
if [ ! -d $HOME/.dotfiles/oh-my-zsh/custom/plugins/fzf ]; then
    echo "install FZF"
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.dotfiles/oh-my-zsh/custom/plugins/fzf
    $HOME/.dotfiles/oh-my-zsh/custom/plugins/fzf/install
else
    echo "FZF is installed"
fi
export ZSH=$HOME/.dotfiles/oh-my-zsh
$HOME/.dotfiles/oh-my-zsh/tools/install.sh
echo 'Complete OH MY ZSH'
echo 'source $HOME/.dotfiles/tool/zsh/config.zsh' >$HOME/.zshrc

if [ "$EUID" -ne 0 ]; then
    # install nodejs
    snap install node --channel=14/stable --classic
    # install nvim
    snap install --beta nvim --classic
fi
