# Example Fish Configuration for kubectl.fish
# Place this in your ~/.config/fish/config.fish file

# kubectl.fish configuration example
# This file shows how to integrate kubectl.fish functions into your fish shell setup

# =====================================
# kubectl.fish Integration
# =====================================

# Optional: Set default kubectl configuration
# set -gx KUBECONFIG ~/.kube/config

# Enable kubectl completion (if not already present)
if command -q kubectl
    kubectl completion fish | source
end

# Optional: Create additional kubectl aliases for convenience
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get namespaces'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kl='kubectl logs'
alias kns='kubectl config set-context --current --namespace'

# kubectl.fish specific aliases for easier access
alias kgron='kubectl-gron'
alias kevents='kubectl-list-events'
alias kall='kubectl-really-all'
alias kyml='kubectl-dump'

# =====================================
# Enhanced kubectl get with Templates
# =====================================

# Set custom template directory (optional - for non-standard locations)
# set -gx KUBECTL_TEMPLATES_DIR ~/my-custom-templates

# Templates are stored in ~/.kube/templates/ by default
# This uses kubectl's native custom-columns functionality

# Template aliases for common operations
alias kgpt='k get pods ^pods-wide'              # Pods with extended info
alias kgpi='k get pods ^images'                 # Pods with image names
alias kgpq='k get pods ^qos'                    # Pods with QoS class
alias kgpo='k get pods ^owners'                 # Pods with owner references

# Node template aliases
alias kgnt='k get nodes ^nodes'                 # Nodes with capacity
alias kgni='k get nodes ^nodes-instance'        # Nodes with instance metadata
alias kgnc='k get nodes ^cordoned'              # Show cordoned nodes
alias kgntaint='k get nodes ^taints'            # Nodes with taints

# Other resource templates
alias kgcrds='k get crds ^crds'                 # CRDs with conversion strategy
alias kgfin='k get all ^finalizers'             # Resources with finalizers
alias kgts='k get pods ^timestamps'             # Resources with timestamps

# jq integration examples
# Extract just pod names: k get pods .items[*].metadata.name
# Get first pod IP: k get pods .items[0].status.podIP

# =====================================
# kt (kubeconfig switching) Integration
# =====================================

# Quick kubeconfig switching aliases
# Requires config files in ~/.kube/configs/ or ~/.ssh/kubeconfigs/
alias ktp='kt production'
alias kts='kt staging'
alias ktd='kt development'
alias ktl='kt'  # List all available configs

# =====================================
# Enhanced Kubernetes Workflow
# =====================================

# Function to quickly switch kubectl contexts
function kctx -d "Switch kubectl context"
    if test (count $argv) -eq 0
        kubectl config get-contexts
    else
        kubectl config use-context $argv[1]
    end
end

# Function to get current kubectl context
function kctx-current -d "Show current kubectl context"
    kubectl config current-context
end

# Function to quickly switch namespaces
function kns -d "Switch or show current namespace"
    if test (count $argv) -eq 0
        kubectl config view --minify -o jsonpath='{..namespace}'
        echo
    else
        kubectl config set-context --current --namespace=$argv[1]
        echo "Switched to namespace: $argv[1]"
    end
end

# =====================================
# kubectl.fish Prompt Integration (Optional)
# =====================================

# Add kubectl context to fish prompt (optional)
# This adds the current kubectl context and namespace to your prompt
function kubectl_prompt_info
    if command -q kubectl
        set -l context (kubectl config current-context 2>/dev/null)
        set -l namespace (kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)

        if test -n "$context"
            if test -n "$namespace"
                echo "⎈ $context:$namespace"
            else
                echo "⎈ $context:default"
            end
        end
    end
end

# Uncomment to add kubectl info to your prompt
# function fish_right_prompt
#     set -l kubectl_info (kubectl_prompt_info)
#     if test -n "$kubectl_info"
#         set_color blue
#         echo $kubectl_info
#         set_color normal
#     end
# end

# =====================================
# Auto-completion Enhancement
# =====================================

# Enhanced completion for the k wrapper function
complete -c k -w kubectl

# Custom completions for kubectl.fish functions
complete -c kubectl-gron -w 'kubectl get'
complete -c kubectl-dump -w 'kubectl get'
complete -c kubectl-list-events -w 'kubectl get events'
complete -c kubectl-really-all -w 'kubectl get'

# =====================================
# Environment Variables
# =====================================

# Optional: Set default output format
# set -gx KUBECTL_OUTPUT yaml

# Optional: Enable kubectl diff with external diff tool
# set -gx KUBECTL_EXTERNAL_DIFF 'diff -u'

# Optional: Set default kubectl timeout
# set -gx KUBECTL_TIMEOUT 30s

# =====================================
# Useful Functions for Kubernetes Development
# =====================================

# Function to quickly port-forward to a pod
function kpf -d "Port forward to a pod"
    if test (count $argv) -lt 2
        echo "Usage: kpf <pod-name> <local-port:remote-port>"
        return 1
    end
    kubectl port-forward $argv[1] $argv[2]
end

# Function to exec into a pod
function kexec -d "Execute command in a pod"
    if test (count $argv) -lt 1
        echo "Usage: kexec <pod-name> [command]"
        return 1
    end

    if test (count $argv) -eq 1
        kubectl exec -it $argv[1] -- /bin/bash
    else
        kubectl exec -it $argv[1] -- $argv[2..-1]
    end
end

# Function to get pod logs with follow
function klf -d "Follow logs from a pod"
    if test (count $argv) -eq 0
        echo "Usage: klf <pod-name> [container-name]"
        return 1
    end

    if test (count $argv) -eq 1
        kubectl logs -f $argv[1]
    else
        kubectl logs -f $argv[1] -c $argv[2]
    end
end

# =====================================
# Optional: Load kubectl.fish functions on startup
# =====================================

# If you installed kubectl.fish functions manually, they should already be available
# If you need to source them from a specific location, uncomment and modify:
# for file in ~/path/to/kubectl.fish/functions/*.fish
#     source $file
# end

# Display a welcome message about kubectl.fish (optional)
# if status is-interactive
#     if command -q kubectl; and functions -q kubectl-gron
#         echo "🐟 kubectl.fish functions loaded! Use 'k' for enhanced kubectl experience."
#     end
# end
