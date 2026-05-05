use crate::utils::{command_exists, detect_os, execute_command, log_info, log_success, log_warn};
use crate::zsh::get_home_dir;
use indicatif::{MultiProgress, ProgressBar, ProgressStyle};
use rayon::prelude::*;
use std::path::Path;
use std::process::Command;

fn should_refresh_font_cache(os_type: &str) -> bool {
    matches!(os_type, "debian" | "redhat" | "arch" | "linux")
}

pub fn install_fonts(dry_run: bool, verbose: bool) {
    log_info("==> Installing Nerd Fonts (MesloLGS NF)...");

    let os_type = detect_os();
    let home_dir = get_home_dir();
    let font_dir = if os_type == "macos" {
        format!("{}/Library/Fonts", home_dir)
    } else {
        format!("{}/.local/share/fonts", home_dir)
    };

    if !Path::new(&font_dir).exists() && !dry_run {
        if let Err(e) = std::fs::create_dir_all(&font_dir) {
            log_warn(&format!("Failed to create font dir {}: {}", font_dir, e));
            return;
        }
    }

    let font_urls = vec![
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf",
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf",
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf",
        "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf",
        "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf",
        "https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Iosevka/IosevkaNerdFontMono-Regular.ttf",
    ];

    let m = MultiProgress::new();
    let sty = ProgressStyle::with_template("[{elapsed_precise}] {spinner:.cyan} {msg}")
        .unwrap()
        .tick_strings(&["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]);

    let downloaded: usize = font_urls
        .into_par_iter()
        .map(|url| {
            let font_file = url.rsplit('/').next().unwrap_or("");
            let decoded_font = font_file.replace("%20", " ");
            let font_path = format!("{}/{}", font_dir, decoded_font);

            if Path::new(&font_path).exists() {
                return 0;
            }

            if dry_run {
                log_info(&format!("[DRY-RUN] Would download: {}", decoded_font));
                return 1;
            }

            let pb = if !verbose {
                let pb = m.add(ProgressBar::new_spinner());
                pb.set_style(sty.clone());
                pb.enable_steady_tick(std::time::Duration::from_millis(100));
                pb.set_message(format!("Downloading {}", decoded_font));
                Some(pb)
            } else {
                log_info(&format!("Downloading {}", decoded_font));
                None
            };

            let output = Command::new("curl")
                .args(["-fsSL", url, "-o", &font_path])
                .output();

            if let Some(pb) = pb {
                pb.finish_and_clear();
            }

            match output {
                Ok(status) if status.status.success() => 1,
                _ => {
                    log_warn(&format!("Failed to download {}", decoded_font));
                    0
                }
            }
        })
        .sum();

    if downloaded > 0 {
        log_success(&format!("{} fonts downloaded successfully.", downloaded));
    } else {
        log_info("All fonts are already installed.");
    }

    if downloaded > 0 && should_refresh_font_cache(&os_type) && command_exists("fc-cache") {
        log_info("Updating font cache...");
        execute_command(
            "fc-cache -f -v >/dev/null 2>&1",
            "Update font cache",
            dry_run,
            verbose,
        );
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;
    use std::env;
    use tempfile::tempdir;

    #[test]
    fn refresh_font_cache_on_supported_linux_families() {
        assert!(should_refresh_font_cache("debian"));
        assert!(should_refresh_font_cache("redhat"));
        assert!(should_refresh_font_cache("arch"));
        assert!(should_refresh_font_cache("linux"));
        assert!(!should_refresh_font_cache("macos"));
    }

    #[test]
    #[serial]
    fn test_install_fonts_dry_run() {
        let dir = tempdir().unwrap();
        env::set_var("HOME", dir.path());

        install_fonts(true, false);

        env::remove_var("HOME");
    }
}
