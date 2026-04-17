#!/usr/bin/env bash

readonly LAZYVIM_REPO="https://github.com/LazyVim/starter.git"

setup_vim_nvim() {
  log_info "Setting up Vim and Neovim..."

  if [[ -f "$HOME/.vimrc" && ! -L "$HOME/.vimrc" ]]; then
    log_info "Backing up existing .vimrc"
    execute_command "cp \"$HOME/.vimrc\" \"$HOME/.vimrc.backup.$(date +%Y%m%d_%H%M%S)\"" "Backup .vimrc"
  fi

  local vim_config="source \"$SCRIPT_DIR/vim/config.vim\""
  execute_command "echo '$vim_config' > \"$HOME/.vimrc\"" "Create .vimrc"

  local nvim_dir="$HOME/.config/nvim"
  local nvim_data_dir="$HOME/.local/share/nvim"
  local lazyvim_lock_file="$nvim_dir/lazy-lock.json"
  local lazyvim_init_marker='require("config.lazy")'

  local has_lazyvim_config=false
  if [[ -f "$lazyvim_lock_file" ]] || grep -qF "$lazyvim_init_marker" "$nvim_dir/init.lua" 2>/dev/null; then
    has_lazyvim_config=true
  fi

  if [[ -d "$nvim_dir" ]] && [[ -n "$(ls -A "$nvim_dir" 2>/dev/null)" ]]; then
    if [[ "$has_lazyvim_config" == true ]]; then
      log_info "LazyVim is already installed."
      if [[ "$UPGRADE_MODE" == true ]]; then
        if [[ -d "$nvim_dir/.git" ]]; then
          log_info "Upgrading LazyVim starter..."
          execute_command "(cd \"$nvim_dir\" && git pull --rebase --autostash)" "Upgrade LazyVim starter"
        else
          log_info "Skipping LazyVim starter git update (no .git metadata)."
        fi
        log_info "Syncing LazyVim plugins..."
        execute_command "nvim --headless '+Lazy! sync' '+qa'" "Sync LazyVim plugins"
      fi
    else
      log_warn "Existing Neovim config found at $nvim_dir. Skipping LazyVim installation to avoid overwriting your config."
      log_warn "Remove or back up $nvim_dir and rerun dotup to install LazyVim."
    fi
  else
    log_info "Installing LazyVim..."
    execute_command "rm -rf \"$nvim_dir\"" "Remove empty Neovim config directory"
    execute_command "git clone \"$LAZYVIM_REPO\" \"$nvim_dir\"" "Clone LazyVim starter"
    execute_command "rm -rf \"$nvim_dir/.git\"" "Remove LazyVim starter git metadata"
    execute_command "rm -rf \"$nvim_data_dir\"" "Remove existing Neovim data for clean LazyVim bootstrap"
    execute_command "nvim --headless '+Lazy! sync' '+qa'" "Install LazyVim plugins"
    log_success "LazyVim installed successfully"
  fi
}
