.PHONY: help test test-verbose install install-hooks clean lint format check dry-run update backup

# Default target
.DEFAULT_GOAL := help

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Show this help message
	@echo "$(BLUE)Dotfiles Repository - Available Commands$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

test: ## Run all tests
	@echo "$(BLUE)Running test suite...$(NC)"
	@./run-tests.sh bootstrap configs scripts

test-all: ## Run all tests including MCP
	@echo "$(BLUE)Running full test suite...$(NC)"
	@./run-tests.sh

test-verbose: ## Run tests with verbose output
	@echo "$(BLUE)Running tests (verbose)...$(NC)"
	@./run-tests.sh -v

test-quick: ## Run only bootstrap tests (quick check)
	@echo "$(BLUE)Running quick tests...$(NC)"
	@./run-tests.sh bootstrap

install: ## Install dotfiles and tools
	@echo "$(BLUE)Installing dotfiles...$(NC)"
	@./bootstrap.sh

install-hooks: ## Install git hooks
	@echo "$(BLUE)Installing git hooks...$(NC)"
	@./scripts/install-hooks.sh

dry-run: ## Preview installation without making changes
	@echo "$(BLUE)Running dry-run mode...$(NC)"
	@DRY_RUN=true ./bootstrap.sh

update: ## Update dotfiles from system configurations
	@echo "$(BLUE)Updating dotfiles from system...$(NC)"
	@./update_dots.sh

backup: ## Create backup of current configurations
	@echo "$(BLUE)Creating backup...$(NC)"
	@BACKUP_DIR="$$HOME/.dotfiles-backup-$$(date +%Y%m%d-%H%M%S)"; \
	mkdir -p "$$BACKUP_DIR"; \
	cp -r "$$HOME/.config" "$$BACKUP_DIR/" 2>/dev/null || true; \
	echo "$(GREEN)Backup created at $$BACKUP_DIR$(NC)"

clean: ## Remove installed configurations
	@echo "$(YELLOW)Warning: This will remove installed configurations$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		rm -rf ~/.config/scripts ~/.local/bin/bluetoothz ~/.local/bin/dkr; \
		echo "$(GREEN)Cleaned up installed files$(NC)"; \
	fi

lint: ## Run ShellCheck on all shell scripts
	@echo "$(BLUE)Running ShellCheck...$(NC)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		find . -name "*.sh" ! -path "./.git/*" ! -path "./tmux/plugins/*" ! -path "./yazi/plugins/*" -exec shellcheck {} + || true; \
	else \
		echo "$(YELLOW)ShellCheck not installed. Install with: apt-get install shellcheck$(NC)"; \
	fi

format: ## Format shell scripts (requires shfmt)
	@echo "$(BLUE)Formatting shell scripts...$(NC)"
	@if command -v shfmt >/dev/null 2>&1; then \
		find . -name "*.sh" ! -path "./.git/*" ! -path "./tmux/plugins/*" ! -path "./yazi/plugins/*" -exec shfmt -w {} +; \
		echo "$(GREEN)Scripts formatted$(NC)"; \
	else \
		echo "$(YELLOW)shfmt not installed. Install with: go install mvdan.cc/sh/v3/cmd/shfmt@latest$(NC)"; \
	fi

check: ## Run all checks (tests + lint)
	@echo "$(BLUE)Running all checks...$(NC)"
	@$(MAKE) test
	@$(MAKE) lint

validate: ## Validate configuration files
	@echo "$(BLUE)Validating configuration files...$(NC)"
	@echo "Checking JSON files..."
	@find . -name "*.json" ! -path "./.git/*" ! -path "./node_modules/*" | while read -r file; do \
		jq empty "$$file" 2>/dev/null && echo "  ✓ $$file" || echo "  ✗ $$file"; \
	done
	@echo "Checking TOML files..."
	@find . -name "*.toml" ! -path "./.git/*" | while read -r file; do \
		echo "  - $$file"; \
	done

validate-install: ## Validate installation is correct
	@echo "$(BLUE)Validating installation...$(NC)"
	@./scripts/validate-install.sh

health-check: ## Run health check on dotfiles environment
	@echo "$(BLUE)Running health check...$(NC)"
	@./scripts/health-check.sh

list-scripts: ## List all available utility scripts
	@echo "$(BLUE)Available utility scripts:$(NC)"
	@ls -1 scripts/*.sh | sed 's/scripts\//  - /' | sed 's/\.sh$$//'

stats: ## Show repository statistics
	@echo "$(BLUE)Repository Statistics:$(NC)"
	@echo ""
	@echo "Shell scripts:     $$(find . -name "*.sh" ! -path "./.git/*" | wc -l)"
	@echo "Test suites:       $$(ls -1 tests/test-*.sh 2>/dev/null | wc -l)"
	@echo "Config dirs:       $$(ls -d */ 2>/dev/null | grep -v ".git" | wc -l)"
	@echo "Documentation:     $$(find docs -name "*.md" 2>/dev/null | wc -l)"
	@echo ""

setup-dev: ## Setup development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@$(MAKE) install-hooks
	@echo "$(GREEN)Development environment ready!$(NC)"

ci: ## Run CI checks locally
	@echo "$(BLUE)Running CI checks locally...$(NC)"
	@$(MAKE) test
	@$(MAKE) lint
	@$(MAKE) validate
	@$(MAKE) health-check
	@echo "$(GREEN)CI checks passed!$(NC)"

doctor: ## Run full diagnostic (validate + health-check)
	@echo "$(BLUE)Running full diagnostic...$(NC)"
	@$(MAKE) validate-install
	@$(MAKE) health-check
	@echo "$(GREEN)Diagnostic complete!$(NC)"
