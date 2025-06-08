#!/usr/bin/env bash

###############################################################################
# System Detection and Utilities
# 
# This module provides system detection, compatibility checks, and
# platform-specific utilities for cross-platform dotfiles setup.
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

# ==============================================================================
# System Detection Functions
# ==============================================================================

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        FreeBSD) echo "freebsd" ;;
        OpenBSD) echo "openbsd" ;;
        NetBSD) echo "netbsd" ;;
        *)      echo "unknown" ;;
    esac
}

# Detect architecture
detect_architecture() {
    case "$(uname -m)" in
        x86_64|amd64) echo "amd64" ;;
        arm64|aarch64) echo "arm64" ;;
        armv7l) echo "armv7" ;;
        i386|i686) echo "i386" ;;
        *)  echo "unknown" ;;
    esac
}

# Detect Linux distribution
detect_linux_distro() {
    if [[ "$(detect_os)" != "linux" ]]; then
        echo "unknown"
        return 1
    fi
    
    # Try various methods to detect distribution
    if command -v lsb_release >/dev/null 2>&1; then
        lsb_release -si | tr '[:upper:]' '[:lower:]'
    elif [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${ID:-unknown}"
    elif [[ -f /etc/redhat-release ]]; then
        echo "redhat"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# Detect package manager
detect_package_manager() {
    local os
    os="$(detect_os)"
    
    case "$os" in
        macos)
            if command -v brew >/dev/null 2>&1; then
                echo "brew"
            elif command -v port >/dev/null 2>&1; then
                echo "macports"
            else
                echo "none"
            fi
            ;;
        linux)
            local distro
            distro="$(detect_linux_distro)"
            
            case "$distro" in
                ubuntu|debian|pop)
                    echo "apt"
                    ;;
                fedora|centos|rhel)
                    if command -v dnf >/dev/null 2>&1; then
                        echo "dnf"
                    elif command -v yum >/dev/null 2>&1; then
                        echo "yum"
                    else
                        echo "none"
                    fi
                    ;;
                arch|manjaro)
                    echo "pacman"
                    ;;
                opensuse*)
                    echo "zypper"
                    ;;
                *)
                    if command -v brew >/dev/null 2>&1; then
                        echo "brew"
                    else
                        echo "none"
                    fi
                    ;;
            esac
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# ==============================================================================
# System Requirements Checking
# ==============================================================================

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if package is installed (generic)
package_installed() {
    local package="$1"
    local package_manager
    package_manager="$(detect_package_manager)"
    
    case "$package_manager" in
        brew)
            brew list "$package" &>/dev/null
            ;;
        apt)
            dpkg -l "$package" 2>/dev/null | grep -q "^ii"
            ;;
        dnf|yum)
            rpm -q "$package" &>/dev/null
            ;;
        pacman)
            pacman -Q "$package" &>/dev/null
            ;;
        zypper)
            zypper search -i "$package" | grep -q "^i"
            ;;
        *)
            log_warn "Cannot check package installation for package manager: $package_manager"
            return 1
            ;;
    esac
}

# Check minimum version requirement
check_version() {
    local current="$1"
    local required="$2"
    
    # Use sort -V for version comparison if available
    if command -v sort >/dev/null 2>&1; then
        local highest
        highest=$(printf '%s\n%s\n' "$current" "$required" | sort -V | tail -n1)
        [[ "$highest" == "$current" ]]
    else
        # Fallback to simple string comparison
        log_warn "Version comparison not available, using string comparison"
        [[ "$current" == "$required" ]] || [[ "$current" > "$required" ]]
    fi
}

# Check if running as root
is_root() {
    [[ $EUID -eq 0 ]]
}

# Check if running with sudo
has_sudo() {
    sudo -n true 2>/dev/null
}

# ==============================================================================
# System Information Functions
# ==============================================================================

# Get system information
get_system_info() {
    local os arch distro package_manager
    
    os="$(detect_os)"
    arch="$(detect_architecture)"
    package_manager="$(detect_package_manager)"
    
    echo "Operating System: $os"
    echo "Architecture: $arch"
    
    if [[ "$os" == "linux" ]]; then
        distro="$(detect_linux_distro)"
        echo "Distribution: $distro"
    fi
    
    echo "Package Manager: $package_manager"
    
    # System resources
    if command -v free >/dev/null 2>&1; then
        local memory
        memory=$(free -h | awk '/^Mem:/ {print $2}')
        echo "Memory: $memory"
    fi
    
    if command -v df >/dev/null 2>&1; then
        local disk
        disk=$(df -h / | awk 'NR==2 {print $4}')
        echo "Available Disk: $disk"
    fi
    
    # Shell information
    echo "Current Shell: ${SHELL##*/}"
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        echo "Zsh Version: $ZSH_VERSION"
    elif [[ -n "${BASH_VERSION:-}" ]]; then
        echo "Bash Version: $BASH_VERSION"
    fi
}

# ==============================================================================
# Path and Environment Functions
# ==============================================================================

# Get user's shell
get_user_shell() {
    if [[ -n "${SHELL:-}" ]]; then
        basename "$SHELL"
    else
        echo "unknown"
    fi
}

# Get shell configuration file
get_shell_config_file() {
    local shell="${1:-$(get_user_shell)}"
    
    case "$shell" in
        zsh)
            echo "$HOME/.zshrc"
            ;;
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "$HOME/.bashrc"
            else
                echo "$HOME/.bash_profile"
            fi
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

# Add directory to PATH if not already present
add_to_path() {
    local dir="$1"
    local prepend="${2:-false}"
    
    if [[ -d "$dir" ]] && [[ ":$PATH:" != *":$dir:"* ]]; then
        if [[ "$prepend" == "true" ]]; then
            export PATH="$dir:$PATH"
        else
            export PATH="$PATH:$dir"
        fi
        log_debug "Added $dir to PATH"
    fi
}

