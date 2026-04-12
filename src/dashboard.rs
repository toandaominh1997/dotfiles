use colored::*;
use std::thread;
use std::time::Duration;
use sysinfo::{Disks, Networks, System};

pub fn show_dashboard() {
    let mut sys = System::new_all();
    let mut disks = Disks::new_with_refreshed_list();
    let mut networks = Networks::new_with_refreshed_list();

    loop {
        sys.refresh_all();
        disks.refresh(true);
        networks.refresh(true);

        // Clear terminal
        print!("{esc}[2J{esc}[1;1H", esc = 27 as char);

        println!(
            "{}",
            "==============================================="
                .cyan()
                .bold()
        );
        println!(
            "{}",
            "            Dotup System Dashboard             "
                .green()
                .bold()
        );
        println!(
            "{}",
            "==============================================="
                .cyan()
                .bold()
        );
        println!("{}", "Press Ctrl+C to exit".dimmed());

        // CPU
        println!("\n[{}]", "CPU Usage".yellow().bold());
        let cpus = sys.cpus();
        let cpu_count = cpus.len();
        let avg_cpu: f32 = if cpu_count > 0 {
            cpus.iter().map(|c| c.cpu_usage()).sum::<f32>() / cpu_count as f32
        } else {
            0.0
        };
        println!("Global CPU Usage: {:.2}% ({} Cores)", avg_cpu, cpu_count);

        // Memory
        println!("\n[{}]", "Memory Usage".yellow().bold());
        let total_mem = sys.total_memory() / 1024 / 1024;
        let used_mem = sys.used_memory() / 1024 / 1024;
        println!("RAM: {} MB / {} MB", used_mem, total_mem);

        let total_swap = sys.total_swap() / 1024 / 1024;
        let used_swap = sys.used_swap() / 1024 / 1024;
        println!("Swap: {} MB / {} MB", used_swap, total_swap);

        // Disks
        println!("\n[{}]", "Disk Usage".yellow().bold());
        for disk in &disks {
            let total = disk.total_space() / 1024 / 1024 / 1024;
            if total == 0 {
                continue;
            }
            let available = disk.available_space() / 1024 / 1024 / 1024;
            let used = total.saturating_sub(available);
            let name = disk.name().to_string_lossy();
            let mount = disk.mount_point().to_string_lossy();
            println!("{} ({}): {} GB / {} GB", name, mount, used, total);
        }

        // Networks
        println!("\n[{}]", "Network Interfaces".yellow().bold());
        for (interface_name, data) in &networks {
            let recv = data.total_received() / 1024 / 1024;
            let trans = data.total_transmitted() / 1024 / 1024;
            if recv > 0 || trans > 0 {
                println!(
                    "{}: {} MB (recv) / {} MB (trans)",
                    interface_name, recv, trans
                );
            }
        }

        // Sleep before the next update
        thread::sleep(Duration::from_secs(2));
    }
}
