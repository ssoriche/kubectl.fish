#!/usr/bin/env fish

# kubectl-list-events - View Kubernetes events sorted by timestamp
#
# DESCRIPTION:
#     This function lists Kubernetes events in a human-readable format, sorted by
#     timestamp. It displays events in a tabular format with columns for time,
#     namespace, type, reason, object, source, and message.
#
# USAGE:
#     kubectl-list-events [kubectl-get-events-options...]
#
# EXAMPLES:
#     kubectl-list-events
#     kubectl-list-events -n kube-system
#     kubectl-list-events --all-namespaces
#     kubectl-list-events --field-selector type=Warning
#
# DEPENDENCIES:
#     - kubectl: Kubernetes command-line tool
#     - jq: JSON processor
#     - column: Text columnization utility
#     - less: Pager (optional)
#
# AUTHOR:
#     kubectl.fish collection

function kubectl-list-events -d "View Kubernetes events sorted by timestamp" --wraps 'kubectl get events'
    # Handle help option
    if contains -- --help $argv; or contains -- -h $argv
        echo "kubectl-list-events - View Kubernetes events sorted by timestamp"
        echo ""
        echo "USAGE:"
        echo "  kubectl-list-events [kubectl-get-events-options...]"
        echo ""
        echo "EXAMPLES:"
        echo "  kubectl-list-events"
        echo "  kubectl-list-events -n kube-system"
        echo "  kubectl-list-events --all-namespaces"
        echo "  kubectl-list-events --field-selector type=Warning"
        echo ""
        echo "DEPENDENCIES:"
        echo "  - kubectl: Kubernetes command-line tool"
        echo "  - jq: JSON processor"
        echo "  - column: Text columnization utility"
        echo "  - less: Pager (optional)"
        return 0
    end

    # Validate prerequisites
    if not command -q kubectl
        echo "Error: kubectl is not installed or not in PATH" >&2
        echo "Please install kubectl to use this function" >&2
        return 1
    end

    if not command -q jq
        echo "Error: jq is not installed or not in PATH" >&2
        echo "Please install jq to use this function" >&2
        echo "  - macOS: brew install jq" >&2
        echo "  - Ubuntu/Debian: apt-get install jq" >&2
        return 1
    end

    if not command -q column
        echo "Error: column utility is not available" >&2
        echo "This is usually part of util-linux package" >&2
        return 1
    end

    # Get events with error handling - let kubectl handle connection errors
    set -l events_json
    if not set events_json (kubectl get events -o json $argv 2>&1)
        echo "Error: Failed to get events from kubectl" >&2
        echo $events_json >&2
        return 1
    end

    # Process events with jq and handle potential parsing errors
    set -l processed_events
    if not set processed_events (echo $events_json | jq -r '
        .items |
        map(. + {t: (.eventTime//.lastTimestamp//(.firstTimestamp//"unknown"))}) |
        sort_by(.t)[] |
        [
            .t,
            (.metadata.namespace//"default"),
            .type,
            .reason,
            (.involvedObject.kind + "/" + .involvedObject.name),
            ((.source.component//"-") + "," + (.source.host//"-")),
            .message
        ] |
        @tsv' 2>&1)
        echo "Error: Failed to process events JSON" >&2
        echo $processed_events >&2
        return 1
    end

    # Create output with header and data
    set -l output
    set output (printf "TIME\tNAMESPACE\tTYPE\tREASON\tOBJECT\tSOURCE\tMESSAGE\n%s" "$processed_events")

    # Format and display
    if command -q less
        echo $output | column -t -s (printf '\t') | less -S
    else
        echo $output | column -t -s (printf '\t')
    end
end
