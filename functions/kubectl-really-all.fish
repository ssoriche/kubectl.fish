#!/usr/bin/env fish

# kubectl-really-all - Get all namespaced resources across all namespaces
#
# DESCRIPTION:
#     This function discovers all namespaced resources in the cluster and fetches
#     them all at once. It's useful for getting a comprehensive view of all
#     resources in the cluster, similar to 'kubectl get all' but truly getting
#     ALL resource types, not just the common ones.
#
# USAGE:
#     kubectl-really-all [kubectl-get-options...]
#
# EXAMPLES:
#     kubectl-really-all
#     kubectl-really-all -o wide
#     kubectl-really-all --show-labels
#     kubectl-really-all -n specific-namespace
#
# DEPENDENCIES:
#     - kubectl: Kubernetes command-line tool
#
# AUTHOR:
#     kubectl.fish collection

function kubectl-really-all -d "Get all namespaced resources across all namespaces" --wraps 'kubectl get'
    # Handle help option
    if contains -- --help $argv; or contains -- -h $argv
        echo "kubectl-really-all - Get all namespaced resources across all namespaces"
        echo ""
        echo "USAGE:"
        echo "  kubectl-really-all [kubectl-get-options...]"
        echo ""
        echo "EXAMPLES:"
        echo "  kubectl-really-all"
        echo "  kubectl-really-all -o wide"
        echo "  kubectl-really-all --show-labels"
        echo "  kubectl-really-all -n specific-namespace"
        echo ""
        echo "DEPENDENCIES:"
        echo "  - kubectl: Kubernetes command-line tool"
        return 0
    end

    # Validate prerequisites
    if not command -q kubectl
        echo "Error: kubectl is not installed or not in PATH" >&2
        echo "Please install kubectl to use this function" >&2
        return 1
    end

    # Get all namespaced resource types
    set -l resources (kubectl api-resources --output name --namespaced --verbs list 2>&1)
    if test $status -ne 0
        echo "Error: Failed to get API resources" >&2
        echo $resources >&2
        return 1
    end

    # Check if we got any resources
    if test (count $resources) -eq 0
        echo "Warning: No namespaced resources found in the cluster" >&2
        return 0
    end

    # Convert to comma-separated list for kubectl
    set -l resource_list (string join ',' $resources | string trim -r -c ',')

    if test -z "$resource_list"
        echo "Error: Failed to build resource list" >&2
        return 1
    end

    # Execute kubectl get with error handling - let kubectl handle connection errors
    kubectl get $resource_list --ignore-not-found $argv
end
