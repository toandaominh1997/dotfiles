#!/usr/bin/env bash

###############################################################################
# Enhanced Logging System
# 
# This module provides a comprehensive logging system with:
# - Multiple log levels
# - Colored output
# - Timestamps
# - Progress indicators
# - Dry-run mode support
###############################################################################

# Source constants if not already loaded
if [[ -z "${DOTFILES_VERSION:-}" ]]; then
    # shellcheck source=./constants.sh
    source "$(dirname "${BASH_SOURCE[0]}")/constants.sh"
fi

# ==============================================================================
# Logging Configuration
# ==============================================================================

# Default log level
LOG_LEVEL=${LOG_LEVEL:-$LOG_INFO}

# Global flags
DRY_RUN_MODE=${DRY_RUN_MODE:-false}
VERBOSE_MODE=${VERBOSE_MODE:-false}
QUIET_MODE=${QUIET_MODE:-false}

# Log file for persistent logging
LOG_FILE="${LOG_FILE:-}"

# ==============================================================================
# Utility Functions
# ==============================================================================

# Check if color output is supported
_supports_color() {
    [[ -t 1 ]] && [[ "${ENABLE_COLOR_OUTPUT}" == "true" ]] && command -v tput >/dev/null 2>&1
}

# Get timestamp
_get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Get formatted caller info for debug mode
_get_caller_info() {
    if [[ "${VERBOSE_MODE}" == "true" ]]; then
        local caller_file="${BASH_SOURCE[3]##*/}"
        local caller_line="${BASH_LINENO[2]}"
        local caller_func="${FUNCNAME[3]}"
        echo "[${caller_file}:${caller_line}:${caller_func}]"
    fi
}

# ==============================================================================
# Core Logging Functions
# ==============================================================================

# Generic log function
_log() {
    local level="$1"
    local message="$2"
    local prefix="$3"
    local color="$4"
    local symbol="$5"
    
    # Check if this log level should be displayed
    if [[ $level -gt $LOG_LEVEL ]]; then
        return 0
    fi
    
    # Skip info and debug in quiet mode
    if [[ "${QUIET_MODE}" == "true" && $level -gt $LOG_WARN ]]; then
        return 0
    fi
    
    local timestamp
    timestamp="$(_get_timestamp)"
    
    local caller_info
    caller_info="$(_get_caller_info)"
    
    local formatted_message
    if _supports_color; then
        formatted_message="${color}${symbol} [${prefix}]${NC} ${DIM}[${timestamp}]${NC} ${caller_info}${message}"
    else
        formatted_message="${symbol} [${prefix}] [${timestamp}] ${caller_info}${message}"
    fi
    
    # Output to stderr for errors and warnings, stdout for others
    if [[ $level -le $LOG_WARN ]]; then
        echo -e "${formatted_message}" >&2
    else
        echo -e "${formatted_message}"
    fi
    
    # Write to log file if specified
    if [[ -n "${LOG_FILE}" ]]; then
        echo "[${timestamp}] [${prefix}] ${caller_info}${message}" >> "${LOG_FILE}"
    fi
}

# ==============================================================================
# Public Logging Functions
# ==============================================================================

# Error logging
log_error() {
    _log $LOG_ERROR "$1" "ERROR" "${RED}" "${CROSS_MARK}"
}

# Warning logging
log_warn() {
    _log $LOG_WARN "$1" "WARN" "${YELLOW}" "${WARNING_SIGN}"
}

# Info logging
log_info() {
    _log $LOG_INFO "$1" "INFO" "${GREEN}" "${CHECK_MARK}"
}

# Debug logging
log_debug() {
    _log $LOG_DEBUG "$1" "DEBUG" "${BLUE}" "${INFO_SIGN}"
}

# Success logging (special case of info)
log_success() {
    _log $LOG_INFO "$1" "SUCCESS" "${GREEN}" "${CHECK_MARK}"
}

# Dry-run specific logging
log_dry_run() {
    if [[ "${DRY_RUN_MODE}" == "true" ]]; then
        _log $LOG_INFO "[DRY RUN] $1" "PREVIEW" "${CYAN}" "${INFO_SIGN}"
    fi
}

# ==============================================================================
# Progress and Status Functions
# ==============================================================================

# Print a section header
print_section() {
    local title="$1"
    local width=80
    local separator
    separator=$(printf '=%.0s' $(seq 1 $width))
    
    if _supports_color; then
        echo -e "\n${CYAN}${BOLD}${separator}${NC}"
        echo -e "${CYAN}${BOLD} ${title}${NC}"
        echo -e "${CYAN}${BOLD}${separator}${NC}\n"
    else
        echo -e "\n${separator}"
        echo -e " ${title}"
        echo -e "${separator}\n"
    fi
}

# Print a subsection header
print_subsection() {
    local title="$1"
    local separator
    separator=$(printf -- '-%.0s' $(seq 1 40))
    
    if _supports_color; then
        echo -e "\n${BLUE}${BOLD}${ARROW_RIGHT} ${title}${NC}"
        echo -e "${BLUE}${separator}${NC}\n"
    else
        echo -e "\n${ARROW_RIGHT} ${title}"
        echo -e "${separator}\n"
    fi
}

