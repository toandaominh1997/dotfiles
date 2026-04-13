use crate::utils::{command_exists, log_error, log_success, log_warn};
use colored::*;
use std::path::Path;

pub fn run_doctor() {
    println!(
        "{}",
        "\n🩺 Running Dotfiles Health Check...\n".cyan().bold()
    );

    let mut issues_found = 0;

    // 1. Check Essential CLI Tools
    println!("{}", "Checking Essential Tools:".bold());
    let essential_tools = vec!["git", "curl", "brew", "zsh", "tmux", "nvim", "starship"];
    for tool in essential_tools {
        if command_exists(tool) {
            log_success(&format!("{} is installed", tool));
        } else {
            log_warn(&format!("{} is NOT installed", tool));
            issues_found += 1;
        }
    }
    println!();

    // 2. Check Expected Configurations (Symlinks & Directories)
    println!("{}", "Checking Configurations:".bold());
    let home = std::env::var("HOME").unwrap_or_else(|_| "~".to_string());

    let expected_paths = vec![
        (format!("{}/.zshrc", home), "Zsh config"),
        (format!("{}/.tmux.conf", home), "Tmux config"),
        (format!("{}/.config/nvim/init.lua", home), "Neovim init.lua"),
        (format!("{}/.config/starship.toml", home), "Starship config"),
    ];

    for (path_str, desc) in expected_paths {
        let path = Path::new(&path_str);
        if path.exists() {
            if path.is_symlink() {
                log_success(&format!("{} symlink exists ({})", desc, path_str));
            } else {
                log_warn(&format!(
                    "{} exists but is NOT a symlink ({})",
                    desc, path_str
                ));
                issues_found += 1;
            }
        } else {
            log_error(&format!("{} is MISSING ({})", desc, path_str));
            issues_found += 1;
        }
    }
    println!();

    // 3. Final Report
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
}
