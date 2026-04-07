export ZSH="$HOME/.dotfiles/oh-my-zsh"

# Theme configuration
# Set to "starship" to use starship prompt, or "powerlevel10k" for powerlevel10k
DOTFILES_THEME="${DOTFILES_THEME:-powerlevel10k}"

if [[ "$DOTFILES_THEME" == "starship" ]]; then
  if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
  else
    echo "Warning: starship not found, falling back to powerlevel10k"
    DOTFILES_THEME="powerlevel10k"
  fi
fi

if [[ "$DOTFILES_THEME" == "powerlevel10k" ]]; then
  POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
  POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
  ZSH_THEME="powerlevel10k/powerlevel10k"
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_from_right
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
  typeset -g POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND='kubectl|helm|kubens'
fi

DEFAULT_USER=$(whoami)

plugins=(
    aliases
    bazel
    brew
    colored-man-pages
    command-not-found
    common-aliases
    copyfile
    docker
    dotenv
    extract
    fzf
    git
    github
    helm
    history
    httpie
    iterm2
    kubectl
    macos
    npm
    python
    skaffold
    terraform
    ubuntu
    vscode
    web-search
    zsh-autosuggestions
    zsh-completions
    zsh-history-substring-search
    zsh-interactive-cd
    zsh-syntax-highlighting
)

# Load zsh-interactive-cd plugin if available
if [[ -f ~/.dotfiles/oh-my-zsh/plugins/zsh-interactive-cd/zsh-interactive-cd.plugin.zsh ]]; then
  source ~/.dotfiles/oh-my-zsh/plugins/zsh-interactive-cd/zsh-interactive-cd.plugin.zsh
fi

# Source Oh-My-Zsh
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  echo "Warning: Oh-My-Zsh not found at $ZSH"
fi

# Editor configuration
export EDITOR='nvim'
export VISUAL='nvim'

# Homebrew setup for macOS
if [[ "$(uname)" == "Darwin" ]]; then
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi


