use crate::utils::{command_exists, detect_os, execute_command, log_error, log_info, log_success, log_warn};
use std::process::{Command, Stdio};
use std::fs::File;
use std::io::BufReader;

const BREW_INSTALL_URL: &str = "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh";

pub const REQUIRED_PACKAGES: &[&str] = &[
    "bash", "fzf", "git", "neovim", "tmux", "vim", "zsh"
];

pub const FORMULAE_PACKAGES: &[&str] = &[
    "ansible", "awscli", "bat", "bazelisk", "cmake", "curl", "duf", "docker",
    "docker-compose", "fish", "gcc", "gh", "go", "helm", "htop", "httpie", "k9s",
    "kubernetes-cli", "lazydocker", "lazygit", "node", "nvm", "rust", "tldr",
    "telnet", "terraform", "thefuck", "unzip", "wget", "zoxide"
];

pub const CASK_PACKAGES: &[&str] = &[
    "alt-tab", "brave-browser", "discord", "docker", "git-credential-manager",
    "google-chrome", "google-cloud-sdk", "iterm2", "jetbrains-toolbox", "messenger",
    "microsoft-edge", "microsoft-teams", "monitorcontrol", "notion", "obsidian",
    "postman", "rar", "slack", "spotify", "stats", "sublime-text", "telegram",
    "tor-browser", "visual-studio-code", "whatsapp", "zoom"
];

use serde::Deserialize;

#[derive(Deserialize)]
struct PackageConfig {
    required_packages: Option<Vec<String>>,
    formulae_packages: Option<Vec<String>>,
    cask_packages: Option<Vec<String>>,
}

pub fn get_packages_from_json(array_name: &str, default_packages: &[&str]) -> Vec<String> {
    let home = std::env::var("HOME").unwrap_or_else(|_| "".to_string());
    let config_path = format!("{}/.dotfiles/tool/config/packages.json", home);
    
    let file = match File::open(&config_path) {
        Ok(f) => f,
        Err(_) => return default_packages.iter().map(|s| s.to_string()).collect(),
    };

    let reader = BufReader::new(file);
    let config: PackageConfig = match serde_json::from_reader(reader) {
        Ok(c) => c,
        Err(_) => return default_packages.iter().map(|s| s.to_string()).collect(),
    };

    let pkgs = match array_name {
        "required_packages" => config.required_packages,
        "formulae_packages" => config.formulae_packages,
        "cask_packages" => config.cask_packages,
        _ => None,
    };

    match pkgs {
        Some(p) if !p.is_empty() => p,
        _ => default_packages.iter().map(|s| s.to_string()).collect(),
    }
}

fn package_exists(package: &str, pkg_type: &str) -> bool {
    if pkg_type == "--cask" {
        Command::new("brew").args(["list", "--cask", package])
            .stdout(Stdio::null()).stderr(Stdio::null()).status()
            .map(|s| s.success()).unwrap_or(false)
    } else {
        Command::new("brew").args(["list", "--formula", package])
            .stdout(Stdio::null()).stderr(Stdio::null()).status()
            .map(|s| s.success()).unwrap_or(false)
            || command_exists(package)
    }
}

pub fn install_homebrew(upgrade_mode: bool, dry_run: bool, verbose: bool) {
    if command_exists("brew") {
        log_info("Homebrew is already installed.");
        if upgrade_mode {
            execute_command("brew update", "Update Homebrew", dry_run, verbose);
            log_info("End update homebrew");
        }
    } else {
        execute_command(
            &format!("/bin/bash -c \"$(curl -fsSL {})\"", BREW_INSTALL_URL),
            "Install Homebrew", dry_run, verbose
        );

        if detect_os() == "linux" {
            let home = std::env::var("HOME").unwrap_or_else(|_| "".to_string());
            let linuxbrew_home = format!("{}/.homebrew/bin/brew", home);
            let linuxbrew_sys = "/home/linuxbrew/.linuxbrew/bin/brew";

            let path = if std::path::Path::new(&linuxbrew_home).exists() {
                linuxbrew_home
            } else if std::path::Path::new(linuxbrew_sys).exists() {
                linuxbrew_sys.to_string()
            } else {
                "".to_string()
            };

            if !path.is_empty() {
                execute_command(&format!("eval \"$({} shellenv)\"", path), "Eval brew shellenv", dry_run, verbose);
            }

            execute_command("brew update --force --quiet", "Brew update", dry_run, verbose);
            execute_command("chmod -R go-w \"$(brew --prefix)/share/zsh\"", "Brew fix permissions", dry_run, verbose);
        }
    }
}

pub fn install_or_upgrade_package(
    package: &str, pkg_type: &str, is_required: bool, upgrade_mode: bool, dry_run: bool, verbose: bool
) -> bool {
    if package_exists(package, pkg_type) {
        log_info(&format!("{} is already installed.", package));
        if upgrade_mode {
            log_info(&format!("Upgrading {}...", package));
            execute_command(
                &format!("brew upgrade \"{}\" 2>/dev/null || true", package),
                &format!("Upgrade {}", package), dry_run, verbose
            );
        }
        return true;
    }

    log_info(&format!("Installing {}...", package));
    let cmd = format!("brew install {} \"{}\"", pkg_type, package);
    if !execute_command(&cmd, &format!("Install {}", package), dry_run, verbose) {
        if is_required {
            log_error(&format!("Failed to install required package: {}", package));
            std::process::exit(1);
        } else {
            log_warn(&format!("Failed to install optional package: {}", package));
            return false;
        }
    }
    
    log_success(&format!("Successfully installed {}", package));
    true
}

pub fn process_packages(
    packages: &[String], pkg_type: &str, is_required: bool, upgrade_mode: bool, dry_run: bool, verbose: bool
) {
    let mut failed_packages = Vec::new();
    let mut success_count = 0;

    for pkg in packages {
        log_info(&format!("Install {}", pkg));
        if install_or_upgrade_package(pkg, pkg_type, is_required, upgrade_mode, dry_run, verbose) {
            success_count += 1;
        } else {
            failed_packages.push(pkg.clone());
        }
    }

    log_info(&format!("Successfully installed {} packages", success_count));
    log_info(&format!("Failed to install {} packages", failed_packages.len()));

    if !failed_packages.is_empty() {
        if is_required {
            log_error(&format!("Failed to install the following required packages: {:?}", failed_packages));
            std::process::exit(1);
        } else {
            log_warn(&format!("Failed to install the following optional packages: {:?}", failed_packages));
        }
    }
}
