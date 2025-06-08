#!/usr/bin/env bash

###############################################################################
# Enhanced Dotfiles Setup Script
# 
# This script sets up a complete development environment with:
# - Homebrew package management
# - Zsh with Oh My Zsh and plugins
# - Tmux with plugin manager
# - Vim/Neovim configuration
# - Cross-platform support (macOS/Linux)
#
# Usage:
#   ./setup.sh [OPTIONS]
#
# Options:
#   -u, --upgrade        Upgrade existing packages and configurations
#   -v, --verbose        Enable verbose logging and debug output
#   -d, --dry-run        Show what would be installed without making changes
#   -q, --quiet          Suppress informational output (errors/warnings only)
#   -l, --log-file FILE  Write logs to specified file
#   -h, --help           Show help message
#   --version            Show version information
#
###############################################################################

set -euo pipefail

###############################################################################
# Bootstrap and Load Dependencies
###############################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load the modular architecture
if [[ -f "$SCRIPT_DIR/lib/constants.sh" ]]; then
    # shellcheck source=./lib/constants.sh
    source "$SCRIPT_DIR/lib/constants.sh"
    
    # shellcheck source=./lib/logging.sh
    source "$SCRIPT_DIR/lib/logging.sh"
    
    # shellcheck source=./scripts/main_setup.sh
    source "$SCRIPT_DIR/scripts/main_setup.sh"
    
    MODULAR_MODE=true
else
    # Fallback to legacy mode if modular files don't exist
    MODULAR_MODE=false
    
    # Legacy constants for compatibility
    readonly DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
    readonly CONFIG_DIR="$SCRIPT_DIR/config"
    readonly UTILS_DIR="$SCRIPT_DIR/utils"
    
    # Ensure config directory exists
    mkdir -p "$CONFIG_DIR"
    
    # Log levels
    readonly LOG_ERROR=1
    readonly LOG_WARN=2
    readonly LOG_INFO=3
    readonly LOG_DEBUG=4
    LOG_LEVEL=$LOG_INFO
    
    # Colors for output
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[1;37m'
    readonly NC='\033[0m' # No Color
    
    # URLs and repositories
    readonly BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    readonly OH_MY_ZSH_REPO="https://github.com/robbyrussell/oh-my-zsh.git"
    readonly NVCHAD_STARTER_REPO="https://github.com/NvChad/starter"
    
    # Configuration file
    readonly PACKAGES_CONFIG="$CONFIG_DIR/packages.conf"
    
    # Source the configuration parser
    source "$UTILS_DIR/config_parser.sh" 2>/dev/null || {
        echo "Warning: Configuration parser not found. Using fallback configuration."
    }
fi

# Default options (can be overridden by command line)
UPGRADE_MODE=false
VERBOSE_MODE=false
DRY_RUN_MODE=false
QUIET_MODE=false
LOG_FILE=""

###############################################################################
# Logging Functions
###############################################################################

log() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ $level -le $LOG_LEVEL ]]; then
        case $level in
            $LOG_ERROR)
                echo -e "${RED}[ERROR]${NC} [$timestamp] $message" >&2
                ;;
            $LOG_WARN)
                echo -e "${YELLOW}[WARN]${NC} [$timestamp] $message" >&2
                ;;
            $LOG_INFO)
                echo -e "${GREEN}[INFO]${NC} [$timestamp] $message"
                ;;
            $LOG_DEBUG)
                if [[ $VERBOSE_MODE == true ]]; then
                    echo -e "${BLUE}[DEBUG]${NC} [$timestamp] $message"
                fi
                ;;
        esac
    fi
}

log_error() { log $LOG_ERROR "$1"; }
log_warn() { log $LOG_WARN "$1"; }
log_info() { log $LOG_INFO "$1"; }
log_debug() { log $LOG_DEBUG "$1"; }

print_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                          Enhanced Dotfiles Setup                            ║
║                                                                              ║
║  This script will set up your development environment with:                 ║
║  • Homebrew package manager                                                 ║
║  • Zsh with Oh My Zsh and plugins                                          ║
║  • Tmux with plugin manager                                                 ║
║  • Vim/Neovim configuration                                                 ║
║  • Cross-platform support (macOS/Linux)                                    ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_help() {
    cat << 'EOF'
Enhanced Dotfiles Setup Script

Usage:
    ./setup.sh [OPTIONS]

Options:
    -u, --upgrade     Upgrade existing packages and configurations
    -v, --verbose     Enable verbose logging
    -d, --dry-run     Show what would be installed without making changes
    -h, --help        Show this help message

Examples:
    ./setup.sh                    # Basic installation
    ./setup.sh --upgrade          # Upgrade existing setup
    ./setup.sh --verbose          # Verbose output
    ./setup.sh --dry-run          # Preview changes

EOF
}

