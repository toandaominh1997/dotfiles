#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Constants & Variables
###############################################################################

BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# Repos for plugins/tools
ZSH_SYNTAX_HIGHLIGHTING_REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"
ZSH_COMPLETIONS_REPO="https://github.com/zsh-users/zsh-completions.git"
ZSH_HISTORY_SEARCH_REPO="https://github.com/zsh-users/zsh-history-substring-search.git"
OH_MY_ZSH_REPO="https://github.com/robbyrussell/oh-my-zsh.git"
ZSH_AUTOSUGGESTIONS_REPO="https://github.com/zsh-users/zsh-autosuggestions"
POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"
TMUX_PLUGIN_MANAGER_REPO="https://github.com/tmux-plugins/tpm"

# Dotfiles directories
DOTFILES_DIR="$HOME/.dotfiles"
OH_MY_ZSH_DIR="$DOTFILES_DIR/oh-my-zsh"

# By default, do not upgrade
has_upgrade="non_upgrade"

# Required brew formula packages
required_packages=(
  bash
  fzf
  neovim
  tmux
  vim
  zsh
)

# Additional brew formula packages
formulae_packages=(
  ansible
  awscli
  bash
  bat
  bazelisk
  cmake
  curl
  duf
  docker
  docker-compose
  exa
  fish
  fzf
  gcc
  gh
  git
  go
  helm
  htop
  httpie
  k9s
  kubernetes-cli
  lazydocker
  lazygit
  neovim
  node
  nvm
  rust
  tldr
  telnet
  terraform
  thefuck
  tmux
  unzip
  vim
  wget
  zsh
  zoxide
)

# Brew cask packages (macOS only)
cask_packages=(
  adobe-creative-cloud
  alacritty
  alt-tab
  brave-browser
  cloudflare-warp
  discord
  docker
  git-credential-manager
  google-chrome
  google-cloud-sdk
  iterm2
  jetbrains-toolbox
  messenger
  microsoft-edge
  microsoft-teams
  monitorcontrol
  notion
  obsidian
  postman
  rar
  skype
  slack
  spotify
  stats
  sublime-text
  telegram
  tor-browser
  visual-studio-code
  visualvm
  warp
  whatsapp
  zoom
)

###############################################################################
# 2. Parse Arguments
###############################################################################
if [[ $# -gt 0 ]]; then
  case "$1" in
    "upgrade"|"--upgrade"|"-U")
      has_upgrade="upgrade"
      ;;
    *)
      echo "Unknown argument: $1"
      echo "Usage: $0 [upgrade|--upgrade|-U]"
      exit 1
      ;;
  esac
fi

###############################################################################
# Helper Functions
###############################################################################

# Check if the package is already installed using brew
command_exists() {
  brew list "$1" &>/dev/null || command -v "$1" &>/dev/null
}

detect_os() {
  case "$(uname)" in
    Darwin) echo "macos" ;;
    *)      echo "linux" ;;
  esac
}

