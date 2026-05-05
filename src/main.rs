mod config;
mod dashboard;
mod doctor;
mod fonts;
mod packages;
mod sync;
mod tmux;
mod tui;
mod utils;
mod vim;
mod zsh;

use clap::Parser;
use std::process::Command;

use config::DotupConfig;
use packages::process_packages;
use tui::MenuAction;
use utils::{detect_os, log_error, log_info, log_success, log_warn};

const SCRIPT_VERSION: &str = "2.1.0";

#[derive(Parser, Debug)]
#[command(author, version = SCRIPT_VERSION, about = "Dotfiles Setup Script", long_about = None)]
struct Args {
    /// Configuration profile to use (e.g., default, work, minimal)
    #[arg(short = 'p', long, default_value = "default")]
    profile: String,

    /// Upgrade existing packages
    #[arg(short = 'u', long)]
    upgrade: bool,

    /// Show what would be installed without making changes
    #[arg(short = 'd', long)]
    dry_run: bool,

    /// Enable verbose output
    #[arg(short = 'v', long)]
    verbose: bool,

    /// Force installation even if already present
    #[arg(short = 'f', long)]
    force: bool,

    /// Run automatically without interactive menu
    #[arg(short = 'a', long)]
    auto: bool,

    /// Show system metrics dashboard
    #[arg(long)]
    dashboard: bool,

    /// Check system health
    #[arg(long)]
    doctor: bool,

    /// Sync dotfiles to remote repository
    #[arg(long)]
    sync: bool,
}

fn run_packages(profile_name: &str, upgrade_mode: bool, dry_run: bool, verbose: bool) {
    let os_type = detect_os();
    packages::init_pkg_manager(upgrade_mode, dry_run, verbose);

    let config = DotupConfig::load();
    let profile = match config.get_profile(profile_name) {
        Some(p) => p,
        None => {
            log_error(&format!(
                "Profile '{}' not found in dotup.toml. Edit dotup.toml or pass --profile <name>.",
                profile_name
            ));
            std::process::exit(1);
        }
    };

    if profile.required_packages.is_empty() {
        log_warn(&format!(
            "Profile '{}' has no required_packages; nothing to install in the required step.",
            profile_name
        ));
    }

    process_packages(
        &profile.required_packages,
        "--formula",
        true,
        upgrade_mode,
        dry_run,
        verbose,
    );
    process_packages(
        &profile.formulae_packages,
        "--formula",
        false,
        upgrade_mode,
        dry_run,
        verbose,
    );

    if os_type == "macos" {
        log_info("==> Installing macOS Brew cask packages...");
        process_packages(
            &profile.cask_packages,
            "--cask",
            false,
            upgrade_mode,
            dry_run,
            verbose,
        );
    }
}

fn run_zsh(upgrade_mode: bool, dry_run: bool, verbose: bool) {
    zsh::setup_oh_my_zsh(upgrade_mode, dry_run, verbose);
    zsh::setup_zsh_plugins(upgrade_mode, dry_run, verbose);
    zsh::setup_starship_config(dry_run, verbose);
    zsh::ensure_custom_config_in_zshrc(dry_run, verbose);
}

fn run_all(profile_name: &str, upgrade_mode: bool, dry_run: bool, verbose: bool) {
    run_packages(profile_name, upgrade_mode, dry_run, verbose);
    fonts::install_fonts(dry_run, verbose);
    run_zsh(upgrade_mode, dry_run, verbose);
    tmux::setup_tmux(upgrade_mode, dry_run, verbose);
    vim::setup_vim_nvim(upgrade_mode, dry_run, verbose);

    if !dry_run && detect_os() == "macos" {
        log_info("==> Running final Brew cleanup...");
        let _ = Command::new("brew").arg("cleanup").status();
    }

    log_success("==> Dotfiles setup complete!");

    log_info("");
    log_info("Next steps:");
    log_info("  1. Restart your terminal or run: source ~/.zshrc");
    log_info("  2. Open tmux and press 'prefix + I' to install tmux plugins");
    log_info("  3. Open nvim and run :Lazy sync if plugins are not installed");
    log_info("");
    log_info("Configuration files:");
    log_info("  - Zsh:  ~/.zshrc");
    log_info("  - Tmux: ~/.tmux.conf");
    log_info("  - Vim:  ~/.vimrc");
    log_info("  - Nvim: ~/.config/nvim");
}

fn interactive_menu(profile_name: &str, mut upgrade_mode: bool, dry_run: bool, verbose: bool) {
    loop {
        let action = match tui::show_menu() {
            Ok(Some(action)) => action,
            Ok(None) => break,
            Err(e) => {
                log_error(&format!("Terminal error: {}", e));
                break;
            }
        };

        print!("{esc}[2J{esc}[1;1H", esc = 27 as char);

        match action {
            MenuAction::InstallEverything => {
                run_all(profile_name, upgrade_mode, dry_run, verbose);
                break;
            }
            MenuAction::InstallPackages => {
                run_packages(profile_name, upgrade_mode, dry_run, verbose);
                wait_for_enter();
            }
            MenuAction::SetupZsh => {
                run_zsh(upgrade_mode, dry_run, verbose);
                wait_for_enter();
            }
            MenuAction::SetupTmux => {
                tmux::setup_tmux(upgrade_mode, dry_run, verbose);
                wait_for_enter();
            }
            MenuAction::SetupVim => {
                vim::setup_vim_nvim(upgrade_mode, dry_run, verbose);
                wait_for_enter();
            }
            MenuAction::InstallFonts => {
                fonts::install_fonts(dry_run, verbose);
                wait_for_enter();
            }
            MenuAction::SystemDashboard => {
                dashboard::show_dashboard();
            }
            MenuAction::UpgradeSetup => {
                upgrade_mode = true;
                run_all(profile_name, upgrade_mode, dry_run, verbose);
                break;
            }
            MenuAction::RunDoctor => {
                let _ = doctor::run_doctor();
                wait_for_enter();
            }
            MenuAction::SyncDotfiles => {
                sync::run_sync(dry_run, verbose);
                wait_for_enter();
            }
            MenuAction::Quit => {
                log_info("Exiting...");
                std::process::exit(0);
            }
        }
    }
}

fn wait_for_enter() {
    use std::io::{Read, Write};
    print!("Press Enter to continue...");
    let _ = std::io::stdout().flush();
    let mut buffer = [0; 1];
    let _ = std::io::stdin().read_exact(&mut buffer);
}

fn main() {
    let args = Args::parse();

    log_info(&format!("Upgrade: {}", args.upgrade));
    log_info(&format!("Profile: {}", args.profile));

    if args.dashboard {
        dashboard::show_dashboard();
        return;
    }
    if args.doctor {
        let issues = doctor::run_doctor();
        std::process::exit(if issues == 0 { 0 } else { 1 });
    }
    if args.sync {
        sync::run_sync(args.dry_run, args.verbose);
        return;
    }

    if args.auto {
        run_all(&args.profile, args.upgrade, args.dry_run, args.verbose);
    } else {
        interactive_menu(&args.profile, args.upgrade, args.dry_run, args.verbose);
    }
}
