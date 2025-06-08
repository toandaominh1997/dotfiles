# Enhanced Dotfiles Setup

A comprehensive and modern dotfiles management system with modular architecture, cross-platform support, and enterprise-grade features.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux-blue.svg)](https://github.com/toandaominh1997/dotfiles)

## ✨ Features

### 🏗️ **Modular Architecture**
- **Library-based Design**: Separated concerns with dedicated modules for logging, system detection, package management
- **Backwards Compatibility**: Legacy mode support for existing installations
- **Clean Separation**: Each module handles specific functionality with clear interfaces

### 🛡️ **Enterprise-Grade Reliability**
- **Comprehensive Error Handling**: Graceful failure recovery with detailed error reporting
- **Dry-Run Mode**: Preview all changes before applying them
- **Automatic Backups**: Smart backup system with retention policies
- **Idempotent Operations**: Safe to run multiple times without side effects

### 🌍 **Cross-Platform Support**
- **Universal Package Management**: Homebrew, apt, dnf, pacman, zypper support
- **Smart Detection**: Automatic OS, architecture, and package manager detection
- **Platform-Specific Features**: Optimized for macOS and Linux distributions

### 📦 **Advanced Package Management**
- **Configuration-Driven**: External config files for easy customization
- **Batch Operations**: Efficient bulk package installation with progress tracking
- **Plugin System**: Git-based plugin management for Zsh and Tmux
- **Upgrade Support**: Intelligent upgrade detection and execution

### 📊 **Developer Experience**
- **Rich Logging**: Colored output with timestamps and log levels
- **Progress Indicators**: Real-time progress bars and status updates
- **Performance Monitoring**: Built-in timing and performance metrics
- **Comprehensive Testing**: Unit and integration test suites

## 🚀 Quick Start

### One-Line Installation

```bash
# Clone and install in one command
git clone https://github.com/toandaominh1997/dotfiles.git ~/.dotfiles/tool && ~/.dotfiles/tool/setup.sh
```

### Step-by-Step Installation

```bash
# 1. Clone the repository
git clone https://github.com/toandaominh1997/dotfiles.git ~/.dotfiles/tool

# 2. Navigate to the directory
cd ~/.dotfiles/tool

# 3. Run setup (preview changes first)
./setup.sh --dry-run

# 4. Install if satisfied with preview
./setup.sh

# Or use Make for convenience
make install
```

## 📖 Usage Guide

### Command Line Interface

```bash
# Basic installation
./setup.sh

# Upgrade existing setup
./setup.sh --upgrade

# Preview changes without applying
./setup.sh --dry-run

# Verbose output with debug information
./setup.sh --verbose

# Quiet mode (errors/warnings only)
./setup.sh --quiet

# Save logs to file
./setup.sh --log-file setup.log

# Show help
./setup.sh --help

# Show version information
./setup.sh --version
```

### Make Commands

```bash
# Show all available commands
make help

# Installation and management
make install              # Install dotfiles
make upgrade              # Upgrade existing setup
make dry-run              # Preview changes

# Testing and validation
make test                 # Run all tests
make test-unit            # Run unit tests
make test-integration     # Run integration tests
make modular-test         # Test modular architecture
make legacy-test          # Test legacy compatibility
make lint                 # Lint shell scripts

# Maintenance
make backup               # Create backup of configurations
make status               # Show current installation status
make outdated             # Check for outdated packages
make clean                # Clean temporary files

# Validation
make validate             # Validate scripts and configuration
make validate-script      # Validate script syntax
make validate-config      # Validate configuration files
```

## 🏗️ Architecture

### Modular Structure

```
.
├── lib/                          # Core library modules
│   ├── constants.sh             # Global constants and configuration
│   ├── logging.sh               # Enhanced logging system
│   ├── system.sh                # System detection and utilities
│   └── package_manager.sh       # Package management abstraction
├── scripts/                     # Main orchestration scripts
│   └── main_setup.sh            # Main setup coordinator
├── tests/                       # Comprehensive test suite
│   ├── integration_test.sh      # Integration tests
│   └── unit_test.sh             # Unit tests (planned)
├── config/                      # Configuration files
│   ├── packages.conf            # Package definitions
│   ├── system.conf              # System-specific settings (planned)
│   └── user.conf                # User preferences (planned)
├── utils/                       # Legacy utilities
│   ├── config_parser.sh         # Configuration file parser
│   └── test.sh                  # Legacy test suite
├── [app-configs]/               # Application configurations
│   ├── zsh/                     # Zsh configuration
│   ├── tmux/                    # Tmux configuration
│   ├── vim/                     # Vim/Neovim configuration
│   ├── fish/                    # Fish shell configuration
│   ├── starship/                # Starship prompt configuration
│   └── wezterm/                 # WezTerm configuration
├── setup.sh                    # Main entry point
├── Makefile                     # Build and management tasks
└── README.md                    # This file
```

### Key Components

#### 1. **Constants Module** (`lib/constants.sh`)
- Global configuration and constants
- Path definitions and URL repositories
- Feature flags and system detection
- Environment variable exports

#### 2. **Logging Module** (`lib/logging.sh`)
- Multi-level logging (ERROR, WARN, INFO, DEBUG)
- Colored output with timestamps
- Progress indicators and banners
- Debug utilities and performance timing

#### 3. **System Module** (`lib/system.sh`)
- Cross-platform OS and architecture detection
- Package manager detection and validation
- File system utilities (backup, symlink, directory creation)
- Network utilities and Git repository management

#### 4. **Package Manager Module** (`lib/package_manager.sh`)
- Unified package management interface
- Support for multiple package managers
- Plugin management for Zsh and Tmux
- Batch operations with progress tracking

#### 5. **Main Setup Orchestrator** (`scripts/main_setup.sh`)
- Coordinates the entire setup process
- Implements setup phases and validation
- Error handling and recovery
- Post-installation optimization

## ⚙️ Configuration

### Package Configuration

Edit `config/packages.conf` to customize package installations:

```ini
[required_packages]
# Essential packages that must be installed
bash
fzf
neovim
tmux
vim
zsh
git
curl
wget

[formula_packages]
# Additional brew formula packages
ansible
awscli
docker
git
go
helm
kubernetes-cli
node
python3
terraform
# ... more packages

[cask_packages]
# macOS applications (Homebrew casks)
alacritty
brave-browser
docker
google-chrome
iterm2
notion
slack
spotify
visual-studio-code
# ... more applications

[zsh_plugins]
# Zsh plugins with Git repository URLs
zsh-syntax-highlighting=https://github.com/zsh-users/zsh-syntax-highlighting.git
zsh-autosuggestions=https://github.com/zsh-users/zsh-autosuggestions.git
zsh-completions=https://github.com/zsh-users/zsh-completions.git
zsh-history-substring-search=https://github.com/zsh-users/zsh-history-substring-search.git
zsh-interactive-cd=https://github.com/changyuheng/zsh-interactive-cd.git

[themes]
# Zsh themes
powerlevel10k=https://github.com/romkatv/powerlevel10k.git

[tmux_plugins]
# Tmux plugins
tpm=https://github.com/tmux-plugins/tpm
```

### Environment Customization

The system supports various environment variables for customization:

```bash
# Logging configuration
export LOG_LEVEL=3                    # 1=ERROR, 2=WARN, 3=INFO, 4=DEBUG
export LOG_FILE="/path/to/logfile"    # Log to file
export QUIET_MODE=true                # Suppress output
export VERBOSE_MODE=true              # Enable debug output

# Installation behavior
export DRY_RUN_MODE=true              # Preview mode
export UPGRADE_MODE=true              # Upgrade existing packages
export BACKUP_DIR="/custom/backup"    # Custom backup location

# Feature flags
export ENABLE_BACKUP=false            # Disable automatic backups
export ENABLE_COLOR_OUTPUT=false      # Disable colored output
export NETWORK_TIMEOUT=60             # Custom network timeout
```

## 🧪 Testing

### Comprehensive Test Suite

The system includes multiple levels of testing:

```bash
# Run all tests
make test

# Individual test suites
make test-unit            # Unit tests for individual components
make test-integration     # Full integration tests
make modular-test         # Test modular architecture
make legacy-test          # Test backward compatibility
make lint                 # Code quality and style checking
```

### Test Coverage

- **Syntax Validation**: All shell scripts are validated for syntax errors
- **System Detection**: OS, architecture, and package manager detection
- **Configuration Parsing**: Package and plugin configuration parsing
- **File Operations**: Backup, symlink, and directory operations
- **Network Operations**: Download and connectivity testing
- **Package Management**: Installation and upgrade operations
- **Integration**: Full end-to-end setup process
- **Performance**: Execution time and resource usage

### Continuous Integration

The system is designed to be CI/CD friendly:

```yaml
# Example GitHub Actions workflow
name: Test Dotfiles Setup
on: [push, pull_request]
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: make test
      - name: Test installation
        run: ./setup.sh --dry-run
```

## 🛠️ Application Configurations

### Zsh Configuration
- **Oh My Zsh**: Modern Zsh configuration framework
- **Powerlevel10k Theme**: Fast and feature-rich prompt
- **Smart Plugins**: Auto-suggestions, syntax highlighting, completions
- **Optimized Performance**: Fast startup and responsive experience

### Tmux Configuration
- **Plugin Manager**: TPM for easy plugin management
- **Modern Keybindings**: Intuitive and productive key mappings
- **Status Line**: Rich status information and customization
- **Session Management**: Improved session and window handling

### Neovim Configuration
- **NvChad**: Modern Neovim configuration with LSP support
- **Plugin Management**: Lazy.nvim for efficient plugin loading
- **Language Support**: Built-in LSP, treesitter, and debugging
- **Modern UI**: Beautiful and functional interface

### Terminal Configuration
- **WezTerm**: Modern terminal emulator configuration
- **Alacritty**: Alternative GPU-accelerated terminal
- **Starship**: Cross-shell prompt with extensive customization

## 🔧 Maintenance

### Regular Maintenance

```bash
# Check for outdated packages
make outdated

# Update everything
make upgrade

# Create backup before major changes
make backup

# Check system status
make status

# Clean up temporary files
make clean
```

### Troubleshooting

#### Common Issues

1. **Permission Errors**
   ```bash
   # Ensure not running as root
   whoami  # Should not be 'root'
   
   # Fix ownership if needed
   sudo chown -R $(whoami):$(whoami) ~/.dotfiles
   ```

2. **Network Issues**
   ```bash
   # Test connectivity
   curl -Is https://github.com | head -n 1
   
   # Check DNS resolution
   nslookup github.com
   ```

3. **Package Manager Issues**
   ```bash
   # Reset Homebrew
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
   ./setup.sh  # Will reinstall Homebrew
   ```

#### Debug Mode

```bash
# Run with maximum verbosity
./setup.sh --verbose --log-file debug.log

# Check specific components
make modular-test
make validate
```

#### Support

- **Documentation**: Check this README and inline documentation
- **Issues**: Report bugs on GitHub Issues
- **Discussions**: Ask questions in GitHub Discussions
- **Logs**: Always include log files when reporting issues

## 🔄 Migration

### From Previous Versions

The system supports automatic migration from previous versions:

```bash
# Backup existing configuration
make backup

# Run setup with upgrade mode
./setup.sh --upgrade

# Validate the migration
make status
```

### Custom Migration

For custom setups, manually migrate your configurations:

1. **Backup existing configs**
2. **Update `config/packages.conf`** with your package lists
3. **Test with dry-run mode**
4. **Apply changes gradually**

## 🤝 Contributing

### Development Setup

```bash
# Clone the repository
git clone https://github.com/toandaominh1997/dotfiles.git
cd dotfiles

# Install development dependencies
make install

# Run tests to ensure everything works
make test

# Make your changes
# ... edit files ...

# Test your changes
make lint
make test
make dry-run

# Submit pull request
```

### Code Guidelines

- **Shell Style**: Follow Google Shell Style Guide
- **Documentation**: Update README and inline docs
- **Testing**: Add tests for new functionality
- **Compatibility**: Ensure backward compatibility
- **Cross-platform**: Test on macOS and Linux

### Release Process

1. **Update version** in `lib/constants.sh`
2. **Update CHANGELOG** with new features
3. **Run full test suite**
4. **Create release tag**
5. **Update documentation**

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Oh My Zsh](https://ohmyz.sh/) - Zsh configuration framework
- [Homebrew](https://brew.sh/) - Package manager for macOS/Linux
- [NvChad](https://nvchad.com/) - Modern Neovim configuration
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Zsh theme
- [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) - Tmux plugin system

## 📊 Project Status

- **Version**: 2.0.0 (Modular Architecture)
- **Compatibility**: Legacy mode available
- **Platforms**: macOS, Linux (Ubuntu, Debian, Fedora, Arch)
- **Testing**: Comprehensive test suite
- **Maintenance**: Actively maintained

---

**Made with ❤️ for developers who love automation and beautiful terminals.**
 
