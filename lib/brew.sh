#!/usr/bin/env bash

readonly BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

package_exists() {
    local package="$1"
    local type="${2:---formula}"

    if [[ "$type" == "--cask" ]]; then
      brew list --cask "$package" &>/dev/null
    else
      brew list --formula "$package" &>/dev/null || command_exists "$package"
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
