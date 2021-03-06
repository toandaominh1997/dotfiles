set +e
set -u

# install vim plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# config vim
echo 'source $HOME/.dotfiles/tool/vim/config.vim' >$HOME/.vimrc
if [ ! -d $HOME/.config/nvim ]; then
    echo "Neovim setup"
    mkdir $HOME/.config/nvim
fi
echo -e "set runtimepath^=~/.vim runtimepath+=~/.vim/after\nlet &packpath = &runtimepath\nsource $HOME/.dotfiles/tool/vim/config.vim" >$HOME/.config/nvim/init.vim

vim +PlugInstall +qall &> /dev/null
nvim +PlugInstall +qall &> /dev/null
echo "Installed Vim/Nvim configuration successfully ^~^"

# config tmux
## install tpm
if [ ! -d $HOME/.dotfiles/.tmux/plugins/tpm ]; then
    echo "install tpm"
    git clone https://github.com/tmux-plugins/tpm $HOME/.dotfiles/.tmux/plugins/tpm
else
    echo "tpm is installed"
fi

echo 'source ~/.dotfiles/tool/tmux/config.tmux' >$HOME/.tmux.conf
echo "Installed Tmux configuration successfully ^~^"

# install oh-my-zsh
if [ ! -d $HOME/.dotfiles/oh-my-zsh ]; then
    echo "install Oh-my-zsh"
    git clone https://github.com/robbyrussell/oh-my-zsh.git $HOME/.dotfiles/oh-my-zsh
else
    echo "Oh-my-zsh is installed"
fi
# install powerlevel10k
if [ ! -d $HOME/.dotfiles/oh-my-zsh/themes/powerlevel10k ]; then
    echo "install powerlevel10k"
    git clone https://github.com/romkatv/powerlevel10k.git $HOME/.dotfiles/oh-my-zsh/themes/powerlevel10k
else
    echo "Powerlevel10k is installed"
fi

# install fonts
if [ ! -d $HOME/.dotfiles/fonts ]; then
    echo "install fonts"
    git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git $HOME/.dotfiles/fonts
    bash $HOME/.dotfiles/fonts/install.sh DroidSansMono
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
if [ ! -d $HOME/.dotfiles/fzf ]; then
    echo "install FZF"
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.dotfiles/fzf
    $HOME/.dotfiles/fzf/install --all
else
    echo "FZF is installed"
fi

export ZSH=$HOME/.dotfiles/oh-my-zsh
$HOME/.dotfiles/oh-my-zsh/tools/install.sh
echo 'Complete OH MY ZSH'
echo 'source $HOME/.dotfiles/tool/zsh/config.zsh' >$HOME/.zshrc
