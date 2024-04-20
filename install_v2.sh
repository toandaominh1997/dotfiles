#!/bin/bash

# Define constants
BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
ZSH_SYNTAX_HIGHLIGHTING_REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"
ZSH_COMPLETIONS_REPO="https://github.com/zsh-users/zsh-completions.git"
ZSH_HISTORY_SEARCH_REPO="https://github.com/zsh-users/zsh-history-substring-search.git"
OH_MY_ZSH_REPO="https://github.com/robbyrussell/oh-my-zsh.git"
ZSH_AUTOSUGGESTIONS_REPO="https://github.com/zsh-users/zsh-autosuggestions"
POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"
TMUX_PLUGIN_MANAGER_REPO="https://github.com/tmux-plugins/tpm"

# Default value for has_upgrade
has_upgrade="non_upgrade"

# Check if script was called with an argument to upgrade
if [ "$1" == "upgrade" ] || [ "$1" == "--upgrade" ] || [ "$1" == "-U" ]; then
    has_upgrade="upgrade"
fi

# Check if the package is already installed using brew
command_exists() {
  brew list "$1" &>/dev/null || command -v "$1" &>/dev/null
}

detect_os() {
  case "$(uname)" in
    Darwin) echo "macos" ;;
    *) echo "linux" ;;
  esac
}
os_type=$(detect_os)

install_homebrew() {
  if command_exists brew; then
    echo "brew is installed"
  else
    echo "WARNING: \"brew\" command is not found. Install it first"
    /bin/bash -c "$(curl -fsSL $BREW_INSTALL_URL)"
    if [[ $os_type == "linux" ]]; then
      eval "$($HOME/.homebrew/bin/brew shellenv)"
      brew update --force --quiet
      chmod -R go-w "$(brew --prefix)/share/zsh"
    fi
  fi
}

# Install or upgrade Zsh plugins and themes
install_or_upgrade_zsh_plugin() {
  local url="$1"
  local dest="$2"
  local name="$3"

  if [[ -d "$dest" ]]; then
    echo "$name is already installed."
    if [[ "$4" == "upgrade" ]]; then
      echo "Upgrading $name..."
      (cd "$dest" && git pull)
    fi
  else
    echo "Installing $name..."
    git clone "$url" "$dest"
  fi
}

# Install or upgrade a single package
install_or_upgrade_package() {
  local package="$1"
  local type="$2"  # "--formula" or "--cask"

  if command_exists "$package"; then
    echo "$package is already installed."
    if [[ "$3" == "upgrade" ]]; then
      echo "Upgrading $package..."
      brew upgrade "$package"
    fi
  else
    echo "Installing $package..."
    brew install "$type" "$package"
  fi
}

# Function to install or upgrade multiple packages
process_packages() {
  local type="$1"
  shift  # Remove the first argument which is the type of package
  local upgrade_flag="$1"
  shift  # Remove the second argument which is the upgrade flag

  for package in "$@"; do
    install_or_upgrade_package "$package" "$type" "$upgrade_flag"
  done
}


main() {
  local upgrade_flag="${1:-non_upgrade}"  # Default to non_upgrade if no parameter
  install_homebrew

  # Install required packages
  echo "Installing required packages..."
  process_packages "--formula" "$upgrade_flag" "${required_packages[@]}"

  # Install optional formulae packages
  echo "Installing additional formulae..."
  process_packages "--formula" "$upgrade_flag" "${formulae_packages[@]}"

  # Install cask packages if on macOS
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "Installing macOS applications..."
    process_packages "--cask" "$upgrade_flag" "${cask_packages[@]}"
  fi

  # Install and setup plugins
  install_or_upgrade_zsh_plugin "$HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-syntax-highlighting" "$ZSH_SYNTAX_HIGHLIGHTING_REPO" "zsh-syntax-highlighting"
  install_or_upgrade_zsh_plugin "$HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-completions" "$ZSH_COMPLETIONS_REPO" "zsh-completions"
  install_or_upgrade_zsh_plugin "$HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-history-substring-search" "$ZSH_HISTORY_SEARCH_REPO" "zsh-history-substring-search"
  install_or_upgrade_zsh_plugin "$HOME/.dotfiles/oh-my-zsh" "$OH_MY_ZSH_REPO" "Oh-my-zsh"
  install_or_upgrade_zsh_plugin "$HOME/.dotfiles/oh-my-zsh/custom/plugins/zsh-autosuggestions" "$ZSH_AUTOSUGGESTIONS_REPO" "zsh-autosuggestions"
  install_or_upgrade_zsh_plugin "$HOME/.dotfiles/oh-my-zsh/themes/powerlevel10k" "$POWERLEVEL10K_REPO" "Powerlevel10k"
  install_or_upgrade_zsh_plugin "$HOME/.dotfiles/.tmux/plugins/tpm" "$TMUX_PLUGIN_MANAGER_REPO" "tpm"

  echo "Cleaning up..."
  brew cleanup
}

# Required packages
required_packages=(
  bash fzf neovim tmux vim zsh
)

# Brew formulae
formulae_packages=(
  ansible awscli bash bat bazelisk cmake curl duf docker docker-compose
  exa fish fzf gcc gh git go helm htop httpie k9s kubernetes-cli lazydocker
  lazygit neovim node nvm rust rust tldr telnet terraform thefuck tmux unzip
  vim wget zsh zoxide
)

# Brew cask packages
cask_packages=(
  adobe-creative-cloud alacritty alt-tab brave-browser cloudflare-warp discord
  docker git-credential-manager google-chrome google-cloud-sdk iterm2
  jetbrains-toolbox messenger microsoft-edge microsoft-teams miniconda
  monitorcontrol notion obsidian postman rar skype slack spotify stats
  sublime-text telegram tor-browser visual-studio-code visualvm warp whatsapp zoom
)

# Execute the main function
main "$@"