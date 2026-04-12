#!/usr/bin/env bash

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

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

detect_os() {
  case "$(uname)" in
    Darwin) echo "macos" ;;
    Linux)
      if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "${ID_LIKE:-}" == *"debian"* || "${ID:-}" == *"ubuntu"* || "${ID:-}" == *"debian"* ]]; then
          echo "debian"
          return
        elif [[ "${ID_LIKE:-}" == *"arch"* || "${ID:-}" == *"arch"* ]]; then
          echo "arch"
          return
        elif [[ "${ID_LIKE:-}" == *"rhel"* || "${ID_LIKE:-}" == *"fedora"* || "${ID:-}" == *"fedora"* ]]; then
          echo "redhat"
          return
        fi
      fi
      echo "linux"
      ;;
    *) echo "unknown" ;;
  esac
}

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
