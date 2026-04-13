use serde::Deserialize;
use std::collections::HashMap;
use std::fs::File;
use std::io::Read;
use std::path::Path;

use crate::utils::log_error;

#[derive(Deserialize, Debug, Default, Clone)]
pub struct PackageConfig {
    #[serde(default)]
    pub required_packages: Vec<String>,
    #[serde(default)]
    pub formulae_packages: Vec<String>,
    #[serde(default)]
    pub cask_packages: Vec<String>,
}

#[derive(Deserialize, Debug, Default)]
pub struct DotupConfig {
    pub profiles: HashMap<String, PackageConfig>,
}

impl DotupConfig {
    pub fn load() -> Self {
        let home = std::env::var("HOME").unwrap_or_else(|_| "".to_string());

        let paths = vec![
            "./dotup.toml".to_string(),
            format!("{}/.dotfiles/tool/dotup.toml", home),
            format!("{}/.config/dotup/dotup.toml", home),
        ];

        for path_str in paths {
            let path = Path::new(&path_str);
            if path.exists() {
                if let Ok(mut file) = File::open(path) {
                    let mut contents = String::new();
                    if file.read_to_string(&mut contents).is_ok() {
                        match toml::from_str(&contents) {
                            Ok(config) => return config,
                            Err(e) => {
                                log_error(&format!(
                                    "Failed to parse TOML config file at {}: {}",
                                    path_str, e
                                ));
                            }
                        }
                    }
                }
            }
        }

        DotupConfig::default()
    }

    pub fn get_profile(&self, profile_name: &str) -> Option<PackageConfig> {
        self.profiles.get(profile_name).cloned()
    }
}
