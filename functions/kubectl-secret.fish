#!/usr/bin/env fish

# kubectl-secret - View and decode Kubernetes secrets
#
# DESCRIPTION:
#     View keys or decode values from Kubernetes secrets.
#     With only a secret name, lists all available keys.
#     With a secret name and key, prints the base64-decoded value to stdout.
#
# USAGE:
#     kubectl-secret <secret> [-n namespace] [kubectl-flags...]
#     kubectl-secret <secret> <key> [-n namespace] [kubectl-flags...]
#
# EXAMPLES:
#     kubectl-secret my-db-creds
#     kubectl-secret my-db-creds -n production
#     kubectl-secret my-db-creds password -n production
#     kubectl-secret my-db-creds password -n production | pbcopy
#
# DEPENDENCIES:
#     - kubectl: Kubernetes command-line tool
#
# AUTHOR:
#     kubectl.fish collection

function kubectl-secret -d "View and decode Kubernetes secrets" --wraps 'kubectl get secret'
    # Handle help option first
    if contains -- --help $argv; or contains -- -h $argv
        echo "kubectl-secret - View and decode Kubernetes secrets"
        echo ""
        echo "USAGE:"
        echo "  kubectl-secret <secret> [-n namespace] [kubectl-flags...]"
        echo "  kubectl-secret <secret> <key> [-n namespace] [kubectl-flags...]"
        echo ""
        echo "DESCRIPTION:"
        echo "  With only a secret name, lists all available keys in the secret."
        echo "  With a secret name and key, prints the base64-decoded value to stdout."
        echo "  Pipe the output to pbcopy (macOS) or xclip (Linux) for clipboard use."
        echo ""
        echo "EXAMPLES:"
        echo "  kubectl-secret my-db-creds"
        echo "  kubectl-secret my-db-creds -n production"
        echo "  kubectl-secret my-db-creds password -n production"
        echo "  kubectl-secret my-db-creds password -n production | pbcopy"
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

    # Validate at least one argument provided
    if test (count $argv) -eq 0
        echo "Error: No arguments provided" >&2
        echo "Usage: kubectl-secret <secret> [key] [kubectl-flags...]" >&2
        echo "Use 'kubectl-secret --help' for more information" >&2
        return 1
    end

    # Parse arguments: separate positional args from kubectl flags
    set -l positional_args
    set -l kubectl_flags
    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case -n --namespace -o --output --context --cluster --kubeconfig
                if test (math $i + 1) -le (count $argv)
                    set kubectl_flags $kubectl_flags $argv[$i] $argv[(math $i + 1)]
                    set i (math $i + 2)
                else
                    echo "Error: $argv[$i] requires a value" >&2
                    return 1
                end
            case '-*'
                set kubectl_flags $kubectl_flags $argv[$i]
                set i (math $i + 1)
            case '*'
                set positional_args $positional_args $argv[$i]
                set i (math $i + 1)
        end
    end

    # Require secret name
    if test (count $positional_args) -eq 0
        echo "Error: Secret name is required" >&2
        echo "Usage: kubectl-secret <secret> [key] [kubectl-flags...]" >&2
        echo "Use 'kubectl-secret --help' for more information" >&2
        return 1
    end

    set -l secret_name $positional_args[1]

    if test (count $positional_args) -gt 2
        echo "Error: Too many arguments provided" >&2
        echo "Usage: kubectl-secret <secret> [key] [kubectl-flags...]" >&2
        echo "Use 'kubectl-secret --help' for more information" >&2
        return 1
    end

    if test (count $positional_args) -ge 2
        # Decode mode: print base64-decoded value for the given key
        set -l key $positional_args[2]
        kubectl get secret $secret_name $kubectl_flags -o go-template="{{index .data \"$key\" | base64decode}}{{\"\\n\"}}"
    else
        # List mode: print all keys in the secret
        kubectl get secret $secret_name $kubectl_flags -o go-template='{{range $k, $v := .data}}{{$k}}{{"\n"}}{{end}}'
    end
end
