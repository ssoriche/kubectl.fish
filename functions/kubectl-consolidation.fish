#!/usr/bin/env fish

# kubectl-consolidation - Enhanced node listing with Karpenter consolidation blocker information
#
# This function wraps 'kubectl get nodes' and augments the output with information about
# why Karpenter cannot consolidate specific nodes. It preserves all kubectl get nodes
# functionality while adding a CONSOLIDATION-BLOCKER column to the table output.
#
# USAGE:
#   kubectl consolidation [OPTIONS] [NODE...]
#   kubectl consolidation --pods NODE [NODE...]
#   kubectl consolidation --nodeclaims [NODE...]
#   kubectl consolidation -l key=value
#   kubectl consolidation -o json
#
# EXAMPLES:
#   kubectl consolidation
#   kubectl consolidation node-1 node-2
#   kubectl consolidation -l node-type=spot
#   kubectl consolidation --nodeclaims
#   kubectl consolidation --pods node-1
#   kubectl consolidation -o json
#
# DEPENDENCIES:
#   - kubectl: Kubernetes command-line tool (required)
#   - jq: Command-line JSON processor (required)
#
# INSTALLATION:
#   brew install jq
#   apt-get install jq
#
# AUTHOR: kubectl.fish collection

function kubectl-consolidation -d "Show nodes with Karpenter consolidation blocker information" --wraps 'kubectl get'
    # Phase 1: Handle help option
    if contains -- --help $argv; or contains -- -h $argv
        echo "kubectl-consolidation - Show nodes with Karpenter consolidation blocker information"
        echo ""
        echo "USAGE:"
        echo "  kubectl consolidation [OPTIONS] [NODE...]"
        echo "  kubectl consolidation --pods NODE [NODE...]"
        echo "  kubectl consolidation --nodeclaims [NODE...]"
        echo "  kubectl consolidation --all [NODE...]"
        echo ""
        echo "DESCRIPTION:"
        echo "  Wraps 'kubectl get nodes' and augments the table output with a CONSOLIDATION-BLOCKER"
        echo "  column showing why Karpenter cannot consolidate specific nodes."
        echo ""
        echo "  The function detects consolidation blockers from multiple sources:"
        echo "    - Pod annotations (karpenter.sh/do-not-evict, do-not-disrupt, do-not-consolidate)"
        echo "    - Node events (CannotConsolidate reasons)"
        echo "    - NodeClaim events (when --nodeclaims flag is used)"
        echo ""
        echo "OPTIONS:"
        echo "  --pods         Show detailed pod-level blockers in column format (requires node names)"
        echo "  --nodeclaims   Include NodeClaim events (Karpenter v0.32+, checks CRD availability)"
        echo "  --all          Alias for --nodeclaims"
        echo "  -o, --output   Output format (json, yaml, etc.) - passes through to kubectl"
        echo ""
        echo "  All kubectl get nodes flags are supported: -l, --selector, --field-selector, etc."
        echo ""
        echo "EXAMPLES:"
        echo "  # Show all nodes with consolidation information"
        echo "  kubectl consolidation"
        echo ""
        echo "  # Show specific nodes"
        echo "  kubectl consolidation node-1 node-2"
        echo ""
        echo "  # Filter nodes by label"
        echo "  kubectl consolidation -l node-type=spot"
        echo ""
        echo "  # Include NodeClaim events (Karpenter v0.32+)"
        echo "  kubectl consolidation --nodeclaims"
        echo ""
        echo "  # Show detailed pod blockers for a node"
        echo "  kubectl consolidation --pods node-1"
        echo ""
        echo "  # Show pod blockers for multiple nodes"
        echo "  kubectl consolidation --pods node-1 node-2"
        echo ""
        echo "  # Get JSON output (passes through to kubectl)"
        echo "  kubectl consolidation -o json"
        echo ""
        echo "BLOCKER TYPES:"
        echo "  do-not-evict          Pod has karpenter.sh/do-not-evict annotation"
        echo "  do-not-disrupt        Pod has karpenter.sh/do-not-disrupt annotation"
        echo "  do-not-consolidate    Node/Pod has do-not-consolidate annotation"
        echo "  pdb-violation         PodDisruptionBudget prevents disruption"
        echo "  local-storage         Pod uses local storage (emptyDir)"
        echo "  non-replicated        Pod has no controller (standalone)"
        echo "  would-increase-cost   Consolidation would increase costs"
        echo "  in-use-security-group Node security group in use"
        echo "  on-demand-protection  Would delete on-demand node"
        echo ""
        echo "DEPENDENCIES:"
        echo "  - kubectl: Kubernetes command-line tool (required)"
        echo "  - jq: Command-line JSON processor (required)"
        echo ""
        echo "INSTALLATION:"
        echo "  brew install kubectl jq"
        echo "  apt-get install kubectl jq"
        return 0
    end

    # Phase 2: Validate prerequisites
    if not command -q kubectl
        echo "Error: kubectl is not installed or not in PATH" >&2
        echo "Please install kubectl to use this function" >&2
        return 1
    end

    if not command -q jq
        echo "Error: jq is required but not installed" >&2
        echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)" >&2
        return 1
    end

    # Phase 3: Argument parsing
    set -l pods_mode false
    set -l include_nodeclaims false
    set -l passthrough_mode false
    set -l node_args
    set -l kubectl_flags

    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case --pods
                set pods_mode true
                set i (math $i + 1)
            case --nodeclaims --all
                set include_nodeclaims true
                set i (math $i + 1)
            case -o --output
                set passthrough_mode true
                break
            case -n --namespace -l --selector --field-selector --sort-by --no-headers --show-labels
                # kubectl flags that need a value
                if test (math $i + 1) -le (count $argv)
                    set kubectl_flags $kubectl_flags $argv[$i] $argv[(math $i + 1)]
                    set i (math $i + 2)
                else
                    echo "Error: $argv[$i] requires a value" >&2
                    return 1
                end
            case '-*'
                # Other kubectl flags
                set kubectl_flags $kubectl_flags $argv[$i]
                set i (math $i + 1)
            case '*'
                # Node names
                set node_args $node_args $argv[$i]
                set i (math $i + 1)
        end
    end

    # Phase 4: Validation
    if test "$pods_mode" = true
        if test (count $node_args) -eq 0
            echo "Error: --pods flag requires at least one node name" >&2
            echo "Usage: kubectl consolidation --pods NODE [NODE...]" >&2
            echo "Use 'kubectl consolidation --help' for more information" >&2
            return 1
        end
    end

    # If passthrough mode, delegate to kubectl
    if test "$passthrough_mode" = true
        kubectl get nodes $argv
        return $status
    end

    # Phase 5: Execute based on mode
    if test "$pods_mode" = true
        # Show pod detail view
        _kubectl_consolidation_show_pods $node_args
    else
        # Show node table view with blockers
        _kubectl_consolidation_show_nodes $include_nodeclaims $kubectl_flags $node_args
    end