install_homebrew() {
  if command_exists brew; then
    echo "Homebrew is already installed."
  else
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL "$BREW_INSTALL_URL")"

    if [[ "$(detect_os)" == "linux" ]]; then
      # On Linux, Homebrew installs to ~/.linuxbrew or ~/.homebrew
      # Adjust if your path differs:
      if [[ -d "$HOME/.homebrew/bin" ]]; then
        eval "$("$HOME/.homebrew/bin/brew" shellenv)"
      elif [[ -d "/home/linuxbrew/.linuxbrew/bin" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
      fi

      brew update --force --quiet
      chmod -R go-w "$(brew --prefix)/share/zsh"
    fi
  fi
}

# Installs or upgrades a Brew package (formula or cask)
install_or_upgrade_package() {
  local package="$1"
  local type="$2"   # e.g. "--formula" or "--cask"
  local upgrade="$3" # "upgrade" or "non_upgrade"

  if command_exists "$package"; then
    echo "[BREW] $package is already installed."
    if [[ "$upgrade" == "upgrade" ]]; then
      echo "[BREW] Upgrading $package..."
      brew upgrade "$package" || true
    fi
  else
    echo "[BREW] Installing $package..."
    brew install $type "$package"
  fi
}

# Processes multiple packages in an array
process_packages() {
  local type="$1"         # e.g. "--formula" or "--cask"
  local upgrade_flag="$2" # "upgrade" or "non_upgrade"
  shift 2

  for package in "$@"; do
    if ! install_or_upgrade_package "$package" "$type" "$upgrade_flag"; then
      echo "[ERROR] Failed to install/upgrade '$package' with type '$type'."
    fi
  done
}

# Install or upgrade a Zsh-related git plugin or repository
# Usage: install_or_upgrade_zsh_repo <repo_url> <destination_path> <repo_name> <upgrade_flag>
install_or_upgrade_zsh_repo() {
  local repo_url="$1"
  local dest_path="$2"
  local repo_name="$3"
  local upgrade_flag="$4"

  if [[ -d "$dest_path" ]]; then
    echo "[ZSH] $repo_name already installed at $dest_path."
    if [[ "$upgrade_flag" == "upgrade" ]]; then
      echo "[ZSH] Upgrading $repo_name..."
      (cd "$dest_path" && git pull --rebase --autostash || true)
    fi
  else
    echo "[ZSH] Installing $repo_name..."
    git clone "$repo_url" "$dest_path"
  fi
}

###############################################################################
# Dotfiles Setup Functions
###############################################################################

setup_oh_my_zsh() {
  local upgrade_flag="$1"

  # If oh-my-zsh directory doesn't exist, clone
  if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
    echo "[ZSH] Installing Oh My Zsh..."
    git clone "$OH_MY_ZSH_REPO" "$OH_MY_ZSH_DIR"
    export ZSH="$OH_MY_ZSH_DIR"
    # Run the official installer script
    "$OH_MY_ZSH_DIR/tools/install.sh" --unattended --skip-chsh || true
  else
    echo "[ZSH] Oh My Zsh is already installed."
    if [[ "$upgrade_flag" == "upgrade" ]]; then
      echo "[ZSH] Upgrading Oh My Zsh..."
      (cd "$OH_MY_ZSH_DIR" && git pull --rebase --autostash || true)
    fi
  fi
}

# Ensure a line exists in ~/.zshrc to source a custom config (if desired)
ensure_custom_config_in_zshrc() {
  local custom_config_line="source \$HOME/.dotfiles/tool/zsh/config.zsh"
  if ! grep -qxF "$custom_config_line" "$HOME/.zshrc" &>/dev/null; then
    echo "[ZSH] Adding custom config to ~/.zshrc"
    echo "$custom_config_line" >> "$HOME/.zshrc"
  else
    echo "[ZSH] Custom config already sourced in ~/.zshrc"
  fi
}
# Setup or upgrade Zsh plugins and themes
setup_zsh_plugins() {
  local upgrade_flag="$1"

  # zsh-syntax-highlighting
  install_or_upgrade_zsh_repo \
    "$ZSH_SYNTAX_HIGHLIGHTING_REPO" \
    "$OH_MY_ZSH_DIR/custom/plugins/zsh-syntax-highlighting" \
    "zsh-syntax-highlighting" \
    "$upgrade_flag"

  # zsh-completions
  install_or_upgrade_zsh_repo \
    "$ZSH_COMPLETIONS_REPO" \
    "$OH_MY_ZSH_DIR/custom/plugins/zsh-completions" \
    "zsh-completions" \
    "$upgrade_flag"

  # zsh-history-substring-search
  install_or_upgrade_zsh_repo \
    "$ZSH_HISTORY_SEARCH_REPO" \
    "$OH_MY_ZSH_DIR/custom/plugins/zsh-history-substring-search" \
    "zsh-history-substring-search" \
    "$upgrade_flag"

  # zsh-autosuggestions
  install_or_upgrade_zsh_repo \
    "$ZSH_AUTOSUGGESTIONS_REPO" \
    "$OH_MY_ZSH_DIR/custom/plugins/zsh-autosuggestions" \
    "zsh-autosuggestions" \
    "$upgrade_flag"

  # powerlevel10k
  install_or_upgrade_zsh_repo \
    "$POWERLEVEL10K_REPO" \
    "$OH_MY_ZSH_DIR/themes/powerlevel10k" \
    "Powerlevel10k" \
    "$upgrade_flag"
}

# Setup Tmux plugin manager (TPM)
setup_tmux() {
  local upgrade_flag="$1"
  install_or_upgrade_zsh_repo \
    "$TMUX_PLUGIN_MANAGER_REPO" \
    "$DOTFILES_DIR/.tmux/plugins/tpm" \
    "tmux-plugin-manager" \
    "$upgrade_flag"

  # Create/overwrite ~/.tmux.conf to source dotfiles config
  echo "source $DOTFILES_DIR/tool/tmux/config.tmux" > "$HOME/.tmux.conf"
  echo "[TMUX] .tmux.conf updated."
}

# Setup Vim & Neovim
setup_vim_nvim() {
  # Link or write .vimrc
  echo "source $DOTFILES_DIR/tool/vim/config.vim" > "$HOME/.vimrc"
  echo "[VIM] .vimrc updated."

  # Ensure Neovim config directory
  NVIM_DIR="$HOME/.config/nvim"
  if [[ -d "$NVIM_DIR" ]]; then
    echo "[NVIM] Neovim config directory already exists."
  else
    echo "[NVIM] Creating Neovim config directory..."
    git clone https://github.com/NvChad/starter ~/.config/nvim
    nvim --headless +":Lazy sync" +":sleep 2" +":q"

  fi

}

main() {
  local upgrade_flag="$has_upgrade"
  local os_type
  os_type="$(detect_os)"

  # Install Homebrew if not present
  install_homebrew

  # Brew formulae
  echo "==> Installing required Brew formulae..."
  process_packages "--formula" "$upgrade_flag" "${required_packages[@]}"

  echo "==> Installing additional Brew formulae..."
  process_packages "--formula" "$upgrade_flag" "${formulae_packages[@]}"

   # 3) Brew casks (macOS only)
  if [[ "$os_type" == "macos" ]]; then
    echo "==> Installing macOS Brew cask packages..."
    process_packages "--cask" "$upgrade_flag" "${cask_packages[@]}"
  fi 

  # 4) Set up Oh My Zsh & plugins
  setup_oh_my_zsh "$upgrade_flag"
  setup_zsh_plugins "$upgrade_flag"

  # 5) Add custom Zsh config to ~/.zshrc (if desired)
  ensure_custom_config_in_zshrc

  # 6) Set up Tmux
  setup_tmux "$upgrade_flag"

  # 7) Set up Vim/Neovim
  setup_vim_nvim
  

  # 8) Cleanup
  echo "==> Running final Brew cleanup..."
  brew cleanup || true

  echo "==> Dotfiles setup complete!"

}

main