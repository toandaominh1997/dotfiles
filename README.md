# dotfiles

A fully automated, cross-platform (macOS + Linux) developer environment — shell, editor, terminal multiplexer, and prompt — configured as code and installed with a single command.

![demo](./docs/demo.png)

---

## What's inside

| Layer | Tool | Details |
|---|---|---|
| **Shell** | Zsh + Oh-My-Zsh | 27 plugins, Powerlevel10k / Starship prompt |
| **Editor** | Neovim (LazyVim) | LSP, Treesitter, Telescope, completion |
| **Multiplexer** | Tmux + TPM | Session persistence, vim-tmux navigation |
| **Terminal** | WezTerm | GPU-accelerated, custom keybindings |
| **Package manager** | Homebrew | Formulae + casks, macOS & Linux |
| **IDE integration** | IdeaVim | JetBrains IDEs with vim motions |

---

## Quick start

```bash
git clone https://github.com/toandaominh1997/dotfiles.git $HOME/.dotfiles/tool
bash $HOME/.dotfiles/tool/setup.sh
```

Restart your terminal, then:

1. Open tmux → `prefix + I` to install tmux plugins
2. Open `nvim` → `:Lazy sync` if plugins are not auto-installed

---

## Setup script

```
Usage: setup.sh [OPTIONS]

OPTIONS:
    -u, --upgrade     Upgrade existing packages
    -d, --dry-run     Preview what would be installed without making changes
    -v, --verbose     Enable verbose output
    -f, --force       Force installation even if already present
    -h, --help        Show this help message
        --version     Show script version

EXAMPLES:
    ./setup.sh                  # Fresh install
    ./setup.sh --upgrade        # Upgrade all packages
    ./setup.sh --dry-run        # Preview changes
    ./setup.sh -v --upgrade     # Verbose upgrade
```

The script installs in order:

1. **Homebrew** (auto-detects Intel vs Apple Silicon)
2. **Required formulae** — `bash`, `fzf`, `git`, `neovim`, `tmux`, `vim`, `zsh`
3. **Optional formulae** — `go`, `rust`, `node`, `python`, `awscli`, `kubectl`, `helm`, `terraform`, `lazygit`, `lazydocker`, `k9s`, `bat`, `zoxide`, `thefuck`, and more
4. **macOS casks** — `iterm2`, `wezterm`, `vscode`, `jetbrains-toolbox`, `docker`, `slack`, `notion`, `obsidian`, and more
5. **Oh-My-Zsh** + plugins
6. **Tmux** config + TPM
7. **Neovim** via LazyVim starter

Existing configs are backed up with a timestamp before being overwritten.

---

## Neovim

