# kubectl.fish Consistency Standards

This document outlines the consistency standards implemented across all kubectl.fish functions to ensure a cohesive user experience that aligns with kubectl's patterns and behaviors.

## 🎯 Design Principles

### 1. **kubectl-First Approach**

- All functions delegate connection handling to kubectl itself
- No redundant cluster connectivity checks
- Consistent error reporting matches kubectl's behavior
- Functions fail gracefully with kubectl's native error messages

### 2. **Predictable Interface**

- Consistent argument patterns across all functions
- Standardized help system (`--help` and `-h`)
- Uniform error message formatting
- Fish shell best practices throughout

### 3. **Seamless Integration**

- Proper `--wraps` annotations for completion support
- Compatible with kubectl's existing flags and options
- No interference with kubectl's native functionality

## 📋 Implementation Standards

### Function Signature Pattern

All functions follow this standardized pattern:

```fish
function function-name -d "Brief description" --wraps 'kubectl-subcommand'
    # 1. Handle help option first
    if contains -- --help $argv; or contains -- -h $argv
        # Display comprehensive help
        return 0
    end

    # 2. Validate prerequisites
    if not command -q kubectl
        echo "Error: kubectl is not installed or not in PATH" >&2
        echo "Please install kubectl to use this function" >&2
        return 1
    end

    # 3. Check function-specific dependencies
    # (if applicable)

    # 4. Validate arguments
    if test (count $argv) -eq 0
        echo "Error: No arguments provided" >&2
        echo "Usage: function-name [options...] arguments..." >&2
        echo "Use 'function-name --help' for more information" >&2
        return 1
    end

    # 5. Execute kubectl command
    kubectl subcommand $argv [| additional-processing]
end
```

### Help System Standardization

Every function implements:

- **`--help` and `-h` flags**: Consistent with kubectl patterns
- **Structured help output**: USAGE, EXAMPLES, DEPENDENCIES sections
- **Comprehensive examples**: Real-world usage scenarios
- **Clear dependency information**: Required and optional tools

### Error Handling Consistency

1. **Standard Error Format**: All errors start with `"Error: "` prefix
2. **Stderr Redirection**: Errors go to stderr (`>&2`)
3. **Installation Guidance**: Clear instructions for missing dependencies
4. **Exit Codes**: Consistent with kubectl (0 = success, 1+ = error)
5. **Help References**: Error messages suggest using `--help`

### Argument Validation

- **Empty Argument Handling**: All functions check for missing arguments
- **Consistent Error Messages**: Standardized "No arguments provided" message
- **Usage Hints**: Brief usage in error message plus help reference
- **kubectl Compatibility**: Functions accept all valid kubectl flags

## 🔧 Function-Specific Consistency

### kubectl-gron

- **Purpose**: JSON flattening with gron/fastgron
- **Pattern**: `kubectl get $argv -o json | $gron_cmd`
- **Dependencies**: Detects fastgron first, then gron
- **Wraps**: `kubectl get`

### kubectl-dump

- **Purpose**: YAML output for backup/migration
- **Pattern**: `kubectl get $argv -o yaml`
- **Dependencies**: Only kubectl required
- **Wraps**: `kubectl get`

### kubectl-list-events

- **Purpose**: Enhanced event viewing with timestamps
- **Pattern**: `kubectl get events -o json $argv | jq | column`
- **Dependencies**: jq, column (with graceful degradation)
- **Wraps**: `kubectl get events`

### kubectl-really-all

- **Purpose**: Comprehensive resource listing
- **Pattern**: `kubectl get $(all-resources) $argv`
- **Dependencies**: Only kubectl required
- **Wraps**: `kubectl get`

### k (Smart Wrapper)

- **Purpose**: Plugin dispatch and enhanced kubectl
- **Pattern**: Function detection → plugin execution or kubectl delegation
- **Dependencies**: kubectl (kubecolor optional)
- **Wraps**: `kubectl`

## 🧪 Testing Standards

### Consistency Test Coverage

