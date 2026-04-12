use crate::utils::{execute_command, log_error, log_info, log_success, log_warn};
use std::env;
use std::path::Path;

const OH_MY_ZSH_REPO: &str = "https://github.com/robbyrussell/oh-my-zsh.git";
const ZSH_SYNTAX_HIGHLIGHTING_REPO: &str =
    "https://github.com/zsh-users/zsh-syntax-highlighting.git";
const ZSH_COMPLETIONS_REPO: &str = "https://github.com/zsh-users/zsh-completions.git";
const ZSH_HISTORY_SEARCH_REPO: &str =
    "https://github.com/zsh-users/zsh-history-substring-search.git";
const ZSH_AUTOSUGGESTIONS_REPO: &str = "https://github.com/zsh-users/zsh-autosuggestions";
const POWERLEVEL10K_REPO: &str = "https://github.com/romkatv/powerlevel10k.git";

pub fn get_home_dir() -> String {
    env::var("HOME").unwrap_or_else(|_| "".to_string())
}

pub fn get_dotfiles_dir() -> String {
    format!("{}/.dotfiles", get_home_dir())
}

pub fn install_or_upgrade_repo(
    repo_url: &str,
    dest_path: &str,
    repo_name: &str,
    upgrade_mode: bool,
    dry_run: bool,
    verbose: bool,
) -> bool {
    if Path::new(dest_path).exists() {
        log_info(&format!(
            "{} already installed at {}.",
            repo_name, dest_path
        ));
        if upgrade_mode {
            log_info(&format!("Upgrading {}...", repo_name));
            if !execute_command(
                &format!("(cd \"{}\" && git pull --rebase --autostash)", dest_path),
                &format!("Upgrade {}", repo_name),
                dry_run,
                verbose,
            ) {
                log_warn(&format!("Failed to upgrade {}, continuing...", repo_name));
            }
        }
        true
    } else {
        log_info(&format!("Installing {}...", repo_name));
        if !execute_command(
            &format!("git clone --depth 1 \"{}\" \"{}\"", repo_url, dest_path),
            &format!("Clone {}", repo_name),
            dry_run,
            verbose,
        ) {
            log_error(&format!("Failed to clone {}", repo_name));
            return false;
        }
        log_success(&format!("Successfully installed {}", repo_name));
        true
    }
}

pub fn setup_oh_my_zsh(upgrade_mode: bool, dry_run: bool, verbose: bool) {
    log_info("Setting up Oh My Zsh");
    let oh_my_zsh_dir = format!("{}/oh-my-zsh", get_dotfiles_dir());

    if !Path::new(&oh_my_zsh_dir).exists() {
        execute_command(
            &format!("git clone \"{}\" \"{}\"", OH_MY_ZSH_REPO, oh_my_zsh_dir),
            "Install Oh My Zsh",
            dry_run,
            verbose,
        );
        execute_command(
            &format!(
                "export ZSH=\"{}\" && \"{}/tools/install.sh\" --unattended --skip-chsh || true",
                oh_my_zsh_dir, oh_my_zsh_dir
            ),
            "Run Oh My Zsh installer",
            dry_run,
            verbose,
        );
    } else {
        log_info("Oh My Zsh is already installed");
        if upgrade_mode {
            log_info("[ZSH] Upgrading Oh My Zsh...");
            execute_command(
                &format!(
                    "(cd \"{}\" && git pull --rebase --autostash)",
                    oh_my_zsh_dir
                ),
                "Upgrade Oh My Zsh",
                dry_run,
                verbose,
            );
        }
    }
}