Built on [LazyVim](https://www.lazyvim.org/). Config lives in `~/.config/nvim` after setup.

### Key mappings

**Leader key:** `Space`

| Key | Action |
|---|---|
| `<leader>ff` | Find files (Telescope) |
| `<leader>fg` | Live grep |
| `<leader>fb` | Buffers |
| `<leader>fh` | Help tags |
| `<leader>tt` | Focus file explorer (NvimTree) |
| `<leader>nf` | Reveal current file in tree |
| `<leader>U` | Toggle undo tree |
| `<leader>w` | Save file |
| `<leader>y / p` | System clipboard yank / paste |
| `<S-l> / <S-h>` | Next / previous buffer |
| `jk` or `kj` | Exit insert mode |
| `;;` | EasyMotion 2-char jump |
| `;l / ;w` | EasyMotion line / word jump |

**LSP (on attach):**

| Key | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gI` | Go to implementation |
| `gr` | References |
| `K` | Hover documentation |
| `gl` | Diagnostic float |
| `<leader>la` | Code action |
| `<leader>lr` | Rename symbol |
| `<leader>lf` | Format file |
| `<leader>lj / lk` | Next / previous diagnostic |

### LSP servers (auto-installed via Mason)

`lua_ls`, `tsserver`, `pyright`, `rust_analyzer`, `clangd`, `cssls`

### Formatters & linters (null-ls)

`prettier` (no semicolons, single quotes), `black`, `stylua`, `yapf`, `eslint`

### Treesitter parsers

c, cpp, html, css, dockerfile, lua, python, javascript, typescript, go, java, json, kotlin, rust, scala, sql, yaml, terraform, toml

### Plugin management

```vim
:Lazy sync       " Install / update all plugins
:Lazy update     " Update plugins
:Mason           " Manage LSP servers
:TSInstall {lang} " Install a Treesitter parser
:TSUpdate        " Update all parsers
```

---

## Tmux

**Prefix:** `Ctrl+a`

### Panes & windows

| Key | Action |
|---|---|
| `prefix -` | Split horizontally |
| `prefix _` | Split vertically |
| `prefix h/j/k/l` | Navigate panes |
| `prefix H/J/K/L` | Resize panes |
| `prefix Ctrl+h/l` | Previous / next window |
| `prefix Tab` | Last active window |
| `prefix r` | Reload config |

### Sessions

| Key | Action |
|---|---|
| `prefix Ctrl+c` | New session |
| `prefix Ctrl+f` | Find session |
| `prefix S` | Switch / kill sessions (fzf) |
| `prefix C` | Create session (fzf) |

### Copy mode (vi keys)

| Key | Action |
|---|---|
| `prefix [` | Enter copy mode |
| `v` | Begin selection |
| `y` | Copy selection |
| `Ctrl+v` | Rectangle selection |

Clipboard integration is automatic: `pbcopy` (macOS), `xclip`/`xsel` (Linux), `wl-copy` (Wayland).

### Plugins

| Plugin | Purpose |
|---|---|
| `tmux-resurrect` | Persist sessions across restarts |
| `tmux-continuum` | Auto-save every 3 minutes |
| `tmux-copycat` | Regex search in buffers |
| `tmux-battery` | Battery indicator in statusline |
| `vim-tmux-navigator` | Seamless vim ↔ tmux pane navigation |

> **Vim-tmux navigation:** `Ctrl+h/j/k/l` works transparently across vim splits and tmux panes.

---

## Zsh

Config is sourced from `~/.dotfiles/tool/zsh/config.zsh` via `~/.zshrc`.

**Theme:** Powerlevel10k (default). Set `DOTFILES_THEME=starship` to switch to Starship.

**Plugin highlights:**

| Category | Plugins |
|---|---|
| Completion & UX | `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`, `zsh-history-substring-search` |
| Navigation | `fzf`, `zoxide`, `extract` |
| Dev | `git`, `docker`, `kubectl`, `helm`, `terraform`, `python`, `npm` |
| macOS | `macos`, `brew`, `iterm2` |
| Misc | `colored-man-pages`, `dotenv`, `thefuck`, `web-search` |

Update Oh-My-Zsh:

```bash
omz update
```

---

## WezTerm

Config at `wezterm/wezterm.lua`. Font: `AestheticIosevka Nerd Font Mono`, size 8. Color scheme: Aesthetic Night.

| Key | Action |
|---|---|
| `Ctrl+\` | Split vertical |
| `Ctrl+Alt+\` | Split horizontal |
| `Ctrl+Shift+h/j/k/l` | Navigate panes |
| `Ctrl+t / w` | New / close tab |
| `Ctrl+Tab` | Next tab |

---

## IdeaVim

Copy `vim/ideavimrc.vim` to `~/.ideavimrc` for JetBrains IDEs.

Enabled plugins: `surround`, `easymotion`, `commentary`, `NERDTree`, `quickscope`

| Key | Action |
|---|---|
| `Ctrl+h/j/k/l` | Navigate splits |
| `<leader>ff` | Find in path |
| `Tab / S-Tab` | Next / previous tab |

---

## Directory structure

```
.
├── setup.sh              # Main installer
├── zsh/
│   └── config.zsh        # Zsh + Oh-My-Zsh config
├── tmux/
│   ├── config.tmux       # Tmux config
│   └── statusline.tmux   # Statusline theme
├── vim/
│   ├── config.vim        # Shared Vim/Neovim config (vim-plug)
│   ├── init.lua          # Neovim entry point (Packer)
│   ├── ideavimrc.vim     # JetBrains IdeaVim config
│   └── lua/user/         # Neovim Lua modules
│       ├── plugins.lua
│       ├── options.lua
│       ├── keymaps.lua
│       └── lsp/
├── starship/
│   └── starship.toml     # Starship prompt config
├── wezterm/
│   └── wezterm.lua       # WezTerm terminal config
├── fish/
│   └── config.fish       # Fish shell config
├── utils/
│   └── config_parser.sh  # INI-style config parser utility
├── docs/
│   ├── QUICK_START.md
│   └── demo.png
└── .github/workflows/
    └── main.yml          # CI: macOS + Ubuntu matrix
```

---

## CI

GitHub Actions runs on every push against `macos-latest` and `ubuntu-latest`, performing a full install and upgrade, then verifying versions of: `brew`, `tmux`, `vim`, `nvim`, `fzf`, `zsh`, `helm`, `go`.

---

## References

- [Vim cheatsheet](https://vim.rtorr.com/)
- [Tmux cheatsheet](https://tmuxcheatsheet.com/)
- [LazyVim docs](https://www.lazyvim.org/)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- [Oh-My-Zsh](https://ohmyz.sh/)
