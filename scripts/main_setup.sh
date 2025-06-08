#!/usr/bin/env bash

###############################################################################
# Main Setup Orchestrator
# 
# This script coordinates the entire dotfiles setup process, including:
# - System validation and preparation
# - Package manager installation
# - Package and plugin installation
# - Configuration file deployment
# - Shell and environment setup
###############################################################################

set -euo pipefail

# ==============================================================================
# Load Dependencies
# ==============================================================================

# Use existing SCRIPT_DIR if available, otherwise calculate it
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ -z "${ROOT_DIR:-}" ]]; then
    readonly ROOT_DIR="$(dirname "$SCRIPT_DIR")"
fi

# Calculate proper root directory from scripts location
readonly MAIN_ROOT_DIR="$(dirname "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)")"

# Source all library modules
# shellcheck source=../lib/constants.sh
source "$MAIN_ROOT_DIR/lib/constants.sh"

# shellcheck source=../lib/logging.sh  
source "$MAIN_ROOT_DIR/lib/logging.sh"

# shellcheck source=../lib/system.sh
source "$MAIN_ROOT_DIR/lib/system.sh"

# shellcheck source=../lib/package_manager.sh
source "$MAIN_ROOT_DIR/lib/package_manager.sh"

# ==============================================================================
# Global Configuration
# ==============================================================================

# Default options (can be overridden by command line)
UPGRADE_MODE=${UPGRADE_MODE:-false}
VERBOSE_MODE=${VERBOSE_MODE:-false}
DRY_RUN_MODE=${DRY_RUN_MODE:-false}
QUIET_MODE=${QUIET_MODE:-false}
LOG_FILE=${LOG_FILE:-}

# ==============================================================================
# Setup Functions
# ==============================================================================

# Pre-flight checks and system validation
validate_system() {
    print_section "System Validation"
    
    # Check basic requirements
    log_info "Checking system requirements..."
    
    # Verify we're not running as root
    if is_root; then
        die "This script should not be run as root. Please run as a regular user."
    fi
    
    # Check internet connectivity
    if ! check_internet 10; then
        die "Internet connection is required for installation. Please check your connection."
    fi
    
    # Check available disk space (at least 1GB free)
    local available_space
    if command_exists df; then
        available_space=$(df / | awk 'NR==2 {print $4}')
        if [[ $available_space -lt 1048576 ]]; then  # 1GB in KB
            warn "Low disk space detected. Installation may fail."
        fi
    fi
    
    # Display system information
    log_info "System Information:"
    get_system_info | while IFS= read -r line; do
        log_info "  $line"
    done
    
    # Check shell compatibility
    local current_shell
    current_shell="$(get_user_shell)"
    log_info "Current shell: $current_shell"
    
    if [[ "$current_shell" != "zsh" ]] && [[ "$current_shell" != "bash" ]]; then
        warn "Unsupported shell: $current_shell. Some features may not work correctly."
    fi
    
    log_success "System validation complete"
}

# Setup package managers
setup_package_managers() {
    print_section "Package Manager Setup"
    
    local pm
    pm="$(detect_package_manager)"
    
    case "$pm" in
        "none"|"unknown")
            log_info "No package manager detected, installing Homebrew..."
            install_homebrew || die "Failed to install Homebrew"
            ;;
        "brew")
            log_info "Homebrew detected"
            ;;
        *)
            log_info "Package manager detected: $pm"
            ;;
    esac
    
    # Update package manager
    update_package_manager || warn "Failed to update package manager"
    
    log_success "Package manager setup complete"
}

# Install core packages
install_core_packages() {
    print_section "Core Package Installation"
    
    # Ensure package configuration exists
    if [[ ! -f "$PACKAGES_CONFIG" ]]; then
        die "Package configuration not found: $PACKAGES_CONFIG"
    fi
    
    # Install packages from configuration
    install_packages_from_config "$PACKAGES_CONFIG" "$UPGRADE_MODE" || {
        warn "Some packages failed to install. Continuing with setup..."
    }
    
    log_success "Core package installation complete"
}

