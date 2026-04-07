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
LAZYVIM_REPO="https://github.com/LazyVim/starter.git"

# Dotfiles directories
DOTFILES_DIR="$HOME/.dotfiles"
OH_MY_ZSH_DIR="$DOTFILES_DIR/oh-my-zsh"

# Script metadata
readonly SCRIPT_VERSION="2.0.0"

# Global flags
UPGRADE_MODE=false
DRY_RUN=false
VERBOSE=false
FORCE=false
has_upgrade="non_upgrade"

# Required brew formula packages (must be installed)
required_packages=(
  bash
  fzf
  git
  neovim
  tmux
  vim
  zsh
)

# Additional brew formula packages (optional)
formulae_packages=(
  ansible
  awscli
  bat
  bazelisk
  cmake
  curl
  duf
  docker
  docker-compose
  fish
  gcc
  gh
  go
  helm
  htop
  httpie
  k9s
  kubernetes-cli
  lazydocker
  lazygit
  node
  nvm
  rust
  tldr
  telnet
  terraform
  thefuck
  unzip
  wget
  zoxide
)

# Brew cask packages (macOS only)
cask_packages=(
  alt-tab
  brave-browser
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
  slack
  spotify
  stats
  sublime-text
  telegram
  tor-browser
  visual-studio-code
  whatsapp
  zoom
)


###############################################################################
# Utility Functions
###############################################################################

log_info() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1" >&2
}

log_debug() {
    if [[ "$VERBOSE" == true ]]; then
      echo -e "\033[0;36m[DEBUG]\033[0m $1"
    fi
    return 0
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

###############################################################################
# Helper Functions
###############################################################################

# Check if the package is already installed using brew
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

package_exists() {
    local package="$1"
    local type="${2:---formula}"

    if [[ "$type" == "--cask" ]]; then
      brew list --cask "$package" &>/dev/null
    else
      brew list --formula "$package" &>/dev/null || command_exists "$package"
    fi
}

detect_os() {
  case "$(uname)" in
    Darwin) echo "macos" ;;
    *)      echo "linux" ;;
  esac
}

# Show usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -u, --upgrade       Upgrade existing packages
    -d, --dry-run      Show what would be installed without making changes
    -v, --verbose      Enable verbose output
    -f, --force        Force installation even if already present
    -h, --help         Show this help message
    --version          Show script version

EXAMPLES:
    $0                 # Basic installation
    $0 --upgrade       # Upgrade existing packages
    $0 --dry-run       # Preview what would be installed
    $0 -v --upgrade    # Verbose upgrade mode

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|--upgrade)
                UPGRADE_MODE=true
                has_upgrade="upgrade"
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            --version)
                echo "Dotfiles Setup Script v$SCRIPT_VERSION"
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Execute command with dry-run support
execute_command() {
    local cmd="$1"
    local description="$2"

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY-RUN] Would execute: $description"
        log_debug "Command: $cmd"
        return 0
    fi

    log_debug "Executing: $cmd"
    if eval "$cmd"; then
        return 0
    else
        local exit_code=$?
        log_error "Command failed: $description"
        log_error "Failed command: $cmd"
        return $exit_code
    fi
}


install_homebrew() {
  if command_exists brew; then
    log_info "Homebrew is already installed."
    if [[ "$UPGRADE_MODE" == true ]]; then
        execute_command "brew update" "Update Homebrew"
        log_info "End update homebrew"
    fi
  else
    execute_command "/bin/bash -c \"\$(curl -fsSL \"$BREW_INSTALL_URL\")\"" "Install Homebrew"

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
  local is_required="${3:-false}" # "upgrade" or "non_upgrade"

  if package_exists "$package" "$type"; then
    log_info "$package is already installed."
    if [[ "$UPGRADE_MODE" == true ]]; then
      log_info "Upgrading $package..."
      execute_command "brew upgrade \"$package\" 2>/dev/null || true" "Upgrade $package"
    fi
    return 0
  fi

  log_info "Installing $package..."
  if ! execute_command "brew install $type \"$package\"" "Install $package"; then
    if [[ "$is_required" == true ]]; then
      log_error "Failed to install required package: $package"
      exit 1
    else
      log_warn "Failed to install optional package: $package"
      return 1
    fi
  fi
  log_success "Successfully installed $package"
}

