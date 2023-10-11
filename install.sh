#!/bin/sh

command_exists() {
  hash "$1" &>/dev/null
}

brew_install() {
  brew install $1
}

brew_reinstall() {
  brew reinstall $1
}
install_package() {
  if command_exists $1
  then
    echo "$1 is installed"
    if [[ $2 == "upgrade" || $2 == "-U" || $2 == "--upgrade" ]];
    then
      echo upgrade $1 ...
      brew reinstall $1
    fi
  else
    brew install $1 
  fi
}
detect_os() {
  if [[ $(uname) == "Darwin" ]];
  then
    return "macos" &>/dev/null
  else
    return "linux" &>/dev/null
  fi

}
has_upgrade=$1

# First install brew 
if command_exists brew; 
then
    echo "brew is installed"
elif [[ "$(uname)" == "Darwin" ]]; 
then
    echo "WARNING: \"brew\" command is not found. Install it first"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; 
then
    echo "WARNING: \"brew\" command is not found. Install it first"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ls -l /home/linuxbrew/.linuxbrew/bin/brew
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
fi


# Install package
install_package git $has_upgrade
install_package lazygit $has_upgrade
install_package lazydocker $has_upgrade
install_package gh $has_upgrade
install_package curl $has_upgrade
install_package wget $has_upgrade
install_package vim $has_upgrade
install_package neovim $has_upgrade
install_package zsh $has_upgrade
install_package tmux $has_upgrade
install_package zsh $has_upgrade
install_package fish $has_upgrade
install_package bat $has_upgrade
install_package cmake $has_upgrade
install_package telnet $has_upgrade
install_package htop $has_upgrade
install_package httpie $has_upgrade
install_package thefuck $has_upgrade # ref: https://github.com/nvbn/thefuck

# Programing language
install_package gcc $has_upgrade
install_package go $has_upgrade
install_package rust $has_upgrade
install_package node $has_upgrade

# Devops 
install_package k9s $has_upgrade
install_package kubernetes-cli $has_upgrade
install_package helm $has_upgrade
install_package terraform $has_upgrade
install_package ansible $has_upgrade


## Install bazel 
install_package bazelisk $has_upgrade
### Ln: sudo ln -s /opt/homebrew/bin/bazelisk /usr/local/bin/bazel

# Setup Zsh/Oh-my-zsh
## Install fzf
install_package fzf $has_upgrade
$(brew --prefix)/opt/fzf/install --all

## Install syntax-highlighting
if [[ ! -d $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]]; then
    echo "install syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-syntax-highlighting
elif [[ $has_upgrade == "upgrade" || $has_upgrade == "--upgrade" || $has_upgrade == "-U" ]]; then
    echo "upgrade zsh-syntax-highlighting"
    rm -rf $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-syntax-highlighting
else
    echo "syntax_highlighting is installed"
fi

# Install zsh-completions
if [[ ! -d $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-completions ]]; then
    echo "install zsh-completions"
    git clone https://github.com/zsh-users/zsh-completions.git $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-completions
elif [[ $has_upgrade == "upgrade" || $has_upgrade == "--upgrade" || $has_upgrade == "-U" ]]; then
    echo "upgrade zsh-completions"
    rm -rf $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-completions
    git clone https://github.com/zsh-users/zsh-completions.git $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-completions
else
    echo "zsh-completions is installed"
fi
# Install zsh-history-substring-search
if [[ ! -d $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-history-substring-search ]]; then
    echo "install zsh-history-substring-search"
    git clone https://github.com/zsh-users/zsh-history-substring-search.git $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-history-substring-search
elif [[ $has_upgrade == "upgrade" || $has_upgrade == "--upgrade" || $has_upgrade == "-U" ]]; then
    echo "upgrade zsh-history-substring-search"
    rm -rf $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-history-substring-search
    git clone https://github.com/zsh-users/zsh-history-substring-search.git $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-history-substring-search
else
    echo "zsh-history-substring-search is installed"
fi

