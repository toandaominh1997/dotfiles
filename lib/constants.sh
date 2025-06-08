#!/usr/bin/env bash

###############################################################################
# Constants and Global Configuration
# 
# This file contains all constants, URLs, paths, and global configuration
# used throughout the dotfiles setup system.
###############################################################################

# Prevent multiple inclusions
if [[ -n "${DOTFILES_CONSTANTS_LOADED:-}" ]]; then
    return 0
fi
readonly DOTFILES_CONSTANTS_LOADED=true

# Strict error handling
set -euo pipefail

# ==============================================================================
# Directory Structure
# ==============================================================================

# Only set if not already defined (avoid readonly variable errors)
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ -z "${ROOT_DIR:-}" ]]; then
    readonly ROOT_DIR="$SCRIPT_DIR"
fi

if [[ -z "${DOTFILES_DIR:-}" ]]; then
    readonly DOTFILES_DIR="$(dirname "$ROOT_DIR")"
fi

# Configuration directories
if [[ -z "${CONFIG_DIR:-}" ]]; then
    readonly CONFIG_DIR="$ROOT_DIR/config"
fi
if [[ -z "${LIB_DIR:-}" ]]; then
    readonly LIB_DIR="$ROOT_DIR/lib"
fi
if [[ -z "${SCRIPTS_DIR:-}" ]]; then
    readonly SCRIPTS_DIR="$ROOT_DIR/scripts"
fi
if [[ -z "${TEMPLATES_DIR:-}" ]]; then
    readonly TEMPLATES_DIR="$ROOT_DIR/templates"
fi
if [[ -z "${TESTS_DIR:-}" ]]; then
    readonly TESTS_DIR="$ROOT_DIR/tests"
fi

# User directories
if [[ -z "${USER_HOME:-}" ]]; then
    readonly USER_HOME="$HOME"
fi
if [[ -z "${USER_CONFIG_DIR:-}" ]]; then
    readonly USER_CONFIG_DIR="$USER_HOME/.config"
fi
if [[ -z "${DOTFILES_INSTALL_DIR:-}" ]]; then
    readonly DOTFILES_INSTALL_DIR="$USER_HOME/.dotfiles"
fi
if [[ -z "${BACKUP_DIR:-}" ]]; then
    readonly BACKUP_DIR="$USER_HOME/.dotfiles-backup"
fi

# ==============================================================================
# Application Paths
# ==============================================================================

readonly ZSH_DIR="$ROOT_DIR/zsh"
readonly VIM_DIR="$ROOT_DIR/vim"
readonly TMUX_DIR="$ROOT_DIR/tmux"
readonly FISH_DIR="$ROOT_DIR/fish"
readonly STARSHIP_DIR="$ROOT_DIR/starship"
readonly WEZTERM_DIR="$ROOT_DIR/wezterm"

# ==============================================================================
# Configuration Files
# ==============================================================================

readonly PACKAGES_CONFIG="$CONFIG_DIR/packages.conf"
readonly SYSTEM_CONFIG="$CONFIG_DIR/system.conf"
readonly USER_CONFIG="$CONFIG_DIR/user.conf"

# ==============================================================================
# External Repository URLs
# ==============================================================================

readonly BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
readonly OH_MY_ZSH_REPO="https://github.com/robbyrussell/oh-my-zsh.git"
readonly NVCHAD_STARTER_REPO="https://github.com/NvChad/starter"
readonly TMUX_PLUGIN_MANAGER_REPO="https://github.com/tmux-plugins/tpm"

# ==============================================================================
# Default Plugin Repositories
# ==============================================================================

readonly ZSH_SYNTAX_HIGHLIGHTING_REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"
readonly ZSH_AUTOSUGGESTIONS_REPO="https://github.com/zsh-users/zsh-autosuggestions.git"
readonly ZSH_COMPLETIONS_REPO="https://github.com/zsh-users/zsh-completions.git"
readonly ZSH_HISTORY_SUBSTRING_SEARCH_REPO="https://github.com/zsh-users/zsh-history-substring-search.git"
readonly ZSH_INTERACTIVE_CD_REPO="https://github.com/changyuheng/zsh-interactive-cd.git"
readonly POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"

