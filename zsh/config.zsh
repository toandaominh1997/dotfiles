export ZSH="$HOME/.dotfiles/oh-my-zsh"

POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
ZSH_THEME="powerlevel10k/powerlevel10k"

DEFAULT_USER=`whoami`



plugins=(
    git
    github
    zsh-syntax-highlighting
    zsh-autosuggestions
    colored-man-pages
    python
    vscode
    command-not-found
    common-aliases
    history
    extract
    copyfile
    kubectl
    dotenv
    helm
    httpie
    )

source $ZSH/oh-my-zsh.sh
export EDITOR='nvim'
if [[ "$(uname)" == "Darwin" ]]; then
  export PATH=$PATH:/opt/homebrew/bin
fi
