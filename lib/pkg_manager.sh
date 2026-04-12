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

process_packages() {
  local type="$1"
  local is_required="$2"
  shift 2
  local packages=("$@")

  if [[ ${#packages[@]} -eq 0 ]]; then
    return 0
  fi

  local to_install=()
  local to_upgrade=()

  for package in "${packages[@]}"; do
    if package_exists "$package" "$type"; then
      to_upgrade+=("$package")
    else
      to_install+=("$package")
    fi
  done

  local os_type
  os_type="$(detect_os)"
  local pkg_manager
  pkg_manager="$(get_pkg_manager "$os_type")"

  if [[ ${#to_install[@]} -gt 0 ]]; then
    log_info "Installing ${#to_install[@]} packages..."
    local install_cmd=""

    if [[ "$pkg_manager" == "brew" ]]; then
      local adopt_flag=""
      if [[ "$type" == "--cask" ]]; then
        adopt_flag="--adopt "
      fi
      install_cmd="brew install $type $adopt_flag${to_install[*]}"
    elif [[ "$pkg_manager" == "apt-get" ]]; then
      install_cmd="sudo apt-get install -y ${to_install[*]}"
    elif [[ "$pkg_manager" == "dnf" ]]; then
      install_cmd="sudo dnf install -y ${to_install[*]}"
    elif [[ "$pkg_manager" == "pacman" ]]; then
      install_cmd="sudo pacman -S --noconfirm ${to_install[*]}"
    fi

    if ! execute_command "$install_cmd" "Install packages"; then
      log_error "Batch installation failed. Attempting individual installation..."
      local failed_pkgs=()
      for pkg in "${to_install[@]}"; do
        local single_cmd=""
        if [[ "$pkg_manager" == "brew" ]]; then
          local adopt_flag=""
          if [[ "$type" == "--cask" ]]; then
            adopt_flag="--adopt "
          fi
          single_cmd="brew install $type $adopt_flag$pkg"
        elif [[ "$pkg_manager" == "apt-get" ]]; then
          single_cmd="sudo apt-get install -y $pkg"
        elif [[ "$pkg_manager" == "dnf" ]]; then
          single_cmd="sudo dnf install -y $pkg"
        elif [[ "$pkg_manager" == "pacman" ]]; then
          single_cmd="sudo pacman -S --noconfirm $pkg"
        fi
        
        if ! execute_command "$single_cmd" "Install $pkg"; then
          failed_pkgs+=("$pkg")
        fi
      done
      
      if [[ ${#failed_pkgs[@]} -gt 0 ]]; then
        log_error "Failed to install the following packages: ${failed_pkgs[*]}"
        if [[ "$is_required" == true ]]; then
          exit 1
        fi
      else
        log_success "Successfully installed packages individually."
      fi
    else
      log_success "Successfully installed packages."
    fi
  else
    log_info "All packages are already installed."
  fi

  if [[ "$UPGRADE_MODE" == true && ${#to_upgrade[@]} -gt 0 ]]; then
    log_info "Upgrading ${#to_upgrade[@]} packages..."
    local upgrade_cmd=""

    if [[ "$pkg_manager" == "brew" ]]; then
      upgrade_cmd="brew upgrade $type ${to_upgrade[*]} 2>/dev/null || true"
    elif [[ "$pkg_manager" == "apt-get" ]]; then
      upgrade_cmd="sudo apt-get install --only-upgrade -y ${to_upgrade[*]}"
    elif [[ "$pkg_manager" == "dnf" ]]; then
      upgrade_cmd="sudo dnf upgrade -y ${to_upgrade[*]}"
    elif [[ "$pkg_manager" == "pacman" ]]; then
      upgrade_cmd="sudo pacman -S --noconfirm ${to_upgrade[*]}"
    fi

    execute_command "$upgrade_cmd" "Upgrade packages"
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
