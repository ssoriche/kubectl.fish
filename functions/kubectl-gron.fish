#!/usr/bin/env fish

function kubectl-gron -d "Dump Kubernetes resources with gron or fastgron" --wraps 'kubectl get'
    # Check if fastgron or gron is available
    if command -q fastgron
        set -f gron_cmd fastgron
    else if command -q gron
        set -f gron_cmd gron
    else
        echo "Error: Neither 'gron' nor 'fastgron' is installed. Please install one of them to use this function." >&2
        return 1
    end

    # Ensure gron_cmd is set before using it
    if not set -q gron_cmd
        echo "Error: gron_cmd is not set. This should not happen." >&2
        return 1
    end

    # Run kubectl get and pipe the output to the selected command
    kubectl get $argv -o json | $gron_cmd
end
