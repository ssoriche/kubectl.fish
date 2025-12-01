# Function Documentation

## __kubectl_find_template

**File:** `functions/__kubectl_find_template.fish`

```fish
# Function: __kubectl_find_template
# Location: functions/__kubectl_find_template.fish

function __kubectl_find_template -a template_name -d "Locate kubectl custom-columns template files"

```

**Description:**
Internal helper function to locate template files for kubectl-get.
Searches configured template directories for .tmpl or .template files.

USAGE:
__kubectl_find_template TEMPLATE_NAME

SEARCH ORDER:
1. $KUBECTL_TEMPLATES_DIR (if set)
2. ~/.kube/templates/


## __kubectl_parse_get_args

**File:** `functions/__kubectl_parse_get_args.fish`

```fish
# Function: __kubectl_parse_get_args
# Location: functions/__kubectl_parse_get_args.fish

function __kubectl_parse_get_args -d "Parse kubectl get arguments for enhanced syntax"

```

**Description:**
Internal helper function to parse kubectl get arguments and detect
enhanced syntax for templates (^template-name) and jq expressions (.field).
Returns structured data for kubectl-get to process.

USAGE:
__kubectl_parse_get_args ARGS...

DETECTS:
- ^template-name: Template syntax for custom-columns
- .field: jq expression syntax (excluding ./paths)

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
provides access to kubectl-* functions in this collection by using the
first argument as a potential function name.

USAGE:
k [kubectl-function-name] [args...]
k [kubectl-command] [args...]

EXAMPLES:

## kt

**File:** `functions/kt.fish`

```fish
# Function: kt
# Location: functions/kt.fish

function kt -d "Switch kubectl configuration files"

```

**Description:**
Manage Kubernetes configuration files by quickly switching between
different kubeconfig files. When called without arguments, lists all
available configurations. When called with a filename, sets the
KUBECONFIG environment variable to that file.

USAGE:
kt                      # List available configs
kt CONFIG               # Switch to CONFIG
kt /path/to/config      # Use absolute path


## kubectl-consolidation

**File:** `functions/kubectl-consolidation.fish`

```fish
# Function: kubectl-consolidation
# Location: functions/kubectl-consolidation.fish

function kubectl-consolidation -d "Show nodes with Karpenter consolidation blocker information" --wraps 'kubectl get'

```

**Description:**
No description available

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

## kubectl-dyff

**File:** `functions/kubectl-dyff.fish`

```fish
# Function: kubectl-dyff
# Location: functions/kubectl-dyff.fish

function kubectl-dyff -d "Semantic diff of Kubernetes manifests using dyff" --wraps 'kubectl diff'

```

**Description:**
This function provides semantic diff between local Kubernetes manifests and
live cluster resources using the dyff tool. It offers a more human-readable
and semantically meaningful diff compared to standard diff tools.

USAGE:
kubectl-dyff [OPTIONS] -f FILE
kubectl-dyff [OPTIONS] FILE

OPTIONS:
-f, --filename FILE    Local manifest file to compare (optional flag)

## kubectl-get

**File:** `functions/kubectl-get.fish`

```fish
# Function: kubectl-get
# Location: functions/kubectl-get.fish

function kubectl-get -d "Enhanced kubectl get with templates and jq support" --wraps 'kubectl get'

```

**Description:**
Enhanced wrapper around 'kubectl get' that adds support for:
- Custom-columns templates with ^template-name syntax
- jq field extraction with .field syntax
- Smart auto-sorting for events, nodes, and replicasets

USAGE:
kubectl-get RESOURCE [NAME] [FLAGS...]
kubectl-get RESOURCE [NAME] ^template-name [FLAGS...]
kubectl-get RESOURCE [NAME] .field [FLAGS...]


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

function kubectl-list-events --description 'List Kubernetes events with proper formatting and pagination'

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
kubectl-why-not-deleted RESOURCE/NAME [-n NAMESPACE]
kubectl-why-not-deleted [-n NAMESPACE] RESOURCE NAME


