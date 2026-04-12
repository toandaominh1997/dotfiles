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

pub fn get_pkg_manager(os_type: &str) -> &'static str {
    match os_type {
        "macos" => "brew",
        "debian" => "apt-get",
        "redhat" => "dnf",
        "arch" => "pacman",
        _ => "brew",
    }
}

fn package_exists(package: &str, pkg_type: &str) -> bool {
    let os_type = detect_os();
    let pkg_manager = get_pkg_manager(&os_type);

    if pkg_manager == "brew" {
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
    } else if pkg_manager == "apt-get" {
        Command::new("dpkg").args(["-s", package])
            .stdout(Stdio::null()).stderr(Stdio::null()).status()
            .map(|s| s.success()).unwrap_or(false) || command_exists(package)
    } else if pkg_manager == "dnf" {
        Command::new("rpm").args(["-q", package])
            .stdout(Stdio::null()).stderr(Stdio::null()).status()
            .map(|s| s.success()).unwrap_or(false) || command_exists(package)
    } else if pkg_manager == "pacman" {
        Command::new("pacman").args(["-Qs", package])
            .stdout(Stdio::null()).stderr(Stdio::null()).status()
            .map(|s| s.success()).unwrap_or(false) || command_exists(package)
    } else {
        command_exists(package)
    }
}

pub fn init_pkg_manager(upgrade_mode: bool, dry_run: bool, verbose: bool) {
    let os_type = detect_os();
    let pkg_manager = get_pkg_manager(&os_type);

    if pkg_manager == "brew" {
        log_info("==> Initializing Homebrew...");
        if command_exists("brew") {
            log_info("Homebrew is already installed.");
            if upgrade_mode {
                execute_command("brew update", "Update Homebrew", dry_run, verbose);
            }
        } else {
            execute_command(
                &format!("/bin/bash -c \"$(curl -fsSL {})\"", BREW_INSTALL_URL),
                "Install Homebrew", dry_run, verbose
            );
            if os_type != "macos" {
                let home = std::env::var("HOME").unwrap_or_else(|_| "".to_string());
                let path = if std::path::Path::new(&format!("{}/.homebrew/bin/brew", home)).exists() {
                    format!("{}/.homebrew/bin/brew", home)
                } else if std::path::Path::new("/home/linuxbrew/.linuxbrew/bin/brew").exists() {
                    "/home/linuxbrew/.linuxbrew/bin/brew".to_string()
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
    } else if pkg_manager == "apt-get" {
        log_info("==> Initializing APT...");
        if upgrade_mode {
            execute_command("sudo apt-get update && sudo apt-get upgrade -y", "Update APT", dry_run, verbose);
        } else {
            execute_command("sudo apt-get update", "Update APT", dry_run, verbose);
        }
    } else if pkg_manager == "dnf" {
        log_info("==> Initializing DNF...");
        if upgrade_mode {
            execute_command("sudo dnf upgrade -y", "Update DNF", dry_run, verbose);
        }
    } else if pkg_manager == "pacman" {
        log_info("==> Initializing Pacman...");
        if upgrade_mode {
            execute_command("sudo pacman -Syu --noconfirm", "Update Pacman", dry_run, verbose);
        } else {
            execute_command("sudo pacman -Sy", "Update Pacman database", dry_run, verbose);
        }
    }
}

pub fn install_or_upgrade_package(
    package: &str, pkg_type: &str, is_required: bool, upgrade_mode: bool, dry_run: bool, verbose: bool
) -> bool {
    let os_type = detect_os();
    let pkg_manager = get_pkg_manager(&os_type);

    if package_exists(package, pkg_type) {
        log_info(&format!("{} is already installed.", package));
        if upgrade_mode {
            log_info(&format!("Upgrading {}...", package));
            if pkg_manager == "brew" {
                execute_command(&format!("brew upgrade \"{}\" 2>/dev/null || true", package), &format!("Upgrade {}", package), dry_run, verbose);
            } else if pkg_manager == "apt-get" {
                execute_command(&format!("sudo apt-get install --only-upgrade -y \"{}\"", package), &format!("Upgrade {}", package), dry_run, verbose);
            } else if pkg_manager == "dnf" {
                execute_command(&format!("sudo dnf upgrade -y \"{}\"", package), &format!("Upgrade {}", package), dry_run, verbose);
            } else if pkg_manager == "pacman" {
                execute_command(&format!("sudo pacman -S --noconfirm \"{}\"", package), &format!("Upgrade {}", package), dry_run, verbose);
            }
        }
        return true;
    }

    log_info(&format!("Installing {}...", package));
    let cmd = if pkg_manager == "brew" {
        format!("brew install {} \"{}\"", pkg_type, package)
    } else if pkg_manager == "apt-get" {
        format!("sudo apt-get install -y \"{}\"", package)
    } else if pkg_manager == "dnf" {
        format!("sudo dnf install -y \"{}\"", package)
    } else if pkg_manager == "pacman" {
        format!("sudo pacman -S --noconfirm \"{}\"", package)
    } else {
        "".to_string()
    };

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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_get_pkg_manager() {
        assert_eq!(get_pkg_manager("macos"), "brew");
        assert_eq!(get_pkg_manager("debian"), "apt-get");
        assert_eq!(get_pkg_manager("redhat"), "dnf");
        assert_eq!(get_pkg_manager("arch"), "pacman");
        assert_eq!(get_pkg_manager("unknown_os"), "brew");
    }
}