# Setup shell environment
setup_shell_environment() {
    print_section "Shell Environment Setup"
    
    # Install Oh My Zsh
    install_oh_my_zsh || warn "Failed to install Oh My Zsh"
    
    # Install Zsh plugins
    local zsh_plugins_dir="$DOTFILES_INSTALL_DIR/oh-my-zsh/custom/plugins"
    ensure_dir "$zsh_plugins_dir"
    
    install_plugins_from_config "$PACKAGES_CONFIG" "zsh_plugins" "$zsh_plugins_dir" || {
        warn "Some Zsh plugins failed to install"
    }
    
    # Install themes
    local zsh_themes_dir="$DOTFILES_INSTALL_DIR/oh-my-zsh/custom/themes"
    ensure_dir "$zsh_themes_dir"
    
    install_plugins_from_config "$PACKAGES_CONFIG" "themes" "$zsh_themes_dir" || {
        warn "Some themes failed to install"
    }
    
    log_success "Shell environment setup complete"
}

# Setup terminal multiplexer
setup_tmux() {
    print_section "Tmux Setup"
    
    # Install Tmux Plugin Manager
    install_tmux_plugin_manager || warn "Failed to install Tmux Plugin Manager"
    
    # Install Tmux plugins
    local tmux_plugins_dir="$HOME/.tmux/plugins"
    ensure_dir "$tmux_plugins_dir"
    
    install_plugins_from_config "$PACKAGES_CONFIG" "tmux_plugins" "$tmux_plugins_dir" || {
        warn "Some Tmux plugins failed to install"
    }
    
    log_success "Tmux setup complete"
}

# Setup editor environment
setup_editor() {
    print_section "Editor Setup"
    
    # Check if Neovim is available
    if command_exists nvim; then
        log_info "Setting up Neovim with NvChad..."
        install_nvchad || warn "Failed to install NvChad"
    else
        log_warn "Neovim not found. Skipping NvChad installation."
    fi
    
    log_success "Editor setup complete"
}

# Deploy configuration files
deploy_configurations() {
    print_section "Configuration Deployment"
    
    # Create symlinks for configuration files
    local configs=(
        "$ZSH_DIR/config.zsh:$HOME/.zshrc"
        "$TMUX_DIR/config.tmux:$HOME/.tmux.conf"
        "$VIM_DIR/config.vim:$HOME/.vimrc"
        "$VIM_DIR/ideavimrc.vim:$HOME/.ideavimrc"
        "$STARSHIP_DIR/starship.toml:$USER_CONFIG_DIR/starship.toml"
        "$WEZTERM_DIR/wezterm.lua:$USER_CONFIG_DIR/wezterm/wezterm.lua"
    )
    
    for config in "${configs[@]}"; do
        local source="${config%%:*}"
        local target="${config#*:}"
        
        if [[ -f "$source" ]]; then
            create_symlink "$source" "$target" true || {
                warn "Failed to create symlink: $target"
            }
        else
            log_debug "Source file not found, skipping: $source"
        fi
    done
    
    # Create Fish config if Fish is installed
    if command_exists fish; then
        local fish_config="$FISH_DIR/config.fish"
        local fish_target="$USER_CONFIG_DIR/fish/config.fish"
        
        if [[ -f "$fish_config" ]]; then
            create_symlink "$fish_config" "$fish_target" true || {
                warn "Failed to create Fish config symlink"
            }
        fi
    fi
    
    log_success "Configuration deployment complete"
}

