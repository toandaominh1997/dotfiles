#!/usr/bin/env bash

###############################################################################
# Enhanced Package Manager
# 
# This module provides a unified interface for package management across
# different platforms and package managers (Homebrew, apt, dnf, pacman, etc.)
###############################################################################

# Source dependencies
if [[ -z "${DOTFILES_VERSION:-}" ]]; then
    # shellcheck source=./constants.sh
    source "$(dirname "${BASH_SOURCE[0]}")/constants.sh"
fi

if [[ -z "$(type -t log_info 2>/dev/null)" ]]; then
    # shellcheck source=./logging.sh
    source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
fi

if [[ -z "$(type -t detect_os 2>/dev/null)" ]]; then
    # shellcheck source=./system.sh
    source "$(dirname "${BASH_SOURCE[0]}")/system.sh"
fi

if [[ -z "$(type -t parse_config_section 2>/dev/null)" ]]; then
    # shellcheck source=../utils/config_parser.sh
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/config_parser.sh"
fi

# ==============================================================================
# Package Manager Detection and Setup
# ==============================================================================

# Install Homebrew if not present
install_homebrew() {
    if command_exists brew; then
        log_info "Homebrew is already installed"
        return 0
    fi
    
    log_info "Installing Homebrew..."
    
    if [[ "${DRY_RUN_MODE}" == "true" ]]; then
        log_dry_run "Would install Homebrew from $BREW_INSTALL_URL"
        return 0
    fi
    
    # Check prerequisites
    if ! check_internet; then
        log_error "Internet connection required to install Homebrew"
        return 1
    fi
    
    # Download and install
    if download_file "$BREW_INSTALL_URL" "/tmp/brew_install.sh"; then
        chmod +x /tmp/brew_install.sh
        if /bin/bash /tmp/brew_install.sh; then
            log_success "Homebrew installed successfully"
            
            # Add to PATH
            if [[ "$IS_MACOS" == "true" ]]; then
                add_to_path "/opt/homebrew/bin" true
            elif [[ "$IS_LINUX" == "true" ]]; then
                add_to_path "/home/linuxbrew/.linuxbrew/bin" true
            fi
            
            # Clean up
            rm -f /tmp/brew_install.sh
            return 0
        else
            log_error "Failed to install Homebrew"
            rm -f /tmp/brew_install.sh
            return 1
        fi
    else
        log_error "Failed to download Homebrew installer"
        return 1
    fi
}

# Update package manager
update_package_manager() {
    local pm
    pm="$(detect_package_manager)"
    
    log_info "Updating package manager: $pm"
    
    if [[ "${DRY_RUN_MODE}" == "true" ]]; then
        log_dry_run "Would update package manager: $pm"
        return 0
    fi
    
    case "$pm" in
        brew)
            brew update
            ;;
        apt)
            sudo apt update
            ;;
        dnf)
            sudo dnf check-update || true  # Don't fail on available updates
            ;;
        yum)
            sudo yum check-update || true
            ;;
        pacman)
            sudo pacman -Sy
            ;;
        zypper)
            sudo zypper refresh
            ;;
        *)
            log_warn "Unknown package manager: $pm"
            return 1
            ;;
    esac
}

# ==============================================================================
# Package Installation Functions
# ==============================================================================

# Install a single package
install_package() {
    local package="$1"
    local package_type="${2:-formula}"  # formula, cask, or auto
    local upgrade_mode="${3:-false}"
    
    if [[ -z "$package" ]]; then
        log_error "Package name cannot be empty"
        return 1
    fi
    
    local pm
    pm="$(detect_package_manager)"
    
    log_debug "Installing package: $package (type: $package_type, pm: $pm)"
    
    # Check if already installed
    if package_installed "$package"; then
        if [[ "$upgrade_mode" == "true" ]]; then
            log_info "Upgrading package: $package"
            upgrade_package "$package" "$package_type"
        else
            log_info "Package already installed: $package"
        fi
        return 0
    fi
    
    log_info "Installing package: $package"
    
    if [[ "${DRY_RUN_MODE}" == "true" ]]; then
        log_dry_run "Would install package: $package"
        return 0
    fi
    
    case "$pm" in
        brew)
            if [[ "$package_type" == "cask" ]]; then
                brew install --cask "$package"
            else
                brew install "$package"
            fi
            ;;
        apt)
            sudo apt install -y "$package"
            ;;
        dnf)
            sudo dnf install -y "$package"
            ;;
        yum)
            sudo yum install -y "$package"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$package"
            ;;
        zypper)
            sudo zypper install -y "$package"
            ;;
        *)
            log_error "Unsupported package manager: $pm"
            return 1
            ;;
    esac
    
    # Verify installation
    if package_installed "$package"; then
        log_success "Successfully installed: $package"
    else
        log_error "Failed to install: $package"
        return 1
    fi
}

