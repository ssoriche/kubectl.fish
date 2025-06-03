---
name: Bug report
about: Create a report to help us improve kubectl.fish
title: "[BUG] "
labels: "bug"
assignees: ""
---

## 🐛 Bug Description

A clear and concise description of what the bug is.

## 🔄 Steps to Reproduce

Steps to reproduce the behavior:

1. Run command '...'
2. With arguments '...'
3. See error

## ✅ Expected Behavior

A clear and concise description of what you expected to happen.

## ❌ Actual Behavior

A clear and concise description of what actually happened.

## 📋 Environment Information

**Fish shell version:**

```bash
fish --version
```

**kubectl version:**

```bash
kubectl version --client
```

**Operating System:**

- [ ] macOS
- [ ] Ubuntu/Debian
- [ ] Other Linux
- [ ] Windows (WSL)

**OS Version:** (e.g., macOS 13.0, Ubuntu 22.04)

**kubectl.fish functions installed:**

```bash
functions -n | string match 'kubectl-*'
```

## 🔍 Error Output

If applicable, add the complete error output:

```
# Paste error output here
```

## 🏗️ Kubernetes Cluster Information

**Cluster type:**

- [ ] Local (kind, minikube, etc.)
- [ ] Cloud provider (AWS EKS, GCP GKE, Azure AKS)
- [ ] Self-managed
- [ ] Other: ****\_\_\_****

**Kubernetes version:**

```bash
kubectl version --short
```

## 📎 Additional Context

Add any other context about the problem here. This could include:

- Configuration files (sanitized)
- Screenshots (if applicable)
- Any workarounds you've tried
- Related issues or documentation

## ✅ Pre-submission Checklist

- [ ] I have searched for existing issues before creating this one
- [ ] I have provided all the requested environment information
- [ ] I have included complete error output (if applicable)
- [ ] I have tested with the latest version of kubectl.fish