# ==============================================================================
# Network and Connectivity Functions
# ==============================================================================

# Check internet connectivity
check_internet() {
    local timeout="${1:-5}"
    
    # Try multiple methods
    if command -v curl >/dev/null 2>&1; then
        curl --connect-timeout "$timeout" --silent --head "https://github.com" >/dev/null 2>&1
    elif command -v wget >/dev/null 2>&1; then
        wget --timeout="$timeout" --tries=1 --spider "https://github.com" >/dev/null 2>&1
    elif command -v ping >/dev/null 2>&1; then
        ping -c 1 -W "$timeout" github.com >/dev/null 2>&1
    else
        log_warn "No network checking tools available"
        return 1
    fi
}

# Download file with retry
download_file() {
    local url="$1"
    local output="$2"
    local max_attempts="${3:-3}"
    
    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        log_debug "Download attempt $attempt/$max_attempts: $url"
        
        if command -v curl >/dev/null 2>&1; then
            if curl -fsSL --connect-timeout "$NETWORK_TIMEOUT" -o "$output" "$url"; then
                return 0
            fi
        elif command -v wget >/dev/null 2>&1; then
            if wget --timeout="$NETWORK_TIMEOUT" --tries=1 -O "$output" "$url"; then
                return 0
            fi
        else
            log_error "No download tools available (curl or wget)"
            return 1
        fi
        
        ((attempt++))
        if [[ $attempt -le $max_attempts ]]; then
            log_debug "Download failed, retrying in 2 seconds..."
            sleep 2
        fi
    done
    
    log_error "Failed to download $url after $max_attempts attempts"
    return 1
}

# ==============================================================================
# File System Functions
# ==============================================================================

# Create directory with parents
ensure_dir() {
    local dir="$1"
    local mode="${2:-755}"
    
    if [[ ! -d "$dir" ]]; then
        log_debug "Creating directory: $dir"
        if [[ "${DRY_RUN_MODE}" != "true" ]]; then
            mkdir -p "$dir"
            chmod "$mode" "$dir"
        else
            log_dry_run "Would create directory: $dir"
        fi
    fi
}

# Backup file with timestamp
backup_file() {
    local file="$1"
    local backup_dir="${2:-$BACKUP_DIR}"
    
    if [[ -f "$file" ]] || [[ -L "$file" ]]; then
        ensure_dir "$backup_dir"
        
        local basename
        basename="$(basename "$file")"
        local timestamp
        timestamp="$(date +%Y%m%d_%H%M%S)"
        local backup_path="$backup_dir/${basename}.backup.$timestamp"
        
        log_info "Backing up $file to $backup_path"
        if [[ "${DRY_RUN_MODE}" != "true" ]]; then
            cp -L "$file" "$backup_path" 2>/dev/null || cp "$file" "$backup_path"
        else
            log_dry_run "Would backup $file to $backup_path"
        fi
    fi
}

# Create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"
    local force="${3:-true}"
    
    # Ensure source exists
    if [[ ! -e "$source" ]]; then
        log_error "Source file does not exist: $source"
        return 1
    fi
    
    # Handle existing target
    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        if [[ "$force" == "true" ]]; then
            backup_file "$target"
            if [[ "${DRY_RUN_MODE}" != "true" ]]; then
                rm -f "$target"
            else
                log_dry_run "Would remove existing target: $target"
            fi
        else
            log_warn "Target already exists and force=false: $target"
            return 1
        fi
    fi
    
    # Create parent directory if needed
    local target_dir
    target_dir="$(dirname "$target")"
    ensure_dir "$target_dir"
    
    # Create symlink
    log_info "Creating symlink: $target → $source"
    if [[ "${DRY_RUN_MODE}" != "true" ]]; then
        ln -sf "$source" "$target"
    else
        log_dry_run "Would create symlink: $target → $source"
    fi
}

# ==============================================================================
# Git Repository Functions
# ==============================================================================

# Check if directory is a git repository
is_git_repo() {
    local dir="${1:-.}"
    [[ -d "$dir/.git" ]] || git -C "$dir" rev-parse --git-dir >/dev/null 2>&1
}

# Clone or update git repository
clone_or_update_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local branch="${3:-}"
    
    if is_git_repo "$target_dir"; then
        log_info "Updating existing repository: $target_dir"
        if [[ "${DRY_RUN_MODE}" != "true" ]]; then
            (
                cd "$target_dir"
                git fetch origin
                if [[ -n "$branch" ]]; then
                    git checkout "$branch"
                fi
                git pull
            )
        else
            log_dry_run "Would update repository: $target_dir"
        fi
    else
        log_info "Cloning repository: $repo_url → $target_dir"
        if [[ "${DRY_RUN_MODE}" != "true" ]]; then
            local clone_cmd="git clone"
            if [[ -n "$branch" ]]; then
                clone_cmd="$clone_cmd -b $branch"
            fi
            clone_cmd="$clone_cmd $repo_url $target_dir"
            eval "$clone_cmd"
        else
            log_dry_run "Would clone repository: $repo_url → $target_dir"
        fi
    fi
}

# ==============================================================================
# Export Functions
# ==============================================================================

# Export all public functions
export -f detect_os detect_architecture detect_linux_distro detect_package_manager
export -f command_exists package_installed check_version is_root has_sudo
export -f get_system_info get_user_shell get_shell_config_file add_to_path
export -f check_internet download_file
export -f ensure_dir backup_file create_symlink
export -f is_git_repo clone_or_update_repo 