###############################################################################
# Utility Functions
###############################################################################

detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unknown" ;;
    esac
}

detect_architecture() {
    case "$(uname -m)" in
        x86_64)  echo "amd64" ;;
        arm64)   echo "arm64" ;;
        aarch64) echo "arm64" ;;
        *)       echo "unknown" ;;
    esac
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

brew_package_installed() {
    if command_exists brew; then
        brew list "$1" &>/dev/null
    else
        return 1
    fi
}

is_git_repo() {
    [[ -d "$1/.git" ]]
}

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up $file to $backup"
        if [[ $DRY_RUN_MODE == false ]]; then
            cp "$file" "$backup"
        fi
    fi
}

create_symlink() {
    local source="$1"
    local target="$2"
    local force=${3:-false}
    
    log_debug "Creating symlink: $target -> $source"
    
    if [[ $DRY_RUN_MODE == true ]]; then
        log_info "[DRY RUN] Would create symlink: $target -> $source"
        return 0
    fi
    
    # Create target directory if needed
    local target_dir
    target_dir="$(dirname "$target")"
    mkdir -p "$target_dir"
    
    # Handle existing files/links
    if [[ -L "$target" ]]; then
        if [[ $force == true ]]; then
            rm "$target"
        else
            log_warn "Symlink already exists: $target"
            return 0
        fi
    elif [[ -f "$target" ]]; then
        if [[ $force == true ]]; then
            backup_file "$target"
            rm "$target"
        else
            log_warn "File already exists: $target"
            return 0
        fi
    fi
    
    ln -s "$source" "$target"
    log_info "Created symlink: $target -> $source"
}

###############################################################################
# Package Management Functions
###############################################################################

install_homebrew() {
    if command_exists brew; then
        log_info "Homebrew is already installed"
        if [[ $UPGRADE_MODE == true ]]; then
            log_info "Checking for Homebrew updates..."
            if [[ $DRY_RUN_MODE == false ]]; then
                brew update
            fi
        fi
        return 0
    fi
    
    log_info "Installing Homebrew..."
    if [[ $DRY_RUN_MODE == true ]]; then
        log_info "[DRY RUN] Would install Homebrew"
        return 0
    fi
    
    /bin/bash -c "$(curl -fsSL "$BREW_INSTALL_URL")"
    
    # Set up Homebrew environment for Linux
    if [[ "$(detect_os)" == "linux" ]]; then
        if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        elif [[ -d "$HOME/.homebrew" ]]; then
            eval "$("$HOME/.homebrew/bin/brew" shellenv)"
        fi
        
        if command_exists brew; then
            brew update --force --quiet
            # Fix permissions for zsh completions
            if [[ -d "$(brew --prefix)/share/zsh" ]]; then
                chmod -R go-w "$(brew --prefix)/share/zsh"
            fi
        fi
    fi
}

is_brew_package_outdated() {
    local package="$1"
    if command_exists brew; then
        brew outdated --quiet | grep -q "^${package}$"
    else
        return 1
    fi
}

install_brew_package() {
    local package="$1"
    local type="$2"  # --formula or --cask
    local upgrade_mode="$3"
    
    log_debug "Processing package: $package (type: $type)"
    
    if brew_package_installed "$package"; then
        log_info "Package '$package' is already installed"
        if [[ $upgrade_mode == true ]]; then
            if is_brew_package_outdated "$package"; then
                log_info "Upgrading package '$package'..."
                if [[ $DRY_RUN_MODE == false ]]; then
                    brew upgrade "$package" 2>/dev/null || {
                        log_warn "Failed to upgrade '$package' or no upgrade available"
                    }
                else
                    log_info "[DRY RUN] Would upgrade package '$package'"
                fi
            else
                log_debug "Package '$package' is already up to date"
            fi
        fi
    else
        log_info "Installing package '$package'..."
        if [[ $DRY_RUN_MODE == false ]]; then
            if ! brew install $type "$package"; then
                log_error "Failed to install package '$package'"
                return 1
            fi
        else
            log_info "[DRY RUN] Would install package '$package'"
        fi
    fi
}

