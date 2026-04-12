#!/usr/bin/env bash

readonly TMUX_PLUGIN_MANAGER_REPO="https://github.com/tmux-plugins/tpm"

setup_tmux() {
  log_info "Setting up Tmux plugin manager (TPM)"
  install_or_upgrade_repo "$TMUX_PLUGIN_MANAGER_REPO" "$HOME/.tmux/plugins/tpm" "tmux-plugin-manager"

  if [[ -f "$HOME/.tmux.conf" && ! -L "$HOME/.tmux.conf" ]]; then
    log_info "Backing up existing .tmux.conf"
    execute_command "cp \"$HOME/.tmux.conf\" \"$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)\"" "Backup .tmux.conf"
  fi

  local tmux_config="source \"$SCRIPT_DIR/tmux/config.tmux\""
  execute_command "echo '$tmux_config' > \"$HOME/.tmux.conf\"" "Create .tmux.conf"
  log_success "Tmux configuration updated"
}
