# Contributing to kubectl.fish

Thank you for your interest in contributing to kubectl.fish! This document provides guidelines and information for contributors.

## 🎯 How to Contribute

### Reporting Issues

1. **Search existing issues** first to avoid duplicates
2. **Use the issue template** when creating new issues
3. **Provide clear reproduction steps** for bugs
4. **Include environment information** (Fish version, OS, kubectl version)

### Feature Requests

1. **Describe the use case** clearly
2. **Explain the expected behavior**
3. **Consider backwards compatibility**
4. **Provide examples** of how the feature would be used

### Code Contributions

1. **Fork the repository** on GitHub
2. **Create a feature branch** from `main`
3. **Follow the coding standards** outlined below
4. **Add tests** for new functionality
5. **Update documentation** as needed
6. **Submit a pull request**

## 🛠️ Development Setup

### Prerequisites

- Fish shell 3.0+
- kubectl (for testing)
- make (for build automation)
- git
- fishcheck (for enhanced linting - optional)

### Setup Steps

```bash
# Clone your fork
git clone https://github.com/yourusername/kubectl.fish.git
cd kubectl.fish

# Install dependencies (optional)
make install-deps-ubuntu  # or install-deps-macos

# Install enhanced linting tools
npm install -g fishcheck

# Install functions for testing
make install

# Check that everything works
make check-deps
make lint
make test
```

## 📋 Coding Standards

