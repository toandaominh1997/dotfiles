#!/usr/bin/env bash
#
# Dotfiles Setup Script
# Refactored for robust execution, clear logging, and dynamic path resolution.

set -euo pipefail

# Trap Ctrl+C (SIGINT) for a clean exit
trap 'echo -e "\n\033[0;31m[ERROR]\033[0m Setup interrupted by user. Exiting..."; exit 1' INT

###############################################################################
# Constants & Variables
###############################################################################

readonly SCRIPT_VERSION="2.1.0"

# Dynamically determine script directory for portability
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly OH_MY_ZSH_DIR="$DOTFILES_DIR/oh-my-zsh"

readonly BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

# Repos for plugins/tools
readonly ZSH_SYNTAX_HIGHLIGHTING_REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"
readonly ZSH_COMPLETIONS_REPO="https://github.com/zsh-users/zsh-completions.git"
readonly ZSH_HISTORY_SEARCH_REPO="https://github.com/zsh-users/zsh-history-substring-search.git"
readonly OH_MY_ZSH_REPO="https://github.com/robbyrussell/oh-my-zsh.git"
readonly ZSH_AUTOSUGGESTIONS_REPO="https://github.com/zsh-users/zsh-autosuggestions"
readonly POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"
readonly TMUX_PLUGIN_MANAGER_REPO="https://github.com/tmux-plugins/tpm"
readonly LAZYVIM_REPO="https://github.com/LazyVim/starter.git"

# Global flags
UPGRADE_MODE=false
DRY_RUN=false
VERBOSE=false
FORCE=false
AUTO_MODE=false

# Required brew formula packages (must be installed)
# NOTE: The rust 'dotup' CLI dynamically parses these arrays. Do not alter the syntax of the array declaration.
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

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -u, --upgrade      Upgrade existing packages
    -d, --dry-run      Show what would be installed without making changes
    -v, --verbose      Enable verbose output
    -f, --force        Force installation even if already present
    -a, --auto         Run automatically without interactive menu
    -h, --help         Show this help message
    --version          Show script version

EXAMPLES:
    $0                 # Basic installation (Interactive)
    $0 --auto          # Basic installation (Non-interactive)
    $0 --upgrade       # Upgrade existing packages
    $0 --dry-run       # Preview what would be installed
    $0 -v --upgrade    # Verbose upgrade mode

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|--upgrade)
                UPGRADE_MODE=true
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
            -a|--auto)
                AUTO_MODE=true
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
    if bash -c "$cmd"; then
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

