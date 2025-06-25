# Function Documentation

## k

**File:** `functions/k.fish`

```fish
# Function: k
# Location: functions/k.fish

function k -d "Smart kubectl wrapper with plugin support" --wraps kubectl

```

**Description:**
This function provides a smart wrapper around kubectl that automatically
detects and uses kubecolor for colorized output when available. It also
provides access to kubectl-\* functions in this collection by using the
first argument as a potential function name.

USAGE:
k [kubectl-function-name] [args...]
k [kubectl-command] [args...]

EXAMPLES:

## kubectl-dump

**File:** `functions/kubectl-dump.fish`

```fish
# Function: kubectl-dump
# Location: functions/kubectl-dump.fish

function kubectl-dump -d "Dump Kubernetes resources as YAML" --wraps 'kubectl get'

```

**Description:**
This function wraps kubectl get to output resources in YAML format.
It provides a simple way to dump resource definitions for backup,
migration, or inspection purposes.

USAGE:
kubectl-dump [kubectl-get-options...] RESOURCE [NAME]

EXAMPLES:
kubectl-dump pods
kubectl-dump deployment my-app

## kubectl-gron

**File:** `functions/kubectl-gron.fish`

```fish
# Function: kubectl-gron
# Location: functions/kubectl-gron.fish

function kubectl-gron -d "Dump Kubernetes resources with gron or fastgron" --wraps 'kubectl get'

```

**Description:**
This function wraps kubectl get to pipe JSON output through gron/fastgron for
easier parsing and analysis of Kubernetes resource structures. It automatically
detects if fastgron (faster) or gron is available and uses the appropriate tool.

USAGE:
kubectl-gron [kubectl-get-options...] RESOURCE [NAME]

EXAMPLES:
kubectl-gron pods
kubectl-gron deployment my-app

## kubectl-list-events

**File:** `functions/kubectl-list-events.fish`

```fish
# Function: kubectl-list-events
# Location: functions/kubectl-list-events.fish

function kubectl-list-events -d "View Kubernetes events sorted by timestamp" --wraps 'kubectl get events'

```

**Description:**
This function lists Kubernetes events in a human-readable format, sorted by
timestamp. It displays events in a tabular format with columns for time,
namespace, type, reason, object, source, and message.

USAGE:
kubectl-list-events [kubectl-get-events-options...]

EXAMPLES:
kubectl-list-events
kubectl-list-events -n kube-system

## kubectl-really-all

**File:** `functions/kubectl-really-all.fish`

```fish
# Function: kubectl-really-all
# Location: functions/kubectl-really-all.fish

function kubectl-really-all -d "Get all namespaced resources across all namespaces" --wraps 'kubectl get'

```

**Description:**
This function discovers all namespaced resources in the cluster and fetches
them all at once. It's useful for getting a comprehensive view of all
resources in the cluster, similar to 'kubectl get all' but truly getting
ALL resource types, not just the common ones.

USAGE:
kubectl-really-all [kubectl-get-options...]

EXAMPLES:
kubectl-really-all

## kubectl-why-not-deleted

**File:** `functions/kubectl-why-not-deleted.fish`

```fish
# Function: kubectl-why-not-deleted
# Location: functions/kubectl-why-not-deleted.fish

function kubectl-why-not-deleted -d "Analyze why a Kubernetes resource is not being deleted" --wraps 'kubectl get'

```

**Description:**
This function analyzes why a Kubernetes resource is not being deleted by checking
for finalizers, owner references, dependent resources, and providing actionable
insights. It helps debug stuck deletions by examining the resource's metadata
and relationships with other resources.

USAGE:
kubectl-why-not-deleted RESOURCE NAME [-n NAMESPACE]

EXAMPLES:
kubectl-why-not-deleted pod my-pod
kubectl-why-not-deleted deployment my-app -n production
kubectl-why-not-deleted pv my-volume
