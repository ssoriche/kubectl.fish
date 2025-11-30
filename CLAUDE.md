# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

kubectl.fish is a collection of kubectl plugins and functions written in Fish shell, designed to enhance Kubernetes workflow with powerful utilities and improved user experience. The project includes a smart kubectl wrapper (`k`) and several kubectl-* functions for specialized operations.

## Core Functions

- **k**: Smart kubectl wrapper with plugin dispatch, kubecolor integration, and enhanced get detection
- **kubectl-get**: Enhanced kubectl get with template system, jq integration, and smart sorting
- **kt**: Kubeconfig switcher for quick context changes
- **kubectl-gron**: Flatten JSON resources using gron/fastgron for easier parsing
- **kubectl-dump**: Export resources as YAML for backup/migration
- **kubectl-list-events**: Enhanced event viewing sorted by timestamp (requires jq)
- **kubectl-really-all**: List all namespaced resources across all namespaces
- **kubectl-why-not-deleted**: Debug stuck resource deletions (requires jq)
- **kubectl-consolidation**: Karpenter consolidation blocker analysis (requires jq)
- **kubectl-dyff**: Semantic diff of Kubernetes manifests (requires dyff, yq)

### Helper Functions

- **__kubectl_find_template**: Locate template files in configured directories
- **__kubectl_parse_get_args**: Parse kubectl get arguments for enhanced syntax

## Development Commands

### Testing
```fish
# Run all tests
fish tests/test_kubectl_functions.fish

# Run tests with make
make test              # All tests
make test-unit         # Unit tests only (no cluster required)
make test-integration  # Integration tests (requires cluster)
```

### Linting and Formatting
```fish
make lint              # Comprehensive linting (syntax + formatting + style)
make format            # Auto-format all Fish files
make check-formatting  # Check formatting without modifications
make lint-fix          # Format and lint in one command
```

The linting pipeline validates:
1. Fish syntax (`fish -n`)
2. Code formatting (`fish_indent`)
3. Style consistency (`.fishcheck.yaml` if fishcheck is installed)

### Installation and Dependencies
```fish
make install           # Install functions to ~/.config/fish/functions/
make uninstall         # Remove installed functions
make check-deps        # Check for required and optional dependencies
```

## Architecture and Patterns

### Function Structure

All kubectl-* functions follow a standardized pattern:

1. **Help handling first** - Always check for `--help` or `-h` flags
2. **Prerequisite validation** - Check for kubectl and function-specific dependencies
3. **Argument validation** - Validate required arguments with clear error messages
4. **kubectl delegation** - Let kubectl handle connection and cluster operations
5. **Error propagation** - Return kubectl's exit codes unchanged

### Standard Function Template

```fish
function kubectl-name -d "Brief description" --wraps 'kubectl subcommand'
    # 1. Handle help option
    if contains -- --help $argv; or contains -- -h $argv
        # Display comprehensive help with USAGE, EXAMPLES, DEPENDENCIES
        return 0
    end

    # 2. Validate prerequisites
    if not command -q kubectl
        echo "Error: kubectl is not installed or not in PATH" >&2
        echo "Please install kubectl to use this function" >&2
        return 1
    end

    # 3. Check function-specific dependencies (if needed)

    # 4. Validate arguments
    if test (count $argv) -eq 0
        echo "Error: No arguments provided" >&2
        echo "Usage: kubectl-name [options...] arguments..." >&2
        echo "Use 'kubectl-name --help' for more information" >&2
        return 1
    end

    # 5. Execute kubectl command
    kubectl subcommand $argv
end
```

### Key Design Principles

1. **kubectl-First Approach**: Functions delegate connection handling to kubectl - no redundant cluster connectivity checks
2. **Consistent Error Formatting**: All errors use `"Error: "` prefix and go to stderr (`>&2`)
3. **Completion Support**: All functions use `--wraps` annotations for proper kubectl completions
4. **Argument Compatibility**: Full support for kubectl flags (e.g., `-n`, `--namespace`, `-o`)
5. **Exit Code Preservation**: Functions return kubectl's exit codes unchanged

### Plugin Discovery

The `k` wrapper discovers kubectl-* functions by:
1. Checking if first argument matches a `kubectl-*` function name
2. If match found, calling that function with remaining arguments
3. Otherwise, delegating to kubectl (or kubecolor if available)

### Enhanced kubectl get Architecture

The enhanced kubectl get system consists of several components working together:

#### Component Overview

1. **k wrapper** (`k.fish`):
   - Detects enhanced get syntax (`^template` or `.field`) in arguments
   - Delegates to `kubectl-get` when enhanced syntax detected
   - Falls through to normal kubectl/kubecolor otherwise