end

# Helper function: Show pod detail view
function _kubectl_consolidation_show_pods
    set -l target_nodes $argv

    # Print header
    echo "NODE"(string repeat -n 42 " ")"POD"(string repeat -n 17 " ")"NAMESPACE    REASON"

    # For each target node, find blocking pods
    for node_name in $target_nodes
        # Get all pods on this node
        set -l pods_json (kubectl get pods --all-namespaces --field-selector "spec.nodeName=$node_name" -o json 2>/dev/null)

        if test $status -ne 0
            continue
        end

        # Find blocking pods
        echo "$pods_json" | jq -r --arg node "$node_name" '
            .items[] |
            select(
                (.metadata.annotations["karpenter.sh/do-not-evict"] == "true") or
                (.metadata.annotations["karpenter.sh/do-not-disrupt"] == "true") or
                (.metadata.annotations["karpenter.sh/do-not-consolidate"] == "true") or
                (.spec.volumes[]? | select(.emptyDir != null))
            ) |
            {
                node: $node,
                name: .metadata.name,
                namespace: .metadata.namespace,
                reason: (
                    if .metadata.annotations["karpenter.sh/do-not-evict"] == "true" then "do-not-evict"
                    elif .metadata.annotations["karpenter.sh/do-not-disrupt"] == "true" then "do-not-disrupt"
                    elif .metadata.annotations["karpenter.sh/do-not-consolidate"] == "true" then "do-not-consolidate"
                    elif (.spec.volumes[]? | select(.emptyDir != null)) then "local-storage"
                    else "unknown"
                    end
                )
            } |
            "\(.node)  \(.name)  \(.namespace)  \(.reason)"
        ' 2>/dev/null
    end

    return 0
