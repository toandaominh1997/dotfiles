mod utils;
mod packages;
mod zsh;
mod tmux;
mod vim;
mod fonts;

use clap::Parser;
use dialoguer::{theme::ColorfulTheme, Select};
use colored::*;
use std::process::Command;

use packages::{
    process_packages, CASK_PACKAGES, FORMULAE_PACKAGES, REQUIRED_PACKAGES,
};
use utils::{detect_os, log_info, log_success, log_error};

const SCRIPT_VERSION: &str = "2.0.0";

#[derive(Parser, Debug)]
#[command(author, version = SCRIPT_VERSION, about = "Dotfiles Setup Script", long_about = None)]
struct Args {
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
}

fn run_packages(upgrade_mode: bool, dry_run: bool, verbose: bool) {
    let os_type = detect_os();
    packages::init_pkg_manager(upgrade_mode, dry_run, verbose);

    let required = packages::get_packages_from_json("required_packages", REQUIRED_PACKAGES);
    let formulae = packages::get_packages_from_json("formulae_packages", FORMULAE_PACKAGES);
    let casks = packages::get_packages_from_json("cask_packages", CASK_PACKAGES);

    process_packages(&required, "--formula", true, upgrade_mode, dry_run, verbose);
    process_packages(&formulae, "--formula", false, upgrade_mode, dry_run, verbose);

    if os_type == "macos" {
        println!("==> Installing macOS Brew cask packages...");
        process_packages(&casks, "--cask", false, upgrade_mode, dry_run, verbose);
    }
}

fn run_zsh(upgrade_mode: bool, dry_run: bool, verbose: bool) {
    zsh::setup_oh_my_zsh(upgrade_mode, dry_run, verbose);
    zsh::setup_zsh_plugins(upgrade_mode, dry_run, verbose);
    zsh::setup_p10k_config(dry_run, verbose);
    zsh::ensure_custom_config_in_zshrc(dry_run, verbose);
}

fn run_all(upgrade_mode: bool, dry_run: bool, verbose: bool) {
    run_packages(upgrade_mode, dry_run, verbose);
    fonts::install_fonts();
    run_zsh(upgrade_mode, dry_run, verbose);
    tmux::setup_tmux(upgrade_mode, dry_run, verbose);
    vim::setup_vim_nvim(upgrade_mode, dry_run, verbose);

    log_info("==> Running final Brew cleanup...");
    let _ = Command::new("brew").arg("cleanup").status();

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

fn interactive_menu(mut upgrade_mode: bool, dry_run: bool, verbose: bool) {
    let selections = &[
        "Install Everything (Default)",
        "Install Homebrew & Packages",
        "Setup Zsh & Themes",
        "Setup Tmux",
        "Setup Vim & Neovim",
        "Install Fonts",
        "Upgrade Existing Setup",
        "Quit",
    ];

    loop {
        print!("\x1B[2J\x1B[1;1H");

        println!("{}", "===============================================".cyan().bold());
        println!("{}", "            Dotfiles Setup Script              ".green().bold());
        println!("{}", "===============================================".cyan().bold());

        let selection = Select::with_theme(&ColorfulTheme::default())
            .with_prompt("Please select an option")
            .default(0)
            .items(&selections[..])
            .interact()
            .unwrap_or(7);

        match selection {
            0 => {
                run_all(upgrade_mode, dry_run, verbose);
                break;
            }
            1 => {
                run_packages(upgrade_mode, dry_run, verbose);
                wait_for_enter();
            }
            2 => {
                run_zsh(upgrade_mode, dry_run, verbose);
                wait_for_enter();
            }
            3 => {
                tmux::setup_tmux(upgrade_mode, dry_run, verbose);
                wait_for_enter();
            }
            4 => {
                vim::setup_vim_nvim(upgrade_mode, dry_run, verbose);
                wait_for_enter();
            }
            5 => {
                fonts::install_fonts();
                wait_for_enter();
            }
            6 => {
                upgrade_mode = true;
                run_all(upgrade_mode, dry_run, verbose);
                break;
            }
            7 => {
                log_info("Exiting...");
                std::process::exit(0);
            }
            _ => {
                log_error("Invalid choice");
                std::thread::sleep(std::time::Duration::from_secs(1));
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

    if args.auto {
        run_all(args.upgrade, args.dry_run, args.verbose);
    } else {
        interactive_menu(args.upgrade, args.dry_run, args.verbose);
    }
}
