# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

A Rust CLI (`dotup`) that bootstraps a personal developer environment by installing packages and writing/symlinking shell, editor, tmux, terminal, and font configs. First-class platforms are macOS and Ubuntu; other Linux package managers are best-effort. The shared static configs live in sibling directories (`zsh/`, `tmux/`, `vim/`, `wezterm/`, `starship/`, `fish/`); the Rust source in `src/` only orchestrates installation and writes references to those files into the user's `$HOME`.

## Common commands

Build, test, lint:
```bash
cargo check
cargo test                  # run all unit tests
cargo test <name>           # single test by substring
cargo build --release
shellcheck lib/*.sh tests/integration_test.sh
bash tests/integration_test.sh   # full dry-run smoke under a temp HOME
```

Run the CLI during development:
```bash
cargo run -- --auto                       # non-interactive: run_all
cargo run -- --auto --dry-run --verbose   # safe end-to-end exercise
cargo run -- --doctor                     # health check (no install)
cargo run -- --auto --profile work        # use a non-default profile
cargo run --                              # interactive ratatui menu
```

Release binary path used in `bin/dotup` is `target/release/dotup`.

## Architecture

### Entry point and dispatch (`src/main.rs`)
`main()` parses `clap` args. Single-shot flags `--dashboard`, `--doctor`, `--sync` short-circuit and return. Otherwise:
- `--auto` → `run_all(...)` runs the install pipeline once and exits.
- no flag → `interactive_menu(...)` loops over `tui::show_menu()` and dispatches to the same per-step functions.

`run_all` order is load-bearing and must stay this sequence: packages → fonts → zsh → tmux → vim/nvim → final `brew cleanup` (macOS only). Most modules expect their predecessors' state to exist.

### Profiles and config (`src/config.rs`, `dotup.toml`)
`DotupConfig::load()` searches three paths in order: `./dotup.toml`, `~/.dotfiles/tool/dotup.toml`, `~/.config/dotup/dotup.toml`. First match wins. If none are found, the binary falls back to a copy of `dotup.toml` embedded at compile time via `include_str!`. Each profile lists `required_packages` (must succeed; failure exits the process), `formulae_packages` (best-effort), and `cask_packages` (macOS only). `dotup.toml` is the single source of truth for default package lists — passing `--profile <name>` for a profile that doesn't exist exits non-zero.

### Package manager abstraction (`src/packages.rs`)
`get_pkg_manager(os)` maps OS family → manager string (`brew`, `apt-get`, `dnf`, `pacman`). `package_exists`, `init_pkg_manager`, and `process_packages` all branch on this string. `process_packages` partitions packages into "to install" vs "already installed" using rayon parallel iteration, then runs a single batch install command. On batch failure it falls back to per-package installs and only fails the run if `is_required` is true.

### Shared shell wrapper (`src/utils.rs`)
`execute_command(cmd, description, dry_run, verbose)` is the canonical command runner used by all modules. In non-verbose mode it spawns under `bash -c`, streams stdout into an `indicatif` spinner (truncated to 60 chars), and returns success as `bool`. In verbose mode it inherits stdio and returns the exit status. Anything that touches the system should go through this — do not call `Command` directly with side effects unless you also wire up dry-run and the spinner.

`detect_os()` returns `"macos"` for macOS, otherwise reads `/etc/os-release` and classifies via `detect_linux_family` into `"debian" | "redhat" | "arch" | "linux"`.

### Setup modules
Each of `zsh.rs`, `tmux.rs`, `vim.rs`, `fonts.rs` follows the same pattern:
1. Compute target paths under `$HOME`.
2. If the existing target is a regular file (not a symlink), back it up with a `.backup.YYYYMMDD_HHMMSS` suffix before overwriting.
3. Write a one-line stub that `source`s the canonical config from `~/.dotfiles/tool/<dir>/...` so updates here propagate without re-running setup.
`zsh.rs` also exposes `get_home_dir()`, `get_dotfiles_dir()` (= `$HOME/.dotfiles`), and `install_or_upgrade_repo()` — used by `tmux.rs` and others to clone TPM and similar tools idempotently with `--depth 1`.

`vim.rs` has special handling: it only bootstraps LazyVim into `~/.config/nvim` when that directory is empty or already a LazyVim install (detected via `lazy-lock.json` or the `require("config.lazy")` marker in `init.lua`). Existing non-LazyVim configs are skipped, never overwritten.

### TUI and dashboard (`src/tui.rs`, `src/dashboard.rs`)
Built on `ratatui` + `crossterm`. `MenuAction` is the enum that bridges the menu and `interactive_menu` in `main.rs` — adding a menu item requires changes in both files plus the matching per-step function. The dashboard uses `sysinfo` and runs in its own loop until ESC.

### Sync (`src/sync.rs`)
`run_sync` is a thin wrapper around `git status --porcelain` → `git add -A` → `git commit -m "Sync dotfiles: <ts>"` → `git push`. It assumes the cwd is the dotfiles repo root with an upstream configured.

## CI behavior to keep green

`.github/workflows/ci.yml` runs two jobs that any change must pass:
1. `cargo check`, `cargo clippy --all-targets -- -D warnings`, `cargo test`, `cargo build --release`, then `cargo run -- --auto --dry-run --verbose` and `cargo run -- --doctor` on both `ubuntu-latest` and `macos-latest`. The dry-run smoke is the main cross-platform exercise — if you add a step to `run_all`, it must be dry-run-safe end-to-end. Clippy is gated, so `-D warnings` failures break the build.
2. `bash tests/integration_test.sh` which re-runs the dry-run + doctor + `cargo test` under a fresh temp `HOME`. Doctor is allowed to exit non-zero here because a tmp HOME has no installed configs.

## Conventions

- `SCRIPT_VERSION` in `main.rs` and `version` in `Cargo.toml` are kept in sync (currently `2.1.0`).
- User-facing output goes through `log_info` / `log_warn` / `log_error` / `log_success` / `log_debug` in `utils.rs` (colored + prefixed glyphs). Don't `println!` directly for status messages.
- Dry-run is a first-class mode, not a debugging convenience: every code path that mutates the system must check `dry_run` (typically by routing through `execute_command`).
