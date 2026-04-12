use crate::utils::{command_exists, detect_os, execute_command, log_error, log_info, log_success};
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

use rayon::prelude::*;

pub fn process_packages(
    packages: &[String], pkg_type: &str, is_required: bool, upgrade_mode: bool, dry_run: bool, verbose: bool
) {
    if packages.is_empty() {
        return;
    }

    let os_type = detect_os();
    let pkg_manager = get_pkg_manager(&os_type);

    let (to_install, to_upgrade): (Vec<String>, Vec<String>) = packages
        .into_par_iter()
        .map(|pkg| pkg.clone())
        .partition(|pkg| !package_exists(pkg, pkg_type));

    if !to_install.is_empty() {
        log_info(&format!("Installing {} packages...", to_install.len()));
        let cmd = if pkg_manager == "brew" {
            format!("brew install {} {}", pkg_type, to_install.join(" "))
        } else if pkg_manager == "apt-get" {
            format!("sudo apt-get install -y {}", to_install.join(" "))
        } else if pkg_manager == "dnf" {
            format!("sudo dnf install -y {}", to_install.join(" "))
        } else if pkg_manager == "pacman" {
            format!("sudo pacman -S --noconfirm {}", to_install.join(" "))
        } else {
            "".to_string()
        };

        if !execute_command(&cmd, "Install packages", dry_run, verbose) {
            log_error("Failed to install packages.");
            if is_required {
                std::process::exit(1);
            }
        } else {
            log_success("Successfully installed packages.");
        }
    } else {
        log_info("All packages are already installed.");
    }

    if upgrade_mode && !to_upgrade.is_empty() {
        log_info(&format!("Upgrading {} packages...", to_upgrade.len()));
        let cmd = if pkg_manager == "brew" {
            format!("brew upgrade {} {} 2>/dev/null || true", pkg_type, to_upgrade.join(" "))
        } else if pkg_manager == "apt-get" {
            format!("sudo apt-get install --only-upgrade -y {}", to_upgrade.join(" "))
        } else if pkg_manager == "dnf" {
            format!("sudo dnf upgrade -y {}", to_upgrade.join(" "))
        } else if pkg_manager == "pacman" {
            format!("sudo pacman -S --noconfirm {}", to_upgrade.join(" "))
        } else {
            "".to_string()
        };

        execute_command(&cmd, "Upgrade packages", dry_run, verbose);
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
