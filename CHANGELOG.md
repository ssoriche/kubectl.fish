# Changelog

All notable changes to kubectl.fish are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Versions are `0.y.z` while the function and template interfaces may still
change. A breaking change to a function signature, the `^template` syntax, or
the template formats bumps the minor version until `1.0.0`.

## [Unreleased]

## [0.2.1] - 2026-08-12

### Fixed

- `pods-nodepools.tmpl` measures its column widths from the data instead of
  hardcoding them. POD was given 46 characters, so every row with a longer name
  pushed the remaining four columns right — and generated names reach ~80
  characters, which meant the table lost its alignment in exactly the namespaces
  busy enough to need it.
- The measuring pass is deliberately `O(items)` rather than a second join. The
  nested-`range` join is the expensive part — ~4s on a 2200-pod namespace — so
  measuring by re-running it would double every render. NODEPOOL is therefore
  measured across every `Node` in the `List` rather than only the ones that turn
  out to host a pod, which can pad it slightly wider than the joined rows need,
  and its width is seeded from `len "<node-gone>"` so that join-only sentinel
  still fits.
- STATUS falls back to `-` when `.status.phase` is absent, which keeps `len` from
  erroring on a nil and stops `<no value>` from overflowing the column.
- `templates/README.md` documents the technique under **Column Widths**, since
  every Go template that aligns output has the same problem.

### Changed

- Bumped `actions/checkout` from `@v4` to `@v7` across all 16 usages, in both
  the GitHub and Forgejo workflows. This clears the Node 20 deprecation warning
  every run was annotating with — `v4` is `using: node20`, `v5` onward is
  `node24`.
- `v7` rather than `v5` specifically so both workflow sets can share a version.
  Forgejo resolves actions from its own mirror, which forks checkout on a
  separate lineage; `v5` and `v6` exist only upstream, while `v7` exists in both.
  Pinning `v5` would have meant leaving Forgejo on `node20` indefinitely with a
  permanent, unexplainable version skew between the two files.
- Bumped the remaining Node 20 actions so no workflow is annotated for a
  deprecated runtime: `github/codeql-action/upload-sarif` `@v3` → `@v4`,
  `azure/setup-kubectl` `@v3` → `@v5`, and `helm/kind-action` `@v1.8.0` → `@v1`.
  CodeQL Action v3 additionally carried its own deprecation, scheduled for
  December 2026. `setup-kubectl@v4` is still `node20`, so `v5` is the first major
  that resolves it.

### Security

- **All 21 action references are pinned to immutable commit SHAs**, with the
  version kept in a trailing comment. A mutable tag can be repointed by the
  action owner, or by whoever compromises that account, with nothing appearing in
  a diff. This includes `aquasecurity/trivy-action`, which tracked the `master`
  branch — the scanner could change between runs.
- Added `.github/dependabot.yml` for the `github-actions` ecosystem. Pinning
  without automation means never receiving an action's own security fixes;
  Dependabot bumps the SHA and rewrites the version comment. It does not read
  `.forgejo/workflows`, so those pins need a manual bump.
- `zizmor` now audits the workflows in CI via `make audit-workflows`, so the
  pinning policy is enforced on every run rather than caught in review. Fixing
  its other findings in the process:
  - Replaced `${{ github.ref_name }}` interpolations in `release.yaml` with
    `$GITHUB_REF_NAME`. Interpolated values are substituted into the script
    before the shell sees them, so a ref containing shell metacharacters would
    have executed.
  - Added `persist-credentials: false` to all nine checkouts. None of them push
    over git, so none needs a credential left in `.git/config`.
  - Added explicit least-privilege `permissions:` to `test.yaml` and
    `badge.yaml`; `security-scan` keeps its override for uploading SARIF.
  - Documented why `badge.yaml`'s `workflow_run` trigger is safe, inline with
    the suppression, rather than leaving the audit permanently failing.

## [0.2.0] - 2026-08-11

### Added

- `make install-templates` installs the bundled templates to
  `$KUBECTL_TEMPLATES_DIR`, or `~/.kube/templates/` when that is unset. No
  plugin manager could do this: fisher and Oh My Fish copy only `functions`,
  `completions`, `conf.d` and `themes`, so installing kubectl.fish through one
  produced the entire `^template-name` mechanism with no templates to resolve.
  Templates you have edited are reported and left in place; `FORCE=1` takes the
  bundled versions instead.
- `make diff-templates` shows drift between the bundled templates and the
  installed ones, in both directions — bundled templates you have modified or
  not installed, and templates that exist only in your directory.
- `make install` now installs templates as well, so a `make`-based install is
  complete in one step.

### Changed

- The manual installation instructions now use `make install` rather than
  listing `cp` commands that silently omitted the templates.
- `make uninstall` states that it deliberately leaves `~/.kube/templates/` in
  place, since that directory holds your own templates alongside the bundled
  ones.

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

[Unreleased]: https://github.com/ssoriche/kubectl.fish/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/ssoriche/kubectl.fish/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/ssoriche/kubectl.fish/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/ssoriche/kubectl.fish/releases/tag/v0.1.0