1. **Help Functionality**: All functions support `--help` and `-h`
2. **Error Formatting**: Consistent "Error: " prefix pattern
3. **Wraps Annotations**: Proper kubectl wrapping for completions
4. **Prerequisite Checking**: Validates dependencies before execution
5. **Argument Validation**: Handles empty arguments consistently

### Test Categories

- **Prerequisites Testing**: Validates dependency availability
- **Help Functionality**: Tests help output and content
- **Argument Validation**: Ensures proper error handling
- **Function Consistency**: Verifies standard patterns
- **Integration Testing**: Tests with real Kubernetes clusters

## 🔄 kubectl Integration

### Connection Handling

- **No Redundant Checks**: Functions don't test cluster connectivity
- **kubectl Error Delegation**: Let kubectl handle connection errors
- **Exit Code Preservation**: Functions return kubectl's exit codes
- **Error Message Passthrough**: kubectl errors displayed to user

### Argument Compatibility

- **Full Flag Support**: All kubectl flags work with functions
- **Namespace Handling**: `-n` and `--namespace` work correctly
- **Output Formats**: Original kubectl `-o` flags preserved where applicable
- **Context Switching**: Functions respect current kubectl context

### Completion Integration

- **Proper Wrapping**: `--wraps` annotations enable kubectl completions
- **Resource Completion**: Tab completion works for resource types
- **Flag Completion**: kubectl flags complete correctly
- **Namespace Completion**: Namespace names complete properly

## 📈 Benefits of Consistency

### User Experience

1. **Predictable Behavior**: Users can predict function behavior
2. **Familiar Patterns**: Follows kubectl conventions users know
3. **Reduced Learning Curve**: Consistent interface across all functions
4. **Reliable Error Handling**: Clear, helpful error messages

### Development Benefits

1. **Maintainable Code**: Consistent patterns across codebase
2. **Easy Testing**: Standardized test patterns
3. **Clear Documentation**: Uniform documentation standards
4. **Simple Contribution**: New functions follow established patterns

### Integration Advantages

1. **kubectl Compatibility**: Seamless integration with existing workflows
2. **Tool Compatibility**: Works with kubectl ecosystem tools
3. **Script Compatibility**: Functions work in automation scripts
4. **Completion Support**: Full shell completion integration

## 🔍 Quality Assurance

### Automated Linting and Formatting

Following the standards established in the [git.fish repository](https://github.com/ssoriche/git.fish), kubectl.fish implements comprehensive automated linting:

**Multi-Level Linting Pipeline:**

1. **Fish Syntax Validation** - `fish -n` checks for syntax errors
2. **Code Formatting** - `fish_indent` ensures consistent formatting
3. **Style Consistency** - `.fishcheck.yaml` enforces coding standards
4. **Best Practices** - fishcheck validates advanced patterns

**Available Commands:**

```bash
make lint         # Run comprehensive linting (syntax + formatting + style)
make format       # Auto-format all Fish files with fish_indent
make check-formatting  # Check formatting without modifications
make lint-fix     # Format and lint in one command
```

**CI/CD Integration:**

- ✅ **GitHub Actions** - Full linting pipeline on every PR/push
- ✅ **Forgejo CI** - Parallel linting validation
- ✅ **Pre-commit Hooks** - Automated formatting checks
- ✅ **Release Validation** - Required linting pass before releases

### Consistency Tests

- **Syntax Validation**: Fish syntax checking for all functions
- **Style Standards**: Automated verification of coding patterns
- **Formatting Consistency**: `fish_indent` validation
- **Help Content Validation**: Tests for required help sections
- **Error Format Verification**: Ensures consistent error patterns
- **Function Standards**: Validates proper `-d` and `--wraps` usage

### Manual Review Guidelines

- **Function Signature**: Verify proper `-d` and `--wraps` usage
- **Help Implementation**: Check for comprehensive help output
- **Error Handling**: Validate error message consistency
- **kubectl Integration**: Ensure proper kubectl delegation
- **Code Formatting**: Confirm `fish_indent` compliance
- **Style Standards**: Validate `.fishcheck.yaml` adherence

This consistency framework ensures that kubectl.fish provides a reliable, predictable, and kubectl-compatible experience while maintaining the unique value each function provides.
