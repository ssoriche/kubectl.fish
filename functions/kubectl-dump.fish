#!/usr/bin/env fish

# kubectl-dump - Dump Kubernetes resources as YAML
#
# DESCRIPTION:
#     This function wraps kubectl get to output resources in YAML format.
#     It provides a simple way to dump resource definitions for backup,
#     migration, or inspection purposes.
#
# USAGE:
#     kubectl-dump [kubectl-get-options...] RESOURCE [NAME]
#
# EXAMPLES:
#     kubectl-dump pods
#     kubectl-dump deployment my-app
#     kubectl-dump pods -n kube-system
#     kubectl-dump service my-service
#
# DEPENDENCIES:
#     - kubectl: Kubernetes command-line tool
#
# AUTHOR:
#     kubectl.fish collection

function kubectl-dump -d "Dump Kubernetes resources as YAML" --wraps 'kubectl get'
    # Handle help option
    if contains -- --help $argv; or contains -- -h $argv
        echo "kubectl-dump - Dump Kubernetes resources as YAML"
        echo ""
        echo "USAGE:"
        echo "  kubectl-dump [kubectl-get-options...] RESOURCE [NAME]"
        echo ""
        echo "EXAMPLES:"
        echo "  kubectl-dump pods"
        echo "  kubectl-dump deployment my-app"
        echo "  kubectl-dump pods -n kube-system"
        echo "  kubectl-dump service my-service"
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

    # Validate arguments
    if test (count $argv) -eq 0
        echo "Error: No arguments provided" >&2
        echo "Usage: kubectl-dump [kubectl-get-options...] RESOURCE [NAME]" >&2
        echo "Use 'kubectl-dump --help' for more information" >&2
        return 1
    end

    # Run kubectl get with YAML output - let kubectl handle connection errors
    kubectl get $argv -o yaml
end