# Upgrade a single package
upgrade_package() {
    local package="$1"
    local package_type="${2:-formula}"
    
    local pm
    pm="$(detect_package_manager)"
    
    log_info "Upgrading package: $package"
    
    if [[ "${DRY_RUN_MODE}" == "true" ]]; then
        log_dry_run "Would upgrade package: $package"
        return 0
    fi
    
    case "$pm" in
        brew)
            if [[ "$package_type" == "cask" ]]; then
                brew upgrade --cask "$package" 2>/dev/null || log_warn "Could not upgrade cask: $package"
            else
                brew upgrade "$package"
            fi
            ;;
        apt)
            sudo apt upgrade -y "$package"
            ;;
        dnf)
            sudo dnf update -y "$package"
            ;;
        yum)
            sudo yum update -y "$package"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$package"
            ;;
        zypper)
            sudo zypper update -y "$package"
            ;;
        *)
            log_error "Unsupported package manager: $pm"
            return 1
            ;;
    esac
}

# ==============================================================================
# Batch Package Operations
# ==============================================================================

# Install packages from array
install_package_list() {
    local -a all_args=("$@")
    local total_args=${#all_args[@]}
    
    # Get package_type and upgrade_mode from last two arguments
    local package_type="${all_args[$((total_args-2))]}"
    local upgrade_mode="${all_args[$((total_args-1))]}"
    
    # Build packages array without the last two arguments
    local -a packages=()
    local i=0
    while [[ $i -lt $((total_args-2)) ]]; do
        packages[i]="${all_args[i]}"
        ((i++))
    done
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_debug "No packages to install"
        return 0
    fi
    
    log_info "Installing ${#packages[@]} packages (type: $package_type)"
    
    local success_count=0
    local failure_count=0
    local total=${#packages[@]}
    local current=0
    
    for package in "${packages[@]}"; do
        ((current++))
        print_progress "$current" "$total" "Installing $package"
        
        if install_package "$package" "$package_type" "$upgrade_mode"; then
            ((success_count++))
        else
            ((failure_count++))
            log_error "Failed to install: $package"
        fi
    done
    
    echo  # New line after progress
    log_info "Package installation complete: $success_count successful, $failure_count failed"
    
    if [[ $failure_count -gt 0 ]]; then
        return 1
    fi
}

# Install packages from configuration
install_packages_from_config() {
    local config_file="$1"
    local upgrade_mode="${2:-false}"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    log_info "Installing packages from configuration: $(basename "$config_file")"
    
    # Required packages first
    local required_packages
    required_packages=($(get_packages_from_config "$config_file" "required_packages"))
    if [[ ${#required_packages[@]} -gt 0 ]]; then
        print_subsection "Required Packages"
        install_package_list "${required_packages[@]}" "formula" "$upgrade_mode"
    fi
    
    # Formula packages
    local formula_packages
    formula_packages=($(get_packages_from_config "$config_file" "formula_packages"))
    if [[ ${#formula_packages[@]} -gt 0 ]]; then
        print_subsection "Formula Packages"
        install_package_list "${formula_packages[@]}" "formula" "$upgrade_mode"
    fi
    
    # Cask packages (macOS only)
    if [[ "$IS_MACOS" == "true" ]]; then
        local cask_packages
        cask_packages=($(get_packages_from_config "$config_file" "cask_packages"))
        if [[ ${#cask_packages[@]} -gt 0 ]]; then
            print_subsection "Cask Packages"
            install_package_list "${cask_packages[@]}" "cask" "$upgrade_mode"
        fi
    fi
}

# ==============================================================================
# Plugin Management
# ==============================================================================

# Install a git-based plugin
install_git_plugin() {
    local plugin_name="$1"
    local plugin_url="$2"
    local target_dir="$3"
    local branch="${4:-}"
    
    log_info "Installing plugin: $plugin_name"
    
    if [[ "${DRY_RUN_MODE}" == "true" ]]; then
        log_dry_run "Would install plugin: $plugin_name from $plugin_url"
        return 0
    fi
    
    # Ensure target directory exists
    ensure_dir "$(dirname "$target_dir")"
    
    # Clone or update repository
    if clone_or_update_repo "$plugin_url" "$target_dir" "$branch"; then
        log_success "Successfully installed plugin: $plugin_name"
    else
        log_error "Failed to install plugin: $plugin_name"
        return 1
    fi
}

# Install plugins from configuration
install_plugins_from_config() {
    local config_file="$1"
    local section="$2"
    local base_dir="$3"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    log_info "Installing plugins from section: $section"
    
    local plugin_data
    plugin_data=$(get_plugins_from_config "$config_file" "$section")
    
    if [[ -z "$plugin_data" ]]; then
        log_debug "No plugins found in section: $section"
        return 0
    fi
    
    local success_count=0
    local failure_count=0
    
    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            continue
        fi
        
        local plugin_name="${line%%=*}"
        local plugin_url="${line#*=}"
        local target_dir="$base_dir/$plugin_name"
        
        if install_git_plugin "$plugin_name" "$plugin_url" "$target_dir"; then
            ((success_count++))
        else
            ((failure_count++))
        fi
    done <<< "$plugin_data"
    
    log_info "Plugin installation complete: $success_count successful, $failure_count failed"
    
    if [[ $failure_count -gt 0 ]]; then
        return 1
    fi
}

# ==============================================================================
# System-specific Package Managers
# ==============================================================================

# Install Oh My Zsh
install_oh_my_zsh() {
    local install_dir="$DOTFILES_INSTALL_DIR/oh-my-zsh"
    
    if [[ -d "$install_dir" ]]; then
        log_info "Oh My Zsh already installed"
        return 0
    fi
    
    log_info "Installing Oh My Zsh..."
    
    if [[ "${DRY_RUN_MODE}" == "true" ]]; then
        log_dry_run "Would install Oh My Zsh to $install_dir"
        return 0
    fi
    
    # Clone Oh My Zsh repository
    if clone_or_update_repo "$OH_MY_ZSH_REPO" "$install_dir"; then
        log_success "Oh My Zsh installed successfully"
    else
        log_error "Failed to install Oh My Zsh"
        return 1
    fi
}

# Install Tmux Plugin Manager
install_tmux_plugin_manager() {
    local install_dir="$HOME/.tmux/plugins/tpm"
    
    if [[ -d "$install_dir" ]]; then
        log_info "Tmux Plugin Manager already installed"
        return 0
    fi
    
    log_info "Installing Tmux Plugin Manager..."
    
    if [[ "${DRY_RUN_MODE}" == "true" ]]; then
        log_dry_run "Would install TPM to $install_dir"
        return 0
    fi
    
    # Clone TPM repository
    if clone_or_update_repo "$TMUX_PLUGIN_MANAGER_REPO" "$install_dir"; then
        log_success "Tmux Plugin Manager installed successfully"
    else
        log_error "Failed to install Tmux Plugin Manager"
        return 1
    fi
}

# Install NvChad
install_nvchad() {
    local nvim_config_dir="$USER_CONFIG_DIR/nvim"
    
    if [[ -d "$nvim_config_dir" ]]; then
        log_info "Neovim configuration already exists"
        if [[ "${DRY_RUN_MODE}" != "true" ]]; then
            backup_file "$nvim_config_dir"
        fi
    fi
    
    log_info "Installing NvChad..."
    
    if [[ "${DRY_RUN_MODE}" == "true" ]]; then
        log_dry_run "Would install NvChad to $nvim_config_dir"
        return 0
    fi
    
    # Remove existing config if present
    if [[ -d "$nvim_config_dir" ]]; then
        rm -rf "$nvim_config_dir"
    fi
    
    # Clone NvChad starter
    if clone_or_update_repo "$NVCHAD_STARTER_REPO" "$nvim_config_dir"; then
        log_success "NvChad installed successfully"
    else
        log_error "Failed to install NvChad"
        return 1
    fi
}

# ==============================================================================
# Maintenance and Cleanup
# ==============================================================================

# Upgrade all packages
upgrade_all_packages() {
    local pm
    pm="$(detect_package_manager)"
    
    log_info "Upgrading all packages with $pm"
    
    if [[ "${DRY_RUN_MODE}" == "true" ]]; then
        log_dry_run "Would upgrade all packages"
        return 0
    fi
    
    case "$pm" in
        brew)
            brew upgrade
            ;;
        apt)
            sudo apt upgrade -y
            ;;
        dnf)
            sudo dnf update -y
            ;;
        yum)
            sudo yum update -y
            ;;
        pacman)
            sudo pacman -Syu --noconfirm
            ;;
        zypper)
            sudo zypper update -y
            ;;
        *)
            log_error "Unsupported package manager: $pm"
            return 1
            ;;
    esac
}

# Clean package cache
clean_package_cache() {
    local pm
    pm="$(detect_package_manager)"
    
    log_info "Cleaning package cache for $pm"
    
    if [[ "${DRY_RUN_MODE}" == "true" ]]; then
        log_dry_run "Would clean package cache"
        return 0
    fi
    
    case "$pm" in
        brew)
            brew cleanup
            ;;
        apt)
            sudo apt autoremove -y
            sudo apt autoclean
            ;;
        dnf)
            sudo dnf autoremove -y
            sudo dnf clean all
            ;;
        yum)
            sudo yum autoremove -y
            sudo yum clean all
            ;;
        pacman)
            sudo pacman -Sc --noconfirm
            ;;
        zypper)
            sudo zypper clean -a
            ;;
        *)
            log_warn "Cache cleaning not supported for: $pm"
            ;;
    esac
}

# ==============================================================================
# Export Functions
# ==============================================================================

# Export all public functions
export -f install_homebrew update_package_manager
export -f install_package upgrade_package install_package_list install_packages_from_config
export -f install_git_plugin install_plugins_from_config
export -f install_oh_my_zsh install_tmux_plugin_manager install_nvchad
export -f upgrade_all_packages clean_package_cache 