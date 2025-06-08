# Enhanced Dotfiles Makefile
# 
# This Makefile provides convenient commands for managing the dotfiles setup.
# Run 'make help' to see available commands.

.PHONY: help install upgrade dry-run clean test lint validate backup restore status outdated
.PHONY: test-integration test-unit modular-test legacy-test

# Default target
.DEFAULT_GOAL := help

# Configuration
SCRIPT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
SETUP_SCRIPT := $(SCRIPT_DIR)/setup.sh
CONFIG_DIR := $(SCRIPT_DIR)/config
LIB_DIR := $(SCRIPT_DIR)/lib
SCRIPTS_DIR := $(SCRIPT_DIR)/scripts
TESTS_DIR := $(SCRIPT_DIR)/tests
BACKUP_DIR := $(HOME)/.dotfiles-backup

# Check if modular architecture is available
MODULAR_AVAILABLE := $(shell test -d $(LIB_DIR) && echo "true" || echo "false")

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
BLUE := \033[0;34m
CYAN := \033[0;36m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(CYAN)Enhanced Dotfiles Setup$(NC)"
	@echo "$(CYAN)=======================$(NC)"
	@echo ""
	@if [ "$(MODULAR_AVAILABLE)" = "true" ]; then \
		echo "$(GREEN)Mode: Modular Architecture$(NC)"; \
	else \
		echo "$(YELLOW)Mode: Legacy (Compatibility)$(NC)"; \
	fi
	@echo ""
	@echo "$(BLUE)Available commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "  make install           # Install dotfiles"
	@echo "  make upgrade           # Upgrade existing setup"
	@echo "  make dry-run           # Preview changes"
	@echo "  make test              # Run all tests"
	@echo "  make test-integration  # Run integration tests"

install: validate-script ## Install dotfiles (basic installation)
	@echo "$(GREEN)Installing dotfiles...$(NC)"
	@chmod +x $(SETUP_SCRIPT)
	@$(SETUP_SCRIPT)

upgrade: validate-script ## Upgrade existing dotfiles setup
	@echo "$(GREEN)Upgrading dotfiles...$(NC)"
	@chmod +x $(SETUP_SCRIPT)
	@$(SETUP_SCRIPT) --upgrade

dry-run: validate-script ## Preview what would be installed/changed
	@echo "$(YELLOW)Dry run mode - no changes will be made$(NC)"
	@chmod +x $(SETUP_SCRIPT)
	@$(SETUP_SCRIPT) --dry-run

verbose: validate-script ## Install with verbose output
	@echo "$(GREEN)Installing dotfiles with verbose output...$(NC)"
	@chmod +x $(SETUP_SCRIPT)
	@$(SETUP_SCRIPT) --verbose

upgrade-verbose: validate-script ## Upgrade with verbose output
	@echo "$(GREEN)Upgrading dotfiles with verbose output...$(NC)"
	@chmod +x $(SETUP_SCRIPT)
	@$(SETUP_SCRIPT) --upgrade --verbose

test: ## Run all tests (syntax, unit, integration)
	@echo "$(GREEN)Running comprehensive test suite...$(NC)"
	@$(MAKE) lint
	@$(MAKE) test-unit
	@$(MAKE) test-integration

test-unit: ## Run unit tests on individual components
	@echo "$(GREEN)Running unit tests...$(NC)"
	@if [ -f "$(TESTS_DIR)/unit_test.sh" ]; then \
		bash $(TESTS_DIR)/unit_test.sh; \
	else \
		echo "$(YELLOW)Unit tests not found, running basic validation$(NC)"; \
		$(MAKE) validate; \
	fi

test-integration: ## Run integration tests
	@echo "$(GREEN)Running integration tests...$(NC)"
	@if [ -f "$(TESTS_DIR)/integration_test.sh" ]; then \
		bash $(TESTS_DIR)/integration_test.sh; \
	else \
		echo "$(YELLOW)Integration tests not found, running dry-run test$(NC)"; \
		@$(MAKE) dry-run >/dev/null && echo "✓ Dry-run test passed" || echo "✗ Dry-run test failed"; \
	fi

modular-test: ## Test modular architecture components
	@echo "$(GREEN)Testing modular architecture...$(NC)"
	@if [ "$(MODULAR_AVAILABLE)" = "true" ]; then \
		echo "Testing modular components..."; \
		find $(LIB_DIR) -name "*.sh" -exec bash -n {} \; && echo "✓ All library modules have valid syntax"; \
		find $(SCRIPTS_DIR) -name "*.sh" -exec bash -n {} \; && echo "✓ All script modules have valid syntax"; \
	else \
		echo "$(RED)Modular architecture not available$(NC)"; \
		exit 1; \
	fi

legacy-test: ## Test legacy compatibility mode
	@echo "$(GREEN)Testing legacy compatibility...$(NC)"
	@if [ -f "$(SETUP_SCRIPT)" ]; then \
		echo "Testing legacy mode..."; \
		bash -n $(SETUP_SCRIPT) && echo "✓ Setup script has valid syntax"; \
		bash $(SETUP_SCRIPT) --help >/dev/null && echo "✓ Help command works"; \
		bash $(SETUP_SCRIPT) --version >/dev/null && echo "✓ Version command works"; \
	else \
		echo "$(RED)Setup script not found$(NC)"; \
		exit 1; \
	fi

lint: ## Lint shell scripts with comprehensive checking
	@echo "$(GREEN)Linting shell scripts...$(NC)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		echo "Running shellcheck on all shell scripts..."; \
		find . -name "*.sh" -not -path "./.*" -exec shellcheck {} + && echo "✓ All shell scripts passed linting"; \
		if [ "$(MODULAR_AVAILABLE)" = "true" ]; then \
			echo "Checking modular architecture..."; \
			find $(LIB_DIR) -name "*.sh" -exec shellcheck {} + && echo "✓ Library modules passed linting"; \
			find $(SCRIPTS_DIR) -name "*.sh" -exec shellcheck {} + && echo "✓ Script modules passed linting"; \
		fi; \
	else \
		echo "$(YELLOW)Warning: shellcheck not found. Install with:$(NC)"; \
		echo "  macOS: brew install shellcheck"; \
		echo "  Ubuntu/Debian: sudo apt install shellcheck"; \
		echo "  Fedora: sudo dnf install shellcheck"; \
		echo "$(YELLOW)Running basic syntax check instead...$(NC)"; \
		find . -name "*.sh" -not -path "./.*" -exec bash -n {} \; && echo "✓ Basic syntax check passed"; \
	fi

validate: validate-script validate-config ## Validate setup script and configuration
	@echo "$(GREEN)Validation passed!$(NC)"

validate-script: ## Validate setup script syntax
	@echo "Validating setup script..."
	@bash -n $(SETUP_SCRIPT) && echo "✓ Setup script syntax is valid" || (echo "✗ Setup script syntax error" && exit 1)
	@if [ -d "utils" ]; then \
		for script in utils/*.sh; do \
			if [ -f "$$script" ]; then \
				bash -n "$$script" && echo "✓ $$script syntax is valid" || (echo "✗ $$script syntax error" && exit 1); \
			fi; \
		done; \
	fi

validate-config: ## Validate configuration files
	@echo "Validating configuration files..."
	@if [ -f "$(CONFIG_DIR)/packages.conf" ]; then \
		echo "✓ Package configuration found"; \
	else \
		echo "$(YELLOW)Warning: Package configuration not found at $(CONFIG_DIR)/packages.conf$(NC)"; \
	fi

backup: ## Create backup of existing configurations
	@echo "$(GREEN)Creating backup...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@backup_date=$$(date +%Y%m%d_%H%M%S); \
	for file in ~/.zshrc ~/.vimrc ~/.tmux.conf ~/.gitconfig; do \
		if [ -f "$$file" ]; then \
			cp "$$file" "$(BACKUP_DIR)/$$(basename $$file).$$backup_date" && \
			echo "✓ Backed up $$file"; \
		fi; \
	done
	@if [ -d ~/.config/nvim ]; then \
		cp -r ~/.config/nvim "$(BACKUP_DIR)/nvim.$$backup_date" && \
		echo "✓ Backed up Neovim configuration"; \
	fi
	@echo "Backup completed in $(BACKUP_DIR)"

restore: ## Restore from backup (interactive)
	@echo "$(GREEN)Available backups in $(BACKUP_DIR):$(NC)"
	@if [ -d "$(BACKUP_DIR)" ]; then \
		ls -la "$(BACKUP_DIR)"; \
		echo ""; \
		echo "$(YELLOW)To restore a specific file, copy it manually from $(BACKUP_DIR)$(NC)"; \
	else \
		echo "$(RED)No backup directory found at $(BACKUP_DIR)$(NC)"; \
	fi

status: ## Show current dotfiles status
	@echo "$(GREEN)Dotfiles Status$(NC)"
	@echo "==============="
	@echo ""
	@echo "Configuration files:"
	@for file in ~/.zshrc ~/.vimrc ~/.tmux.conf; do \
		if [ -f "$$file" ]; then \
			echo "  ✓ $$file"; \
		else \
			echo "  ✗ $$file (missing)"; \
		fi; \
	done
	@echo ""
	@echo "Directories:"
	@for dir in ~/.dotfiles ~/.config/nvim; do \
		if [ -d "$$dir" ]; then \
			echo "  ✓ $$dir"; \
		else \
			echo "  ✗ $$dir (missing)"; \
		fi; \
	done
	@echo ""
	@echo "Package managers:"
	@if command -v brew >/dev/null 2>&1; then \
		echo "  ✓ Homebrew ($$(brew --version | head -n1))"; \
	else \
		echo "  ✗ Homebrew (not installed)"; \
	fi
	@if command -v nvim >/dev/null 2>&1; then \
		echo "  ✓ Neovim ($$(nvim --version | head -n1))"; \
	else \
		echo "  ✗ Neovim (not installed)"; \
	fi

outdated: ## Check for outdated packages and components
	@echo "$(GREEN)Checking for Outdated Components$(NC)"
	@echo "===================================="
	@echo ""
	@echo "$(BLUE)Homebrew Packages:$(NC)"
	@if command -v brew >/dev/null 2>&1; then \
		outdated=$$(brew outdated --verbose); \
		if [ -n "$$outdated" ]; then \
			echo "$$outdated" | while IFS= read -r line; do \
				echo "  ⚠  $$line"; \
			done; \
			echo ""; \
			echo "$(YELLOW)Run 'brew upgrade' or 'make upgrade' to update these packages.$(NC)"; \
		else \
			echo "  ✓ All Homebrew packages are up to date"; \
		fi; \
	else \
		echo "  ✗ Homebrew not installed"; \
	fi
	@echo ""
	@echo "$(BLUE)Oh My Zsh:$(NC)"
	@if [ -d ~/.dotfiles/oh-my-zsh ]; then \
		cd ~/.dotfiles/oh-my-zsh && \
		git fetch origin >/dev/null 2>&1 && \
		LOCAL=$$(git rev-parse HEAD) && \
		REMOTE=$$(git rev-parse origin/master 2>/dev/null || git rev-parse origin/main 2>/dev/null) && \
		if [ "$$LOCAL" != "$$REMOTE" ]; then \
			LOCAL_SHORT=$$(git rev-parse --short HEAD); \
			REMOTE_SHORT=$$(git rev-parse --short origin/master 2>/dev/null || git rev-parse --short origin/main 2>/dev/null); \
			COMMITS_BEHIND=$$(git rev-list --count HEAD..origin/master 2>/dev/null || git rev-list --count HEAD..origin/main 2>/dev/null); \
			echo "  ⚠  Oh My Zsh: $$LOCAL_SHORT → $$REMOTE_SHORT ($$COMMITS_BEHIND commits behind)"; \
			echo "     Run 'omz update' or 'make upgrade' to update"; \
		else \
			LOCAL_SHORT=$$(git rev-parse --short HEAD); \
			echo "  ✓ Oh My Zsh is up to date ($$LOCAL_SHORT)"; \
		fi; \
	else \
		echo "  ✗ Oh My Zsh not found"; \
	fi
	@echo ""
	@echo "$(BLUE)Zsh Plugins:$(NC)"
	@if [ -d ~/.dotfiles/oh-my-zsh/custom/plugins ]; then \
		plugin_updates=0; \
		for plugin in ~/.dotfiles/oh-my-zsh/custom/plugins/*/; do \
			if [ -d "$$plugin/.git" ]; then \
				plugin_name=$$(basename "$$plugin"); \
				cd "$$plugin" && \
				git fetch origin >/dev/null 2>&1 && \
				LOCAL=$$(git rev-parse HEAD) && \
				REMOTE=$$(git rev-parse origin/master 2>/dev/null || git rev-parse origin/main 2>/dev/null) && \
				if [ "$$LOCAL" != "$$REMOTE" ]; then \
					LOCAL_SHORT=$$(git rev-parse --short HEAD); \
					REMOTE_SHORT=$$(git rev-parse --short origin/master 2>/dev/null || git rev-parse --short origin/main 2>/dev/null); \
					COMMITS_BEHIND=$$(git rev-list --count HEAD..origin/master 2>/dev/null || git rev-list --count HEAD..origin/main 2>/dev/null); \
					echo "  ⚠  $$plugin_name: $$LOCAL_SHORT → $$REMOTE_SHORT ($$COMMITS_BEHIND commits behind)"; \
					plugin_updates=$$((plugin_updates + 1)); \
				fi; \
			fi; \
		done; \
		if [ $$plugin_updates -eq 0 ]; then \
			echo "  ✓ All Zsh plugins are up to date"; \
		else \
			echo "     Run 'make upgrade' to update plugins"; \
		fi; \
	else \
		echo "  ✗ Zsh plugins directory not found"; \
	fi
	@echo ""
	@echo "$(BLUE)Tmux Plugins:$(NC)"
	@if [ -d ~/.dotfiles/.tmux/plugins ]; then \
		tmux_updates=0; \
		for plugin in ~/.dotfiles/.tmux/plugins/*/; do \
			if [ -d "$$plugin/.git" ]; then \
				plugin_name=$$(basename "$$plugin"); \
				cd "$$plugin" && \
				git fetch origin >/dev/null 2>&1 && \
				LOCAL=$$(git rev-parse HEAD) && \
				REMOTE=$$(git rev-parse origin/master 2>/dev/null || git rev-parse origin/main 2>/dev/null) && \
				if [ "$$LOCAL" != "$$REMOTE" ]; then \
					LOCAL_SHORT=$$(git rev-parse --short HEAD); \
					REMOTE_SHORT=$$(git rev-parse --short origin/master 2>/dev/null || git rev-parse --short origin/main 2>/dev/null); \
					COMMITS_BEHIND=$$(git rev-list --count HEAD..origin/master 2>/dev/null || git rev-list --count HEAD..origin/main 2>/dev/null); \
					echo "  ⚠  $$plugin_name: $$LOCAL_SHORT → $$REMOTE_SHORT ($$COMMITS_BEHIND commits behind)"; \
					tmux_updates=$$((tmux_updates + 1)); \
				fi; \
			fi; \
		done; \
		if [ $$tmux_updates -eq 0 ]; then \
			echo "  ✓ All Tmux plugins are up to date"; \
		else \
			echo "     Run 'make upgrade' to update Tmux plugins"; \
		fi; \
	else \
		echo "  ✗ Tmux plugins directory not found"; \
	fi
	@echo ""
	@echo "$(BLUE)Neovim Configuration:$(NC)"
	@if [ -d ~/.config/nvim/.git ]; then \
		cd ~/.config/nvim && \
		git fetch origin >/dev/null 2>&1 && \
		LOCAL=$$(git rev-parse HEAD) && \
		REMOTE=$$(git rev-parse origin/master 2>/dev/null || git rev-parse origin/main 2>/dev/null) && \
		if [ "$$LOCAL" != "$$REMOTE" ]; then \
			LOCAL_SHORT=$$(git rev-parse --short HEAD); \
			REMOTE_SHORT=$$(git rev-parse --short origin/master 2>/dev/null || git rev-parse --short origin/main 2>/dev/null); \
			COMMITS_BEHIND=$$(git rev-list --count HEAD..origin/master 2>/dev/null || git rev-list --count HEAD..origin/main 2>/dev/null); \
			echo "  ⚠  Neovim config: $$LOCAL_SHORT → $$REMOTE_SHORT ($$COMMITS_BEHIND commits behind)"; \
			echo "     Run 'make upgrade' to update"; \
		else \
			LOCAL_SHORT=$$(git rev-parse --short HEAD); \
			echo "  ✓ Neovim configuration is up to date ($$LOCAL_SHORT)"; \
		fi; \
	else \
		echo "  ⚠  Neovim configuration is not a git repository or not found"; \
	fi
	@echo ""
	@echo "$(BLUE)Dotfiles Repository:$(NC)"
	@if [ -d .git ]; then \
		git fetch origin >/dev/null 2>&1 && \
		LOCAL=$$(git rev-parse HEAD) && \
		REMOTE=$$(git rev-parse origin/master 2>/dev/null || git rev-parse origin/main 2>/dev/null) && \
		if [ "$$LOCAL" != "$$REMOTE" ]; then \
			LOCAL_SHORT=$$(git rev-parse --short HEAD); \
			REMOTE_SHORT=$$(git rev-parse --short origin/master 2>/dev/null || git rev-parse --short origin/main 2>/dev/null); \
			COMMITS_BEHIND=$$(git rev-list --count HEAD..origin/master 2>/dev/null || git rev-list --count HEAD..origin/main 2>/dev/null); \
			echo "  ⚠  Dotfiles repo: $$LOCAL_SHORT → $$REMOTE_SHORT ($$COMMITS_BEHIND commits behind)"; \
			echo "     Run 'git pull' to update"; \
		else \
			LOCAL_SHORT=$$(git rev-parse --short HEAD); \
			echo "  ✓ Dotfiles repository is up to date ($$LOCAL_SHORT)"; \
		fi; \
	else \
		echo "  ⚠  Not in a git repository"; \
	fi
	@echo ""
	@echo "$(GREEN)Check completed!$(NC)"
	@echo "Use 'make upgrade' to update most components automatically."

clean: ## Clean up temporary files and caches
	@echo "$(GREEN)Cleaning up...$(NC)"
	@if command -v brew >/dev/null 2>&1; then \
		echo "Running brew cleanup..."; \
		brew cleanup; \
	fi
	@echo "Removing temporary files..."
	@find . -name "*.tmp" -delete 2>/dev/null || true
	@find . -name ".DS_Store" -delete 2>/dev/null || true
	@echo "Cleanup completed"

update-submodules: ## Update git submodules (if any)
	@echo "$(GREEN)Updating git submodules...$(NC)"
	@if [ -f .gitmodules ]; then \
		git submodule update --init --recursive; \
		git submodule foreach git pull origin main; \
	else \
		echo "No git submodules found"; \
	fi

install-dev: ## Install development dependencies
	@echo "$(GREEN)Installing development dependencies...$(NC)"
	@if command -v brew >/dev/null 2>&1; then \
		brew install shellcheck shfmt; \
	else \
		echo "$(RED)Error: Homebrew not found. Please install Homebrew first.$(NC)"; \
		exit 1; \
	fi

format: ## Format shell scripts
	@echo "$(GREEN)Formatting shell scripts...$(NC)"
	@if command -v shfmt >/dev/null 2>&1; then \
		find . -name "*.sh" -exec shfmt -w -i 4 {} +; \
	else \
		echo "$(RED)Error: shfmt not found. Install with 'make install-dev'$(NC)"; \
		exit 1; \
	fi

docs: ## Generate documentation
	@echo "$(GREEN)Generating documentation...$(NC)"
	@echo "# Enhanced Dotfiles Setup" > USAGE.md
	@echo "" >> USAGE.md
	@echo "## Available Commands" >> USAGE.md
	@echo "" >> USAGE.md
	@$(MAKE) help | grep -E "^  " >> USAGE.md
	@echo "Documentation generated in USAGE.md"

# Check if setup script exists
validate-script-exists:
	@if [ ! -f "$(SETUP_SCRIPT)" ]; then \
		echo "$(RED)Error: Setup script not found at $(SETUP_SCRIPT)$(NC)"; \
		exit 1; \
	fi 