upgrade_outdated_brew_packages() {
    local type="$1"
    
    if ! command_exists brew; then
        log_warn "Homebrew not available for upgrade"
        return 1
    fi
    
    local outdated_packages
    if [[ "$type" == "--cask" ]]; then
        outdated_packages=$(brew outdated --cask --quiet 2>/dev/null || true)
    else
        outdated_packages=$(brew outdated --quiet 2>/dev/null || true)
    fi
    
    if [[ -n "$outdated_packages" ]]; then
        log_info "Upgrading outdated $type packages..."
        if [[ $DRY_RUN_MODE == false ]]; then
            if [[ "$type" == "--cask" ]]; then
                echo "$outdated_packages" | xargs brew upgrade --cask || {
                    log_warn "Some cask upgrades failed"
                }
            else
                echo "$outdated_packages" | xargs brew upgrade || {
                    log_warn "Some formula upgrades failed"
                }
            fi
        else
            log_info "[DRY RUN] Would upgrade: $outdated_packages"
        fi
    else
        log_info "All $type packages are up to date"
    fi
}

install_packages_from_list() {
    local list_name="$1"
    local type="$2"
    shift 2
    local packages=("$@")
    
    if [[ $UPGRADE_MODE == true ]]; then
        log_info "Checking for outdated $list_name packages..."
        upgrade_outdated_brew_packages "$type"
    else
        log_info "Installing $list_name packages..."
        
        for package in "${packages[@]}"; do
            if ! install_brew_package "$package" "$type" "$UPGRADE_MODE"; then
                log_error "Failed to process package: $package"
            fi
        done
    fi
}

###############################################################################
# Configuration Setup Functions
###############################################################################

is_git_repo_outdated() {
    local dest_path="$1"
    if [[ -d "$dest_path/.git" ]]; then
        (cd "$dest_path" && \
         git fetch origin >/dev/null 2>&1 && \
         local local_commit=$(git rev-parse HEAD) && \
         local remote_commit=$(git rev-parse origin/master 2>/dev/null || git rev-parse origin/main 2>/dev/null) && \
         [[ "$local_commit" != "$remote_commit" ]])
    else
        return 1
    fi
}

clone_or_update_repo() {
    local repo_url="$1"
    local dest_path="$2"
    local repo_name="$3"
    local upgrade_mode="$4"
    
    if [[ -d "$dest_path" ]]; then
        log_info "$repo_name is already cloned at $dest_path"
        if [[ $upgrade_mode == true ]]; then
            if is_git_repo_outdated "$dest_path"; then
                log_info "Updating $repo_name..."
                if [[ $DRY_RUN_MODE == false ]]; then
                    (cd "$dest_path" && git pull --rebase --autostash) || {
                        log_warn "Failed to update $repo_name"
                    }
                else
                    log_info "[DRY RUN] Would update $repo_name"
                fi
            else
                log_debug "$repo_name is already up to date"
            fi
        fi
    else
        log_info "Cloning $repo_name..."
        if [[ $DRY_RUN_MODE == false ]]; then
            if ! git clone "$repo_url" "$dest_path"; then
                log_error "Failed to clone $repo_name"
                return 1
            fi
        else
            log_info "[DRY RUN] Would clone $repo_name from $repo_url to $dest_path"
        fi
    fi
}

setup_oh_my_zsh() {
    local oh_my_zsh_dir="$DOTFILES_DIR/oh-my-zsh"
    
    clone_or_update_repo "$OH_MY_ZSH_REPO" "$oh_my_zsh_dir" "Oh My Zsh" "$UPGRADE_MODE"
    
    # Don't run the installer if we're in dry run mode or if it's already set up
    if [[ $DRY_RUN_MODE == false && ! -f "$oh_my_zsh_dir/oh-my-zsh.sh" ]]; then
        log_info "Running Oh My Zsh installer..."
        export ZSH="$oh_my_zsh_dir"
        "$oh_my_zsh_dir/tools/install.sh" --unattended --skip-chsh || {
            log_warn "Oh My Zsh installer failed or was interrupted"
        }
    fi
}

