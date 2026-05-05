use colored::*;
use indicatif::{ProgressBar, ProgressStyle};
use std::io::{BufRead, BufReader};
use std::process::{Command, Stdio};
use std::time::Duration;

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

pub fn detect_linux_family(os_release: &str) -> &'static str {
    let content_lower = os_release.to_lowercase();

    if content_lower.contains("id_like=debian")
        || content_lower.contains("id=ubuntu")
        || content_lower.contains("id=debian")
    {
        "debian"
    } else if content_lower.contains("id_like=arch") || content_lower.contains("id=arch") {
        "arch"
    } else if content_lower.contains("id_like=rhel")
        || content_lower.contains("id_like=fedora")
        || content_lower.contains("id=fedora")
    {
        "redhat"
    } else {
        "linux"
    }
}

pub fn detect_os() -> String {
    if cfg!(target_os = "macos") {
        return "macos".to_string();
    }

    if let Ok(content) = std::fs::read_to_string("/etc/os-release") {
        return detect_linux_family(&content).to_string();
    }

    "linux".to_string()
}

pub fn write_file(path: &str, contents: &str, description: &str, dry_run: bool, verbose: bool) -> bool {
    if dry_run {
        log_info(&format!("[DRY-RUN] Would write: {}", description));
        log_debug(&format!("Path: {} ({} bytes)", path, contents.len()), verbose);
        return true;
    }

    log_debug(&format!("Writing: {}", path), verbose);
    match std::fs::write(path, contents) {
        Ok(()) => true,
        Err(e) => {
            log_error(&format!("{} failed: {}", description, e));
            false
        }
    }
}

/// Run `<brew_path> shellenv` and apply its `export VAR="VALUE"` lines
/// to this process's environment, so subsequent `execute_command` children
/// inherit a working brew PATH/HOMEBREW_PREFIX/etc.
pub fn apply_brew_shellenv(brew_path: &str) -> bool {
    let output = match Command::new(brew_path).arg("shellenv").output() {
        Ok(o) if o.status.success() => o,
        Ok(o) => {
            log_error(&format!(
                "{} shellenv exited with {}",
                brew_path, o.status
            ));
            return false;
        }
        Err(e) => {
            log_error(&format!("Failed to run {} shellenv: {}", brew_path, e));
            return false;
        }
    };

    let stdout = String::from_utf8_lossy(&output.stdout);
    for line in stdout.lines() {
        let line = line.trim();
        let rest = match line.strip_prefix("export ") {
            Some(r) => r,
            None => continue,
        };
        let eq = match rest.find('=') {
            Some(i) => i,
            None => continue,
        };
        let name = &rest[..eq];
        let raw_value = &rest[eq + 1..];
        let value = raw_value.trim_matches(|c| c == '"' || c == '\'');
        std::env::set_var(name, value);
    }
    true
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
        for line in reader.lines().map_while(Result::ok) {
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

#[cfg(test)]
mod tests {
    use super::detect_linux_family;

    #[test]
    fn detect_linux_family_recognizes_supported_variants() {
        assert_eq!(detect_linux_family("ID=ubuntu"), "debian");
        assert_eq!(detect_linux_family("ID=debian"), "debian");
        assert_eq!(detect_linux_family("ID_LIKE=arch"), "arch");
        assert_eq!(detect_linux_family("ID=fedora"), "redhat");
        assert_eq!(detect_linux_family("ID=alpine"), "linux");
    }
}
