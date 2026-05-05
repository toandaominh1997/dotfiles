use crate::packages::get_pkg_manager;
use crate::utils::{command_exists, detect_os, log_error, log_success, log_warn};
use colored::*;
use std::path::Path;

fn expected_package_manager(os_type: &str) -> Option<&'static str> {
    match get_pkg_manager(os_type) {
        "" => None,
        pkg_manager => Some(pkg_manager),
    }
}

fn required_tools(os_type: &str) -> Vec<&'static str> {
    let mut tools = vec!["git", "curl", "zsh", "tmux", "nvim", "starship"];

    if let Some(pkg_manager) = expected_package_manager(os_type) {
        tools.push(pkg_manager);
    }

    tools
}

fn expected_paths(home: &str) -> Vec<(String, &'static str, bool)> {
    vec![
        (format!("{}/.zshrc", home), "Zsh config", false),
        (format!("{}/.tmux.conf", home), "Tmux config", false),
        (
            format!("{}/.config/nvim/init.lua", home),
            "Neovim init.lua",
            true,
        ),
        (
            format!("{}/.config/starship.toml", home),
            "Starship config",
            true,
        ),
    ]
}

pub fn run_doctor() -> usize {
    println!(
        "{}",
        "\n🩺 Running Dotfiles Health Check...\n".cyan().bold()
    );

    let os_type = detect_os();
    let mut issues_found = 0;

    println!("{}", "Checking Essential Tools:".bold());
    for tool in required_tools(&os_type) {
        if command_exists(tool) {
            log_success(&format!("{} is installed", tool));
        } else {
            log_warn(&format!("{} is NOT installed", tool));
            issues_found += 1;
        }
    }
    println!();

    println!("{}", "Checking Configurations:".bold());
    let home = std::env::var("HOME").unwrap_or_else(|_| "~".to_string());

    for (path_str, desc, should_be_symlink) in expected_paths(&home) {
        let path = Path::new(&path_str);
        if !path.exists() {
            log_error(&format!("{} is MISSING ({})", desc, path_str));
            issues_found += 1;
            continue;
        }

        if should_be_symlink && !path.is_symlink() {
            log_warn(&format!(
                "{} exists but is NOT a symlink ({})",
                desc, path_str
            ));
            issues_found += 1;
            continue;
        }

        log_success(&format!("{} exists ({})", desc, path_str));
    }
    println!();

    if issues_found == 0 {
        println!(
            "{}",
            "✨ All checks passed! Your system is healthy."
                .green()
                .bold()
        );
    } else {
        println!(
            "{}",
            format!(
                "⚠️ Found {} issue(s). Consider running setup or checking missing dependencies.",
                issues_found
            )
            .yellow()
            .bold()
        );
    }
    println!();

    issues_found
}

#[cfg(test)]
mod tests {
    use super::{expected_package_manager, expected_paths, required_tools};

    #[test]
    fn doctor_uses_platform_package_manager_when_supported() {
        assert_eq!(expected_package_manager("macos"), Some("brew"));
        assert_eq!(expected_package_manager("debian"), Some("apt-get"));
        assert_eq!(expected_package_manager("linux"), None);
    }

    #[test]
    fn doctor_requires_platform_specific_package_manager() {
        assert!(required_tools("macos").contains(&"brew"));
        assert!(required_tools("debian").contains(&"apt-get"));
        assert!(!required_tools("linux").contains(&"brew"));
    }

    #[test]
    fn doctor_only_requires_symlinks_for_managed_config_targets() {
        let paths = expected_paths("/tmp/home");
        let zshrc = paths
            .iter()
            .find(|(_, desc, _)| *desc == "Zsh config")
            .unwrap();
        let nvim = paths
            .iter()
            .find(|(_, desc, _)| *desc == "Neovim init.lua")
            .unwrap();

        assert!(!zshrc.2);
        assert!(nvim.2);
    }
}