setup_zsh_plugins() {
    local oh_my_zsh_dir="$DOTFILES_DIR/oh-my-zsh"
    local plugins_dir="$oh_my_zsh_dir/custom/plugins"
    local themes_dir="$oh_my_zsh_dir/custom/themes"
    
    # Create directories
    if [[ $DRY_RUN_MODE == false ]]; then
        mkdir -p "$plugins_dir" "$themes_dir"
    fi
    
    if [[ $UPGRADE_MODE == true ]]; then
        log_info "Checking for plugin updates..."
        local updates_found=false
        
        # Check plugins for updates
        if [[ -d "$plugins_dir" ]]; then
            for plugin_dir in "$plugins_dir"/*; do
                if [[ -d "$plugin_dir/.git" ]]; then
                    local plugin_name=$(basename "$plugin_dir")
                    if is_git_repo_outdated "$plugin_dir"; then
                        log_info "Updating plugin: $plugin_name"
                        if [[ $DRY_RUN_MODE == false ]]; then
                            (cd "$plugin_dir" && git pull --rebase --autostash) || {
                                log_warn "Failed to update plugin: $plugin_name"
                            }
                        else
                            log_info "[DRY RUN] Would update plugin: $plugin_name"
                        fi
                        updates_found=true
                    else
                        log_debug "Plugin $plugin_name is up to date"
                    fi
                fi
            done
        fi
        
        # Check themes for updates
        if [[ -d "$themes_dir" ]]; then
            for theme_dir in "$themes_dir"/*; do
                if [[ -d "$theme_dir/.git" ]]; then
                    local theme_name=$(basename "$theme_dir")
                    if is_git_repo_outdated "$theme_dir"; then
                        log_info "Updating theme: $theme_name"
                        if [[ $DRY_RUN_MODE == false ]]; then
                            (cd "$theme_dir" && git pull --rebase --autostash) || {
                                log_warn "Failed to update theme: $theme_name"
                            }
                        else
                            log_info "[DRY RUN] Would update theme: $theme_name"
                        fi
                        updates_found=true
                    else
                        log_debug "Theme $theme_name is up to date"
                    fi
                fi
            done
        fi
        
        if [[ $updates_found == false ]]; then
            log_info "All Zsh plugins and themes are up to date"
        fi
    else
        # Install plugins from configuration
        if [[ -f "$PACKAGES_CONFIG" ]]; then
            while IFS='=' read -r plugin_name plugin_url; do
                local plugin_path="$plugins_dir/$plugin_name"
                clone_or_update_repo "$plugin_url" "$plugin_path" "$plugin_name" "$UPGRADE_MODE"
            done < <(get_plugins_from_config "$PACKAGES_CONFIG" "zsh_plugins")
            
            # Install themes from configuration
            while IFS='=' read -r theme_name theme_url; do
                local theme_path="$themes_dir/$theme_name"
                clone_or_update_repo "$theme_url" "$theme_path" "$theme_name" "$UPGRADE_MODE"
            done < <(get_plugins_from_config "$PACKAGES_CONFIG" "themes")
        else
            log_warn "Configuration file not found. Using fallback plugin installation."
            # Fallback to hardcoded plugins (bash 3.2 compatible)
            local fallback_plugins="zsh-syntax-highlighting=https://github.com/zsh-users/zsh-syntax-highlighting.git
zsh-completions=https://github.com/zsh-users/zsh-completions.git
zsh-history-substring-search=https://github.com/zsh-users/zsh-history-substring-search.git
zsh-autosuggestions=https://github.com/zsh-users/zsh-autosuggestions"
            
            while IFS='=' read -r plugin_name plugin_url; do
                if [[ -n $plugin_name && -n $plugin_url ]]; then
                    local plugin_path="$plugins_dir/$plugin_name"
                    clone_or_update_repo "$plugin_url" "$plugin_path" "$plugin_name" "$UPGRADE_MODE"
                fi
            done <<< "$fallback_plugins"
            
            # Install PowerLevel10k theme
            clone_or_update_repo "https://github.com/romkatv/powerlevel10k.git" "$themes_dir/powerlevel10k" "Powerlevel10k" "$UPGRADE_MODE"
        fi
    fi
}

setup_zsh_config() {
    local zshrc="$HOME/.zshrc"
    local custom_config="source \$HOME/.dotfiles/tool/zsh/config.zsh"
    
    log_info "Setting up Zsh configuration..."
    
    if [[ -f "$zshrc" ]] && grep -qxF "$custom_config" "$zshrc" 2>/dev/null; then
        log_info "Custom Zsh config already sourced in ~/.zshrc"
    else
        log_info "Adding custom config source to ~/.zshrc"
        if [[ $DRY_RUN_MODE == false ]]; then
            echo "$custom_config" >> "$zshrc"
        else
            log_info "[DRY RUN] Would add custom config to ~/.zshrc"
        fi
    fi
}

setup_tmux() {
    local tmux_dir="$DOTFILES_DIR/.tmux"
    local plugins_dir="$tmux_dir/plugins"
    
    # Create directories
    if [[ $DRY_RUN_MODE == false ]]; then
        mkdir -p "$plugins_dir"
    fi
    
    if [[ $UPGRADE_MODE == true ]]; then
        log_info "Checking for Tmux plugin updates..."
        local updates_found=false
        
        if [[ -d "$plugins_dir" ]]; then
            for plugin_dir in "$plugins_dir"/*; do
                if [[ -d "$plugin_dir/.git" ]]; then
                    local plugin_name=$(basename "$plugin_dir")
                    if is_git_repo_outdated "$plugin_dir"; then
                        log_info "Updating Tmux plugin: $plugin_name"
                        if [[ $DRY_RUN_MODE == false ]]; then
                            (cd "$plugin_dir" && git pull --rebase --autostash) || {
                                log_warn "Failed to update Tmux plugin: $plugin_name"
                            }
                        else
                            log_info "[DRY RUN] Would update Tmux plugin: $plugin_name"
                        fi
                        updates_found=true
                    else
                        log_debug "Tmux plugin $plugin_name is up to date"
                    fi
                fi
            done
        fi
        
        if [[ $updates_found == false ]]; then
            log_info "All Tmux plugins are up to date"
        fi
    else
        # Install TPM (Tmux Plugin Manager) from configuration
        if [[ -f "$PACKAGES_CONFIG" ]]; then
            while IFS='=' read -r plugin_name plugin_url; do
                local plugin_path="$plugins_dir/$plugin_name"
                clone_or_update_repo "$plugin_url" "$plugin_path" "Tmux $plugin_name" "$UPGRADE_MODE"
            done < <(get_plugins_from_config "$PACKAGES_CONFIG" "tmux_plugins")
        else
            # Fallback to hardcoded TPM installation
            log_warn "Configuration file not found. Using fallback TPM installation."
            clone_or_update_repo "https://github.com/tmux-plugins/tpm" "$plugins_dir/tpm" "Tmux Plugin Manager" "$UPGRADE_MODE"
        fi
    fi
    
    # Create/update ~/.tmux.conf
    local tmux_conf="$HOME/.tmux.conf"
    local tmux_config_source="source $DOTFILES_DIR/tool/tmux/config.tmux"
    
    log_info "Setting up Tmux configuration..."
    if [[ $DRY_RUN_MODE == false ]]; then
        echo "$tmux_config_source" > "$tmux_conf"
        log_info "Updated ~/.tmux.conf"
    else
        log_info "[DRY RUN] Would update ~/.tmux.conf"
    fi
}

setup_vim_neovim() {
    log_info "Setting up Vim configuration..."
    
    # Setup Vim
    local vimrc="$HOME/.vimrc"
    local vim_config_source="source $DOTFILES_DIR/tool/vim/config.vim"
    
    if [[ $DRY_RUN_MODE == false ]]; then
        echo "$vim_config_source" > "$vimrc"
        log_info "Updated ~/.vimrc"
    else
        log_info "[DRY RUN] Would update ~/.vimrc"
    fi
    
    # Setup Neovim
    local nvim_dir="$HOME/.config/nvim"
    
    if [[ -d "$nvim_dir" ]]; then
        log_info "Neovim configuration directory already exists"
        if [[ $UPGRADE_MODE == true ]]; then
            if is_git_repo_outdated "$nvim_dir"; then
                log_info "Updating Neovim configuration..."
                if [[ $DRY_RUN_MODE == false ]]; then
                    (cd "$nvim_dir" && git pull --rebase --autostash) || {
                        log_warn "Failed to update Neovim configuration"
                    }
                else
                    log_info "[DRY RUN] Would update Neovim configuration"
                fi
            else
                log_info "Neovim configuration is already up to date"
            fi
        fi
    else
        log_info "Setting up Neovim with NvChad starter configuration..."
        if [[ $DRY_RUN_MODE == false ]]; then
            git clone "$NVCHAD_STARTER_REPO" "$nvim_dir" || {
                log_error "Failed to clone NvChad starter configuration"
                return 1
            }
        else
            log_info "[DRY RUN] Would clone NvChad starter configuration"
        fi
    fi
}

###############################################################################
# Package Lists
###############################################################################

get_required_packages() {
    if [[ -f "$PACKAGES_CONFIG" ]]; then
        get_packages_from_config "$PACKAGES_CONFIG" "required_packages"
    else
        echo "bash fzf neovim tmux vim zsh git curl wget"
    fi
}

get_formula_packages() {
    if [[ -f "$PACKAGES_CONFIG" ]]; then
        get_packages_from_config "$PACKAGES_CONFIG" "formula_packages"
    elif [[ -f "$SCRIPT_DIR/brew/application.sh" ]]; then
        # Extract packages from the existing file
        grep -E '^\s*"[^"]+"\s*$' "$SCRIPT_DIR/brew/application.sh" | \
            sed 's/^[[:space:]]*"//' | sed 's/"[[:space:]]*$//' | \
            grep -v '^$' | sort -u | tr '\n' ' '
    else
        echo "ansible awscli bash bat bazelisk cmake curl fish fzf gcc gh git go helm htop httpie k9s kubernetes-cli lazydocker lazygit neovim node nvm rust telnet terraform thefuck tmux unzip vim wget zsh zoxide"
    fi
}

get_cask_packages() {
    if [[ -f "$PACKAGES_CONFIG" ]]; then
        get_packages_from_config "$PACKAGES_CONFIG" "cask_packages"
    elif [[ -f "$SCRIPT_DIR/brew/application.sh" ]]; then
        # Extract cask packages from the existing file
        local in_cask_section=false
        while IFS= read -r line; do
            if [[ $line =~ ^cask_packages= ]]; then
                in_cask_section=true
                continue
            elif [[ $in_cask_section == true ]]; then
                if [[ $line =~ ^\) ]]; then
                    break
                elif [[ $line =~ ^\"(.+)\"$ ]]; then
                    echo "${BASH_REMATCH[1]}"
                fi
            fi
        done < "$SCRIPT_DIR/brew/application.sh" | tr '\n' ' '
    else
        echo "alacritty alt-tab brave-browser discord docker google-chrome iterm2 notion slack spotify visual-studio-code"
    fi
}

###############################################################################
# Main Installation Functions
###############################################################################

validate_environment() {
    log_info "Validating environment..."
    
    # Check for required commands
    local required_commands=("git" "curl")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            log_error "Required command not found: $cmd"
            return 1
        fi
    done
    
    # Check OS support
    local os_type
    os_type=$(detect_os)
    if [[ $os_type == "unknown" ]]; then
        log_error "Unsupported operating system: $(uname -s)"
        return 1
    fi
    
    log_info "Environment validation passed"
    log_info "OS: $os_type"
    log_info "Architecture: $(detect_architecture)"
    return 0
}

install_packages() {
    local os_type
    os_type=$(detect_os)
    
    # Install Homebrew
    install_homebrew
    
    # Required packages
    log_info "Installing required packages..."
    read -ra required_packages <<< "$(get_required_packages)"
    install_packages_from_list "required" "--formula" "${required_packages[@]}"
    
    # Formula packages
    log_info "Installing formula packages..."
    read -ra formula_packages <<< "$(get_formula_packages)"
    install_packages_from_list "formula" "--formula" "${formula_packages[@]}"
    
    # Cask packages (macOS only)
    if [[ $os_type == "macos" ]]; then
        log_info "Installing cask packages..."
        read -ra cask_packages <<< "$(get_cask_packages)"
        install_packages_from_list "cask" "--cask" "${cask_packages[@]}"
    else
        log_info "Skipping cask packages (not on macOS)"
    fi
}

setup_configurations() {
    log_info "Setting up configurations..."
    
    # Setup shell configurations
    setup_oh_my_zsh
    setup_zsh_plugins
    setup_zsh_config
    
    # Setup terminal multiplexer
    setup_tmux
    
    # Setup editors
    setup_vim_neovim
}

cleanup() {
    if command_exists brew; then
        log_info "Running Homebrew cleanup..."
        if [[ $DRY_RUN_MODE == false ]]; then
            brew cleanup || log_warn "Homebrew cleanup failed"
        else
            log_info "[DRY RUN] Would run brew cleanup"
        fi
    fi
}

###############################################################################
# Argument Parsing
###############################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -u|--upgrade)
                UPGRADE_MODE=true
                export UPGRADE_MODE
                shift
                ;;
            -v|--verbose)
                VERBOSE_MODE=true
                export VERBOSE_MODE
                if [[ "${MODULAR_MODE}" != "true" ]]; then
                    LOG_LEVEL=$LOG_DEBUG
                fi
                shift
                ;;
            -d|--dry-run)
                DRY_RUN_MODE=true
                export DRY_RUN_MODE
                shift
                ;;
            -q|--quiet)
                QUIET_MODE=true
                export QUIET_MODE
                shift
                ;;
            -l|--log-file)
                if [[ -n "${2:-}" ]]; then
                    LOG_FILE="$2"
                    export LOG_FILE
                    shift 2
                else
                    echo "Error: --log-file requires a filename argument" >&2
                    exit 1
                fi
                ;;
            --version)
                if [[ "${MODULAR_MODE}" == "true" ]]; then
                    echo "Enhanced Dotfiles Setup v${DOTFILES_VERSION}"
                else
                    echo "Enhanced Dotfiles Setup v1.0.0 (Legacy Mode)"
                fi
                echo "OS: $(uname -s) $(uname -m)"
                exit 0
                ;;
            -h|--help)
                if [[ "${MODULAR_MODE}" == "true" ]]; then
                    print_help
                else
                    legacy_print_help
                fi
                exit 0
                ;;
            *)
                echo "Error: Unknown argument: $1" >&2
                echo
                if [[ "${MODULAR_MODE}" == "true" ]]; then
                    print_help
                else
                    legacy_print_help
                fi
                exit 1
                ;;
        esac
    done
}

###############################################################################
# Legacy Functions (for compatibility)
###############################################################################

legacy_print_help() {
    cat << 'EOF'
Enhanced Dotfiles Setup Script

USAGE:
    ./setup.sh [OPTIONS]

OPTIONS:
    -u, --upgrade    Upgrade existing packages and configurations
    -v, --verbose    Enable verbose logging
    -d, --dry-run    Show what would be installed without making changes
    -h, --help       Show this help message

EXAMPLES:
    ./setup.sh                    # Basic installation
    ./setup.sh --upgrade          # Upgrade existing setup
    ./setup.sh --verbose          # Verbose output
    ./setup.sh --dry-run          # Preview changes

EOF
}

legacy_main() {
    # Set up error handling
    trap 'echo "Error: Setup failed at line $LINENO" >&2' ERR
    
    # Print banner
    if [[ -n "$(type -t print_banner 2>/dev/null)" ]]; then
        print_banner
    else
        echo "Enhanced Dotfiles Setup"
        echo "======================="
    fi
    
    # Show current settings
    echo "Running with the following settings:"
    echo "  Upgrade mode: $UPGRADE_MODE"
    echo "  Verbose mode: $VERBOSE_MODE"
    echo "  Dry run mode: $DRY_RUN_MODE"
    echo "  Dotfiles directory: ${DOTFILES_DIR:-$SCRIPT_DIR}"
    echo
    
    # Validate environment
    if ! validate_environment; then
        echo "Error: Environment validation failed" >&2
        exit 1
    fi
    
    # Main installation steps
    echo "Starting dotfiles setup..."
    
    install_packages
    setup_configurations
    cleanup
    
    # Success message
    echo
    echo "🎉 Dotfiles setup completed successfully!"
    
    if [[ $DRY_RUN_MODE == true ]]; then
        echo
        echo "This was a dry run. No actual changes were made."
        echo "Run without --dry-run to apply the changes."
    else
        echo
        echo "You may need to:"
        echo "  • Restart your terminal or run 'source ~/.zshrc'"
        echo "  • Install Tmux plugins by pressing 'prefix + I' in tmux"
        echo "  • Open Neovim and run ':Lazy sync' to install plugins"
    fi
}

###############################################################################
# Main Function
###############################################################################

main() {
    # Parse command line arguments first
    parse_arguments "$@"
    
    if [[ "${MODULAR_MODE}" == "true" ]]; then
        # Use the new modular setup
        main_setup
    else
        # Use legacy setup for backward compatibility
        legacy_main
    fi
}

# Run main function with all arguments
main "$@"
