use crate::utils::{execute_command, log_info, log_success, log_warn};
use crate::zsh::{get_dotfiles_dir, get_home_dir};
use std::path::Path;

const LAZYVIM_REPO: &str = "https://github.com/LazyVim/starter.git";

pub fn setup_vim_nvim(upgrade_mode: bool, dry_run: bool, verbose: bool) {
    log_info("Setting up Vim and Neovim...");
    let home_dir = get_home_dir();

    let vimrc_path = format!("{}/.vimrc", home_dir);
    if Path::new(&vimrc_path).exists() {
        if let Ok(metadata) = std::fs::symlink_metadata(&vimrc_path) {
            if !metadata.file_type().is_symlink() {
                log_info("Backing up existing .vimrc");
                execute_command(
                    &format!(
                        "cp \"{}\" \"{}.backup.$(date +%Y%m%d_%H%M%S)\"",
                        vimrc_path, vimrc_path
                    ),
                    "Backup .vimrc",
                    dry_run,
                    verbose,
                );
            }
        }
    }

    let vim_config_content = format!("source {}/tool/vim/config.vim", get_dotfiles_dir());
    execute_command(
        &format!("echo \"{}\" > \"{}\"", vim_config_content, vimrc_path),
        "Create .vimrc",
        dry_run,
        verbose,
    );

    let nvim_dir = format!("{}/.config/nvim", home_dir);
    let nvim_data_dir = format!("{}/.local/share/nvim", home_dir);
    let lazyvim_lock_file = format!("{}/lazy-lock.json", nvim_dir);
    let lazyvim_init_marker = "require(\"config.lazy\")";

    let mut has_lazyvim_config = false;
    if Path::new(&lazyvim_lock_file).exists() {
        has_lazyvim_config = true;
    } else {
        let init_lua = format!("{}/init.lua", nvim_dir);
        if let Ok(contents) = std::fs::read_to_string(&init_lua) {
            if contents.contains(lazyvim_init_marker) {
                has_lazyvim_config = true;
            }
        }
    }

    let is_dir_not_empty = std::fs::read_dir(&nvim_dir)
        .map(|mut d| d.next().is_some())
        .unwrap_or(false);

    if Path::new(&nvim_dir).exists() && is_dir_not_empty {
        if has_lazyvim_config {
            log_info("LazyVim is already installed.");
            if upgrade_mode {
                let nvim_git = format!("{}/.git", nvim_dir);
                if Path::new(&nvim_git).exists() {
                    log_info("Upgrading LazyVim starter...");
                    execute_command(
                        &format!("(cd \"{}\" && git pull --rebase --autostash)", nvim_dir),
                        "Upgrade LazyVim starter",
                        dry_run,
                        verbose,
                    );
                } else {
                    log_info("Skipping LazyVim starter git update (no .git metadata).");
                }
                log_info("Syncing LazyVim plugins...");
                execute_command(
                    "nvim --headless '+Lazy! sync' '+qa'",
                    "Sync LazyVim plugins",
                    dry_run,
                    verbose,
                );
            }
        } else {
            log_warn(&format!("Existing Neovim config found at {}. Skipping LazyVim installation to avoid overwriting your config.", nvim_dir));
            log_warn(&format!(
                "Remove or back up {} and rerun setup.sh to install LazyVim.",
                nvim_dir
            ));
        }
    } else {
        log_info("Installing LazyVim...");
        execute_command(
            &format!("rm -rf \"{}\"", nvim_dir),
            "Remove empty Neovim config directory",
            dry_run,
            verbose,
        );
        execute_command(
            &format!("git clone \"{}\" \"{}\"", LAZYVIM_REPO, nvim_dir),
            "Clone LazyVim starter",
            dry_run,
            verbose,
        );
        execute_command(
            &format!("rm -rf \"{}/.git\"", nvim_dir),
            "Remove LazyVim starter git metadata",
            dry_run,
            verbose,
        );
        execute_command(
            &format!("rm -rf \"{}\"", nvim_data_dir),
            "Remove existing Neovim data for clean LazyVim bootstrap",
            dry_run,
            verbose,
        );
        execute_command(
            "nvim --headless '+Lazy! sync' '+qa'",
            "Install LazyVim plugins",
            dry_run,
            verbose,
        );
        log_success("LazyVim installed successfully");
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;
    use std::env;
    use tempfile::tempdir;

    #[test]
    #[serial]
    fn test_setup_vim_nvim_dry_run() {
        let dir = tempdir().unwrap();
        env::set_var("HOME", dir.path());

        setup_vim_nvim(false, true, false);

        env::remove_var("HOME");
    }
}