# Install oh-my-zsh
if [[ ! -d $HOME/.dotfiles/oh-my-zsh ]]; then
    echo "install Oh-my-zsh"
    git clone https://github.com/robbyrussell/oh-my-zsh.git $HOME/.dotfiles/oh-my-zsh
    export ZSH=$HOME/.dotfiles/oh-my-zsh
    $HOME/.dotfiles/oh-my-zsh/tools/install.sh
elif [[ $1 == "upgrade" ]]; then
    echo "upgrade oh-my-zsh"
    rm -rf $HOME/.dotfiles/oh-my-zsh
    git clone https://github.com/robbyrussell/oh-my-zsh.git $HOME/.dotfiles/oh-my-zsh
    export ZSH=$HOME/.dotfiles/oh-my-zsh
    $HOME/.dotfiles/oh-my-zsh/tools/install.sh
else
    echo "Oh-my-zsh is installed"
fi
# Install autosuggestions
if [[ ! -d $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-autosuggestions ]]; then
    echo "install autosuggestions"
    git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-autosuggestions
elif [[ $has_upgrade == "upgrade" || $has_upgrade == "--upgrade" || $has_upgrade == "-U" ]]; then
    echo "upgrade zsh-autosuggestions"
    rm -rf $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-autosuggestions
else
    echo "autosuggestions is installed"
fi
# Install powerlevel10k
if [[ ! -d $HOME/.dotfiles/oh-my-zsh/themes/powerlevel10k ]]; then
    echo "install powerlevel10k"
    git clone https://github.com/romkatv/powerlevel10k.git $HOME/.dotfiles/oh-my-zsh/themes/powerlevel10k
elif [[ $has_upgrade == "upgrade" || $has_upgrade == "--upgrade" || $has_upgrade == "-U" ]]; then
    echo "upgrade powerlevel10k"
    rm -rf $HOME/.dotfiles/oh-my-zsh/themes/powerlevel10k
    git clone https://github.com/romkatv/powerlevel10k.git $HOME/.dotfiles/oh-my-zsh/themes/powerlevel10k
else
    echo "Powerlevel10k is installed"
fi
## Config zshrc
if grep  "source \$HOME/.dotfiles/tool/zsh/config.zsh" $HOME/.zshrc
then
  echo "Exist config.zsh in zshrc"
else
  echo "Write source $HOME/.dotfiles/tool/zsh/config.zsh in zshrc"
  sed -i '' '1s/^/source $HOME\/.dotfiles\/tool\/zsh\/config.zsh\n/' ~/.zshrc
fi

# Setup TMUX
if [[ ! -d $HOME/.dotfiles/.tmux/plugins/tpm ]]; then
    echo "install tpm"
    git clone https://github.com/tmux-plugins/tpm $HOME/.dotfiles/.tmux/plugins/tpm
elif [[ $1 == "upgrade" ]]; then
    echo "upgrade tpm"
    rm -rf $HOME/.dotfiles/.tmux/plugins/tpm
    git clone https://github.com/tmux-plugins/tpm $HOME/.dotfiles/.tmux/plugins/tpm
else
    echo "tpm is installed"
fi

echo 'source ~/.dotfiles/tool/tmux/config.tmux' >$HOME/.tmux.conf


# Setup vim/nvim
echo 'source $HOME/.dotfiles/tool/vim/config.vim' >$HOME/.vimrc
if [[ ! -d $HOME/.config/nvim ]]; then
    echo "Neovim setup"
    mkdir $HOME/.config/nvim
fi

echo -e "set runtimepath^=~/.vim runtimepath+=~/.vim/after\nlet &packpath = &runtimepath\nsource $HOME/.dotfiles/tool/vim/init.lua" >$HOME/.config/nvim/init.vim
ln -s ~/.dotfiles/tool/vim/lua ~/.config/nvim/lua

#vim +PlugInstall +qall
#nvim +PlugInstall +qall
echo "Installed Vim/Nvim configuration successfully ^~^"
