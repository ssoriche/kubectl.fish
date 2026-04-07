# kubectl.fish

[![CI](https://github.com/ssoriche/kubectl.fish/actions/workflows/test.yaml/badge.svg)](https://github.com/ssoriche/kubectl.fish/actions/workflows/test.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Fish Shell](https://img.shields.io/badge/fish-3.0%2B-blue.svg)](https://fishshell.com/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-compatible-326ce5.svg)](https://kubernetes.io/)

A collection of kubectl plugins and functions written in fish shell, designed to enhance your Kubernetes workflow with powerful utilities and improved user experience.

## 🚀 Features

- **Smart kubectl wrapper** (`k`) with plugin support and colorized output
- **Enhanced kubectl get** with template system, jq integration, and smart sorting
- **Kubeconfig switching** with `kt` for quick context changes
- **Resource dumping** with `kubectl-gron` (flatten JSON) and `kubectl-dump` (YAML output)
- **Enhanced event viewing** with `kubectl-list-events` (sorted by timestamp)
- **Comprehensive resource listing** with `kubectl-really-all` (all namespaced resources)
- **Deletion analysis** with `kubectl-why-not-deleted` (debug stuck deletions)
- **16 production-ready templates** imported from the zsh kubectl plugin
- **Robust error handling** and prerequisite checking
- **Comprehensive test suite** for reliability
- **Fish shell best practices** with proper documentation

## 📦 Installation

### Prerequisites

- [Fish shell](https://fishshell.com/) 3.0 or later
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured for your cluster

### Method 1: Manual Installation

1. Clone this repository:

```bash
git clone https://github.com/ssoriche/kubectl.fish.git
cd kubectl.fish
```

2. Copy functions to your fish functions directory:

```bash
cp functions/*.fish ~/.config/fish/functions/
```

3. Reload fish configuration:

```bash
source ~/.config/fish/config.fish
```

### Method 2: Fisher Package Manager

```bash
fisher install ssoriche/kubectl.fish
```

### Method 3: Oh My Fish

```bash
omf install https://github.com/ssoriche/kubectl.fish
```

## 🔧 Functions

### `k` - Smart kubectl wrapper

A smart wrapper around kubectl that provides plugin support and enhanced output.

**Features:**

- Automatically uses `kubecolor` for colorized output when available
- Provides access to all `kubectl-*` functions in this collection
- Falls back to standard kubectl when no plugin matches

**Usage:**

```bash
k [kubectl-function-name] [args...]
k [kubectl-command] [args...]
```

**Examples:**

```bash
k get pods                    # Regular kubectl command
k get pods ^pods-wide         # Enhanced get with template
k get pods .items[0].metadata.name  # Enhanced get with jq
k gron pods                   # Uses kubectl-gron function
k list-events                 # Uses kubectl-list-events function
k really-all                  # Uses kubectl-really-all function
```

### `kubectl-get` - Enhanced kubectl get with templates and jq

An enhanced `kubectl get` wrapper that adds custom-columns templates, jq field extraction, and smart sorting.

**Features:**

- **Template System**: Load custom-columns templates with `^template-name` syntax
- **jq Integration**: Extract JSON fields with `.field` syntax
- **Smart Sorting**: Auto-sort events, nodes, and replicasets by relevant timestamps

**Dependencies:** `jq` (for `.field` syntax only)

**Template Locations:**

Templates are searched in order:
1. `$KUBECTL_TEMPLATES_DIR` (if set)
2. `~/.kube/templates/`

**Usage:**

```bash
# Standard kubectl get
kubectl-get pods
k get pods

# Use a template
kubectl-get pods ^pods-wide
k get pods ^images

# Extract JSON field with jq
kubectl-get pods .items[0].metadata.name
k get pods .items[*].status.podIP

# Smart sorting (automatic)
k get events                  # Auto-sorted by lastTimestamp
k get nodes                   # Auto-sorted by creationTimestamp
```

**Available Templates:**

16 production-ready templates included (see `templates/README.md`):

- **Node Management**: `nodes`, `cordoned`, `taints`
- **Pod Analysis**: `pods-wide`, `images`, `qos`, `owners`, `timestamps`
- **Service Mesh**: `linkerd`
- **ScaleOps**: `scaleops-pod`, `scaleops-pod-wide`, `scaleops-hpa`
- **Resources**: `crds`, `finalizers`, `deployments`

**Creating Custom Templates:**

Create a `.tmpl` file in one of the template directories:

```bash
# Create a custom pod template
mkdir -p ~/.kube/templates
echo "NAME:.metadata.name,IP:.status.podIP,NODE:.spec.nodeName" > \
    ~/.kube/templates/my-pods.tmpl

# Use it
k get pods ^my-pods
```

See `templates/README.md` for comprehensive template documentation and examples.

### `kt` - Kubeconfig switcher

Quickly switch between different kubectl configuration files.

**Usage:**

```bash
kt                      # List available configs
kt production           # Switch to production config
kt staging              # Switch to staging config
kt ~/.kube/dev          # Use absolute path
```

**Search Paths:**

- `~/.kube/configs/`
- `~/.ssh/kubeconfigs/`

**Examples:**

```bash
# List all available configs (* marks current)
kt

# Switch to production
kt production

# Switch to development
kt development

# Check what config you're using
echo $KUBECONFIG
```

**Setup:**

Organize your kubeconfig files:

```bash
mkdir -p ~/.kube/configs
mv ~/.kube/config-prod ~/.kube/configs/production
mv ~/.kube/config-dev ~/.kube/configs/development

# Now switch easily
kt production
kt development
```

### `kubectl-gron` - JSON resource flattening

Dump Kubernetes resources with `gron` or `fastgron` for easier parsing and analysis.

**Dependencies:** `gron` or `fastgron`

**Installation:**

```bash
# macOS
brew install gron
# or for faster alternative
brew install fastgron

# Ubuntu/Debian
wget https://github.com/tomnomnom/gron/releases/download/v0.6.1/gron-linux-amd64-0.6.1.tgz
tar xzf gron-linux-amd64-0.6.1.tgz
sudo mv gron /usr/local/bin/
```

**Usage:**

```bash
kubectl-gron [kubectl-get-options...] RESOURCE [NAME]
```

**Examples:**

```bash
kubectl-gron pods
kubectl-gron deployment my-app
kubectl-gron pods -n kube-system
```

### `kubectl-list-events` - Enhanced event viewer

View Kubernetes events in a human-readable format, sorted by timestamp.

**Dependencies:** `jq`

**Installation:**

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

**Usage:**

```bash
kubectl-list-events [kubectl-get-events-options...]
```

**Examples:**

```bash
kubectl-list-events
kubectl-list-events -n kube-system
kubectl-list-events --all-namespaces
kubectl-list-events --field-selector type=Warning
```

### `kubectl-really-all` - Comprehensive resource listing

Get all namespaced resources across all namespaces, not just the common ones included in `kubectl get all`.

**Usage:**

```bash
kubectl-really-all [kubectl-get-options...]
```

**Examples:**

```bash
kubectl-really-all
kubectl-really-all -o wide
kubectl-really-all --show-labels
kubectl-really-all -n specific-namespace
```

### `kubectl-dump` - YAML resource export

Dump Kubernetes resources as YAML for backup, migration, or inspection.

**Usage:**

```bash
kubectl-dump [kubectl-get-options...] RESOURCE [NAME]
```

**Examples:**

```bash
kubectl-dump pods
kubectl-dump deployment my-app
kubectl-dump pods -n kube-system
kubectl-dump service my-service
```

### `kubectl-why-not-deleted` - Deletion analysis

Analyze why a Kubernetes resource is not being deleted by examining finalizers, owner references, and dependencies.

**Dependencies:** `jq`

**Installation:**

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

**Usage:**

```bash
kubectl-why-not-deleted RESOURCE NAME [-n NAMESPACE]
kubectl-why-not-deleted RESOURCE/NAME [-n NAMESPACE]
kubectl-why-not-deleted [-n NAMESPACE] RESOURCE NAME
```

**Examples:**

```bash
kubectl-why-not-deleted pod my-stuck-pod
kubectl-why-not-deleted pod/my-stuck-pod
kubectl-why-not-deleted deployment my-app -n production
kubectl-why-not-deleted Pod/my-pod-name -n production
kubectl-why-not-deleted pvc my-volume-claim
kubectl-why-not-deleted namespace my-namespace
```

## 🧪 Testing

This project includes a comprehensive test suite to ensure reliability and proper error handling.

### Running Tests

```bash
# Run all tests
fish tests/test_kubectl_functions.fish

# Or if you want to see detailed output
fish -d tests/test_kubectl_functions.fish
```

### Linting and Code Quality

This project follows strict linting standards consistent with the [git.fish repository](https://github.com/ssoriche/git.fish):

```bash
# Run comprehensive linting (syntax + formatting + style)
make lint

# Format all Fish files automatically
make format

# Check formatting without modifying files
make check-formatting

# Fix formatting and run linting
make lint-fix
```

**Linting Features:**

- ✅ **Fish syntax validation** using `fish -n`
- ✅ **Code formatting** validation with `fish_indent`
- ✅ **Style consistency** enforcement via `.fishcheck.yaml`
- ✅ **Best practices** checking with fishcheck (if available)

**Installation for enhanced linting:**

```bash
# Install fishcheck for comprehensive style checking
npm install -g fishcheck
```

### Test Categories

1. **Prerequisites Testing**: Validates that required dependencies are available
2. **Argument Validation**: Ensures proper argument handling and error messages
3. **Error Handling**: Tests error conditions and proper exit codes
4. **Integration Testing**: Tests actual functionality with a Kubernetes cluster
5. **Function Discovery**: Validates that the `k` wrapper can find kubectl-\* functions
6. **Linting Standards**: Verifies syntax, formatting, and style consistency

### Test Requirements

- Fish shell with testing support
- kubectl configured for a cluster (for integration tests)
- Optional: gron/fastgron, jq (for complete test coverage)
- Optional: fishcheck (for enhanced linting)

## 🎯 Best Practices

This collection follows fish shell best practices and maintains strict consistency with kubectl patterns. See [CONSISTENCY.md](CONSISTENCY.md) for detailed standards and implementation guidelines.

### Function Design

- ✅ Proper argument validation with clear error messages
- ✅ Comprehensive prerequisite checking
- ✅ Proper exit status handling and propagation
- ✅ Local variable scoping with `set -l`
- ✅ Descriptive function descriptions with `-d`
- ✅ Proper `--wraps` usage for completion support
- ✅ Consistent `--help` and `-h` option support

### Error Handling

- ✅ Graceful handling of missing dependencies
- ✅ Clear error messages with installation instructions
- ✅ Proper stderr redirection for errors
- ✅ Exit status preservation and propagation
- ✅ kubectl-compatible error handling

### Documentation

- ✅ Comprehensive inline documentation
- ✅ Usage examples for each function
- ✅ Dependency requirements clearly stated
- ✅ Installation instructions provided

### kubectl Integration

- ✅ Functions delegate connection handling to kubectl
- ✅ No redundant cluster connectivity checks
- ✅ Full compatibility with kubectl flags and options
- ✅ Proper completion support through `--wraps` annotations

## 🔧 Configuration

### Optional Dependencies

For enhanced functionality, consider installing these optional tools:

- **kubecolor**: Colorized kubectl output

  ```bash
  # macOS
  brew install kubecolor

  # Ubuntu/Debian
  wget https://github.com/hidetatz/kubecolor/releases/download/v0.0.25/kubecolor_0.0.25_Linux_x86_64.tar.gz
  tar xzf kubecolor_0.0.25_Linux_x86_64.tar.gz
  sudo mv kubecolor /usr/local/bin/
  ```

- **less**: For paginated output (usually pre-installed)

### Fish Shell Configuration

Add these to your `~/.config/fish/config.fish` for enhanced experience:

```fish
# Set default kubectl context/namespace if desired
# set -gx KUBECONFIG ~/.kube/config

# Add kubectl completion (if not already present)
kubectl completion fish | source

# Optional: Create additional aliases
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
```

## 🤝 Contributing

Contributions are welcome! Please ensure:

1. **Follow fish best practices** as demonstrated in existing functions
2. **Add comprehensive documentation** with usage examples
3. **Include tests** for new functionality
4. **Handle errors gracefully** with clear error messages
5. **Validate prerequisites** and provide installation instructions

### Development Setup

```bash
# Clone the repository
git clone https://github.com/ssoriche/kubectl.fish.git
cd kubectl.fish

# Install functions for testing
cp functions/*.fish ~/.config/fish/functions/

# Run tests
fish tests/test_kubectl_functions.fish
```

### Pull Request Process

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-new-feature`
3. Make your changes following the coding standards
4. Add tests for your changes
5. Run the full test suite: `make test`
6. Commit your changes: `git commit -am 'Add some feature'`
7. Push to the branch: `git push origin feature/my-new-feature`
8. Submit a pull request

All pull requests are automatically tested using GitHub Actions and Forgejo CI/CD to ensure code quality and functionality.

## 📋 Requirements

### Core Requirements

- Fish shell 3.0+
- kubectl

### Optional Requirements

- gron or fastgron (for kubectl-gron)
- jq (for kubectl-list-events, kubectl-why-not-deleted)
- kubecolor (for enhanced k wrapper)
- column (usually pre-installed)
- less (for paginated output)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [kubectl](https://kubernetes.io/) - The Kubernetes command-line tool
- [Fish shell](https://fishshell.com/) - The friendly interactive shell
- [gron](https://github.com/tomnomnom/gron) - Make JSON greppable
- [jq](https://stedolan.github.io/jq/) - Command-line JSON processor
- [kubecolor](https://github.com/hidetatz/kubecolor) - Colorized kubectl output

## 🔗 Related Projects

- [kubectl aliases](https://github.com/ahmetb/kubectl-aliases) - Bash/Zsh kubectl aliases
- [kubectx](https://github.com/ahmetb/kubectx) - Switch between kubectl contexts
- [stern](https://github.com/stern/stern) - Multi pod log tailing
- [k9s](https://github.com/derailed/k9s) - Kubernetes CLI dashboard
