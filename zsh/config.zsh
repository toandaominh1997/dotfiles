export ZSH="$HOME/.dotfiles/oh-my-zsh"
export FZF_BASE="$HOME/.dotfiles/fzf"
ZSH_THEME="powerlevel10k/powerlevel10k"
DEFAULT_USER=`whoami`



plugins=(
    git
    github
    zsh-syntax-highlighting
    zsh-autosuggestions
    colored-man-pages
    python
    fzf
    vscode
    command-not-found
    common-aliases
    history
    extract
    copyfile
    )

source $ZSH/oh-my-zsh.sh
export EDITOR='nvim'
