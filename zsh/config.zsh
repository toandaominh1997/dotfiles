# ==============================================================================
# Homebrew — must be first so brew-installed tools are on PATH during init
# ==============================================================================
if [[ "$(uname)" == "Darwin" ]]; then
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# ==============================================================================
# Oh My Zsh
# ==============================================================================
export ZSH="$HOME/.dotfiles/oh-my-zsh"

# Starship handles the prompt; OMZ theme must be blank
ZSH_THEME=""

# Static user — avoids a subshell on every shell start
DEFAULT_USER="$USER"

# zsh-completions: must be on fpath before oh-my-zsh calls compinit
fpath+=(${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-completions/src)

plugins=(
  aliases
  bazel
  brew
  colored-man-pages
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
  vscode
  web-search
  zsh-autosuggestions
  zsh-completions
  zsh-history-substring-search
  zsh-syntax-highlighting
)

if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  echo "Warning: Oh-My-Zsh not found at $ZSH"
fi

# Starship prompt (after oh-my-zsh so it wins the prompt)
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
else
  echo "Warning: starship not found — run dotup to install"
fi

# ==============================================================================
# History
# ==============================================================================
HISTSIZE=100000
SAVEHIST=100000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_ALL_DUPS   # no duplicate entries
setopt HIST_IGNORE_SPACE      # don't save commands starting with a space
setopt HIST_REDUCE_BLANKS     # trim extra blanks
setopt SHARE_HISTORY          # share history across all sessions in real time
setopt EXTENDED_HISTORY       # save timestamp and duration

# ==============================================================================
# Editor
# ==============================================================================
export EDITOR='nvim'
export VISUAL='nvim'

# ==============================================================================
# Tools
# ==============================================================================

# zoxide — smart cd with frecency (replaces plain cd)
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# fzf — key bindings and completions (ctrl-r, ctrl-t, alt-c)
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/fzf.zsh" ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/fzf.zsh"
elif [[ -f "$HOME/.fzf.zsh" ]]; then
  source "$HOME/.fzf.zsh"
fi

if [[ -f "$HOME/.dotfiles/tool/zsh/local.zsh" ]]; then
  source "$HOME/.dotfiles/tool/zsh/local.zsh"
fi