pub fn setup_zsh_plugins(upgrade_mode: bool, dry_run: bool, verbose: bool) {
    log_info("Setting up Zsh plugins");
    let omz_dir = format!("{}/oh-my-zsh", get_dotfiles_dir());

    install_or_upgrade_repo(
        ZSH_SYNTAX_HIGHLIGHTING_REPO,
        &format!("{}/custom/plugins/zsh-syntax-highlighting", omz_dir),
        "zsh-syntax-highlighting",
        upgrade_mode,
        dry_run,
        verbose,
    );
    install_or_upgrade_repo(
        ZSH_COMPLETIONS_REPO,
        &format!("{}/custom/plugins/zsh-completions", omz_dir),
        "zsh-completions",
        upgrade_mode,
        dry_run,
        verbose,
    );
    install_or_upgrade_repo(
        ZSH_HISTORY_SEARCH_REPO,
        &format!("{}/custom/plugins/zsh-history-substring-search", omz_dir),
        "zsh-history-substring-search",
        upgrade_mode,
        dry_run,
        verbose,
    );
    install_or_upgrade_repo(
        ZSH_AUTOSUGGESTIONS_REPO,
        &format!("{}/custom/plugins/zsh-autosuggestions", omz_dir),
        "zsh-autosuggestions",
        upgrade_mode,
        dry_run,
        verbose,
    );
    install_or_upgrade_repo(
        POWERLEVEL10K_REPO,
        &format!("{}/custom/themes/powerlevel10k", omz_dir),
        "Powerlevel10k",
        upgrade_mode,
        dry_run,
        verbose,
    );
}

pub fn setup_p10k_config(dry_run: bool, verbose: bool) {
    let src = format!("{}/tool/zsh/.p10k.zsh", get_dotfiles_dir());
    let dest = format!("{}/.p10k.zsh", get_home_dir());

    if !Path::new(&src).exists() {
        log_warn(&format!(".p10k.zsh not found at {}, skipping symlink", src));
        return;
    }

    if let Ok(metadata) = std::fs::symlink_metadata(&dest) {
        if metadata.file_type().is_symlink() {
            log_info("~/.p10k.zsh symlink already exists");
            return;
        }

        log_info("Backing up existing ~/.p10k.zsh");
        execute_command(
            &format!("mv \"{}\" \"{}.backup.$(date +%Y%m%d_%H%M%S)\"", dest, dest),
            "Backup .p10k.zsh",
            dry_run,
            verbose,
        );
    }

    execute_command(
        &format!("ln -sf \"{}\" \"{}\"", src, dest),
        "Symlink .p10k.zsh",
        dry_run,
        verbose,
    );
    log_success(&format!("Linked .p10k.zsh -> {}", dest));
}

pub fn ensure_custom_config_in_zshrc(dry_run: bool, _verbose: bool) {
    let zshrc_path = format!("{}/.zshrc", get_home_dir());
    let custom_config_line = "source $HOME/.dotfiles/tool/zsh/config.zsh";

    if !Path::new(&zshrc_path).exists() {
        log_info("Creating new .zshrc");
        if !dry_run {
            let _ = std::fs::File::create(&zshrc_path);
        }
    }

    let contents = std::fs::read_to_string(&zshrc_path).unwrap_or_default();
    if !contents.contains(custom_config_line) {
        log_info("Adding custom config to ~/.zshrc");
        if !dry_run {
            use std::io::Write;
            if let Ok(mut file) = std::fs::OpenOptions::new().append(true).open(&zshrc_path) {
                writeln!(
                    file,
                    "\n# Dotfiles custom configuration\n{}",
                    custom_config_line
                )
                .unwrap();
            }
        }
    } else {
        log_info("Custom config already sourced in ~/.zshrc");
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
    fn test_zsh_directories() {
        let dir = tempdir().unwrap();
        env::set_var("HOME", dir.path());
        
        let home = get_home_dir();
        assert_eq!(home, dir.path().to_str().unwrap());
        
        let dotfiles = get_dotfiles_dir();
        assert_eq!(dotfiles, format!("{}/.dotfiles", home));
        
        env::remove_var("HOME");
    }

    #[test]
    #[serial]
    fn test_zsh_functions_dry_run() {
        let dir = tempdir().unwrap();
        env::set_var("HOME", dir.path());
        
        // These should not modify the actual system or crash, thanks to dry_run=true
        setup_oh_my_zsh(false, true, false);
        setup_zsh_plugins(false, true, false);
        setup_p10k_config(true, false);
        ensure_custom_config_in_zshrc(true, false);
        
        env::remove_var("HOME");
    }
}