end

# Helper function: Show node table view with blockers
function _kubectl_consolidation_show_nodes
    set -l include_nodeclaims $argv[1]
    set -l kubectl_flags $argv[2..-1]

    # Check if NodeClaim CRD exists (for --nodeclaims support)
    set -l has_nodeclaim_crd false
    if test "$include_nodeclaims" = true
        if kubectl get crd nodeclaims.karpenter.sh >/dev/null 2>&1
            set has_nodeclaim_crd true
        else
            echo "Warning: NodeClaim CRD not found, showing Node events only (Karpenter v0.32+ required)" >&2
        end
    end

    # Get node list - use string collect to preserve newlines
    set -l node_output (kubectl get nodes $kubectl_flags 2>&1 | string collect)
    set -l kubectl_status $status

    if test $kubectl_status -ne 0
        echo "$node_output" >&2
        return $kubectl_status
    end

    # Parse node output
    set -l lines (string split \n -- "$node_output")

    if test (count $lines) -eq 0
        return 0
    end

    # Check for header
    set -l has_header false
    set -l header_line ""
    set -l data_start_index 1

    if string match -q "NAME*" -- "$lines[1]"
        set has_header true
        set header_line "$lines[1]"
        set data_start_index 2
    end

    # Extract node names
    set -l node_names
    for i in (seq $data_start_index (count $lines))
        if test -z "$lines[$i]"
            continue
        end

        set -l node_name (string split -n -m 1 " " -- "$lines[$i]" | head -n 1 | string trim)
        if test -n "$node_name"
            set node_names $node_names $node_name
        end
    end

    # Collect blocker information for each node
    set -l blocker_info
    for node_name in $node_names
        set -l blockers

        # 1. Check pod annotations
        set -l pod_blockers (_kubectl_consolidation_check_pod_annotations $node_name)
        if test -n "$pod_blockers"
            for blocker in (string split "," -- "$pod_blockers")
                if not contains $blocker $blockers
                    set blockers $blockers $blocker
                end
            end
        end

        # 2. Check node events
        set -l event_blockers (_kubectl_consolidation_check_node_events $node_name)
        if test -n "$event_blockers"
            for blocker in (string split "," -- "$event_blockers")
                if not contains $blocker $blockers
                    set blockers $blockers $blocker
                end
            end
        end

        # 3. Check NodeClaim events if enabled
        if test "$has_nodeclaim_crd" = true
            set -l nodeclaim_blockers (_kubectl_consolidation_check_nodeclaim_events $node_name)
            if test -n "$nodeclaim_blockers"
                for blocker in (string split "," -- "$nodeclaim_blockers")
                    if not contains $blocker $blockers
                        set blockers $blockers $blocker
                    end
                end
            end
        end

        # Format blockers
        if test (count $blockers) -eq 0
            set blocker_info $blocker_info "<none>"
        else
            set blocker_info $blocker_info (string join "," -- $blockers)
        end
    end

    # Output the augmented table
    if test "$has_header" = true
        echo "$header_line  CONSOLIDATION-BLOCKER"
    end

    # Print data lines with blocker information
    set -l node_index 1
    for i in (seq $data_start_index (count $lines))
        if test -z "$lines[$i]"
            continue
        end

        set -l blocker ""
        if test $node_index -le (count $blocker_info)
            set blocker $blocker_info[$node_index]
        else
            set blocker "<error>"
        end

        echo "$lines[$i]  $blocker"
        set node_index (math $node_index + 1)
    end

    return 0
end

