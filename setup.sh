#!/usr/bin/env bash
#
# Dotfiles Setup Script
# Refactored into a modular architecture to align with the Rust dotup CLI.

set -euo pipefail

# Trap Ctrl+C (SIGINT) for a clean exit
trap 'echo -e "\n\033[0;31m[ERROR]\033[0m Setup interrupted by user. Exiting..."; exit 1' INT

readonly SCRIPT_VERSION="2.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly DOTFILES_DIR
readonly OH_MY_ZSH_DIR="$DOTFILES_DIR/oh-my-zsh"

# Global flags
UPGRADE_MODE=false
DRY_RUN=false
VERBOSE=false
FORCE=false
AUTO_MODE=false

# Source modular components (Aligns perfectly with Rust src/* modules)
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/lib/packages.sh"
source "$SCRIPT_DIR/lib/pkg_manager.sh"
source "$SCRIPT_DIR/lib/zsh.sh"
source "$SCRIPT_DIR/lib/tmux.sh"
source "$SCRIPT_DIR/lib/vim.sh"
source "$SCRIPT_DIR/lib/fonts.sh"

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

OPTIONS:
    -u, --upgrade      Upgrade existing packages
    -d, --dry-run      Show what would be installed without making changes
    -v, --verbose      Enable verbose output
    -f, --force        Force installation even if already present
    -a, --auto         Run automatically without interactive menu
    -h, --help         Show this help message
    --version          Show script version

EXAMPLES:
    $0                 # Basic installation (Interactive)
    $0 --auto          # Basic installation (Non-interactive)
    $0 --upgrade       # Upgrade existing packages
    $0 --dry-run       # Preview what would be installed
    $0 -v --upgrade    # Verbose upgrade mode

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -u|--upgrade)
                UPGRADE_MODE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -a|--auto)
                AUTO_MODE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            --version)
                echo "Dotfiles Setup Script v$SCRIPT_VERSION"
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

run_all() {
  run_packages
  install_fonts
  run_zsh
  setup_tmux
  setup_vim_nvim

  log_info "==> Running final Brew cleanup..."
  if command_exists brew; then
    brew cleanup || true
  fi

  log_success "==> Dotfiles setup complete!"
  
  echo ""
  log_info "Next steps:"
  log_info "  1. Restart your terminal or run: source $HOME/.zshrc"
  log_info "  2. Open tmux and press 'prefix + I' to install tmux plugins"
  log_info "  3. Open nvim and run :Lazy sync if plugins are not installed"
  echo ""
  log_info "Configuration files:"
  log_info "  - Zsh:  $HOME/.zshrc"
  log_info "  - Tmux: $HOME/.tmux.conf"
  log_info "  - Vim:  $HOME/.vimrc"
  log_info "  - Nvim: $HOME/.config/nvim"
}

interactive_menu() {
  while true; do
    clear
    echo -e "\033[1;36m===============================================\033[0m"
    echo -e "\033[1;32m            Dotfiles Setup Script              \033[0m"
    echo -e "\033[1;36m===============================================\033[0m"
    echo "Please select an option:"
    echo "  1) Install Everything (Default)"
    echo "  2) Install Homebrew & Packages"
    echo "  3) Setup Zsh & Themes"
    echo "  4) Setup Tmux"
    echo "  5) Setup Vim & Neovim"
    echo "  6) Install Fonts"
    echo "  7) Upgrade Existing Setup"
    echo "  q) Quit"
    echo -e "\033[1;36m===============================================\033[0m"
    read -r -p "Enter your choice [1]: " choice
    choice=${choice:-1}
    
    case $choice in
      1)
        run_all
        break
        ;;
      2)
        run_packages
        read -r -p "Press Enter to continue..."
        ;;
      3)
        run_zsh
        read -r -p "Press Enter to continue..."
        ;;
      4)
        setup_tmux
        read -r -p "Press Enter to continue..."
        ;;
      5)
        setup_vim_nvim
        read -r -p "Press Enter to continue..."
        ;;
      6)
        install_fonts
        read -r -p "Press Enter to continue..."
        ;;
      7)
        UPGRADE_MODE=true
        run_all
        break
        ;;
      q|Q)
        log_info "Exiting..."
        exit 0
        ;;
      *)
        log_error "Invalid choice"
        sleep 1
        ;;
    esac
  done
}

main() {
  parse_arguments "$@"

  log_info "Upgrade Mode: $UPGRADE_MODE"

  if [[ "$AUTO_MODE" == true ]]; then
    run_all
  else
    interactive_menu
  fi
}

main "$@"
