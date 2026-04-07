# Quick Start Guide

## Installation

### Fresh Install
```bash
git clone https://github.com/toandaominh1997/dotfiles.git $HOME/.dotfiles/tool
bash $HOME/.dotfiles/tool/setup.sh
```

### Upgrade Existing Installation
```bash
cd $HOME/.dotfiles/tool
git pull
bash setup.sh --upgrade
```

## Setup Options

```bash
# Show help
bash setup.sh --help

# Dry run (see what would be installed)
bash setup.sh --dry-run

# Verbose output
bash setup.sh --verbose

# Force reinstall
bash setup.sh --force

# Upgrade mode
bash setup.sh --upgrade
```

## Post-Installation Steps

1. **Restart your terminal** or source the config:
   ```bash
   source ~/.zshrc
   ```

2. **Install tmux plugins**:
   - Open tmux
   - Press `Ctrl+a` then `I` (capital i) to install plugins

3. **Install vim plugins**:
   ```bash
   vim +PlugInstall +qall
   ```

4. **Configure Neovim** (if using NvChad):
   ```bash
   nvim
   # Wait for plugins to install automatically
   ```

## Customization

### Change Theme

Set the `DOTFILES_THEME` environment variable before sourcing zsh config:

```bash
# In your ~/.zshrc (before the dotfiles source line)
export DOTFILES_THEME="starship"  # or "powerlevel10k"
```

### Local Overrides

Create local config files that won't be tracked by git:

- **Tmux**: `~/.tmux.conf.local`
- **Zsh**: Add custom configs after the dotfiles source line in `~/.zshrc`

## Tmux Copy/Paste (iTerm2)

### Copy
- **Visual mode**: `Ctrl+a` then `[` to enter copy mode, `v` to select, `y` to copy
- **Mouse**: Just select text with mouse (if mouse mode is enabled)

### Paste
- **From tmux buffer**: `Ctrl+a` then `p` or `P`
- **From system clipboard**: `Cmd+V` (iTerm2) or `Ctrl+a` then `p`

## Key Bindings

### Tmux (prefix: Ctrl+a)
- `Ctrl+a c` - Create new window
- `Ctrl+a -` - Split horizontally
- `Ctrl+a _` - Split vertically
- `Ctrl+a h/j/k/l` - Navigate panes
- `Ctrl+a [` - Enter copy mode
- `Ctrl+a r` - Reload config

### Vim/Neovim
- `Space` - Leader key
- `Space w` - Save file
- `Space ff` - Find files (Telescope)
- `Space fg` - Live grep (Telescope)
- `Ctrl+e` - Toggle file tree
- `;;` - EasyMotion

## Troubleshooting

### Clipboard not working in tmux
1. Ensure iTerm2 is up to date
2. Check that `pbcopy` and `pbpaste` are available:
   ```bash
   which pbcopy pbpaste
   ```
3. Reload tmux config:
   ```bash
   tmux source-file ~/.tmux.conf
   ```

### Oh-My-Zsh not loading
1. Check if Oh-My-Zsh is installed:
   ```bash
   ls -la ~/.dotfiles/oh-my-zsh
   ```
2. Reinstall if needed:
   ```bash
   bash setup.sh --force
   ```

### Homebrew packages failing
1. Update Homebrew:
   ```bash
   brew update
   ```
2. Run setup in verbose mode:
   ```bash
   bash setup.sh --upgrade --verbose
   ```

## Backup and Restore

The setup script automatically backs up existing configs with timestamps:
- `.vimrc.backup.YYYYMMDD_HHMMSS`
- `.tmux.conf.backup.YYYYMMDD_HHMMSS`

To restore a backup:
```bash
cp ~/.vimrc.backup.20260401_142530 ~/.vimrc
```

## Uninstalling

To remove dotfiles configurations:

```bash
# Remove symlinks/configs
rm ~/.zshrc ~/.vimrc ~/.tmux.conf

# Remove Oh-My-Zsh
rm -rf ~/.dotfiles/oh-my-zsh

# Remove tmux plugins
rm -rf ~/.tmux/plugins

# Restore backups if needed
cp ~/.vimrc.backup.* ~/.vimrc
```

## Getting Help

- **Issues**: https://github.com/toandaominh1997/dotfiles/issues
- **Vim cheatsheet**: https://vim.rtorr.com/
- **Tmux cheatsheet**: https://tmuxcheatsheet.com/