# Post-installation setup and verification
post_installation_setup() {
    print_section "Post-Installation Setup"
    
    # Set Zsh as default shell if it's not already
    if [[ "$(get_user_shell)" != "zsh" ]] && command_exists zsh; then
        log_info "Setting Zsh as default shell..."
        
        if [[ "${DRY_RUN_MODE}" == "true" ]]; then
            log_dry_run "Would set Zsh as default shell"
        else
            local zsh_path
            zsh_path="$(command -v zsh)"
            
            # Add Zsh to /etc/shells if not present
            if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
                echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
            fi
            
            # Change default shell
            sudo chsh -s "$zsh_path" "$USER" || {
                warn "Failed to change default shell. You may need to do this manually."
            }
        fi
    fi
    
    # Initialize Homebrew environment
    if [[ "$IS_MACOS" == "true" ]] && [[ -x "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ "$IS_LINUX" == "true" ]] && [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    
    # Source Zsh configuration to test it
    if [[ -f "$HOME/.zshrc" ]] && [[ "${DRY_RUN_MODE}" != "true" ]]; then
        log_info "Testing Zsh configuration..."
        if zsh -c "source $HOME/.zshrc && echo 'Zsh configuration loaded successfully'" 2>/dev/null; then
            log_success "Zsh configuration is valid"
        else
            warn "Zsh configuration may have issues"
        fi
    fi
    
    log_success "Post-installation setup complete"
}

# Cleanup temporary files and optimize
cleanup_and_optimize() {
    print_section "Cleanup and Optimization"
    
    # Clean package cache
    clean_package_cache || warn "Failed to clean package cache"
    
    # Remove old backup files (older than retention period)
    if [[ -d "$BACKUP_DIR" ]] && [[ "${DRY_RUN_MODE}" != "true" ]]; then
        log_info "Cleaning old backup files..."
        find "$BACKUP_DIR" -name "*.backup.*" -mtime +$BACKUP_RETENTION_DAYS -delete 2>/dev/null || true
    fi
    
    # Compile Zsh completions if available
    if command_exists zsh && [[ -f "$HOME/.zshrc" ]] && [[ "${DRY_RUN_MODE}" != "true" ]]; then
        log_info "Compiling Zsh completions..."
        zsh -c "autoload -U compinit && compinit" 2>/dev/null || true
    fi
    
    log_success "Cleanup and optimization complete"
}

# ==============================================================================
# Main Setup Orchestrator
# ==============================================================================

# Main setup function that coordinates everything
main_setup() {
    local start_time
    start_time=$(date +%s.%N)
    
    print_banner
    
    # Display current configuration
    if [[ "${VERBOSE_MODE}" == "true" ]]; then
        debug_vars
    fi
    
    log_info "Starting dotfiles setup..."
    log_info "Mode: $(if [[ "${DRY_RUN_MODE}" == "true" ]]; then echo "DRY RUN"; else echo "LIVE"; fi)"
    log_info "Upgrade: $UPGRADE_MODE"
    
    # Execute setup phases
    start_timer "total_setup"
    
    validate_system
    setup_package_managers
    install_core_packages
    setup_shell_environment
    setup_tmux
    setup_editor
    deploy_configurations
    post_installation_setup
    cleanup_and_optimize
    
    end_timer "total_setup"
    
    # Calculate and display total time
    local end_time
    end_time=$(date +%s.%N)
    local duration
    duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "unknown")
    
    print_section "Setup Complete!"
    
    log_success "Dotfiles setup completed successfully in ${duration}s"
    
    if [[ "${DRY_RUN_MODE}" == "true" ]]; then
        echo
        log_info "This was a dry run. No changes were made to your system."
        log_info "Run without --dry-run to perform the actual installation."
    else
        echo
        log_info "Next steps:"
        log_info "1. Restart your terminal or run: source ~/.zshrc"
        log_info "2. Install Tmux plugins: Press Ctrl+a then I in tmux"
        log_info "3. Configure Neovim: Run 'nvim' and let plugins install"
        log_info "4. Customize settings in ~/.zshrc, ~/.tmux.conf, etc."
    fi
    
    echo
    log_info "For help and troubleshooting, see: https://github.com/toandaominh1997/dotfiles"
}

# Error handler
handle_error() {
    local exit_code=$?
    local line_number=$1
    
    log_error "Setup failed at line $line_number with exit code $exit_code"
    log_error "For troubleshooting help, check the logs or run with --verbose"
    
    exit $exit_code
}

# ==============================================================================
# Script Entry Point
# ==============================================================================

# Set up error handling
trap 'handle_error $LINENO' ERR

# Run main setup if this script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_setup "$@"
fi

# Export the main function for external use
export -f main_setup 