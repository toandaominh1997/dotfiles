use crate::utils::{execute_command, log_info, log_success};
use crate::zsh::{get_dotfiles_dir, get_home_dir, install_or_upgrade_repo};
use std::path::Path;

const TMUX_PLUGIN_MANAGER_REPO: &str = "https://github.com/tmux-plugins/tpm";

pub fn setup_tmux(upgrade_mode: bool, dry_run: bool, verbose: bool) {
    log_info("Setting up Tmux plugin manager (TPM)");
    let home_dir = get_home_dir();
    let tpm_dir = format!("{}/.tmux/plugins/tpm", home_dir);

    install_or_upgrade_repo(
        TMUX_PLUGIN_MANAGER_REPO,
        &tpm_dir,
        "tmux-plugin-manager",
        upgrade_mode,
        dry_run,
        verbose,
    );

    let tmux_conf = format!("{}/.tmux.conf", home_dir);
    if Path::new(&tmux_conf).exists() {
        if let Ok(metadata) = std::fs::symlink_metadata(&tmux_conf) {
            if !metadata.file_type().is_symlink() {
                log_info("Backing up existing .tmux.conf");
                execute_command(
                    &format!(
                        "cp \"{}\" \"{}.backup.$(date +%Y%m%d_%H%M%S)\"",
                        tmux_conf, tmux_conf
                    ),
                    "Backup .tmux.conf",
                    dry_run,
                    verbose,
                );
            }
        }
    }

    let tmux_config_content = format!("source {}/tool/tmux/config.tmux", get_dotfiles_dir());
    execute_command(
        &format!("echo \"{}\" > \"{}\"", tmux_config_content, tmux_conf),
        "Create .tmux.conf",
        dry_run,
        verbose,
    );
    log_success("Tmux configuration updated");
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;
    use std::env;
    use tempfile::tempdir;

    #[test]
    #[serial]
    fn test_setup_tmux_dry_run() {
        let dir = tempdir().unwrap();
        env::set_var("HOME", dir.path());

        setup_tmux(false, true, false);

        env::remove_var("HOME");
    }
}
