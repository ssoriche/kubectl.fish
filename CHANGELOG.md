# Changelog

All notable changes to kubectl.fish are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Versions are `0.y.z` while the function and template interfaces may still
change. A breaking change to a function signature, the `^template` syntax, or
the template formats bumps the minor version until `1.0.0`.

## [Unreleased]

## [0.1.0] - 2026-08-11

First tagged release. Contents below describe the collection as it stands, not
changes relative to an earlier version.

### Added

- **Enhanced `kubectl get`** (`kubectl-get`) with three additions over plain
  kubectl: `^template-name` to load a saved output template, `.field` to extract
  JSON through jq, and automatic sorting for resources whose default ordering is
  unhelpful (events by `.lastTimestamp`; nodes, replicasets and nodeclaims by
  creation timestamp).
- **Three template formats**, detected from file content: custom-columns
  specifications, a `FLAGS:` line of extra kubectl flags, and Go templates
  (anything containing `{{`). Go templates can join across resource types — see
  `templates/pods-nodepools.tmpl` for pods resolved to their Karpenter NodePool.
- **20 templates** covering nodes, pods, QoS, ownership, taints, finalizers,
  CRDs, Linkerd mesh status, ScaleOps, Karpenter NodeClaim drift, and ArgoCD
  application status. See `templates/README.md`.
- **Template discovery** from `$KUBECTL_TEMPLATES_DIR` or `~/.kube/templates/`,
  with tab completion for template names.
- **`kubectl` dispatcher** routing `kubectl <subcommand>` to any matching
  `kubectl-*` function, plus a `k` abbreviation registered via `conf.d`.
- **Inspection helpers**: `kubectl-gron` / `kubectl-dump` (flatten resources for
  grepping), `kubectl-dyff` (structural diffs), `kubectl-list-events`,
  `kubectl-really-all` (genuinely all resource types, not kubectl's subset),
  `kubectl-secret` (decode secret data), and `kubectl-why-not-deleted`
  (finalizers blocking a delete).
- **`kt`** for switching between per-cluster kubeconfig files.

[Unreleased]: https://github.com/ssoriche/kubectl.fish/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ssoriche/kubectl.fish/releases/tag/v0.1.0