2. **kubectl-get** (`kubectl-get.fish`):
   - Main enhanced get function
   - Parses arguments using `__kubectl_parse_get_args`
   - Finds templates using `__kubectl_find_template`
   - Applies smart sorting based on resource type
   - Executes kubectl with enhanced arguments

3. **Helper Functions**:
   - `__kubectl_find_template`: Searches template directories
   - `__kubectl_parse_get_args`: Detects and extracts enhanced syntax

#### Template System

**Search Order**:
1. `$KUBECTL_TEMPLATES_DIR` (if set) - exclusive search
2. `~/.kube/templates/` - Standard kubectl template location

The template system uses kubectl's native custom-columns functionality, providing syntax sugar (`^template-name`) for easier template access.

**File Extensions**: `.tmpl` or `.template`

**Template Format**: kubectl custom-columns format
```
NAME:.metadata.name,STATUS:.status.phase,AGE:.metadata.creationTimestamp
```

#### Enhanced Syntax Detection

**Template Syntax**: `^template-name`
- Prefix `^` indicates template lookup
- Example: `k get pods ^pods-wide`

**jq Syntax**: `.field`
- Prefix `.` indicates jq expression
- Excludes relative paths (`./` or `../`)
- Example: `k get pods .items[0].metadata.name`

**Smart Sorting**:
- `events`: Automatically add `--sort-by=.lastTimestamp`
- `nodes`: Automatically add `--sort-by=.metadata.creationTimestamp`
- `replicasets`: Automatically add `--sort-by=.metadata.creationTimestamp`
- Only applied if no existing `--sort-by` flag

#### Integration Flow

```
User Command: k get pods ^pods-wide
    ↓
k wrapper detects '^' syntax
    ↓
Calls: kubectl-get pods ^pods-wide
    ↓
__kubectl_parse_get_args extracts: template=pods-wide, args=[pods]
    ↓
__kubectl_find_template locates: ~/.kube/templates/pods-wide.tmpl
    ↓
Reads template content
    ↓
Executes: kubectl get pods --output=custom-columns=<content>
```

### kt (Kubeconfig Switcher)

Simple function to switch between kubeconfig files:
- Lists configs from `~/.kube/configs/` and `~/.ssh/kubeconfigs/`
- Sets `KUBECONFIG` environment variable
- Marks current config with asterisk in list mode

## Testing Standards

The test suite covers:
- **Prerequisites Testing**: Validates dependency availability
- **Help Functionality**: Tests help output and content
- **Argument Validation**: Ensures proper error handling for missing/invalid arguments
- **Function Consistency**: Verifies standard error format and wraps annotations
- **Argument Forwarding**: Tests that kubectl flags are properly forwarded
- **Integration Testing**: Tests with real Kubernetes clusters (when available)
- **Linting Standards**: Fish syntax, formatting, and style validation

### Test Execution Notes

- Unit tests run without cluster access
- Integration tests are skipped if no cluster is available
- Tests use mocking to validate argument forwarding without requiring external tools

## Important Implementation Details

### Argument Parsing

- **kubectl-why-not-deleted** supports multiple formats:
  - `kubectl-why-not-deleted RESOURCE NAME [-n NAMESPACE]`
  - `kubectl-why-not-deleted RESOURCE/NAME [-n NAMESPACE]`
  - `kubectl-why-not-deleted [-n NAMESPACE] RESOURCE NAME`

- Uses Fish's `while` loop pattern to parse namespace flags separately from resource arguments

### Dependency Detection

Functions prefer faster alternatives when available:
- `kubectl-gron`: Checks for `fastgron` first, falls back to `gron`
- `k` wrapper: Uses `kubecolor` if available, falls back to `kubectl`

### Variable Scoping

- Always use `set -l` for local variables to avoid polluting the global scope
- Use `set -g` only for truly global state (e.g., test counters)
- Temporary files in tests use `mktemp` and are cleaned up properly

## Code Style and Conventions

- Use 4-space indentation
- Prefer functional patterns over classes
- Use Fish-specific syntax:
  - `if/end` not `if/fi`
  - `()` for command substitution (modern Fish), not `$()`
  - `test` command for conditionals
  - `string` builtin for string operations
- Run `fish_indent` to ensure consistent formatting
- Follow patterns from CONSISTENCY.md for new functions

## CI/CD

Tests run automatically on:
- GitHub Actions (`.github/workflows/test.yaml`)
- Pull requests and pushes trigger full test suite
- Linting is enforced via `make lint`

## Dependencies

### Required
- Fish shell 3.0+
- kubectl

### Optional (function-specific)
- gron or fastgron (for kubectl-gron)
- jq (for kubectl-list-events, kubectl-why-not-deleted)
- kubecolor (for enhanced k wrapper)
- column (usually pre-installed, for kubectl-list-events)
- fishcheck (for enhanced linting via npm)
