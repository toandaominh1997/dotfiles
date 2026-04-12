#!/usr/bin/env bash

readonly BREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"

get_pkg_manager() {
  local os_type="$1"
  case "$os_type" in
    macos) echo "brew" ;;
    debian) echo "apt-get" ;;
    redhat) echo "dnf" ;;
    arch) echo "pacman" ;;
    *) echo "brew" ;;
  esac
}

package_exists() {
  local package="$1"
  local type="${2:---formula}"
  local os_type
  os_type="$(detect_os)"
  local pkg_manager
  pkg_manager="$(get_pkg_manager "$os_type")"

  if [[ "$pkg_manager" == "brew" ]]; then
    if [[ "$type" == "--cask" ]]; then
      brew list --cask "$package" &>/dev/null
    else
      brew list --formula "$package" &>/dev/null || command_exists "$package"
    fi
  elif [[ "$pkg_manager" == "apt-get" ]]; then
    dpkg -s "$package" &>/dev/null || command_exists "$package"
  elif [[ "$pkg_manager" == "dnf" ]]; then
    rpm -q "$package" &>/dev/null || command_exists "$package"
  elif [[ "$pkg_manager" == "pacman" ]]; then
    pacman -Qs "$package" &>/dev/null || command_exists "$package"
  else
    command_exists "$package"
  fi
}

install_homebrew() {
  if command_exists brew; then
    log_info "Homebrew is already installed."
    if [[ "$UPGRADE_MODE" == true ]]; then
        execute_command "brew update" "Update Homebrew"
    fi
  else
    execute_command "/bin/bash -c \"\$(curl -fsSL \"$BREW_INSTALL_URL\")\"" "Install Homebrew"

    if [[ "$(detect_os)" != "macos" ]]; then
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

init_pkg_manager() {
  local os_type="$1"
  local pkg_manager
  pkg_manager="$(get_pkg_manager "$os_type")"

  if [[ "$pkg_manager" == "brew" ]]; then
    log_info "==> Initializing Homebrew..."
    install_homebrew
  elif [[ "$pkg_manager" == "apt-get" ]]; then
    log_info "==> Initializing APT..."
    if [[ "$UPGRADE_MODE" == true ]]; then
        execute_command "sudo apt-get update && sudo apt-get upgrade -y" "Update APT"
    else
        execute_command "sudo apt-get update" "Update APT"
    fi
  elif [[ "$pkg_manager" == "dnf" ]]; then
    log_info "==> Initializing DNF..."
    if [[ "$UPGRADE_MODE" == true ]]; then
        execute_command "sudo dnf upgrade -y" "Update DNF"
    fi
  elif [[ "$pkg_manager" == "pacman" ]]; then
    log_info "==> Initializing Pacman..."
    if [[ "$UPGRADE_MODE" == true ]]; then
        execute_command "sudo pacman -Syu --noconfirm" "Update Pacman"
    else
        execute_command "sudo pacman -Sy" "Update Pacman database"
    fi
  fi
}

install_or_upgrade_package() {
  local package="$1"
  local type="$2"   # e.g. "--formula" or "--cask"
  local is_required="${3:-false}"
  local os_type
  os_type="$(detect_os)"
  local pkg_manager
  pkg_manager="$(get_pkg_manager "$os_type")"

  if package_exists "$package" "$type"; then
    log_info "$package is already installed."
    if [[ "$UPGRADE_MODE" == true ]]; then
      log_info "Upgrading $package..."
      if [[ "$pkg_manager" == "brew" ]]; then
        execute_command "brew upgrade \"$package\" 2>/dev/null || true" "Upgrade $package via brew"
      elif [[ "$pkg_manager" == "apt-get" ]]; then
        execute_command "sudo apt-get install --only-upgrade -y \"$package\"" "Upgrade $package via apt"
      elif [[ "$pkg_manager" == "dnf" ]]; then
        execute_command "sudo dnf upgrade -y \"$package\"" "Upgrade $package via dnf"
      elif [[ "$pkg_manager" == "pacman" ]]; then
        execute_command "sudo pacman -S --noconfirm \"$package\"" "Upgrade $package via pacman"
      fi
    fi
    return 0
  fi

  log_info "Installing $package..."
  local install_cmd=""

  if [[ "$pkg_manager" == "brew" ]]; then
    install_cmd="brew install $type \"$package\""
  elif [[ "$pkg_manager" == "apt-get" ]]; then
    install_cmd="sudo apt-get install -y \"$package\""
  elif [[ "$pkg_manager" == "dnf" ]]; then
    install_cmd="sudo dnf install -y \"$package\""
  elif [[ "$pkg_manager" == "pacman" ]]; then
    install_cmd="sudo pacman -S --noconfirm \"$package\""
  fi

  if ! execute_command "$install_cmd" "Install $package"; then
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
  init_pkg_manager "$os_type"

  process_packages "--formula" true "${required_packages[@]}"
  process_packages "--formula" false "${formulae_packages[@]}"

  if [[ "$os_type" == "macos" ]]; then
    log_info "==> Installing macOS Brew cask packages..."
    process_packages "--cask" false "${cask_packages[@]}"
  fi
}
