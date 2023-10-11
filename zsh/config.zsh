export ZSH="$HOME/.dotfiles/oh-my-zsh"


theme="notstarship"
if [[ $theme == "starship" ]]; then
  eval "$(starship init zsh)"
else 
  POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
  POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
  ZSH_THEME="powerlevel10k/powerlevel10k"
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_from_right
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
  typeset -g POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND='kubectl|helm|kubens'
fi

DEFAULT_USER=`whoami`

plugins=(
    aliases
    brew
    bazel
    copyfile
    command-not-found
    common-aliases
    colored-man-pages
    docker
    dotenv
    extract
    fzf
    git
    github
    helm
    httpie
    history
    macos
    npm
    kubectl
    iterm2
    pip
    python
    tmux
    terraform
    skaffold
    vscode
    ubuntu
    zsh-interactive-cd
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-completions
    zsh-history-substring-search
    web-search
)
source ~/.dotfiles/oh-my-zsh/plugins/zsh-interactive-cd/zsh-interactive-cd.plugin.zsh

source $ZSH/oh-my-zsh.sh
export EDITOR='nvim'
if [[ "$(uname)" == "Darwin" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi


