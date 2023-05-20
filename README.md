# dotfiles
A set of vim/nvim, zsh/oh-my-zsh, and tmux configuration files.

## Basic Installation

Dotfiles is installed by running one of the following commands in your terminal. You can install this via the command-line with `git`.

#### Install dotfiles
```bash
git clone https://github.com/toandaominh1997/dotfiles.git $HOME/.dotfiles/tool
bash $HOME/.dotfiles/tool/install.sh
```
#### Upgrade dotfiles
```bash
bash $HOME/.dotfiles/tool/install.sh upgrade
```

## How to use

### Vim/nvim
vim cheatsheet: ![https://vim.rtorr.com/](https://vim.rtorr.com/)
#### Map
```
:nmap
:vmap
:imap
```

#### Packer 
```
// update package
:PackerUpdate 
:PackerInstall
```
#### Lsp
```
:LspLog
```

#### Nvim Tree 
```
// NvimTreeFocus
<leader>tt
```
#### Telescope
```
// find files:
<leader>ff

// live grep
<learder>fg

// buffers
<leader>fb

// Helper 
<leader>fh
```

#### Comment
```
visual-text > gc
```

### Tmux 
tmux cheatsheet: ![https://tmuxcheatsheet.com/](https://tmuxcheatsheet.com/)

- create window
```
control + a + c
```


### Updating oh-my-zsh
```
omz update
```
## Visualization
<img src='./docs/demo.png'>
 
