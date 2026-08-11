# kubectl.fish Templates

This directory contains custom-columns templates for use with the enhanced `kubectl-get` function.

## Overview

Templates allow you to create reusable, formatted output views for kubectl get commands. Instead of typing long `--output=custom-columns=...` arguments, you can use the `^template-name` syntax to apply predefined templates.

## Usage

```fish
# Using a template
k get pods ^pods-wide

# Traditional kubectl (equivalent)
kubectl get pods --output=custom-columns=NAME:.metadata.name,STATUS:.status.phase,...
```

## Template Locations

Templates are searched in the following order:

1. **`$KUBECTL_TEMPLATES_DIR`** - If set, this directory is searched exclusively
2. **`~/.kube/templates/`** - Standard kubectl template location

The template system uses kubectl's native custom-columns functionality, so templates should be stored where kubectl expects them.

### Setting Custom Template Directory

```fish
# In your config.fish (optional - for non-standard locations)
set -gx KUBECTL_TEMPLATES_DIR ~/my-custom-templates
```

### Installing the bundled templates

Because that directory sits outside the fish config tree, no plugin manager
installs these files — fisher and Oh My Fish copy only `functions`,
`completions`, `conf.d`, and `themes`. If you installed kubectl.fish through a
plugin manager, run this from a clone of the repository to get the templates:

```fish
make install-templates
```

Templates you have edited are left alone rather than overwritten. `make
diff-templates` shows what differs (including templates only you have), and
`make install-templates FORCE=1` takes the bundled versions anyway.

## Template Format

A template file is one of three formats, detected by its content:

| Format | Detected by | Becomes |
|--------|-------------|---------|
| custom-columns | anything else (the default) | `--output=custom-columns=…` |
| flags | leading `FLAGS:` | the listed flags, appended to the command |
| Go template | contains `{{` | `--output=go-template=…` |

Most templates use kubectl's custom-columns format — a single line of column specifications:

```
COLUMN_NAME:JSON_PATH,COLUMN_NAME:JSON_PATH,...
```

### Example Template

File: `pods-wide.tmpl`
```
NAME:.metadata.name,READY:.status.containerStatuses[*].ready,STATUS:.status.phase,RESTARTS:.status.containerStatuses[*].restartCount,AGE:.metadata.creationTimestamp,IP:.status.podIP,NODE:.spec.nodeName
```

Usage:
```fish
k get pods ^pods-wide
```

### Go Templates

Custom-columns renders one resource type at a time, so it cannot show a value
that lives on a *different* object. Go templates can, because a multi-resource
request returns a single `List` in which every item carries its own `.kind`:

```fish
k get pods,nodes ^pods-nodepools -n my-namespace
```

Go templates may span multiple lines. `kubectl-get` reads them with `string
collect` so the newlines survive — without it, fish splits the file on newlines
and then re-joins with spaces, flattening every rendered row onto one line.

kubectl's template engine is Go's `text/template` plus two extra functions,
`exists` and `base64decode`. Notably absent:

- **No arithmetic.** There is no `add`, so values cannot be summed (you can list
  each container's `restartCount`, but not total them).
- **No `dict`.** Sprig is not available, so a lookup map cannot be built; joins
  are a nested `range` — a linear scan per item.
- **No `sort`.**

Guard every field access that may be absent with `exists`, and prefer `printf`
for column alignment so the output needs no `column -t`.

## Creating Your Own Templates

1. Create a new `.tmpl` or `.template` file in one of the template directories
2. Write its body in whichever of the three formats fits (see below)
3. Use it with `k get RESOURCE ^your-template-name`

Which format to reach for:

- **One resource type, one value per column** → custom-columns. Put the column
  specification on a single line. This is the right default.
- **Only adding label or field columns** → `FLAGS:` followed by the flags, e.g.
  `FLAGS:-L app -L tier`.
- **A value that lives on a different object, or any conditional or fallback
  logic** → a Go template. Remember that the request must ask for every resource
  type involved (`k get pods,nodes ^your-template`), or the items you are
  ranging over will not be there to find.

The dispatcher picks the format from the file's content, not its name — anything
containing `{{` is treated as a Go template, so a custom-columns file must not
contain that sequence.

### Tips for Creating Templates

- **Use descriptive column names**: Make them SHORT but clear (e.g., "NAME", "STATUS")
- **JSON paths**: Follow kubectl's JSONPath syntax (e.g., `.metadata.name`)
- **Arrays**: Use `[*]` for all elements or `[0]` for first element
- **Nested paths**: Chain with dots (e.g., `.status.conditions[*].type`)
- **Test with kubectl**: Verify with `kubectl get ... -o json` first
- **Go templates**: Guard optional fields with `exists`, align with `printf`, and
  see `pods-nodepools.tmpl` for a worked cross-resource example

### Example: Creating a Custom Node Template

1. Inspect the JSON structure:
```fish
kubectl get nodes -o json | jq '.items[0]' | less
```

2. Identify the fields you want:
```
.metadata.name
.status.conditions[?(@.type=="Ready")].status
.status.capacity.cpu
.status.capacity.memory
```

3. Create the template directory and file:
```fish
mkdir -p ~/.kube/templates
echo "NAME:.metadata.name,READY:.status.conditions[?(@.type==\"Ready\")].status,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory" > ~/.kube/templates/nodes-custom.tmpl
```

4. Use it:
```fish
k get nodes ^nodes-custom
```

## Available Templates

This directory includes both example templates and production-ready templates imported from the original zsh kubectl plugin.

### Basic Templates

- `pods-wide.tmpl` - Extended pod information view
- `nodes-custom.tmpl` - Node information with capacity
- `deployments.tmpl` - Deployment status overview

### Imported from zsh kubectl plugin

Credit: https://github.com/ripta/dotfiles/tree/master/zsh-custom/plugins/kube/templates

#### Node Management

- `nodes.tmpl` - Node capacity and allocatable resources
- `nodes-instance.tmpl` - Node instance metadata (instance-group, instance-type, nodepool)
- `cordoned.tmpl` - Show cordoned nodes with timestamp
- `taints.tmpl` - Display node taints

#### Pod Analysis

- `images.tmpl` - Pod name, status, and container images
- `qos.tmpl` - Pod Quality of Service class
- `owners.tmpl` - Pod ownership references
- `timestamps.tmpl` - Resource creation, deletion, and start times

#### Service Mesh

- `linkerd.tmpl` - Linkerd service mesh injection and proxy status

#### ScaleOps Integration

- `scaleops-pod.tmpl` - ScaleOps admission and policy info
- `scaleops-pod-wide.tmpl` - Extended ScaleOps pod details
- `scaleops-hpa.tmpl` - ScaleOps HPA analysis data

#### Resource Management

- `crds.tmpl` - Custom Resource Definitions with conversion strategy
- `finalizers.tmpl` - Resources with finalizers blocking deletion

#### Karpenter

- `nodeclaim-drift.tmpl` - NodeClaim drift status and reason (Drifted condition)
- `pods-nodepools.tmpl` - Pods joined to their node's NodePool (Go template; requires `get pods,nodes`)

#### ArgoCD

- `argocd-status.tmpl` - Application sync status, health, deployed revision, and destination namespace

## Importing Templates from zsh Plugin

The original inspiration for this feature comes from the zsh kubectl plugin, which includes many production-ready templates. See the implementation plan for importing these templates.

Repository: https://github.com/ripta/dotfiles/tree/master/zsh-custom/plugins/kube/templates

## Troubleshooting

### Template Not Found

```
Error: Template 'my-template' not found
Search paths:
  - ~/.kube/templates/
```

**Solutions:**
- Check template file exists in ~/.kube/templates/
- Verify file extension is `.tmpl` or `.template`
- Check spelling of template name (case-sensitive)
- Use `KUBECTL_TEMPLATES_DIR` for non-standard locations

### Template Produces No Output

**Causes:**
- Invalid JSONPath expression
- Field doesn't exist for resource type
- Syntax error in custom-columns format

**Debug:**
1. Test with `kubectl get RESOURCE -o json` to see available fields
2. Verify JSONPath with `kubectl get RESOURCE -o jsonpath='{.items[0].your.path}'`
3. Test template directly: `kubectl get RESOURCE --output=custom-columns="$(cat template.tmpl)"`

## Examples

### Pod Templates

```fish
# Wide pod view
k get pods ^pods-wide

# Pod with images
k get pods ^images

# Pod with QoS class
k get pods ^qos
```

### Node Templates

```fish
# Standard node view
k get nodes ^nodes

# Cordoned nodes only (with filtering)
k get nodes ^cordoned

# Node taints
k get nodes ^taints
```

### Resource Templates

```fish
# Custom Resource Definitions
k get crds ^crds

# Finalizers view
k get all ^finalizers

# Owner references
k get pods ^owners
```

## Combining with Other Features

### Templates + Namespaces

```fish
k get pods -n kube-system ^pods-wide
```

### Templates + Sorting

Smart sorting is applied automatically:

```fish
k get events ^timestamps  # Auto-sorted by lastTimestamp
```

### Templates + Watching

```fish
k get pods ^pods-wide --watch
```

## Contributing Templates

If you create useful templates, consider contributing them back to the kubectl.fish project!

1. Test thoroughly with various resource types
2. Add clear documentation about what the template shows
3. Use descriptive column names
4. Submit a pull request

---

For more information about kubectl.fish enhanced get functionality, see:
- `kubectl-get --help` - Enhanced get command documentation
- `k --help` - Wrapper help with template examples
- [kubectl.fish GitHub](https://github.com/ssoriche/kubectl.fish) - Project repository