# ==============================================================================
# Log Levels and Colors
# ==============================================================================

readonly LOG_ERROR=1
readonly LOG_WARN=2
readonly LOG_INFO=3
readonly LOG_DEBUG=4

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m' # No Color

# Unicode symbols
readonly CHECK_MARK="✓"
readonly CROSS_MARK="✗"
readonly WARNING_SIGN="⚠"
readonly INFO_SIGN="ℹ"
readonly ARROW_RIGHT="→"
readonly BULLET="•"

# ==============================================================================
# System Detection
# ==============================================================================

readonly OS_TYPE="$(uname -s)"
readonly ARCH_TYPE="$(uname -m)"

# OS-specific constants
case "$OS_TYPE" in
    Darwin)
        readonly IS_MACOS=true
        readonly IS_LINUX=false
        readonly BREW_PREFIX="/opt/homebrew"
        readonly PACKAGE_MANAGER="brew"
        ;;
    Linux)
        readonly IS_MACOS=false
        readonly IS_LINUX=true
        readonly BREW_PREFIX="/home/linuxbrew/.linuxbrew"
        readonly PACKAGE_MANAGER="auto-detect"
        ;;
    *)
        readonly IS_MACOS=false
        readonly IS_LINUX=false
        readonly BREW_PREFIX=""
        readonly PACKAGE_MANAGER="unknown"
        ;;
esac

# ==============================================================================
# Default Configuration Values
# ==============================================================================

readonly DEFAULT_SHELL="zsh"
readonly DEFAULT_EDITOR="nvim"
readonly DEFAULT_TERMINAL="wezterm"
readonly DEFAULT_THEME="powerlevel10k"

# ==============================================================================
# Feature Flags
# ==============================================================================

readonly ENABLE_BACKUP=true
readonly ENABLE_DRY_RUN=true
readonly ENABLE_VERBOSE_MODE=true
readonly ENABLE_COLOR_OUTPUT=true
readonly ENABLE_UNICODE_SYMBOLS=true

# ==============================================================================
# Timeouts and Limits
# ==============================================================================

readonly NETWORK_TIMEOUT=30
readonly MAX_RETRY_ATTEMPTS=3
readonly BACKUP_RETENTION_DAYS=30

# ==============================================================================
# Version Information
# ==============================================================================

readonly DOTFILES_VERSION="2.0.0"
readonly MIN_BASH_VERSION="4.0"
readonly MIN_ZSH_VERSION="5.0"

# ==============================================================================
# Export all constants for global access
# ==============================================================================

export SCRIPT_DIR ROOT_DIR DOTFILES_DIR
export CONFIG_DIR LIB_DIR SCRIPTS_DIR TEMPLATES_DIR TESTS_DIR
export USER_HOME USER_CONFIG_DIR DOTFILES_INSTALL_DIR BACKUP_DIR
export ZSH_DIR VIM_DIR TMUX_DIR FISH_DIR STARSHIP_DIR WEZTERM_DIR
export PACKAGES_CONFIG SYSTEM_CONFIG USER_CONFIG
export BREW_INSTALL_URL OH_MY_ZSH_REPO NVCHAD_STARTER_REPO TMUX_PLUGIN_MANAGER_REPO
export LOG_ERROR LOG_WARN LOG_INFO LOG_DEBUG
export RED GREEN YELLOW BLUE PURPLE CYAN WHITE BOLD DIM NC
export CHECK_MARK CROSS_MARK WARNING_SIGN INFO_SIGN ARROW_RIGHT BULLET
export OS_TYPE ARCH_TYPE IS_MACOS IS_LINUX BREW_PREFIX PACKAGE_MANAGER
export DEFAULT_SHELL DEFAULT_EDITOR DEFAULT_TERMINAL DEFAULT_THEME
export ENABLE_BACKUP ENABLE_DRY_RUN ENABLE_VERBOSE_MODE ENABLE_COLOR_OUTPUT ENABLE_UNICODE_SYMBOLS
export NETWORK_TIMEOUT MAX_RETRY_ATTEMPTS BACKUP_RETENTION_DAYS
export DOTFILES_VERSION MIN_BASH_VERSION MIN_ZSH_VERSION 