install_or_upgrade_package() {
  local package="$1"
  local type="$2"   # e.g. "--formula" or "--cask"
  local is_required="${3:-false}"

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

process_packages() {
  local type="$1"
  local is_required="$2"
  shift 2
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
  
  if [[ ${#failed_packages[@]} -gt 0 ]]; then
    log_warn "Failed to install ${#failed_packages[@]} packages"
    if [[ "$is_required" == true ]]; then
      log_error "Failed to install the following required packages: ${failed_packages[*]}"
      exit 1
    else
      log_warn "Failed to install the following optional packages: ${failed_packages[*]}"
    fi
  fi
}

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

  if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
    execute_command "git clone \"$OH_MY_ZSH_REPO\" \"$OH_MY_ZSH_DIR\"" "Install Oh My Zsh"
    execute_command "export ZSH=\"$OH_MY_ZSH_DIR\"" "Set ZSH environment"
    execute_command "\"$OH_MY_ZSH_DIR/tools/install.sh\" --unattended --skip-chsh || true" "Run Oh My Zsh installer"
  else
    log_info "Oh My Zsh is already installed"
    if [[ "$UPGRADE_MODE" == true ]]; then
      log_info "[ZSH] Upgrading Oh My Zsh..."
      execute_command "(cd \"$OH_MY_ZSH_DIR\" && git pull --rebase --autostash)" "Upgrade Oh My Zsh"
    fi
  fi
}

ensure_custom_config_in_zshrc() {
  local custom_config_line="source \"$SCRIPT_DIR/zsh/config.zsh\""

  if [[ ! -f "$HOME/.zshrc" ]]; then
    log_info "Creating new .zshrc"
    touch "$HOME/.zshrc"
  fi

  if ! grep -qF "source \"$SCRIPT_DIR/zsh/config.zsh\"" "$HOME/.zshrc" 2>/dev/null; then
    log_info "Adding custom config to ~/.zshrc"
    {
      echo ""
      echo "# Dotfiles custom configuration"
      echo "$custom_config_line"
    } >> "$HOME/.zshrc"
  else
    log_info "Custom config already sourced in ~/.zshrc"
  fi
}

setup_zsh_plugins() {
  log_info "Setting up Zsh plugins"
  
  install_or_upgrade_repo "$ZSH_SYNTAX_HIGHLIGHTING_REPO" "$OH_MY_ZSH_DIR/custom/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"
  install_or_upgrade_repo "$ZSH_COMPLETIONS_REPO" "$OH_MY_ZSH_DIR/custom/plugins/zsh-completions" "zsh-completions"
  install_or_upgrade_repo "$ZSH_HISTORY_SEARCH_REPO" "$OH_MY_ZSH_DIR/custom/plugins/zsh-history-substring-search" "zsh-history-substring-search"
  install_or_upgrade_repo "$ZSH_AUTOSUGGESTIONS_REPO" "$OH_MY_ZSH_DIR/custom/plugins/zsh-autosuggestions" "zsh-autosuggestions"
  install_or_upgrade_repo "$POWERLEVEL10K_REPO" "$OH_MY_ZSH_DIR/custom/themes/powerlevel10k" "Powerlevel10k"
}

setup_p10k_config() {
  local src="$SCRIPT_DIR/zsh/.p10k.zsh"
  local dest="$HOME/.p10k.zsh"

  if [[ ! -f "$src" ]]; then
    log_warn ".p10k.zsh not found at $src, skipping symlink"
    return 0
  fi

  if [[ -L "$dest" ]]; then
    log_info "~/.p10k.zsh symlink already exists"
    return 0
  fi

  if [[ -f "$dest" ]]; then
    log_info "Backing up existing ~/.p10k.zsh"
    execute_command "mv \"$dest\" \"${dest}.backup.$(date +%Y%m%d_%H%M%S)\"" "Backup .p10k.zsh"
  fi

  execute_command "ln -sf \"$src\" \"$dest\"" "Symlink .p10k.zsh"
  log_success "Linked .p10k.zsh -> $dest"
}

setup_tmux() {
  log_info "Setting up Tmux plugin manager (TPM)"
  install_or_upgrade_repo "$TMUX_PLUGIN_MANAGER_REPO" "$HOME/.tmux/plugins/tpm" "tmux-plugin-manager"

  if [[ -f "$HOME/.tmux.conf" && ! -L "$HOME/.tmux.conf" ]]; then
    log_info "Backing up existing .tmux.conf"
    execute_command "cp \"$HOME/.tmux.conf\" \"$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)\"" "Backup .tmux.conf"
  fi

  local tmux_config="source \"$SCRIPT_DIR/tmux/config.tmux\""
  execute_command "echo '$tmux_config' > \"$HOME/.tmux.conf\"" "Create .tmux.conf"
  log_success "Tmux configuration updated"
}

setup_vim_nvim() {
  log_info "Setting up Vim and Neovim..."

  if [[ -f "$HOME/.vimrc" && ! -L "$HOME/.vimrc" ]]; then
    log_info "Backing up existing .vimrc"
    execute_command "cp \"$HOME/.vimrc\" \"$HOME/.vimrc.backup.$(date +%Y%m%d_%H%M%S)\"" "Backup .vimrc"
  fi

  local vim_config="source \"$SCRIPT_DIR/vim/config.vim\""
  execute_command "echo '$vim_config' > \"$HOME/.vimrc\"" "Create .vimrc"

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

run_packages() {
  local os_type
  os_type="$(detect_os)"
  log_info "==> Installing Homebrew..."
  install_homebrew

  process_packages "--formula" true "${required_packages[@]}"
  process_packages "--formula" false "${formulae_packages[@]}"

  if [[ "$os_type" == "macos" ]]; then
    log_info "==> Installing macOS Brew cask packages..."
    process_packages "--cask" false "${cask_packages[@]}"
  fi
}

run_zsh() {
  setup_oh_my_zsh
  setup_zsh_plugins
  setup_p10k_config
  ensure_custom_config_in_zshrc
}

install_fonts() {
  log_info "==> Installing Nerd Fonts (MesloLGS NF)..."

  local os_type
  os_type="$(detect_os)"
  local font_dir

  if [[ "$os_type" == "macos" ]]; then
    font_dir="$HOME/Library/Fonts"
  else
    font_dir="$HOME/.local/share/fonts"
  fi

  if [[ ! -d "$font_dir" ]]; then
    mkdir -p "$font_dir"
  fi

  local base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
  local fonts=(
    "MesloLGS%20NF%20Regular.ttf"
    "MesloLGS%20NF%20Bold.ttf"
    "MesloLGS%20NF%20Italic.ttf"
    "MesloLGS%20NF%20Bold%20Italic.ttf"
  )

  local pids=()
  local downloaded=0

  for font_file in "${fonts[@]}"; do
    local decoded_font="${font_file//%20/ }"
    local font_path="$font_dir/$decoded_font"

    if [[ -f "$font_path" ]]; then
      log_info "Font already exists: $decoded_font"
      continue
    fi

    log_info "Downloading $decoded_font..."
    curl -fsSL "$base_url/$font_file" -o "$font_path" &
    pids+=($!)
    ((downloaded++))
  done

  if [[ ${#pids[@]} -gt 0 ]]; then
    wait "${pids[@]}" || log_warn "A font download failed"
    log_success "Fonts downloaded successfully."
  fi

  if [[ "$downloaded" -gt 0 && "$os_type" == "linux" ]] && command_exists fc-cache; then
    log_info "Updating font cache..."
    fc-cache -f -v >/dev/null 2>&1
  fi
}

run_all() {
  run_packages
  install_fonts
  run_zsh
  setup_tmux
  setup_vim_nvim

  log_info "==> Running final Brew cleanup..."
  if command_exists brew; then
    brew cleanup || true
  fi

  log_success "==> Dotfiles setup complete!"
  
  echo ""
  log_info "Next steps:"
  log_info "  1. Restart your terminal or run: source ~/.zshrc"
  log_info "  2. Open tmux and press 'prefix + I' to install tmux plugins"
  log_info "  3. Open nvim and run :Lazy sync if plugins are not installed"
  echo ""
  log_info "Configuration files:"
  log_info "  - Zsh:  ~/.zshrc"
  log_info "  - Tmux: ~/.tmux.conf"
  log_info "  - Vim:  ~/.vimrc"
  log_info "  - Nvim: ~/.config/nvim"
}

interactive_menu() {
  while true; do
    clear
    echo -e "\033[1;36m===============================================\033[0m"
    echo -e "\033[1;32m            Dotfiles Setup Script              \033[0m"
    echo -e "\033[1;36m===============================================\033[0m"
    echo "Please select an option:"
    echo "  1) Install Everything (Default)"
    echo "  2) Install Homebrew & Packages"
    echo "  3) Setup Zsh & Themes"
    echo "  4) Setup Tmux"
    echo "  5) Setup Vim & Neovim"
    echo "  6) Install Fonts"
    echo "  7) Upgrade Existing Setup"
    echo "  q) Quit"
    echo -e "\033[1;36m===============================================\033[0m"
    read -r -p "Enter your choice [1]: " choice
    choice=${choice:-1}
    
    case $choice in
      1)
        run_all
        break
        ;;
      2)
        run_packages
        read -r -p "Press Enter to continue..."
        ;;
      3)
        run_zsh
        read -r -p "Press Enter to continue..."
        ;;
      4)
        setup_tmux
        read -r -p "Press Enter to continue..."
        ;;
      5)
        setup_vim_nvim
        read -r -p "Press Enter to continue..."
        ;;
      6)
        install_fonts
        read -r -p "Press Enter to continue..."
        ;;
      7)
        UPGRADE_MODE=true
        run_all
        break
        ;;
      q|Q)
        log_info "Exiting..."
        exit 0
        ;;
      *)
        log_error "Invalid choice"
        sleep 1
        ;;
    esac
  done
}

main() {
  parse_arguments "$@"

  log_info "Upgrade Mode: $UPGRADE_MODE"

  if [[ "$AUTO_MODE" == true ]]; then
    run_all
  else
    interactive_menu
  fi
}

main "$@"