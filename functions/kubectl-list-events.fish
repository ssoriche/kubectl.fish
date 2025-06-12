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

function kubectl-list-events --description 'List Kubernetes events with proper formatting and pagination'
    # Get events in JSON format
    set -l events_json (kubectl get events -o json 2>/dev/null)
    if test $status -ne 0
        echo "Error: Failed to get events from Kubernetes" >&2
        return 1
    end

    # Process events with jq and handle potential parsing errors
    set -l processed_events
    if not set processed_events (echo $events_json | jq -r '
        .items |
        map(
            [
                (.eventTime // .lastTimestamp // .firstTimestamp // "unknown"),
                (if .metadata.namespace then .metadata.namespace else "default" end),
                (.type // "unknown"),
                (.reason // "unknown"),
                ((if .involvedObject.kind then .involvedObject.kind else "unknown" end) + "/" + (if .involvedObject.name then .involvedObject.name else "unknown" end)),
                ((if .source.component then .source.component else "-" end) + "," + (if .source.host then .source.host else "-" end)),
                (.message // "no message")
            ]
        ) |
        sort_by(.[0]) |
        .[] |
        @tsv' 2>/dev/null)
        echo "Error: Failed to process events JSON" >&2
        echo "JQ Error: $processed_events" >&2
        return 1
    end

    # Handle empty results
    if test -z "$processed_events"
        echo "No events found"
        return 0
    end

    # Add header
    set -l header "TIME\tNAMESPACE\tTYPE\tREASON\tOBJECT\tSOURCE\tMESSAGE"
    set all_lines $header $processed_events

    # Write to temp file and page that
    set -l temp_file (mktemp)
    printf "%s\n" $all_lines >$temp_file
    less -S $temp_file
    rm -f $temp_file
end
