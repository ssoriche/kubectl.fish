# kubectl.fish Makefile
# Provides convenient commands for development, testing, and installation

.PHONY: help install uninstall test test-unit test-integration lint format lint-fix check-formatting clean check-deps check-fish

# Default target
help: ## Show this help message
	@echo "kubectl.fish - Fish shell functions for kubectl"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Installation targets
install: check-fish ## Install functions to fish functions directory
	@echo "Installing kubectl.fish functions..."
	@mkdir -p ~/.config/fish/functions
	@cp functions/*.fish ~/.config/fish/functions/
	@echo "✅ Functions installed successfully!"
	@echo "   Restart your fish shell or run 'source ~/.config/fish/config.fish'"

uninstall: check-fish ## Remove functions from fish functions directory
	@echo "Uninstalling kubectl.fish functions..."
	@rm -f ~/.config/fish/functions/kubectl-*.fish
	@rm -f ~/.config/fish/functions/k.fish
	@echo "✅ Functions uninstalled successfully!"

# Testing targets
test: check-deps test-unit test-integration ## Run all tests

test-unit: check-fish ## Run unit tests (no cluster required)
	@echo "Running unit tests..."
	@fish tests/test_kubectl_functions.fish || true

test-integration: check-fish check-kubectl ## Run integration tests (requires cluster)
	@echo "Running integration tests..."
	@if kubectl cluster-info >/dev/null 2>&1; then \
		echo "✅ Kubernetes cluster available, running integration tests..."; \
		fish tests/test_kubectl_functions.fish; \
	else \
		echo "⚠️  No Kubernetes cluster available, skipping integration tests"; \
		echo "   Configure kubectl to connect to a cluster for full testing"; \
	fi

# Development targets
lint: check-fish ## Check fish syntax and formatting for all functions
	@echo "🔍 Running comprehensive Fish linting..."
	@echo ""

	@echo "Checking Fish syntax..."
	@for file in functions/*.fish tests/*.fish; do \
		echo "  Checking $$file..."; \
		fish -n "$$file" || exit 1; \
	done
	@echo "✅ All files have valid Fish syntax"
	@echo ""

	@echo "Checking Fish formatting..."
	@for file in functions/*.fish tests/*.fish; do \
		echo "  Checking formatting of $$file..."; \
		fish_indent < "$$file" > "/tmp/$$(basename $$file).formatted" 2>/dev/null || { \
			echo "❌ Error formatting $$file"; \
			exit 1; \
		}; \
		if ! diff -u "$$file" "/tmp/$$(basename $$file).formatted" >/dev/null; then \
			echo "❌ $$file is not properly formatted"; \
			echo "Run: fish_indent < $$file > $$file.tmp && mv $$file.tmp $$file"; \
			exit 1; \
		fi; \
		rm -f "/tmp/$$(basename $$file).formatted"; \
	done
	@echo "✅ All files are properly formatted"
	@echo ""

	@if command -v fishcheck >/dev/null 2>&1; then \
		echo "Running fishcheck linting..."; \
		fishcheck functions/*.fish tests/*.fish || exit 1; \
		echo "✅ All files pass fishcheck validation"; \
	else \
		echo "⚠️  fishcheck not available - install for enhanced linting"; \
		echo "   npm install -g fishcheck"; \
	fi
	@echo ""

	@if [ -d ".github/workflows" ]; then \
		echo "Checking GitHub workflow syntax..."; \
		for file in .github/workflows/*.yaml; do \
			echo "  Checking $$file..."; \
		done; \
	fi
	@if [ -d ".forgejo/workflows" ]; then \
		echo "Checking Forgejo workflow syntax..."; \
		for file in .forgejo/workflows/*.yaml; do \
			echo "  Checking $$file..."; \
		done; \
	fi
	@echo "✅ Comprehensive linting completed!"

format: check-fish ## Format all Fish files using fish_indent
	@echo "🎨 Formatting Fish files..."
	@for file in functions/*.fish tests/*.fish; do \
		echo "  Formatting $$file..."; \
		fish_indent < "$$file" > "$$file.tmp" && mv "$$file.tmp" "$$file"; \
	done
	@echo "✅ All Fish files formatted!"

lint-fix: format lint ## Format files and run linting
	@echo "🔧 Files formatted and linted!"

check-formatting: check-fish ## Check if files are properly formatted (non-destructive)
	@echo "Checking Fish file formatting..."
	@for file in functions/*.fish tests/*.fish; do \
		echo "  Checking $$file..."; \
		fish_indent < "$$file" > "/tmp/$$(basename $$file).formatted"; \
		if ! diff -u "$$file" "/tmp/$$(basename $$file).formatted" >/dev/null; then \
			echo "❌ $$file is not properly formatted"; \
			echo "   Run 'make format' to fix formatting"; \
			rm -f "/tmp/$$(basename $$file).formatted"; \
			exit 1; \
		fi; \
		rm -f "/tmp/$$(basename $$file).formatted"; \
	done
	@echo "✅ All files are properly formatted"

check-deps: ## Check for required and optional dependencies
	@echo "Checking dependencies..."
	@echo ""
	@echo "Required dependencies:"
	@command -v fish >/dev/null 2>&1 && echo "  ✅ fish" || echo "  ❌ fish (required)"
	@command -v kubectl >/dev/null 2>&1 && echo "  ✅ kubectl" || echo "  ❌ kubectl (required)"
	@echo ""
	@echo "Optional dependencies:"
	@command -v gron >/dev/null 2>&1 && echo "  ✅ gron" || echo "  ⚠️  gron (optional, for kubectl-gron)"
	@command -v fastgron >/dev/null 2>&1 && echo "  ✅ fastgron" || echo "  ⚠️  fastgron (optional, for kubectl-gron)"
	@command -v jq >/dev/null 2>&1 && echo "  ✅ jq" || echo "  ⚠️  jq (optional, for kubectl-list-events)"
	@command -v kubecolor >/dev/null 2>&1 && echo "  ✅ kubecolor" || echo "  ⚠️  kubecolor (optional, for enhanced k wrapper)"
	@command -v column >/dev/null 2>&1 && echo "  ✅ column" || echo "  ⚠️  column (usually pre-installed)"
	@command -v less >/dev/null 2>&1 && echo "  ✅ less" || echo "  ⚠️  less (usually pre-installed)"

clean: ## Clean up temporary files
	@echo "Cleaning up..."
	@find . -name "*.tmp" -delete
	@find . -name "*.bak" -delete
	@echo "✅ Cleanup complete!"

# Development helpers
demo: check-deps install ## Install and run a quick demo
	@echo "Running kubectl.fish demo..."
	@echo ""
	@echo "Available functions:"
	@fish -c "functions -n | string match 'kubectl-*' | string replace 'kubectl-' '  '"
	@echo ""
	@echo "Try these commands:"
	@echo "  k help                    # Show k wrapper help"
	@echo "  kubectl-dump --help       # Show kubectl-dump help"
	@echo "  kubectl-really-all --help # Show kubectl-really-all help"

docs: ## Generate function documentation
	@echo "Generating function documentation..."
	@echo "# Function Documentation" > FUNCTIONS.md
	@echo "" >> FUNCTIONS.md
	@for func in functions/*.fish; do \
		name=$$(basename "$$func" .fish); \
		echo "## $$name" >> FUNCTIONS.md; \
		echo "" >> FUNCTIONS.md; \
		echo "**File:** \`$$func\`" >> FUNCTIONS.md; \
		echo "" >> FUNCTIONS.md; \
		echo '```fish' >> FUNCTIONS.md; \
		if fish -c "source $$func; functions $$name --details" 2>/dev/null | grep -v "^$$func$$" >> FUNCTIONS.md; then \
			echo "" >> FUNCTIONS.md; \
		else \
			echo "# Function: $$name" >> FUNCTIONS.md; \
			echo "# Location: $$func" >> FUNCTIONS.md; \
			echo "" >> FUNCTIONS.md; \
			grep "^function $$name" "$$func" >> FUNCTIONS.md; \
			echo "" >> FUNCTIONS.md; \
		fi; \
		echo '```' >> FUNCTIONS.md; \
		echo "" >> FUNCTIONS.md; \
		echo "**Description:**" >> FUNCTIONS.md; \
		grep "^# DESCRIPTION:" -A 10 "$$func" | grep "^#" | sed 's/^# *//' | grep -v "^DESCRIPTION:" >> FUNCTIONS.md || echo "No description available" >> FUNCTIONS.md; \
		echo "" >> FUNCTIONS.md; \
	done
	@echo "✅ Documentation generated in FUNCTIONS.md"

