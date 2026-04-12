use crate::utils::{command_exists, detect_os, log_info, log_success, log_warn};
use crate::zsh::get_home_dir;
use std::path::Path;
use std::process::Command;

pub fn install_fonts() {
    log_info("==> Installing Nerd Fonts (MesloLGS NF)...");

    let os_type = detect_os();
    let home_dir = get_home_dir();
    let font_dir = if os_type == "macos" {
        format!("{}/Library/Fonts", home_dir)
    } else {
        format!("{}/.local/share/fonts", home_dir)
    };

    if !Path::new(&font_dir).exists() {
        std::fs::create_dir_all(&font_dir).unwrap_or_default();
    }

    let base_url = "https://github.com/romkatv/powerlevel10k-media/raw/master";
    let fonts = [
        "MesloLGS%20NF%20Regular.ttf",
        "MesloLGS%20NF%20Bold.ttf",
        "MesloLGS%20NF%20Italic.ttf",
        "MesloLGS%20NF%20Bold%20Italic.ttf",
    ];

    let mut children = vec![];
    let mut downloaded = 0;

    for font_file in &fonts {
        let decoded_font = font_file.replace("%20", " ");
        let font_path = format!("{}/{}", font_dir, decoded_font);

        if Path::new(&font_path).exists() {
            log_info(&format!("Font already exists: {}", decoded_font));
            continue;
        }

        log_info(&format!("Downloading {}...", decoded_font));
        let child = Command::new("curl")
            .args(["-fsSL", &format!("{}/{}", base_url, font_file), "-o", &font_path])
            .spawn();

        if let Ok(c) = child {
            children.push(c);
            downloaded += 1;
        }
    }

    if !children.is_empty() {
        for mut child in children {
            let _ = child.wait().unwrap_or_else(|_| {
                log_warn("A font download failed");
                std::process::exit(1);
            });
        }
        log_success("Fonts downloaded successfully.");
    }

    if downloaded > 0 && os_type == "linux" && command_exists("fc-cache") {
        log_info("Updating font cache...");
        let _ = Command::new("fc-cache").args(["-f", "-v"]).output();
    }
}
