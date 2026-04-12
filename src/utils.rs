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
use std::io::{BufRead, BufReader};
use std::time::Duration;

pub fn execute_command(cmd: &str, description: &str, dry_run: bool, verbose: bool) -> bool {
    if dry_run {
        log_info(&format!("[DRY-RUN] Would execute: {}", description));
        log_debug(&format!("Command: {}", cmd), verbose);
        return true;
    }

    log_debug(&format!("Executing: {}", cmd), verbose);

    if verbose {
        let status = Command::new("bash").arg("-c").arg(cmd).status();
        return match status {
            Ok(s) if s.success() => true,
            _ => {
                log_error(&format!("Command failed: {}", description));
                log_error(&format!("Failed command: {}", cmd));
                false
            }
        };
    }

    let pb = ProgressBar::new_spinner();
    pb.enable_steady_tick(Duration::from_millis(100));
    pb.set_style(
        ProgressStyle::default_spinner()
            .tick_strings(&["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"])
            .template("{spinner:.cyan} {msg}")
            .unwrap(),
    );
    pb.set_message(format!("{}...", description));

    let mut child = Command::new("bash")
        .arg("-c")
        .arg(format!("{} 2>&1", cmd))
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .stdin(Stdio::null())
        .spawn()
        .unwrap_or_else(|e| panic!("Failed to spawn command: {}", e));

    if let Some(stdout) = child.stdout.take() {
        let reader = BufReader::new(stdout);
        for line in reader.lines() {
            if let Ok(line) = line {
                let trimmed = line.trim();
                if !trimmed.is_empty() {
                    let mut msg = trimmed.to_string();
                    if msg.len() > 60 {
                        msg.truncate(57);
                        msg.push_str("...");
                    }
                    pb.set_message(format!("{} - {}", description, msg));
                }
            }
        }
    }

    let status = child
        .wait()
        .unwrap_or_else(|e| panic!("Failed to wait on child: {}", e));
    pb.finish_and_clear();

    match status.success() {
        true => true,
        false => {
            log_error(&format!("Command failed: {}", description));
            log_error(&format!("Failed command: {}", cmd));
            false
        }
    }
}