This project follows strict coding standards consistent with the [git.fish repository](https://github.com/ssoriche/git.fish) to ensure synergy across Fish shell projects.

### Fish Shell Best Practices

1. **Function Names**: Use `kubectl-*` prefix for new functions
2. **Local Variables**: Always use `set -l` for local scope
3. **Error Handling**: Check return codes and provide meaningful errors
4. **Documentation**: Include comprehensive inline documentation
5. **Arguments**: Validate arguments and provide usage examples
6. **Formatting**: Use `fish_indent` for consistent formatting
7. **Style**: Follow `.fishcheck.yaml` standards for consistency

### Linting and Formatting

Before submitting code, ensure it passes all linting checks:

```bash
# Check and fix formatting
make format

# Run comprehensive linting
make lint

# Fix any formatting issues and re-run linting
make lint-fix
```

**Linting Requirements:**

- ✅ Valid Fish syntax (`fish -n`)
- ✅ Consistent formatting (`fish_indent`)
- ✅ Style standards (`.fishcheck.yaml`)
- ✅ Best practices (fishcheck)

### Function Structure

Every function should follow this structure:

```fish
#!/usr/bin/env fish

# function-name - Brief description
#
# DESCRIPTION:
#     Detailed description of what the function does
#     and how it works.
#
# USAGE:
#     function-name [options...] arguments...
#
# EXAMPLES:
#     function-name pods
#     function-name deployment my-app
#
# DEPENDENCIES:
#     - kubectl: Kubernetes command-line tool
#     - jq: JSON processor (if needed)
#
# AUTHOR:
#     kubectl.fish collection

function function-name -d "Brief description" --wraps 'kubectl'
    # Validate prerequisites
    if not command -q kubectl
        echo "Error: kubectl is not installed or not in PATH" >&2
        return 1
    end

    # Validate arguments
    if test (count $argv) -eq 0
        echo "Error: No arguments provided" >&2
        echo "Usage: function-name [options...] arguments..." >&2
        return 1
    end

    # Function implementation
    # ...
end
```

### Error Handling

- **Always check prerequisites** (kubectl, external tools)
- **Validate arguments** before processing
- **Use proper exit codes** (0 for success, 1+ for errors)
- **Write errors to stderr** using `>&2`
- **Provide helpful error messages** with installation instructions

### Testing

Every new function must include:

1. **Unit tests** for error conditions
2. **Integration tests** if applicable
3. **Documentation tests** to ensure examples work
4. **Prerequisite tests** to validate dependencies

Add tests to `tests/test_kubectl_functions.fish`:

```fish
function test_my_new_function
    echo "=== Testing My New Function ==="

    # Test prerequisite checking
    test_assert "my-function without kubectl" "my-function args" 1

    # Test argument validation
    test_assert "my-function with no arguments" "my-function" 1

    # Test actual functionality (if kubectl available)
    if command -q kubectl
        test_assert "my-function basic execution" "my-function test-args" 0
    else
        test_skip "my-function execution" "kubectl not available"
    end
end
```

## 🧪 Testing

### Running Tests

```bash
# Check syntax
make lint

# Run unit tests
make test-unit

# Run integration tests (requires Kubernetes cluster)
make test-integration

# Run all tests
make test
```

### Test Categories

1. **Syntax Tests**: Fish shell syntax validation
2. **Unit Tests**: Error handling, argument validation
3. **Integration Tests**: Actual functionality with cluster
4. **Documentation Tests**: Example validation

### CI/CD

All pull requests are automatically tested using:

- **GitHub Actions**: Cross-platform testing
- **Forgejo CI**: Additional validation
- **Security Scanning**: Vulnerability detection
- **Documentation Checks**: Completeness validation

## 📚 Documentation

### Inline Documentation

- Use the standard header format shown above
- Include practical examples
- Document all dependencies
- Explain complex logic with comments

### README Updates

When adding new functions:

1. Add function to the features list
2. Add usage section with examples
3. Update installation instructions if needed
4. Add to the dependency list

### Commit Messages

Use conventional commit format:

```
feat: add kubectl-logs function for enhanced log viewing
fix: handle empty namespace in kubectl-really-all
docs: update README with new installation method
test: add integration tests for kubectl-gron
```

## 🔍 Code Review Process

### What We Look For

1. **Functionality**: Does it work as intended?
2. **Code Quality**: Follows fish best practices?
3. **Testing**: Adequate test coverage?
4. **Documentation**: Clear and complete?
5. **Backwards Compatibility**: Doesn't break existing usage?

### Review Timeline

- Initial review within 48 hours
- Follow-up reviews within 24 hours
- Approval and merge after all checks pass

## 🚀 Releasing

Releases are cut from `main` by pushing a tag. Publishing is automated by
`.github/workflows/release.yaml`; everything before the tag is a normal PR.

Two files track the version and must agree, which `make version-check` enforces
on every PR into `main`:

- `VERSION` — the bare version, no `v` prefix (e.g. `0.1.0`)
- `CHANGELOG.md` — the newest `## [x.y.z]` heading must match `VERSION`

To cut a release:

1. Move the accumulated `## [Unreleased]` notes under a new
   `## [x.y.z] - YYYY-MM-DD` heading, and add the matching link reference at the
   bottom of the file.
2. Update `VERSION` to the same number.
3. Run `make release-check` (lint, tests, version consistency) and
   `make release-notes` to preview exactly what the release body will say.
4. Open a PR, get it green, and merge it.
5. Tag the merge commit on `main` and push the tag:

   ```fish
   git switch main
   git pull
   git tag v0.1.0
   git push origin v0.1.0
   ```

The workflow then re-verifies the tag against `VERSION`, re-runs the full suite,
extracts that version's `CHANGELOG.md` section, and publishes it as the GitHub
release body. A tag that disagrees with `VERSION` fails rather than publishing
something mislabelled.

While the project is on `0.y.z`, a breaking change to a function signature, the
`^template` syntax, or the template formats bumps the minor version.

## 🎁 Recognition

Contributors will be:

- Listed in the README acknowledgments
- Credited in release notes
- Given collaborator access for significant contributions

## 📞 Getting Help

- **Issues**: Open a GitHub issue for bugs or features
- **Discussions**: Use GitHub Discussions for questions
- **Email**: Contact maintainers for security issues

## 📄 License

By contributing to kubectl.fish, you agree that your contributions will be licensed under the MIT License.

## 🙏 Thank You

Thank you for helping make kubectl.fish better for the entire Kubernetes community! Every contribution, no matter how small, makes a difference.
