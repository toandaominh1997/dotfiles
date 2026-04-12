use colored::*;
use std::process::{Command, Stdio};

pub fn log_info(msg: &str) {
    println!("{} {}", "ℹ".blue().bold(), msg);
}

pub fn log_warn(msg: &str) {
    println!("{} {}", "⚠".yellow().bold(), msg);
}

pub fn log_error(msg: &str) {
    eprintln!("{} {}", "✖".red().bold(), msg);
}

pub fn log_debug(msg: &str, verbose: bool) {
    if verbose {
        println!("{} {}", "⚙".cyan(), msg.dimmed());
    }
}

pub fn log_success(msg: &str) {
    println!("{} {}", "✔".green().bold(), msg);
}

pub fn detect_os() -> String {
    if cfg!(target_os = "macos") {
        return "macos".to_string();
    }

    if let Ok(content) = std::fs::read_to_string("/etc/os-release") {
        let content_lower = content.to_lowercase();
        if content_lower.contains("id_like=debian")
            || content_lower.contains("id=ubuntu")
            || content_lower.contains("id=debian")
        {
            return "debian".to_string();
        } else if content_lower.contains("id_like=arch") || content_lower.contains("id=arch") {
            return "arch".to_string();
        } else if content_lower.contains("id_like=rhel")
            || content_lower.contains("id_like=fedora")
            || content_lower.contains("id=fedora")
        {
            return "redhat".to_string();
        }
    }

    "linux".to_string()
}

pub fn command_exists(cmd: &str) -> bool {
    Command::new("sh")
        .arg("-c")
        .arg(format!("command -v {}", cmd))
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|s| s.success())
        .unwrap_or(false)
}

use indicatif::{ProgressBar, ProgressStyle};
use std::time::Duration;

pub fn execute_command(cmd: &str, description: &str, dry_run: bool, verbose: bool) -> bool {
    if dry_run {
        log_info(&format!("[DRY-RUN] Would execute: {}", description));
        log_debug(&format!("Command: {}", cmd), verbose);
        return true;
    }

    log_debug(&format!("Executing: {}", cmd), verbose);

    let pb = if !verbose {
        let pb = ProgressBar::new_spinner();
        pb.enable_steady_tick(Duration::from_millis(100));
        pb.set_style(
            ProgressStyle::default_spinner()
                .tick_strings(&["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"])
                .template("{spinner:.cyan} {msg}")
                .unwrap(),
        );
        pb.set_message(format!("{}...", description));
        Some(pb)
    } else {
        None
    };

    let output = if verbose {
        Command::new("bash").arg("-c").arg(cmd).status()
    } else {
        Command::new("bash")
            .arg("-c")
            .arg(cmd)
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
    };

    if let Some(pb) = pb {
        pb.finish_and_clear();
    }

    match output {
        Ok(status) if status.success() => true,
        _ => {
            log_error(&format!("Command failed: {}", description));
            log_error(&format!("Failed command: {}", cmd));
            false
        }
    }
}
