# ArgoCD Status Template Design

**Date:** 2026-05-31
**Status:** Approved

## Summary

Add `templates/argocd-status.tmpl` — a custom-columns template for viewing ArgoCD `Application` resource status at a glance.

## Template File

**Path:** `templates/argocd-status.tmpl`

**Content:**
```
NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision,NAMESPACE:.spec.destination.namespace
```

## Columns

| Column | Field | Rationale |
|--------|-------|-----------|
| NAME | `.metadata.name` | Application name |
| SYNC | `.status.sync.status` | Synced / OutOfSync |
| HEALTH | `.status.health.status` | Healthy / Degraded / Progressing |
| REVISION | `.status.sync.revision` | Git commit SHA currently deployed |
| NAMESPACE | `.spec.destination.namespace` | Target namespace; at end for consistency with standard kubectl output |

## Usage

```fish
kubectl get application -n argocd ^argocd-status
# or via abbreviation
k get application -n argocd ^argocd-status
```

## Design Decisions

- **Name `argocd-status` over `applications`**: `application` is a generic word that could collide with other CRDs; prefixing with `argocd-` scopes it clearly.
- **NAMESPACE last**: Matches standard kubectl column ordering convention (status columns before supporting context).
- **No timestamp column**: `status.operationState.finishedAt` renders as a full ISO string rather than a relative age, making it wide and hard to scan.
- **No PROJECT column**: Useful only in large multi-team installs; omitted to keep the template compact.

## Scope

Single new file. No changes to functions, tests, completions, or documentation.