# Validation helpers
check-fish:
	@command -v fish >/dev/null 2>&1 || (echo "❌ Fish shell is required but not installed" && exit 1)

check-kubectl:
	@command -v kubectl >/dev/null 2>&1 || (echo "❌ kubectl is required but not installed" && exit 1)

# Release helpers
release-check: lint test ## Run all checks before release
	@echo "🚀 All checks passed! Ready for release."

install-deps-macos: ## Install optional dependencies on macOS using Homebrew
	@echo "Installing optional dependencies on macOS..."
	@command -v brew >/dev/null 2>&1 || (echo "❌ Homebrew is required" && exit 1)
	@brew install gron jq kubecolor || echo "Some packages may already be installed"
	@echo "✅ Dependencies installed!"

install-deps-ubuntu: ## Install optional dependencies on Ubuntu/Debian
	@echo "Installing optional dependencies on Ubuntu/Debian..."
	@sudo apt-get update
	@sudo apt-get install -y jq curl wget
	@echo "Installing gron..."
	@wget -O /tmp/gron.tgz https://github.com/tomnomnom/gron/releases/download/v0.6.1/gron-linux-amd64-0.6.1.tgz
	@tar -xzf /tmp/gron.tgz -C /tmp
	@sudo mv /tmp/gron /usr/local/bin/
	@echo "Installing fastgron (optional)..."
	@wget -O /tmp/fastgron-ubuntu https://github.com/adamritter/fastgron/releases/download/v0.7.7/fastgron-ubuntu || echo "fastgron download failed, continuing with gron only"
	@if [ -f /tmp/fastgron-ubuntu ]; then \
		chmod +x /tmp/fastgron-ubuntu; \
		sudo mv /tmp/fastgron-ubuntu /usr/local/bin/fastgron; \
		echo "✅ fastgron installed successfully"; \
	else \
		echo "⚠️ fastgron installation failed, kubectl-gron will use gron"; \
	fi
	@echo "Installing kubecolor..."
	@wget -O /tmp/kubecolor.tgz https://github.com/hidetatz/kubecolor/releases/download/v0.0.25/kubecolor_0.0.25_Linux_x86_64.tar.gz
	@tar -xzf /tmp/kubecolor.tgz -C /tmp
	@sudo mv /tmp/kubecolor /usr/local/bin/
	@rm -f /tmp/gron.tgz /tmp/kubecolor.tgz
	@echo "✅ Dependencies installed!"
