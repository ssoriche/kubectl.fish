#!/usr/bin/env fish

# kubectl-gron - Dump Kubernetes resources with gron or fastgron
#
# DESCRIPTION:
#     This function wraps kubectl get to pipe JSON output through gron/fastgron for
#     easier parsing and analysis of Kubernetes resource structures. It automatically
#     detects if fastgron (faster) or gron is available and uses the appropriate tool.
#
# USAGE:
#     kubectl-gron [kubectl-get-options...] RESOURCE [NAME]
#
# EXAMPLES:
#     kubectl-gron pods
#     kubectl-gron deployment my-app
#     kubectl-gron pods -n kube-system
#
# DEPENDENCIES:
#     - kubectl: Kubernetes command-line tool
#     - gron or fastgron: JSON flattening tool
#
# AUTHOR:
#     kubectl.fish collection

function kubectl-gron -d "Dump Kubernetes resources with gron or fastgron" --wraps 'kubectl get'
    # Handle help option
    if contains -- --help $argv; or contains -- -h $argv
        echo "kubectl-gron - Dump Kubernetes resources with gron or fastgron"
        echo ""
        echo "USAGE:"
        echo "  kubectl-gron [kubectl-get-options...] RESOURCE [NAME]"
        echo ""
        echo "EXAMPLES:"
        echo "  kubectl-gron pods"
        echo "  kubectl-gron deployment my-app"
        echo "  kubectl-gron pods -n kube-system"
        echo ""
        echo "DEPENDENCIES:"
        echo "  - kubectl: Kubernetes command-line tool"
        echo "  - gron or fastgron: JSON flattening tool"
        return 0
    end

    # Validate prerequisites
    if not command -q kubectl
        echo "Error: kubectl is not installed or not in PATH" >&2
        echo "Please install kubectl to use this function" >&2
        return 1
    end

    # Check for gron tools availability
    set -l gron_cmd
    if command -q fastgron
        set gron_cmd fastgron
    else if command -q gron
        set gron_cmd gron
    else
        echo "Error: Neither 'gron' nor 'fastgron' is installed" >&2
        echo "Please install one of them:" >&2
        echo "  - fastgron: https://github.com/adamritter/fastgron" >&2
        echo "  - gron: https://github.com/tomnomnom/gron" >&2
        return 1
    end

    # Validate arguments
    if test (count $argv) -eq 0
        echo "Error: No arguments provided" >&2
        echo "Usage: kubectl-gron [kubectl-get-options...] RESOURCE [NAME]" >&2
        echo "Use 'kubectl-gron --help' for more information" >&2
        return 1
    end

    # Run kubectl get and pipe to gron - let kubectl handle connection errors
    kubectl get $argv -o json | $gron_cmd
end
