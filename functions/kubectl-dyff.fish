#!/usr/bin/env fish

# kubectl-dyff - Semantic diff of Kubernetes manifests using dyff
#
# DESCRIPTION:
#     This function provides semantic diff between local Kubernetes manifests and
#     live cluster resources using the dyff tool. It offers a more human-readable
#     and semantically meaningful diff compared to standard diff tools.
#
# USAGE:
#     kubectl-dyff [OPTIONS] -f FILE
#     kubectl-dyff [OPTIONS] FILE
#
# OPTIONS:
#     -f, --filename FILE    Local manifest file to compare (optional flag)
#     -n, --namespace NS     Override namespace from manifest
#     --omit-header          Omit dyff header in output
#     --set-exit-code        Set exit code based on differences (0=none, 1=diff found)
#
# EXAMPLES:
#     kubectl-dyff -f deployment.yaml
#     kubectl-dyff deployment.yaml
#     kubectl-dyff -f pod.yaml -n production
#     kubectl-dyff --omit-header --set-exit-code deployment.yaml
#
# DEPENDENCIES:
#     - kubectl: Kubernetes command-line tool
#     - dyff: Semantic YAML diff tool
#     - yq: YAML processor for extracting resource metadata
#
# AUTHOR:
#     kubectl.fish collection

function kubectl-dyff -d "Semantic diff of Kubernetes manifests using dyff" --wraps 'kubectl diff'
    # Handle help option
    if contains -- --help $argv; or contains -- -h $argv
        echo "kubectl-dyff - Semantic diff of Kubernetes manifests using dyff"
        echo ""
        echo "USAGE:"
        echo "  kubectl-dyff [OPTIONS] -f FILE"
        echo "  kubectl-dyff [OPTIONS] FILE"
        echo ""
        echo "OPTIONS:"
        echo "  -f, --filename FILE    Local manifest file to compare (optional flag)"
        echo "  -n, --namespace NS     Override namespace from manifest"
        echo "  --omit-header          Omit dyff header in output"
        echo "  --set-exit-code        Set exit code based on differences (0=none, 1=diff found)"
        echo ""
        echo "DESCRIPTION:"
        echo "  This function provides semantic diff between local Kubernetes manifests and"
        echo "  live cluster resources using the dyff tool. It offers a more human-readable"
        echo "  and semantically meaningful diff compared to standard diff tools."
        echo ""
        echo "EXAMPLES:"
        echo "  kubectl-dyff -f deployment.yaml"
        echo "  kubectl-dyff deployment.yaml"
        echo "  kubectl-dyff -f pod.yaml -n production"
        echo "  kubectl-dyff --omit-header --set-exit-code deployment.yaml"
        echo ""
        echo "DEPENDENCIES:"
        echo "  - kubectl: Kubernetes command-line tool"
        echo "  - dyff: Semantic YAML diff tool"
        echo "  - yq: YAML processor for extracting resource metadata"
        echo ""
        echo "INSTALLATION:"
        echo "  # dyff"
        echo "  # macOS"
        echo "  brew install dyff"
        echo ""
        echo "  # Go"
        echo "  go install github.com/homeport/dyff/cmd/dyff@latest"
        echo ""
        echo "  # yq"
        echo "  # macOS"
        echo "  brew install yq"
        echo ""
        echo "  # Go"
        echo "  go install github.com/mikefarah/yq/v4@latest"
        return 0
    end

    # Validate prerequisites
    if not command -q kubectl
        echo "Error: kubectl is not installed or not in PATH" >&2
        echo "Please install kubectl to use this function" >&2
        return 1
    end

    if not command -q dyff
        echo "Error: dyff is not installed or not in PATH" >&2
        echo "Install with: brew install dyff (macOS) or go install github.com/homeport/dyff/cmd/dyff@latest" >&2
        return 1
    end

    if not command -q yq
        echo "Error: yq is not installed or not in PATH" >&2
        echo "Install with: brew install yq (macOS) or go install github.com/mikefarah/yq/v4@latest" >&2
        return 1
    end

    # Parse arguments
    set -l manifest_file
    set -l namespace_override
    set -l dyff_options
    set -l i 1

    while test $i -le (count $argv)
        switch $argv[$i]
            case -f --filename
                if test (math $i + 1) -le (count $argv)
                    set manifest_file $argv[(math $i + 1)]
                    set i (math $i + 2)
                else
                    echo "Error: -f/--filename requires a value" >&2
                    return 1
                end
            case -n --namespace
                if test (math $i + 1) -le (count $argv)
                    set namespace_override $argv[(math $i + 1)]
                    set i (math $i + 2)
                else
                    echo "Error: -n/--namespace requires a value" >&2
                    return 1
                end
            case --omit-header
                set dyff_options $dyff_options --omit-header
                set i (math $i + 1)
            case --set-exit-code
                set dyff_options $dyff_options --set-exit-code
                set i (math $i + 1)
            case -*
                echo "Error: Unknown option: $argv[$i]" >&2
                echo "Use 'kubectl-dyff --help' for more information" >&2
                return 1
            case "*"
                # If no manifest_file set yet, treat as filename
                if test -z "$manifest_file"
                    set manifest_file $argv[$i]
                else
                    echo "Error: Multiple files specified" >&2
                    echo "Use 'kubectl-dyff --help' for more information" >&2
                    return 1
                end
                set i (math $i + 1)
        end
    end

    # Validate that a manifest file was provided
    if test -z "$manifest_file"
        echo "Error: No manifest file provided" >&2
        echo "Usage: kubectl-dyff [OPTIONS] -f FILE" >&2
        echo "       kubectl-dyff [OPTIONS] FILE" >&2
        echo "Use 'kubectl-dyff --help' for more information" >&2
        return 1
    end

    # Validate that the manifest file exists
    if not test -f "$manifest_file"
        echo "Error: Manifest file not found: $manifest_file" >&2
        return 1
    end

    # Extract resource metadata from the manifest
    set -l kind (yq eval '.kind' "$manifest_file")
    set -l name (yq eval '.metadata.name' "$manifest_file")
    set -l namespace (yq eval '.metadata.namespace // "default"' "$manifest_file")

    # Use namespace override if provided
    if test -n "$namespace_override"
        set namespace $namespace_override
    end

    # Validate extracted metadata
    if test "$kind" = null -o -z "$kind"
        echo "Error: Could not extract 'kind' from manifest file" >&2
        return 1
    end

    if test "$name" = null -o -z "$name"
        echo "Error: Could not extract 'metadata.name' from manifest file" >&2
        return 1
    end

    # Build kubectl get command
    set -l kubectl_args get $kind $name -o yaml

    # Add namespace for namespaced resources (skip for cluster-scoped resources)
    if test "$namespace" != null -a -n "$namespace"
        set kubectl_args $kubectl_args -n $namespace
    end

    # Get the live resource from cluster
    set -l live_resource_file (mktemp)
    if not kubectl $kubectl_args >$live_resource_file 2>/dev/null
        echo "Error: Could not retrieve $kind/$name from cluster" >&2
        if test "$namespace" != null -a -n "$namespace"
            echo "Namespace: $namespace" >&2
        end
        echo "Resource may not exist in cluster yet (this is normal for new resources)" >&2
        rm -f $live_resource_file
        return 1
    end

    # Run dyff comparison
    dyff between $dyff_options $live_resource_file $manifest_file
    set -l dyff_exit_code $status

    # Cleanup temporary file
    rm -f $live_resource_file

    return $dyff_exit_code
end
