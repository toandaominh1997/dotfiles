# Changelog

All notable changes to this dotfiles project will be documented in this file.

## [2.1.0] - 2026-04-01

### Added
- Backup mechanism for existing config files before overwriting (.vimrc, .tmux.conf)
- Better error handling for git operations with fallback for optional packages
- iTerm2-specific clipboard integration with OSC 52 support
- Mouse drag selection copy support in tmux
- `set-clipboard on` for better terminal clipboard integration
- Depth-limited git clones for faster installation
- Better next steps instructions after setup completion
- Environment variable `DOTFILES_THEME` to control theme selection
- `VISUAL` editor environment variable
- Support for both Intel and Apple Silicon Homebrew paths

### Changed
- Removed duplicate packages from `required_packages` and `formulae_packages` arrays
- Fixed upgrade flag documentation (changed from `-U` to `-u/--upgrade`)
- Improved tmux clipboard copy/paste for macOS with proper pbcopy/pbpaste integration
- Simplified paste bindings (removed bracketed paste escape sequences)
- Enhanced zsh config with better error handling and fallback mechanisms
- Theme selection now uses environment variable instead of hardcoded string
- Improved Oh-My-Zsh source with existence check
- Better Homebrew detection for both Intel and Apple Silicon Macs
- Improved LazyVim installation with upgrade support
- Better logging throughout setup script

### Fixed
- Tmux plugin manager now installs to correct path (`~/.tmux/plugins/tpm`)
- Copy/paste in tmux when using iTerm2 on macOS
- Missing .zshrc file creation if it doesn't exist
- Git clone operations now use `--depth 1` for faster installation
- Upgrade mode now properly updates LazyVim configuration

### Removed
- 200+ lines of commented-out code from tmux/config.tmux
- Duplicate package entries in setup.sh
- Unnecessary bracketed paste mode escape sequences

### Security
- Added validation for git operations
- Better error handling prevents partial installations

## [2.0.0] - Previous Release

Initial version with basic dotfiles setup functionality.
