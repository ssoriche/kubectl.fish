# kubectl.fish Makefile
# Provides convenient commands for development, testing, and installation

.PHONY: help install uninstall install-templates diff-templates test test-unit test-integration lint format lint-fix check-formatting clean check-deps check-fish version-check version-check-tag release-notes audit-workflows

# Pinned so a zizmor release cannot change CI's verdict without a commit here.
# Dependabot does not manage this, so bump it by hand.
ZIZMOR_VERSION ?= 1.29.0

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
	@if [ -d completions ]; then \
		echo "Installing completions..."; \
		mkdir -p ~/.config/fish/completions; \
		cp completions/*.fish ~/.config/fish/completions/; \
	fi
	@if [ -d conf.d ]; then \
		echo "Installing conf.d files..."; \
		mkdir -p ~/.config/fish/conf.d; \
		cp conf.d/*.fish ~/.config/fish/conf.d/; \
	fi
	@echo "✅ Functions installed successfully!"
	@echo "   Restart your fish shell or run 'source ~/.config/fish/config.fish'"
	@$(MAKE) --no-print-directory install-templates

# Templates live outside the fish config directories, so no plugin manager
# installs them: fisher only copies functions, completions, conf.d and themes.
# Without this target a fresh install has the whole ^template dispatch mechanism
# and nothing to dispatch to.
install-templates: ## Install bundled templates (FORCE=1 to overwrite local edits)
	@dir="$${KUBECTL_TEMPLATES_DIR:-$$HOME/.kube/templates}"; \
	echo "Installing templates to $$dir..."; \
	mkdir -p "$$dir"; \
	added=0; updated=0; kept=0; \
	for f in templates/*.tmpl; do \
		name=`basename "$$f"`; \
		if [ ! -f "$$dir/$$name" ]; then \
			cp "$$f" "$$dir/$$name"; added=`expr $$added + 1`; \
		elif cmp -s "$$f" "$$dir/$$name"; then \
			:; \
		elif [ -n "$(FORCE)" ]; then \
			cp "$$f" "$$dir/$$name"; updated=`expr $$updated + 1`; \
		else \
			echo "  ⚠️  kept your version of $$name (differs from bundled)"; \
			kept=`expr $$kept + 1`; \
		fi; \
	done; \
	echo "✅ Templates installed: $$added added, $$updated overwritten, $$kept left alone"; \
	if [ "$$kept" -gt 0 ]; then \
		echo "   Run 'make diff-templates' to see the differences,"; \
		echo "   or 'make install-templates FORCE=1' to replace them."; \
	fi

diff-templates: ## Show differences between bundled templates and installed ones
	@dir="$${KUBECTL_TEMPLATES_DIR:-$$HOME/.kube/templates}"; \
	echo "Comparing templates/ against $$dir"; \
	found=0; \
	for f in templates/*.tmpl; do \
		name=`basename "$$f"`; \
		if [ ! -f "$$dir/$$name" ]; then \
			echo "  not installed: $$name"; found=`expr $$found + 1`; \
		elif ! cmp -s "$$f" "$$dir/$$name"; then \
			echo "--- differs: $$name"; \
			diff -u "$$dir/$$name" "$$f" || true; \
			found=`expr $$found + 1`; \
		fi; \
	done; \
	for f in "$$dir"/*.tmpl; do \
		[ -e "$$f" ] || continue; \
		name=`basename "$$f"`; \
		if [ ! -f "templates/$$name" ]; then \
			echo "  local only: $$name"; found=`expr $$found + 1`; \
		fi; \
	done; \
	test "$$found" -eq 0 && echo "✅ Templates are in sync" || echo "$$found template(s) differ"

uninstall: check-fish ## Remove functions from fish functions directory
	@echo "Uninstalling kubectl.fish functions..."
	@rm -f ~/.config/fish/functions/kubectl-*.fish
	@rm -f ~/.config/fish/functions/kubectl.fish
	@rm -f ~/.config/fish/functions/__kubectl_find_template.fish
	@rm -f ~/.config/fish/functions/__kubectl_parse_get_args.fish
	@rm -f ~/.config/fish/functions/__kubectl_complete_templates.fish
	@rm -f ~/.config/fish/completions/kubectl.fish
	@rm -f ~/.config/fish/completions/kubectl-get.fish
	@rm -f ~/.config/fish/conf.d/k_abbr.fish
	@echo "✅ Functions uninstalled successfully!"
	@echo "   Templates in ~/.kube/templates were left in place; that directory"
	@echo "   holds your own templates too, so removing it is not safe to automate."

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
	@for file in functions/*.fish tests/*.fish completions/*.fish conf.d/*.fish; do \
		echo "  Checking $$file..."; \
		fish -n "$$file" || exit 1; \
	done
	@echo "✅ All files have valid Fish syntax"
	@echo ""

	@echo "Checking Fish formatting..."
	@for file in functions/*.fish tests/*.fish completions/*.fish conf.d/*.fish; do \
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
		fishcheck functions/*.fish tests/*.fish completions/*.fish conf.d/*.fish || exit 1; \
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
	@for file in functions/*.fish tests/*.fish completions/*.fish conf.d/*.fish; do \
		echo "  Formatting $$file..."; \
		fish_indent < "$$file" > "$$file.tmp" && mv "$$file.tmp" "$$file"; \
	done
	@echo "✅ All Fish files formatted!"

lint-fix: format lint ## Format files and run linting
	@echo "🔧 Files formatted and linted!"

check-formatting: check-fish ## Check if files are properly formatted (non-destructive)
	@echo "Checking Fish file formatting..."
	@for file in functions/*.fish tests/*.fish completions/*.fish conf.d/*.fish; do \
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
release-check: lint test version-check ## Run all checks before release
	@echo "🚀 All checks passed! Ready for release."

# Note: failures below use { ...; exit 1; } rather than ( ...; exit 1 ). A
# subshell's exit only ends the subshell, so with more commands on the same
# recipe line the check would report the error and then carry on to succeed.
audit-workflows: ## Audit GitHub workflows with zizmor (needs uv or pipx)
	@if command -v uvx >/dev/null 2>&1; then \
		runner="uvx"; \
	elif command -v pipx >/dev/null 2>&1; then \
		runner="pipx run"; \
	else \
		echo "❌ zizmor needs either uv or pipx installed"; \
		echo "   brew install uv   # or: brew install pipx"; \
		exit 1; \
	fi; \
	echo "Auditing .github/workflows with zizmor $(ZIZMOR_VERSION)..."; \
	$$runner zizmor==$(ZIZMOR_VERSION) .github/workflows/

version-check: ## Verify VERSION is semver and matches the newest CHANGELOG entry
	@test -f VERSION || { echo "❌ VERSION file is missing"; exit 1; }
	@test -f CHANGELOG.md || { echo "❌ CHANGELOG.md is missing"; exit 1; }
	@v=`tr -d '[:space:]' < VERSION`; \
	echo "$$v" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$$' \
		|| { echo "❌ VERSION '$$v' is not MAJOR.MINOR.PATCH"; exit 1; }; \
	c=`grep -Eo '^## \[[0-9]+\.[0-9]+\.[0-9]+\]' CHANGELOG.md | head -1 | tr -d '#[] '`; \
	test -n "$$c" || { echo "❌ CHANGELOG.md has no released version heading"; exit 1; }; \
	test "$$v" = "$$c" \
		|| { echo "❌ VERSION ($$v) does not match newest CHANGELOG entry ($$c)"; exit 1; }; \
	echo "✅ VERSION $$v matches CHANGELOG"

version-check-tag: version-check ## Verify a tag matches VERSION (make version-check-tag TAG=v0.1.0)
	@test -n "$(TAG)" || { echo "❌ TAG is required, e.g. make version-check-tag TAG=v0.1.0"; exit 1; }
	@v=`tr -d '[:space:]' < VERSION`; \
	test "$(TAG)" = "v$$v" \
		|| { echo "❌ tag $(TAG) does not match VERSION $$v (expected v$$v)"; exit 1; }; \
	echo "✅ tag $(TAG) matches VERSION"

release-notes: ## Print the CHANGELOG section for the current VERSION
	@v=`tr -d '[:space:]' < VERSION`; \
	awk -v ver="$$v" ' \
		index($$0, "## [" ver "]") == 1 { inside = 1; next } \
		inside && index($$0, "## [") == 1 { exit } \
		inside && $$0 ~ /^\[[^]]+\]:/ { exit } \
		inside { print } \
	' CHANGELOG.md | awk 'NF { started = 1 } started { print }'

install-deps-macos: ## Install optional dependencies on macOS using Homebrew
	@echo "Installing optional dependencies on macOS..."
	@command -v brew >/dev/null 2>&1 || (echo "❌ Homebrew is required" && exit 1)
	@brew install gron jq || echo "Some packages may already be installed"
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
	@rm -f /tmp/gron.tgz
	@echo "✅ Dependencies installed!"
