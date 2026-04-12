use std::process::{Command, Stdio};
use colored::*;

pub fn log_info(msg: &str) {
    println!("{} {}", "[INFO]".blue(), msg);
}

pub fn log_warn(msg: &str) {
    println!("{} {}", "[WARN]".yellow().bold(), msg);
}

pub fn log_error(msg: &str) {
    eprintln!("{} {}", "[ERROR]".red(), msg);
}

pub fn log_debug(msg: &str, verbose: bool) {
    if verbose {
        println!("{} {}", "[DEBUG]".cyan(), msg);
    }
}

pub fn log_success(msg: &str) {
    println!("{} {}", "[SUCCESS]".green(), msg);
}

pub fn detect_os() -> &'static str {
    if cfg!(target_os = "macos") {
        "macos"
    } else {
        "linux"
    }
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

pub fn execute_command(cmd: &str, description: &str, dry_run: bool, verbose: bool) -> bool {
    if dry_run {
        log_info(&format!("[DRY-RUN] Would execute: {}", description));
        log_debug(&format!("Command: {}", cmd), verbose);
        return true;
    }

    log_debug(&format!("Executing: {}", cmd), verbose);
    
    match Command::new("bash").arg("-c").arg(cmd).status() {
        Ok(status) if status.success() => true,
        _ => {
            log_error(&format!("Command failed: {}", description));
            log_error(&format!("Failed command: {}", cmd));
            false
        }
    }
}
