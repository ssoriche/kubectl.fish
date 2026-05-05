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
    argparse --ignore-unknown \
        h/help \
        o/output= \
        n/namespace= \
        context= \
        cluster= \
        kubeconfig= \
        -- $argv
    or return 1

    if set -q _flag_help
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

    if set -q _flag_output
        echo "Error: -o/--output is not supported; output format is managed internally" >&2
        echo "Use 'kubectl-secret --help' for more information" >&2
        return 1
    end

    if not command -q kubectl
        echo "Error: kubectl is not installed or not in PATH" >&2
        echo "Please install kubectl to use this function" >&2
        return 1
    end

    # $argv now contains only positionals and any undeclared flags (passed with = form)
    set -l positional_args
    set -l extra_flags
    for arg in $argv
        if string match -q -- '-*' $arg
            set extra_flags $extra_flags $arg
        else
            set positional_args $positional_args $arg
        end
    end

    if test (count $positional_args) -eq 0
        echo "Error: No arguments provided" >&2
        echo "Usage: kubectl-secret <secret> [key] [kubectl-flags...]" >&2
        echo "Use 'kubectl-secret --help' for more information" >&2
        return 1
    end

    if test (count $positional_args) -gt 2
        echo "Error: Too many arguments provided" >&2
        echo "Usage: kubectl-secret <secret> [key] [kubectl-flags...]" >&2
        echo "Use 'kubectl-secret --help' for more information" >&2
        return 1
    end

    set -l kubectl_flags $extra_flags
    set -q _flag_namespace; and set kubectl_flags $kubectl_flags -n $_flag_namespace
    set -q _flag_context; and set kubectl_flags $kubectl_flags --context $_flag_context
    set -q _flag_cluster; and set kubectl_flags $kubectl_flags --cluster $_flag_cluster
    set -q _flag_kubeconfig; and set kubectl_flags $kubectl_flags --kubeconfig $_flag_kubeconfig

    set -l secret_name $positional_args[1]

    if test (count $positional_args) -ge 2
        set -l key $positional_args[2]
        if not string match -qr '^[-._a-zA-Z0-9]+$' -- $key
            echo "Error: invalid key name '$key'; keys must match [-._a-zA-Z0-9]+" >&2
            return 1
        end
        kubectl get secret $secret_name $kubectl_flags -o go-template="{{index .data \"$key\" | base64decode}}{{\"\\n\"}}"
    else
        kubectl get secret $secret_name $kubectl_flags -o go-template='{{range $k, $v := .data}}{{$k}}{{"\n"}}{{end}}'
    end
end
