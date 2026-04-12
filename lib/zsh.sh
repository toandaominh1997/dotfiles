#!/usr/bin/env bash

readonly ZSH_SYNTAX_HIGHLIGHTING_REPO="https://github.com/zsh-users/zsh-syntax-highlighting.git"
readonly ZSH_COMPLETIONS_REPO="https://github.com/zsh-users/zsh-completions.git"
readonly ZSH_HISTORY_SEARCH_REPO="https://github.com/zsh-users/zsh-history-substring-search.git"
readonly OH_MY_ZSH_REPO="https://github.com/robbyrussell/oh-my-zsh.git"
readonly ZSH_AUTOSUGGESTIONS_REPO="https://github.com/zsh-users/zsh-autosuggestions"
readonly POWERLEVEL10K_REPO="https://github.com/romkatv/powerlevel10k.git"

install_or_upgrade_repo() {
  local repo_url="$1"
  local dest_path="$2"
  local repo_name="$3"

  if [[ -d "$dest_path" ]]; then
    log_info "$repo_name already installed at $dest_path."
    if [[ "$UPGRADE_MODE" == true ]]; then
      log_info "Upgrading $repo_name..."
      if ! execute_command "(cd \"$dest_path\" && git pull --rebase --autostash)" "Upgrade $repo_name"; then
        log_warn "Failed to upgrade $repo_name, continuing..."
      fi
    fi
  else
    log_info "Installing $repo_name..."
    if ! execute_command "git clone --depth 1 \"$repo_url\" \"$dest_path\"" "Clone $repo_name"; then
      log_error "Failed to clone $repo_name"
      return 1
    fi
    log_success "Successfully installed $repo_name"
  fi
}

setup_oh_my_zsh() {
  log_info "Setting up Oh My Zsh"

  if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
    execute_command "git clone \"$OH_MY_ZSH_REPO\" \"$OH_MY_ZSH_DIR\"" "Install Oh My Zsh"
    execute_command "export ZSH=\"$OH_MY_ZSH_DIR\"" "Set ZSH environment"
    execute_command "\"$OH_MY_ZSH_DIR/tools/install.sh\" --unattended --skip-chsh || true" "Run Oh My Zsh installer"
  else
    log_info "Oh My Zsh is already installed"
    if [[ "$UPGRADE_MODE" == true ]]; then
      log_info "[ZSH] Upgrading Oh My Zsh..."
      execute_command "(cd \"$OH_MY_ZSH_DIR\" && git pull --rebase --autostash)" "Upgrade Oh My Zsh"
    fi
  fi
}

ensure_custom_config_in_zshrc() {
  local custom_config_line="source \"$SCRIPT_DIR/zsh/config.zsh\""

  if [[ ! -f "$HOME/.zshrc" ]]; then
    log_info "Creating new .zshrc"
    touch "$HOME/.zshrc"
  fi

  if ! grep -qF "source \"$SCRIPT_DIR/zsh/config.zsh\"" "$HOME/.zshrc" 2>/dev/null; then
    log_info "Adding custom config to $HOME/.zshrc"
    {
      echo ""
      echo "# Dotfiles custom configuration"
      echo "$custom_config_line"
    } >> "$HOME/.zshrc"
  else
    log_info "Custom config already sourced in $HOME/.zshrc"
  fi
}

setup_zsh_plugins() {
  log_info "Setting up Zsh plugins"
  
  install_or_upgrade_repo "$ZSH_SYNTAX_HIGHLIGHTING_REPO" "$OH_MY_ZSH_DIR/custom/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"
  install_or_upgrade_repo "$ZSH_COMPLETIONS_REPO" "$OH_MY_ZSH_DIR/custom/plugins/zsh-completions" "zsh-completions"
  install_or_upgrade_repo "$ZSH_HISTORY_SEARCH_REPO" "$OH_MY_ZSH_DIR/custom/plugins/zsh-history-substring-search" "zsh-history-substring-search"
  install_or_upgrade_repo "$ZSH_AUTOSUGGESTIONS_REPO" "$OH_MY_ZSH_DIR/custom/plugins/zsh-autosuggestions" "zsh-autosuggestions"
  install_or_upgrade_repo "$POWERLEVEL10K_REPO" "$OH_MY_ZSH_DIR/custom/themes/powerlevel10k" "Powerlevel10k"
}

setup_p10k_config() {
  local src="$SCRIPT_DIR/zsh/.p10k.zsh"
  local dest="$HOME/.p10k.zsh"

  if [[ ! -f "$src" ]]; then
    log_warn ".p10k.zsh not found at $src, skipping symlink"
    return 0
  fi

  if [[ -L "$dest" ]]; then
    log_info "$HOME/.p10k.zsh symlink already exists"
    return 0
  fi

  if [[ -f "$dest" ]]; then
    log_info "Backing up existing $HOME/.p10k.zsh"
    execute_command "mv \"$dest\" \"${dest}.backup.$(date +%Y%m%d_%H%M%S)\"" "Backup .p10k.zsh"
  fi

  execute_command "ln -sf \"$src\" \"$dest\"" "Symlink .p10k.zsh"
  log_success "Linked .p10k.zsh -> $dest"
}

run_zsh() {
  setup_oh_my_zsh
  setup_zsh_plugins
  setup_p10k_config
  ensure_custom_config_in_zshrc
}