# Helper function: Check pod annotations for blockers
function _kubectl_consolidation_check_pod_annotations
    set -l node_name $argv[1]
    set -l blockers

    # Get pods with blocking annotations
    set -l pods_json (kubectl get pods --all-namespaces --field-selector "spec.nodeName=$node_name" -o json 2>/dev/null)
    set -l kubectl_status $status

    if test $kubectl_status -eq 0; and test -n "$pods_json"
        set -l has_do_not_evict (echo "$pods_json" | jq -r '[.items[].metadata.annotations["karpenter.sh/do-not-evict"]? // ""] | any(. == "true")' 2>/dev/null)
        set -l has_do_not_disrupt (echo "$pods_json" | jq -r '[.items[].metadata.annotations["karpenter.sh/do-not-disrupt"]? // ""] | any(. == "true")' 2>/dev/null)
        set -l has_do_not_consolidate (echo "$pods_json" | jq -r '[.items[].metadata.annotations["karpenter.sh/do-not-consolidate"]? // ""] | any(. == "true")' 2>/dev/null)

        if test "$has_do_not_evict" = true
            set blockers $blockers do-not-evict
        end
        if test "$has_do_not_disrupt" = true
            set blockers $blockers do-not-disrupt
        end
        if test "$has_do_not_consolidate" = true
            set blockers $blockers do-not-consolidate
        end
    end

    if test (count $blockers) -gt 0
        string join "," -- $blockers
    end
end

# Helper function: Check node events for blockers
function _kubectl_consolidation_check_node_events
    set -l node_name $argv[1]
    set -l blockers

    # Get recent events for this node
    set -l events (kubectl get events --field-selector "involvedObject.name=$node_name,involvedObject.kind=Node" \
        --sort-by='.lastTimestamp' -o json 2>/dev/null | \
        jq -r '.items[] | select(.reason == "CannotConsolidate" or (.message | contains("consolidation")) or (.message | contains("Consolidation"))) | .message' 2>/dev/null)

    # Normalize event messages to short codes
    for event in $events
        set -l normalized (_kubectl_consolidation_normalize_event $event)
        if test -n "$normalized"
            if not contains $normalized $blockers
                set blockers $blockers $normalized
            end
        end
    end

    if test (count $blockers) -gt 0
        string join "," -- $blockers
    end
end

# Helper function: Check NodeClaim events for blockers
function _kubectl_consolidation_check_nodeclaim_events
    set -l node_name $argv[1]
    set -l blockers

    # Get NodeClaim name for this node
    set -l nodeclaim_name (kubectl get nodeclaims -o json 2>/dev/null | \
        jq -r --arg node "$node_name" '.items[] | select(.status.nodeName == $node) | .metadata.name' 2>/dev/null)

    if test -n "$nodeclaim_name"
        # Get events for this NodeClaim
        set -l events (kubectl get events --field-selector "involvedObject.name=$nodeclaim_name,involvedObject.kind=NodeClaim" \
            --sort-by='.lastTimestamp' -o json 2>/dev/null | \
            jq -r '.items[] | select(.reason == "CannotConsolidate" or (.message | contains("consolidation")) or (.message | contains("Consolidation"))) | .message' 2>/dev/null)

        # Normalize event messages
        for event in $events
            set -l normalized (_kubectl_consolidation_normalize_event $event)
            if test -n "$normalized"
                if not contains $normalized $blockers
                    set blockers $blockers $normalized
                end
            end
        end
    end

    if test (count $blockers) -gt 0
        string join "," -- $blockers
    end
end

# Helper function: Normalize event messages to short codes
function _kubectl_consolidation_normalize_event
    set -l event_message $argv[1]

    # Match event message patterns to short codes
    if string match -q -i "*pdb*prevent*" -- "$event_message"
        echo pdb-violation
    else if string match -q -i "*local storage*" -- "$event_message"
        echo local-storage
    else if string match -q -i "*non-replicated*" -- "$event_message"
        echo non-replicated
    else if string match -q -i "*would increase cost*" -- "$event_message"
        echo would-increase-cost
    else if string match -q -i "*in-use security group*" -- "$event_message"
        echo in-use-security-group
    else if string match -q -i "*on-demand*" -- "$event_message"
        echo on-demand-protection
    else if string match -q -i "*do-not-consolidate*" -- "$event_message"
        echo do-not-consolidate
    else if string match -q -i "*do-not-disrupt*" -- "$event_message"
        echo do-not-disrupt
    else if string match -q -i "*do-not-evict*" -- "$event_message"
        echo do-not-evict
    end
end
