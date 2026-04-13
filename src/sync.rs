use crate::utils::{execute_command, log_error, log_info, log_success};
use colored::*;
use std::process::Command;

pub fn run_sync(dry_run: bool, verbose: bool) {
    println!("{}", "\n🔄 Syncing Dotfiles...\n".cyan().bold());

    // 1. Get current dotfiles directory
    let dotfiles_dir = std::env::current_dir().unwrap_or_else(|_| std::path::PathBuf::from("."));
    log_info(&format!("Dotfiles directory: {:?}", dotfiles_dir));

    // 2. Check for git repository
    if !dotfiles_dir.join(".git").exists() {
        log_error("Not a git repository. Cannot sync.");
        return;
    }

    // 3. Check for uncommitted changes
    let status_output = Command::new("git")
        .arg("status")
        .arg("--porcelain")
        .output()
        .expect("Failed to execute git status");

    if status_output.stdout.is_empty() {
        log_info("No changes to sync. Everything is up to date.");
        return;
    }

    log_info("Found changes to sync:");
    println!("{}", String::from_utf8_lossy(&status_output.stdout));

    // 4. Stage changes
    if execute_command("git add -A", "Staging changes", dry_run, verbose) {
        log_success("Changes staged");
    } else {
        log_error("Failed to stage changes");
        return;
    }

    // 5. Commit changes
    let timestamp = chrono::Local::now().format("%Y-%m-%d %H:%M:%S").to_string();
    let commit_msg = format!("Sync dotfiles: {}", timestamp);

    if execute_command(
        &format!("git commit -m \"{}\"", commit_msg),
        "Committing changes",
        dry_run,
        verbose,
    ) {
        log_success(&format!("Committed: {}", commit_msg));
    } else {
        log_error("Failed to commit changes");
        return;
    }

    // 6. Push changes
    if execute_command("git push", "Pushing to remote", dry_run, verbose) {
        log_success("✨ Sync complete! Changes pushed to remote.");
    } else {
        log_error("Failed to push changes to remote. Are you on a branch with an upstream?");
    }
    println!();
}
