use crate::utils::{
    apply_brew_shellenv, command_exists, detect_os, execute_command, log_error, log_info,
    log_success, log_warn,
};
use std::process::{Command, Stdio};

const BREW_INSTALL_URL: &str = "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh";

pub fn get_pkg_manager(os_type: &str) -> &'static str {
    match os_type {
        "macos" => "brew",
        "debian" => "apt-get",
        "redhat" => "dnf",
        "arch" => "pacman",
        _ => "",
    }
}

fn package_exists(package: &str, pkg_type: &str) -> bool {
    let os_type = detect_os();
    let pkg_manager = get_pkg_manager(&os_type);

    if pkg_manager.is_empty() {
        return command_exists(package);
    }

    if pkg_manager == "brew" {
        if pkg_type == "--cask" {
            Command::new("brew")
                .args(["list", "--cask", package])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status()
                .map(|s| s.success())
                .unwrap_or(false)
        } else {
            Command::new("brew")
                .args(["list", "--formula", package])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status()
                .map(|s| s.success())
                .unwrap_or(false)
                || command_exists(package)
        }
    } else if pkg_manager == "apt-get" {
        Command::new("dpkg")
            .args(["-s", package])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map(|s| s.success())
            .unwrap_or(false)
            || command_exists(package)
    } else if pkg_manager == "dnf" {
        Command::new("rpm")
            .args(["-q", package])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map(|s| s.success())
            .unwrap_or(false)
            || command_exists(package)
    } else if pkg_manager == "pacman" {
        Command::new("pacman")
            .args(["-Qs", package])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map(|s| s.success())
            .unwrap_or(false)
            || command_exists(package)
    } else {
        command_exists(package)
    }
}

pub fn init_pkg_manager(upgrade_mode: bool, dry_run: bool, verbose: bool) {
    let os_type = detect_os();
    let pkg_manager = get_pkg_manager(&os_type);

    if pkg_manager.is_empty() {
        log_error(&format!(
            "Unsupported platform '{}'. dotup officially supports macOS and Ubuntu.",
            os_type
        ));
        return;
    }

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
                "Install Homebrew",
                dry_run,
                verbose,
            );
            if os_type != "macos" {
                let home = std::env::var("HOME").unwrap_or_else(|_| "".to_string());
                let path = if std::path::Path::new(&format!("{}/.homebrew/bin/brew", home)).exists()
                {
                    format!("{}/.homebrew/bin/brew", home)
                } else if std::path::Path::new("/home/linuxbrew/.linuxbrew/bin/brew").exists() {
                    "/home/linuxbrew/.linuxbrew/bin/brew".to_string()
                } else {
                    "".to_string()
                };
                if path.is_empty() {
                    log_warn(
                        "Could not locate Homebrew install on Linux; skipping brew shellenv setup",
                    );
                } else if !dry_run && !apply_brew_shellenv(&path) {
                    log_warn(
                        "Failed to apply brew shellenv; subsequent brew commands may not find brew on PATH",
                    );
                }
                execute_command(
                    "brew update --force --quiet",
                    "Brew update",
                    dry_run,
                    verbose,
                );
                execute_command(
                    "chmod -R go-w \"$(brew --prefix)/share/zsh\"",
                    "Brew fix permissions",
                    dry_run,
                    verbose,
                );
            }
        }
    } else if pkg_manager == "apt-get" {
        log_info("==> Initializing APT...");
        if upgrade_mode {
            execute_command(
                "sudo apt-get update && sudo apt-get upgrade -y",
                "Update APT",
                dry_run,
                verbose,
            );
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
            execute_command(
                "sudo pacman -Syu --noconfirm",
                "Update Pacman",
                dry_run,
                verbose,
            );
        } else {
            execute_command(
                "sudo pacman -Sy",
                "Update Pacman database",
                dry_run,
                verbose,
            );
        }
    }
}

use rayon::prelude::*;

fn install_command(pkg_manager: &str, pkg_type: &str, packages: &[&str]) -> Option<String> {
    let joined = packages.join(" ");
    match pkg_manager {
        "brew" => {
            let adopt = if pkg_type == "--cask" { " --adopt" } else { "" };
            Some(format!("brew install {}{} {}", pkg_type, adopt, joined))
        }
        "apt-get" => Some(format!("sudo apt-get install -y {}", joined)),
        "dnf" => Some(format!("sudo dnf install -y {}", joined)),
        "pacman" => Some(format!("sudo pacman -S --noconfirm {}", joined)),
        _ => None,
    }
}

fn upgrade_command(pkg_manager: &str, pkg_type: &str, packages: &[&str]) -> Option<String> {
    let joined = packages.join(" ");
    match pkg_manager {
        "brew" => Some(format!(
            "brew upgrade {} {} 2>/dev/null || true",
            pkg_type, joined
        )),
        "apt-get" => Some(format!(
            "sudo apt-get install --only-upgrade -y {}",
            joined
        )),
        "dnf" => Some(format!("sudo dnf upgrade -y {}", joined)),
        "pacman" => Some(format!("sudo pacman -S --noconfirm {}", joined)),
        _ => None,
    }
}

pub fn process_packages(
    packages: &[String],
    pkg_type: &str,
    is_required: bool,
    upgrade_mode: bool,
    dry_run: bool,
    verbose: bool,
) {
    if packages.is_empty() {
        return;
    }

    let os_type = detect_os();
    let pkg_manager = get_pkg_manager(&os_type);

    if pkg_manager.is_empty() {
        log_error(&format!(
            "Unsupported platform '{}'. dotup officially supports macOS and Ubuntu.",
            os_type
        ));
        if is_required {
            std::process::exit(1);
        }
        return;
    }

    let (to_install, to_upgrade): (Vec<String>, Vec<String>) = packages
        .into_par_iter()
        .map(|pkg| pkg.clone())
        .partition(|pkg| !package_exists(pkg, pkg_type));

    if !to_install.is_empty() {
        log_info(&format!("Installing {} packages...", to_install.len()));
        let to_install_refs: Vec<&str> = to_install.iter().map(String::as_str).collect();
        let batch_cmd = install_command(pkg_manager, pkg_type, &to_install_refs)
            .unwrap_or_default();

        if !execute_command(&batch_cmd, "Install packages", dry_run, verbose) {
            log_error("Batch installation failed. Attempting individual installation...");
            let mut failed_pkgs = Vec::new();
            for pkg in &to_install {
                let single = install_command(pkg_manager, pkg_type, &[pkg.as_str()])
                    .unwrap_or_default();
                if !execute_command(&single, &format!("Install {}", pkg), dry_run, verbose) {
                    failed_pkgs.push(pkg.clone());
                }
            }
            if !failed_pkgs.is_empty() {
                log_error(&format!(
                    "Failed to install the following packages: {:?}",
                    failed_pkgs
                ));
                if is_required {
                    std::process::exit(1);
                }
            } else {
                log_success("Successfully installed packages individually.");
            }
        } else {
            log_success("Successfully installed packages.");
        }
    } else {
        log_info("All packages are already installed.");
    }

    if upgrade_mode && !to_upgrade.is_empty() {
        log_info(&format!("Upgrading {} packages...", to_upgrade.len()));
        let to_upgrade_refs: Vec<&str> = to_upgrade.iter().map(String::as_str).collect();
        let cmd = upgrade_command(pkg_manager, pkg_type, &to_upgrade_refs).unwrap_or_default();
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
        assert_eq!(get_pkg_manager("unknown_os"), "");
    }
}