# Processes multiple packages in an array
process_packages() {
  local type="$1"         # e.g. "--formula" or "--cask"
  local upgrade_flag="$2" # "upgrade" or "non_upgrade"
  local is_required="${3:-false}"
  shift 3
  local packages=("$@")

  local failed_packages=()
  local success_count=0

  for package in "${packages[@]}"; do
    log_info "Install $package"
    if install_or_upgrade_package "$package" "$type" "$is_required"; then
      ((success_count+=1))
    else
      failed_packages+=("$package")
    fi
  done
  log_info "Successfully installed $success_count packages"
  log_info "Failed to install ${#failed_packages[@]} packages"
  if [[ ${#failed_packages[@]} -gt 0 ]]; then
    if [[ "$is_required" == true ]]; then
      log_error "Failed to install the following required packages: ${failed_packages[*]}"
      exit 1
    else
      log_warn "Failed to install the following optional packages: ${failed_packages[*]}"
    fi
  fi
}

# Install or upgrade a Zsh-related git plugin or repository
# Usage: install_or_upgrade_repo <repo_url> <destination_path> <repo_name> <upgrade_flag>
install_or_upgrade_repo() {
  local repo_url="$1"
  local dest_path="$2"
  local repo_name="$3"

  if [[ -d "$dest_path" ]]; then
    log_info "$repo_name already installed at $dest_path."
    if [[ "$UPGRADE_MODE" == true ]]; then
      log_info "Upgrading $repo_name..."
      if ! execute_command "(cd \"$dest_path\" && git pull --rebase --autostash)" "Upgrade $repo_name"; then
        log_warn "Failed to upgrade $repo_name, continuing..."
      fi
    fi
  else
    log_info "Installing $repo_name..."
    if ! execute_command "git clone --depth 1 \"$repo_url\" \"$dest_path\"" "Clone $repo_name"; then
      log_error "Failed to clone $repo_name"
      return 1
    fi
    log_success "Successfully installed $repo_name"
  fi
}

###############################################################################
# Dotfiles Setup Functions
###############################################################################

setup_oh_my_zsh() {
  log_info "Setting up Oh My Zsh"

  # If oh-my-zsh directory doesn't exist, clone
  if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
    execute_command "git clone \"$OH_MY_ZSH_REPO\" \"$OH_MY_ZSH_DIR\"" "Install Oh My Zsh"
    execute_command "export ZSH=\"$OH_MY_ZSH_DIR\"" "Set ZSH environment"
    execute_command "\"$OH_MY_ZSH_DIR/tools/install.sh\" --unattended --skip-chsh || true" "Run Oh My Zsh installer"
  else
    log_info "Oh My Zsh is already installed"
    if [[ "$UPGRADE_MODE" == true ]]; then
      echo "[ZSH] Upgrading Oh My Zsh..."
      execute_command "(cd \"$OH_MY_ZSH_DIR\" && git pull --rebase --autostash)" "Upgrade Oh My Zsh"
    fi
  fi
}

# Ensure a line exists in ~/.zshrc to source a custom config (if desired)
ensure_custom_config_in_zshrc() {
  local custom_config_line="source \$HOME/.dotfiles/tool/zsh/config.zsh"

  # Create .zshrc if it doesn't exist
  if [[ ! -f "$HOME/.zshrc" ]]; then
    log_info "Creating new .zshrc"
    touch "$HOME/.zshrc"
  fi

  if ! grep -qF "source \$HOME/.dotfiles/tool/zsh/config.zsh" "$HOME/.zshrc" 2>/dev/null; then
    log_info "Adding custom config to ~/.zshrc"
    echo "" >> "$HOME/.zshrc"
    echo "# Dotfiles custom configuration" >> "$HOME/.zshrc"
    echo "$custom_config_line" >> "$HOME/.zshrc"
  else
    log_info "Custom config already sourced in ~/.zshrc"
  fi
}
# Setup or upgrade Zsh plugins and themes
setup_zsh_plugins() {
  log_info "Setting up Zsh plugins"
  # zsh-syntax-highlighting
  install_or_upgrade_repo \
    "$ZSH_SYNTAX_HIGHLIGHTING_REPO" \
    "$OH_MY_ZSH_DIR/custom/plugins/zsh-syntax-highlighting" \
    "zsh-syntax-highlighting"

  # zsh-completions
  install_or_upgrade_repo \
    "$ZSH_COMPLETIONS_REPO" \
    "$OH_MY_ZSH_DIR/custom/plugins/zsh-completions" \
    "zsh-completions"

  # zsh-history-substring-search
  install_or_upgrade_repo \
    "$ZSH_HISTORY_SEARCH_REPO" \
    "$OH_MY_ZSH_DIR/custom/plugins/zsh-history-substring-search" \
    "zsh-history-substring-search"

  # zsh-autosuggestions
  install_or_upgrade_repo \
    "$ZSH_AUTOSUGGESTIONS_REPO" \
    "$OH_MY_ZSH_DIR/custom/plugins/zsh-autosuggestions" \
    "zsh-autosuggestions"

  # powerlevel10k
  install_or_upgrade_repo \
    "$POWERLEVEL10K_REPO" \
    "$OH_MY_ZSH_DIR/themes/powerlevel10k" \
    "Powerlevel10k"
}

# Setup Tmux plugin manager (TPM)
setup_tmux() {
  log_info "Setting up Tmux plugin manager (TPM)"
  install_or_upgrade_repo \
    "$TMUX_PLUGIN_MANAGER_REPO" \
    "$HOME/.tmux/plugins/tpm" \
    "tmux-plugin-manager"

  # Backup existing tmux config if it exists and is not a symlink
  if [[ -f "$HOME/.tmux.conf" && ! -L "$HOME/.tmux.conf" ]]; then
    log_info "Backing up existing .tmux.conf"
    execute_command "cp \"$HOME/.tmux.conf\" \"$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)\"" "Backup .tmux.conf"
  fi

  # Setup tmux configuration
  local tmux_config="source $DOTFILES_DIR/tool/tmux/config.tmux"
  execute_command "echo \"$tmux_config\" > \"$HOME/.tmux.conf\"" "Create .tmux.conf"
  log_success "Tmux configuration updated"
}

# Setup Vim & Neovim
setup_vim_nvim() {
  log_info "Setting up Vim and Neovim..."

  # Backup existing vim config if it exists
  if [[ -f "$HOME/.vimrc" && ! -L "$HOME/.vimrc" ]]; then
    log_info "Backing up existing .vimrc"
    execute_command "cp \"$HOME/.vimrc\" \"$HOME/.vimrc.backup.$(date +%Y%m%d_%H%M%S)\"" "Backup .vimrc"
  fi

  # Setup Vim
  local vim_config="source $DOTFILES_DIR/tool/vim/config.vim"
  execute_command "echo \"$vim_config\" > \"$HOME/.vimrc\"" "Create .vimrc"

  # Ensure Neovim config directory
  local nvim_dir="$HOME/.config/nvim"
  local nvim_data_dir="$HOME/.local/share/nvim"
  local lazyvim_lock_file="$nvim_dir/lazy-lock.json"
  local lazyvim_init_marker='require("config.lazy")'

  local has_lazyvim_config=false
  if [[ -f "$lazyvim_lock_file" ]] || grep -qF "$lazyvim_init_marker" "$nvim_dir/init.lua" 2>/dev/null; then
    has_lazyvim_config=true
  fi

  if [[ -d "$nvim_dir" ]] && [[ -n "$(ls -A "$nvim_dir" 2>/dev/null)" ]]; then
    if [[ "$has_lazyvim_config" == true ]]; then
      log_info "LazyVim is already installed."
      if [[ "$UPGRADE_MODE" == true ]]; then
        if [[ -d "$nvim_dir/.git" ]]; then
          log_info "Upgrading LazyVim starter..."
          execute_command "(cd \"$nvim_dir\" && git pull --rebase --autostash)" "Upgrade LazyVim starter"
        else
          log_info "Skipping LazyVim starter git update (no .git metadata)."
        fi
        log_info "Syncing LazyVim plugins..."
        execute_command "nvim --headless '+Lazy! sync' '+qa'" "Sync LazyVim plugins"
      fi
    else
      log_warn "Existing Neovim config found at $nvim_dir. Skipping LazyVim installation to avoid overwriting your config."
      log_warn "Remove or back up $nvim_dir and rerun setup.sh to install LazyVim."
    fi
  else
    log_info "Installing LazyVim..."
    execute_command "rm -rf \"$nvim_dir\"" "Remove empty Neovim config directory"
    execute_command "git clone \"$LAZYVIM_REPO\" \"$nvim_dir\"" "Clone LazyVim starter"
    execute_command "rm -rf \"$nvim_dir/.git\"" "Remove LazyVim starter git metadata"
    execute_command "rm -rf \"$nvim_data_dir\"" "Remove existing Neovim data for clean LazyVim bootstrap"
    execute_command "nvim --headless '+Lazy! sync' '+qa'" "Install LazyVim plugins"
    log_success "LazyVim installed successfully"
  fi
}

main() {

  # Parse command line arguments
  parse_arguments "$@"

  # Show script info
  log_info "Upgrade: $UPGRADE_MODE"

  local upgrade_flag="$has_upgrade"
  local os_type
  os_type="$(detect_os)"

  # Install Homebrew if not present
  log_info "==> Installing Homebrew..."
  install_homebrew

  # Brew formulae
  process_packages "--formula" "$UPGRADE_MODE" true "${required_packages[@]}"

  process_packages "--formula" "$UPGRADE_MODE" false "${formulae_packages[@]}"

  # 3) Brew casks (macOS only)
  if [[ "$os_type" == "macos" ]]; then
  echo "==> Installing macOS Brew cask packages..."
  process_packages "--cask" "$UPGRADE_MODE" false "${cask_packages[@]}"
  fi 

  # 4) Set up Oh My Zsh & plugins
  setup_oh_my_zsh
  setup_zsh_plugins

  # # 5) Add custom Zsh config to ~/.zshrc (if desired)
  ensure_custom_config_in_zshrc

  # 6) Set up Tmux
  setup_tmux

  # 7) Set up Vim/Neovim
  setup_vim_nvim

  # 8) Cleanup
  log_info "==> Running final Brew cleanup..."
  brew cleanup || true

  log_success "==> Dotfiles setup complete!"
  log_info ""
  log_info "Next steps:"
  log_info "  1. Restart your terminal or run: source ~/.zshrc"
  log_info "  2. Open tmux and press 'prefix + I' to install tmux plugins"
  log_info "  3. Open nvim and run :Lazy sync if plugins are not installed"
  log_info ""
  log_info "Configuration files:"
  log_info "  - Zsh:  ~/.zshrc"
  log_info "  - Tmux: ~/.tmux.conf"
  log_info "  - Vim:  ~/.vimrc"
  log_info "  - Nvim: ~/.config/nvim"

}

main "$@"
