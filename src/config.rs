use serde::Deserialize;
use std::collections::HashMap;
use std::fs;
use std::path::Path;

use crate::utils::{log_error, log_info};

const EMBEDDED_DEFAULTS: &str = include_str!("../dotup.toml");

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
    /// Search well-known locations for `dotup.toml`. Falls back to the copy
    /// embedded at compile time so the binary always has working defaults.
    pub fn load() -> Self {
        let home = std::env::var("HOME").unwrap_or_else(|_| "".to_string());

        let paths = [
            "./dotup.toml".to_string(),
            format!("{}/.dotfiles/tool/dotup.toml", home),
            format!("{}/.config/dotup/dotup.toml", home),
        ];

        for path_str in &paths {
            if !Path::new(path_str).exists() {
                continue;
            }
            match fs::read_to_string(path_str) {
                Ok(contents) => match toml::from_str::<DotupConfig>(&contents) {
                    Ok(config) => return config,
                    Err(e) => log_error(&format!(
                        "Failed to parse TOML config file at {}: {}",
                        path_str, e
                    )),
                },
                Err(e) => log_error(&format!("Failed to read {}: {}", path_str, e)),
            }
        }

        log_info("No dotup.toml found on disk; using embedded defaults.");
        toml::from_str(EMBEDDED_DEFAULTS)
            .expect("embedded dotup.toml must parse — checked at compile time")
    }

    pub fn get_profile(&self, profile_name: &str) -> Option<PackageConfig> {
        self.profiles.get(profile_name).cloned()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn embedded_defaults_parse_and_have_default_profile() {
        let config: DotupConfig =
            toml::from_str(EMBEDDED_DEFAULTS).expect("embedded dotup.toml must parse");
        let default = config
            .get_profile("default")
            .expect("embedded config must define a 'default' profile");
        assert!(!default.required_packages.is_empty());
    }
}
