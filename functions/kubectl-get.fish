#!/usr/bin/env fish

# kubectl-get - Enhanced kubectl get with templates and jq support
#
# DESCRIPTION:
#     Enhanced wrapper around 'kubectl get' that adds support for:
#     - Custom-columns templates with ^template-name syntax
#     - jq field extraction with .field syntax
#     - Smart auto-sorting for events, nodes, and replicasets
#
# USAGE:
#     kubectl-get RESOURCE [NAME] [FLAGS...]
#     kubectl-get RESOURCE [NAME] ^template-name [FLAGS...]
#     kubectl-get RESOURCE [NAME] .field [FLAGS...]
#
# EXAMPLES:
#     kubectl-get pods                    # Standard kubectl get
#     kubectl-get pods ^pods-wide         # Use custom template
#     kubectl-get pods .items[0].metadata.name  # jq field extraction
#     kubectl-get events                  # Auto-sorted by timestamp
#     kubectl-get nodes ^nodes            # Template for node view
#     kubectl-get pods -n kube-system ^scaleops-pod  # Template with namespace
#
# TEMPLATE SYNTAX:
#     ^template-name  - Loads custom-columns template from:
#                       $KUBECTL_TEMPLATES_DIR or ~/.kube/templates/
#
# JQ SYNTAX:
#     .field          - Extracts JSON field using jq
#                       (e.g., .items[0].metadata.name)
#
# SMART SORTING:
#     - events: Automatically sorted by .lastTimestamp
#     - nodes: Automatically sorted by .metadata.creationTimestamp
#     - replicasets: Automatically sorted by .metadata.creationTimestamp
#
# DEPENDENCIES:
#     - kubectl: Kubernetes command-line tool
#     - jq: JSON processor (required for .field syntax)
#
# AUTHOR:
#     kubectl.fish collection

function kubectl-get -d "Enhanced kubectl get with templates and jq support" --wraps 'kubectl get'
    # Handle help option first
    if contains -- --help $argv; or contains -- -h $argv
        echo "kubectl-get - Enhanced kubectl get with templates and jq support"
        echo ""
        echo "USAGE:"
        echo "  kubectl-get RESOURCE [NAME] [FLAGS...]"
        echo "  kubectl-get RESOURCE [NAME] ^template-name [FLAGS...]"
        echo "  kubectl-get RESOURCE [NAME] .field [FLAGS...]"
        echo ""
        echo "DESCRIPTION:"
        echo "  Enhanced wrapper around 'kubectl get' that adds support for:"
        echo "    - Custom-columns templates with ^template-name syntax"
        echo "    - jq field extraction with .field syntax"
        echo "    - Smart auto-sorting for events, nodes, and replicasets"
        echo ""
        echo "EXAMPLES:"
        echo "  kubectl-get pods                    # Standard kubectl get"
        echo "  kubectl-get pods ^pods-wide         # Use custom template"
        echo "  kubectl-get pods .items[0].metadata.name  # jq field extraction"
        echo "  kubectl-get events                  # Auto-sorted by timestamp"
        echo "  kubectl-get nodes ^nodes            # Template for node view"
        echo "  kubectl-get pods -n kube-system ^scaleops-pod"
        echo ""
        echo "TEMPLATE SYNTAX:"
        echo "  ^template-name  - Loads custom-columns template from:"
        echo "                    \$KUBECTL_TEMPLATES_DIR or ~/.kube/templates/"
        echo ""
        echo "JQ SYNTAX:"
        echo "  .field          - Extracts JSON field using jq"
        echo "                    (e.g., .items[0].metadata.name)"
        echo ""
        echo "SMART SORTING:"
        echo "  - events: Automatically sorted by .lastTimestamp"
        echo "  - nodes: Automatically sorted by .metadata.creationTimestamp"
        echo "  - replicasets: Automatically sorted by .metadata.creationTimestamp"
        echo ""
        echo "DEPENDENCIES:"
        echo "  - kubectl: Kubernetes command-line tool"
        echo "  - jq: JSON processor (required for .field syntax)"
        echo ""
        echo "INSTALLATION:"
        echo "  # macOS"
        echo "  brew install jq"
        echo ""
        echo "  # Ubuntu/Debian"
        echo "  sudo apt-get install jq"
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
        echo "Usage: kubectl-get RESOURCE [NAME] [FLAGS...]" >&2
        echo "Use 'kubectl-get --help' for more information" >&2
        return 1
    end

    # Parse arguments for special syntax
    set -l parsed (__kubectl_parse_get_args $argv)

    # Extract parsed values
    set -l template_name ""
    set -l jq_expr ""
    set -l kubectl_args

    for line in $parsed
        set -l key (string split -m 1 : -- $line)[1]
        set -l value (string split -m 1 : -- $line)[2]

        switch $key
            case template
                set template_name $value
            case jq
                set jq_expr $value
            case args
                set kubectl_args (string split " " -- $value)
        end
    end

    # Handle template syntax (^template-name)
    if test -n "$template_name"
        set -l template_path (__kubectl_find_template $template_name)
        if test -z "$template_path"
            echo "Error: Template '$template_name' not found" >&2
            echo "Search paths:" >&2
            if set -q KUBECTL_TEMPLATES_DIR
                echo "  - $KUBECTL_TEMPLATES_DIR" >&2
            else
                echo "  - ~/.kube/templates/" >&2
            end
            echo "Use 'kubectl-get --help' for more information" >&2
            return 1
        end

        set -l template_content (cat $template_path)
        set kubectl_args $kubectl_args "--output=custom-columns=$template_content"
    end

    # Handle jq syntax (.field)
    if test -n "$jq_expr"
        # Validate jq is available
        if not command -q jq
            echo "Error: jq is required for .field syntax but not installed" >&2
            echo "Install with: brew install jq (macOS) or apt-get install jq (Ubuntu)" >&2
            return 1
        end

        # Add JSON output flag
        set kubectl_args $kubectl_args -o json
    end

    # Apply smart sorting if no --sort-by flag present
    if not contains -- --sort-by $kubectl_args
        # Get the resource type (first non-flag argument)
        set -l resource_type ""
        for arg in $kubectl_args
            if not string match -qr '^-' -- $arg
                set resource_type $arg
                break
            end
        end

        # Apply sorting based on resource type
        switch $resource_type
            case events event
                set kubectl_args $kubectl_args "--sort-by=.lastTimestamp"
            case nodes node no
                set kubectl_args $kubectl_args "--sort-by=.metadata.creationTimestamp"
            case replicasets replicaset rs
                set kubectl_args $kubectl_args "--sort-by=.metadata.creationTimestamp"
        end
    end

    # Execute kubectl command
    if test -n "$jq_expr"
        # Remove leading dot from jq expression if present
        set jq_expr (string replace -r '^\.' '' -- $jq_expr)
        kubectl get $kubectl_args | jq ".$jq_expr"
    else
        kubectl get $kubectl_args
    end
end