# Print progress indicator
print_progress() {
    local current="$1"
    local total="$2"
    local description="$3"
    
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 2))  # 50 chars max
    local empty=$((50 - filled))
    
    if _supports_color; then
        printf "\r${BLUE}Progress:${NC} [${GREEN}%*s${NC}%*s] ${BOLD}%d%%${NC} - %s" \
            $filled '' $empty '' $percentage "$description"
    else
        printf "\rProgress: [%*s%*s] %d%% - %s" \
            $filled '' $empty '' $percentage "$description"
    fi
    
    if [[ $current -eq $total ]]; then
        echo  # New line when complete
    fi
}

# ==============================================================================
# Specialized Output Functions
# ==============================================================================

# Print banner with version info
print_banner() {
    if [[ "${QUIET_MODE}" == "true" ]]; then
        return 0
    fi
    
    if _supports_color; then
        echo -e "${CYAN}${BOLD}"
    fi
    
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                         Enhanced Dotfiles Setup                             ║
║                                                                              ║
║  A comprehensive and modern dotfiles management system with:                ║
║  • Homebrew package management (macOS/Linux)                               ║
║  • Zsh with Oh My Zsh and plugins                                          ║
║  • Tmux with plugin manager                                                 ║
║  • Vim/Neovim configuration (NvChad)                                       ║
║  • Cross-platform support                                                   ║
║  • Configurable package lists                                               ║
║  • Backup and safety mechanisms                                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    
    if _supports_color; then
        echo -e "${NC}"
        echo -e "${DIM}Version: ${DOTFILES_VERSION} | OS: ${OS_TYPE} | Arch: ${ARCH_TYPE}${NC}\n"
    else
        echo -e "Version: ${DOTFILES_VERSION} | OS: ${OS_TYPE} | Arch: ${ARCH_TYPE}\n"
    fi
}

# Print help message
print_help() {
    cat << 'EOF'
Enhanced Dotfiles Setup Script

USAGE:
    ./setup.sh [OPTIONS]

OPTIONS:
    -u, --upgrade        Upgrade existing packages and configurations
    -v, --verbose        Enable verbose logging and debug output
    -d, --dry-run        Show what would be installed without making changes
    -q, --quiet          Suppress informational output (errors/warnings only)
    -l, --log-file FILE  Write logs to specified file
    -h, --help           Show this help message
    --version            Show version information

EXAMPLES:
    ./setup.sh                     # Basic installation
    ./setup.sh --upgrade           # Upgrade existing setup
    ./setup.sh --verbose           # Verbose output with debug info
    ./setup.sh --dry-run           # Preview changes without applying
    ./setup.sh --quiet             # Minimal output
    ./setup.sh --log-file setup.log  # Log to file

MAKE COMMANDS:
    make install          # Install dotfiles
    make upgrade          # Upgrade existing setup
    make dry-run          # Preview changes
    make backup           # Create backup
    make status           # Show current status
    make test             # Run tests
    make clean            # Clean temporary files

For more information, see README.md or visit:
https://github.com/toandaominh1997/dotfiles

EOF
}

# Print error and exit
die() {
    log_error "$1"
    exit "${2:-1}"
}

# Print warning but continue
warn() {
    log_warn "$1"
}

# ==============================================================================
# Debug and Development Functions
# ==============================================================================

# Debug variable dump
debug_vars() {
    if [[ "${VERBOSE_MODE}" != "true" ]]; then
        return 0
    fi
    
    log_debug "Environment Variables:"
    log_debug "  DRY_RUN_MODE: ${DRY_RUN_MODE}"
    log_debug "  VERBOSE_MODE: ${VERBOSE_MODE}"
    log_debug "  QUIET_MODE: ${QUIET_MODE}"
    log_debug "  LOG_LEVEL: ${LOG_LEVEL}"
    log_debug "  LOG_FILE: ${LOG_FILE:-"(none)"}"
    log_debug "  OS_TYPE: ${OS_TYPE}"
    log_debug "  ARCH_TYPE: ${ARCH_TYPE}"
    log_debug "  BREW_PREFIX: ${BREW_PREFIX}"
    log_debug "  ROOT_DIR: ${ROOT_DIR}"
    log_debug "  CONFIG_DIR: ${CONFIG_DIR}"
}

# Performance timing - use simple variables instead of associative arrays for compatibility
start_timer() {
    local name="$1"
    eval "_TIMER_${name}=$(date +%s.%N)"
}

end_timer() {
    local name="$1"
    local start_var="_TIMER_${name}"
    local start_time="${!start_var:-}"
    
    if [[ -n "$start_time" ]]; then
        local end_time
        end_time=$(date +%s.%N)
        local duration
        if command -v bc >/dev/null 2>&1; then
            duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "unknown")
        else
            duration="unknown"
        fi
        log_debug "Timer '${name}': ${duration}s"
        unset "$start_var"
    fi
}

# ==============================================================================
# Export Functions
# ==============================================================================

# Export all public functions
export -f log_error log_warn log_info log_debug log_success log_dry_run
export -f print_section print_subsection print_progress print_banner print_help
export -f die warn debug_vars start_timer end_timer 