#!/usr/bin/env fish

# k - Smart kubectl wrapper with plugin support
#
# DESCRIPTION:
#     This function provides a smart wrapper around kubectl that automatically
#     detects and uses kubecolor for colorized output when available. It also
#     provides access to kubectl-* functions in this collection by using the
#     first argument as a potential function name.
#
# USAGE:
#     k [kubectl-function-name] [args...]
#     k [kubectl-command] [args...]
#
# EXAMPLES:
#     k get pods                    # Regular kubectl command
#     k gron pods                   # Uses kubectl-gron function
#     k list-events                 # Uses kubectl-list-events function
#     k really-all                  # Uses kubectl-really-all function
#
# BEHAVIOR:
#     1. If first argument matches a kubectl-* function, run that function
#     2. Otherwise, run kubectl (or kubecolor if available) with all arguments
#
# DEPENDENCIES:
#     - kubectl: Kubernetes command-line tool
#     - kubecolor: Colorized kubectl output (optional)
#
# AUTHOR:
#     kubectl.fish collection

function k -d "Smart kubectl wrapper with plugin support" --wraps kubectl
    # Handle help option
    if contains -- --help $argv; or contains -- -h $argv
        echo "k - Smart kubectl wrapper with plugin support"
        echo ""
        echo "USAGE:"
        echo "  k [kubectl-function-name] [args...]"
        echo "  k [kubectl-command] [args...]"
        echo ""
        echo "EXAMPLES:"
        echo "  k get pods                    # Regular kubectl command"
        echo "  k gron pods                   # Uses kubectl-gron function"
        echo "  k list-events                 # Uses kubectl-list-events function"
        echo "  k really-all                  # Uses kubectl-really-all function"
        echo ""
        echo "AVAILABLE KUBECTL.FISH FUNCTIONS:"
        set -l available_functions (functions -n | string match 'kubectl-*' | string replace 'kubectl-' '')
        if test (count $available_functions) -gt 0
            for func in $available_functions
                echo "  $func"
            end
        else
            echo "  (none found - functions may not be loaded)"
        end
        echo ""
        echo "DEPENDENCIES:"
        echo "  - kubectl: Kubernetes command-line tool"
        echo "  - kubecolor: Colorized kubectl output (optional)"
        return 0
    end

    # Validate prerequisites
    if not command -q kubectl
        echo "Error: kubectl is not installed or not in PATH" >&2
        echo "Please install kubectl to use this function" >&2
        return 1
    end

    # Handle case with no arguments
    if test (count $argv) -eq 0
        echo "Error: No arguments provided" >&2
        echo "Usage: k [kubectl-function-name|kubectl-command] [args...]" >&2
        echo "Use 'k --help' for more information" >&2
        return 1
    end

    # Check if first argument corresponds to a kubectl-* function
    set -l k_func "kubectl-$argv[1]"

    if functions -q $k_func
        # Run the kubectl function with remaining arguments
        $k_func $argv[2..-1]
        return $status
    else
        # Determine which kubectl command to use
        set -l k_cmd
        if command -q kubecolor
            set k_cmd kubecolor
        else
            set k_cmd kubectl
        end

        # Run kubectl/kubecolor with all arguments
        $k_cmd $argv
        return $status
    end
end
