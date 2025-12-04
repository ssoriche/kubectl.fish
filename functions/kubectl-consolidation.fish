#!/usr/bin/env fish

# kubectl-consolidation - Enhanced node listing with Karpenter consolidation blocker information
#
# This function wraps 'kubectl get nodes' and augments the output with information about
# why Karpenter cannot consolidate specific nodes. It preserves all kubectl get nodes
# functionality while adding PROVISIONER, CAPACITY-TYPE, CPU-UTIL, MEM-UTIL, and
# CONSOLIDATION-BLOCKER columns to the table output. Nodes are sorted by creation
# timestamp by default (oldest first).
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
        echo "  Wraps 'kubectl get nodes' and augments the table output with PROVISIONER,"
        echo "  CAPACITY-TYPE, CPU-UTIL, MEM-UTIL, and CONSOLIDATION-BLOCKER columns"
        echo "  showing Karpenter node information, resource utilization (based on pod"
        echo "  requests), and why specific nodes cannot be consolidated."
        echo ""
        echo "  Nodes are sorted by creation timestamp by default (oldest first)."
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
        echo "  high-utilization      Node CPU or memory utilization >= 80%"
        echo "  do-not-evict          Pod has karpenter.sh/do-not-evict annotation"
        echo "  do-not-disrupt        Pod has karpenter.sh/do-not-disrupt annotation"
        echo "  do-not-consolidate    Node/Pod has do-not-consolidate annotation"
        echo "  pdb-violation         PodDisruptionBudget prevents disruption"
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

    # Check if column command is available for formatting
    if not command -q column
        echo "Error: 'column' command is required for --pods output but not found" >&2
        return 1
    end

    # Create temp file for collecting output
    set -l tmp_output (mktemp)

    # Print header with actual tabs
    printf "NODE\tNAMESPACE\tPOD\tAGE\tREASON\n" >$tmp_output

    # For each target node, find blocking pods
    for node_name in $target_nodes
        # Get all pods on this node
        set -l pods_json (kubectl get pods --all-namespaces --field-selector "spec.nodeName=$node_name" -o json 2>/dev/null)

        if test $status -ne 0
            continue
        end

        # Find blocking pods (only Karpenter disruption annotations)
        # Output as TSV for proper column formatting with relative age
        echo "$pods_json" | jq -r --arg node "$node_name" '
            # Function to format age as relative duration
            def age_format:
                . as $seconds |
                if $seconds < 60 then ($seconds | floor | tostring) + "s"
                elif $seconds < 3600 then (($seconds / 60) | floor | tostring) + "m"
                elif $seconds < 86400 then (($seconds / 3600) | floor | tostring) + "h"
                else (($seconds / 86400) | floor | tostring) + "d"
                end;

            .items[] |
            select(
                (.metadata.annotations["karpenter.sh/do-not-evict"] == "true") or
                (.metadata.annotations["karpenter.sh/do-not-disrupt"] == "true") or
                (.metadata.annotations["karpenter.sh/do-not-consolidate"] == "true")
            ) |
            [
                $node,
                .metadata.namespace,
                .metadata.name,
                ((now - (.metadata.creationTimestamp | fromdateiso8601)) | age_format),
                (
                    if .metadata.annotations["karpenter.sh/do-not-evict"] == "true" then "do-not-evict"
                    elif .metadata.annotations["karpenter.sh/do-not-disrupt"] == "true" then "do-not-disrupt"
                    elif .metadata.annotations["karpenter.sh/do-not-consolidate"] == "true" then "do-not-consolidate"
                    else "unknown"
                    end
                )
            ] | @tsv
        ' 2>/dev/null >>$tmp_output
    end

    # Format output with proper column alignment
    column -t -s (printf '\t') $tmp_output

    # Cleanup
    rm -f $tmp_output

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

    # Apply default sorting by creation timestamp if no --sort-by flag present
    if not contains -- --sort-by $kubectl_flags
        set kubectl_flags $kubectl_flags --sort-by='.metadata.creationTimestamp'
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

        set -l node_name (string split -n -m 1 " " -- "$lines[$i]" | string trim)[1]
        if test -n "$node_name"
            set node_names $node_names $node_name
        end
    end

    # OPTIMIZATION: Fetch data upfront
    # If specific nodes requested, only fetch data for those nodes (fast)
    # If all nodes requested, fetch all data once (slower but still O(1))

    # Create temp files
    set -l tmp_pods (mktemp)
    set -l tmp_events (mktemp)

    # Build field selectors for specific nodes if applicable
    # OPTIMIZATION: Fetch pods and events in PARALLEL to reduce wall-clock time
    if test (count $node_names) -le 10
        # For small number of nodes, fetch pods per-node (much faster)
        # Collect all pod data first, then merge once (avoids N file operations)
        # Run in background using fish_exec_job
        fish -c "
            for node in $node_names
                kubectl get pods --all-namespaces --field-selector \"spec.nodeName=\$node\" -o json 2>/dev/null
            end | jq -s '{items: [.[].items[] | {spec: {nodeName: .spec.nodeName, containers: [.spec.containers[]? | {resources: .resources}]}, metadata: {namespace: .metadata.namespace, name: .metadata.name, annotations: .metadata.annotations}}]}' >$tmp_pods 2>/dev/null
            if test \$status -ne 0
                echo '{\"items\":[]}' >$tmp_pods
            end
        " &
        set -l pods_job $last_pid

        # Fetch events in parallel
        fish -c "
            for node in $node_names
                kubectl get events --all-namespaces --field-selector \"involvedObject.kind=Node,involvedObject.name=\$node\" -o json 2>/dev/null
            end | jq -s '{items: [.[].items[] | {involvedObject: .involvedObject, reason: .reason, message: .message}]}' >$tmp_events 2>/dev/null
            if test \$status -ne 0
                echo '{\"items\":[]}' >$tmp_events
            end
        " &
        set -l events_job $last_pid

        # Wait for both jobs to complete
        wait $pods_job $events_job 2>/dev/null
    else
        # For many nodes, fetch all pods and events in parallel
        # Fetch pods in background with reduced fields
        fish -c "
            kubectl get pods --all-namespaces -o json 2>/dev/null | jq '{items: [.items[] | {spec: {nodeName: .spec.nodeName, containers: [.spec.containers[]? | {resources: .resources}]}, metadata: {namespace: .metadata.namespace, name: .metadata.name, annotations: .metadata.annotations}}]}' >$tmp_pods 2>&1
            if test \$status -ne 0
                echo '{\"items\":[]}' >$tmp_pods
            end
        " &
        set -l pods_job $last_pid

        # Fetch events in background with reduced fields
        fish -c "
            kubectl get events --all-namespaces --field-selector involvedObject.kind=Node -o json 2>/dev/null | jq '{items: [.items[] | {involvedObject: .involvedObject, reason: .reason, message: .message}]}' >$tmp_events 2>&1
            if test \$status -ne 0
                echo '{\"items\":[]}' >$tmp_events
            end
        " &
        set -l events_job $last_pid

        # Wait for both jobs to complete
        wait $pods_job $events_job 2>/dev/null
    end

    # Fetch node labels, provisioner, capacity type, and resource capacity
    set -l tmp_node_labels (mktemp)
    kubectl get nodes $kubectl_flags -o json 2>/dev/null | jq -r '
        # Helper function to convert CPU to millicores
        def cpu_to_millicores:
            if type == "string" then
                if endswith("m") then
                    .[:-1] | tonumber
                else
                    (tonumber * 1000)
                end
            else
                (tonumber * 1000)
            end;

        # Helper function to convert memory to bytes
        def memory_to_bytes:
            if type == "string" then
                if endswith("Ki") then
                    .[:-2] | tonumber | . * 1024
                elif endswith("Mi") then
                    .[:-2] | tonumber | . * 1024 * 1024
                elif endswith("Gi") then
                    .[:-2] | tonumber | . * 1024 * 1024 * 1024
                elif endswith("Ti") then
                    .[:-2] | tonumber | . * 1024 * 1024 * 1024 * 1024
                elif endswith("K") then
                    .[:-1] | tonumber | . * 1000
                elif endswith("M") then
                    .[:-1] | tonumber | . * 1000 * 1000
                elif endswith("G") then
                    .[:-1] | tonumber | . * 1000 * 1000 * 1000
                elif endswith("T") then
                    .[:-1] | tonumber | . * 1000 * 1000 * 1000 * 1000
                else
                    tonumber
                end
            else
                tonumber
            end;

        (if .items then .items else [.] end)[] |
        [
            .metadata.name,
            (.metadata.labels["karpenter.sh/provisioner-name"] // "<none>"),
            (.metadata.labels["karpenter.sh/capacity-type"] // "<none>"),
            ((.status.allocatable.cpu // "0") | cpu_to_millicores),
            ((.status.allocatable.memory // "0") | memory_to_bytes)
        ] | @tsv
    ' >$tmp_node_labels 2>/dev/null

    # Calculate resource utilization per node
    set -l tmp_utilization (mktemp)
    jq -r --slurpfile pods $tmp_pods --rawfile nodes_data $tmp_node_labels '
        # Helper function to convert CPU to millicores
        def cpu_to_millicores:
            if type == "string" then
                if . == "" or . == null then 0
                elif endswith("m") then
                    .[:-1] | tonumber
                else
                    (tonumber * 1000)
                end
            elif type == "number" then
                (. * 1000)
            else
                0
            end;

        # Helper function to convert memory to bytes
        def memory_to_bytes:
            if type == "string" then
                if . == "" or . == null then 0
                elif endswith("Ki") then
                    .[:-2] | tonumber | . * 1024
                elif endswith("Mi") then
                    .[:-2] | tonumber | . * 1024 * 1024
                elif endswith("Gi") then
                    .[:-2] | tonumber | . * 1024 * 1024 * 1024
                elif endswith("Ti") then
                    .[:-2] | tonumber | . * 1024 * 1024 * 1024 * 1024
                else
                    tonumber
                end
            elif type == "number" then
                .
            else
                0
            end;

        # Parse node data TSV into lookup table
        # Format: node_name<TAB>provisioner<TAB>capacity_type<TAB>cpu_millicores<TAB>memory_bytes
        ($nodes_data | split("\n") | map(select(length > 0) | split("\t")) |
            map({key: .[0], value: {cpu: (.[3] | tonumber), mem: (.[4] | tonumber)}}) |
            from_entries) as $node_capacity |

        # Group pods by node name
        ($pods[0].items | group_by(.spec.nodeName // "") |
            map({key: (.[0].spec.nodeName // ""), value: .}) |
            from_entries) as $pods_by_node |

        # For each node in the capacity data
        $node_capacity | to_entries[] |
        .key as $node_name |
        .value as $capacity |

        # Calculate total requests for this node
        (($pods_by_node[$node_name] // []) |
            map(.spec.containers[]? | .resources.requests // {}) |
            {
                cpu: (map(.cpu // "0" | cpu_to_millicores) | add // 0),
                mem: (map(.memory // "0" | memory_to_bytes) | add // 0)
            }
        ) as $requests |

        # Calculate utilization percentages
        (if $capacity.cpu > 0 then (($requests.cpu / $capacity.cpu) * 100 | floor) else 0 end) as $cpu_util |
        (if $capacity.mem > 0 then (($requests.mem / $capacity.mem) * 100 | floor) else 0 end) as $mem_util |

        # Output: node_name<TAB>cpu_util%<TAB>mem_util%
        [$node_name, ($cpu_util | tostring) + "%", ($mem_util | tostring) + "%"] | @tsv
    ' -n >$tmp_utilization 2>/dev/null
    set -l util_status $status

    if test $util_status -ne 0; or not test -s $tmp_utilization
        # Fallback: create empty utilization data
        for node in $node_names
            printf '%s\t-\t-\n' "$node" >>$tmp_utilization
        end
    end

    # OPTIMIZATION: Process ALL nodes in a single jq pass
    # Build a TSV mapping: node_name<TAB>blockers
    # COMPLEXITY: O(pods + events + nodes) using pre-grouped lookup tables
    # - Pre-group pods by nodeName: O(pods log pods)
    # - Pre-group events by node name: O(events log events)
    # - For each node, O(1) hash lookup: O(nodes)
    # Total: O(pods log pods + events log events + nodes) - much better than O(nodes × (pods + events))
    set -l tmp_results (mktemp)

    # Create temp file with node list (as JSON array)
    set -l tmp_nodes (mktemp)
    printf '%s\n' $node_names | jq -R . | jq -s . >$tmp_nodes

    # Single jq invocation to process all data at once
    # Input: Four data sources loaded via --slurpfile (pods, events, nodes, utilization)
    # Output: TSV lines of "node_name<TAB>blocker1,blocker2" or "node_name<TAB><none>"
    # OPTIMIZATION: Pre-group data by node name for O(pods + events + nodes) instead of O(nodes × (pods + events))
    jq -r --slurpfile pods $tmp_pods --slurpfile events $tmp_events --slurpfile nodes $tmp_nodes --rawfile util_data $tmp_utilization '
        # Define helper function to normalize event messages to short blocker codes
        # Used to convert verbose Karpenter event messages into standardized identifiers
        def normalize_blocker:
            . as $input |
            if ($input | type) != "string" then empty
            elif ($input | test("pdb.*prevent"; "i")) then "pdb-violation"
            elif ($input | test("local storage"; "i")) then "local-storage"
            elif ($input | test("non-replicated"; "i")) then "non-replicated"
            elif ($input | test("would increase cost"; "i")) then "would-increase-cost"
            elif ($input | test("in-use security group"; "i")) then "in-use-security-group"
            elif ($input | test("on-demand"; "i")) then "on-demand-protection"
            elif ($input | test("do-not-consolidate"; "i")) then "do-not-consolidate"
            elif ($input | test("do-not-disrupt"; "i")) then "do-not-disrupt"
            elif ($input | test("do-not-evict"; "i")) then "do-not-evict"
            else empty
            end;

        # Build lookup indices once (O(pods + events + util) preprocessing)
        # Group pods by nodeName for fast lookup
        ($pods[0].items | group_by(.spec.nodeName // "") | map({key: (.[0].spec.nodeName // ""), value: .}) | from_entries) as $pods_by_node |

        # Group events by node name for fast lookup
        ($events[0].items | map(select(.involvedObject.kind == "Node")) | group_by(.involvedObject.name // "") | map({key: (.[0].involvedObject.name // ""), value: .}) | from_entries) as $events_by_node |

        # Parse utilization data: node_name<TAB>cpu_util%<TAB>mem_util%
        ($util_data | split("\n") | map(select(length > 0) | split("\t")) |
            map({key: .[0], value: {cpu: (.[1] | rtrimstr("%") | tonumber? // 0), mem: (.[2] | rtrimstr("%") | tonumber? // 0)}}) |
            from_entries) as $util_by_node |

        # Iterate over each node name from the input list (O(nodes) processing)
        $nodes[0][] as $node |

        # Build a set of pod names that currently exist on this node (for event validation)
        # Format: "namespace/podname" to match event message format
        (($pods_by_node[$node] // []) | map((.metadata.namespace // "") + "/" + (.metadata.name // "")) | unique) as $existing_pods |

        # Collect all consolidation blockers for this node from three sources:
        (
            # Source 1: High utilization check (prevents consolidation)
            (($util_by_node[$node] // {cpu: 0, mem: 0}) |
                if (.cpu >= 80 or .mem >= 80) then ["high-utilization"] else [] end) +

            # Source 2: Pod annotations (O(1) lookup + O(pods_on_node) scan)
            # Check pods on this node for do-not-evict/disrupt/consolidate annotations
            ([($pods_by_node[$node] // [])[] |
                if .metadata.annotations["karpenter.sh/do-not-evict"] == "true" then "do-not-evict"
                elif .metadata.annotations["karpenter.sh/do-not-disrupt"] == "true" then "do-not-disrupt"
                elif .metadata.annotations["karpenter.sh/do-not-consolidate"] == "true" then "do-not-consolidate"
                else empty
                end
            ] | unique) +

            # Source 3: Node events (O(1) lookup + O(events_for_node) scan)
            # Extract and normalize blocker reasons from Karpenter events
            # IMPORTANT: Only include event-based blockers if the referenced pod still exists
            ([($events_by_node[$node] // [])[] |
                select(
                    (.reason // "") as $r |
                    (.message // "") as $m |
                    ($r == "CannotConsolidate" or $r == "DeprovisioningBlocked" or $r == "DisruptionBlocked" or (($m | length) > 0 and ($m | test("consolidat|deprovision|disrupt"; "i"))))
                ) |
                (.message // "") as $msg |
                if ($msg == "" or ($msg | length) == 0) then empty
                # Extract pod name from message format: Pod "namespace/podname"
                # Only process if the pod still exists on this node
                elif (($msg | length) > 0 and ($msg | test("Pod \""))) then
                    # Try to extract pod name (format: Pod "namespace/podname")
                    (($msg | capture("Pod \"(?<pod>[^\"]+)\""; "i") | .pod) // "") as $pod_name |
                    if ($pod_name != "" and ($existing_pods | index($pod_name))) then $msg else empty end
                else
                    # Event does not reference a specific pod, include it
                    $msg
                end |
                normalize_blocker
            ] | unique)
        ) | unique |

        # Format output: node_name<TAB>comma-separated-blockers
        # Example: "node-1<TAB>do-not-evict,pdb-violation" or "node-2<TAB><none>"
        $node + "\t" + (if length > 0 then join(",") else "<none>" end)
    ' -n >$tmp_results 2>/dev/null
    set -l jq_status $status

    rm -f $tmp_nodes

    # Check if jq processing succeeded
    if test $jq_status -ne 0
        echo "Error: jq processing failed (exit code: $jq_status)" >&2
        echo "This usually indicates jq is not available or encountered invalid data" >&2
        rm -f $tmp_pods $tmp_events $tmp_results
        return 1
    else if not test -s $tmp_results
        echo "Warning: jq produced empty results" >&2
        # Create fallback results with <none> for all nodes
        for node in $node_names
            printf '%s\t<none>\n' "$node" >>$tmp_results
        end
    end

    # Read results into arrays (single pass - O(n) instead of O(n²))
    set -l blocker_info (cut -f2 $tmp_results)

    # Read node labels (provisioner and capacity type)
    set -l provisioner_info (cut -f2 $tmp_node_labels)
    set -l capacity_info (cut -f3 $tmp_node_labels)

    # Read utilization data
    set -l cpu_util_info (cut -f2 $tmp_utilization)
    set -l mem_util_info (cut -f3 $tmp_utilization)

    # Cleanup temp files
    rm -f $tmp_pods $tmp_events $tmp_results $tmp_node_labels $tmp_utilization

    # Create temp file for formatted output
    set -l tmp_output (mktemp)

    # Build the augmented table
    if test "$has_header" = true
        printf '%s\tPROVISIONER\tCAPACITY-TYPE\tCPU-UTIL\tMEM-UTIL\tCONSOLIDATION-BLOCKER\n' "$header_line" >$tmp_output
    end

    # Print data lines with blocker information
    set -l node_index 1
    for i in (seq $data_start_index (count $lines))
        if test -z "$lines[$i]"
            continue
        end

        set -l provisioner ""
        set -l capacity ""
        set -l cpu_util ""
        set -l mem_util ""
        set -l blocker ""

        if test $node_index -le (count $blocker_info)
            set provisioner $provisioner_info[$node_index]
            set capacity $capacity_info[$node_index]
            set cpu_util $cpu_util_info[$node_index]
            set mem_util $mem_util_info[$node_index]
            set blocker $blocker_info[$node_index]
        else
            set provisioner "<error>"
            set capacity "<error>"
            set cpu_util "<error>"
            set mem_util "<error>"
            set blocker "<error>"
        end

        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$lines[$i]" "$provisioner" "$capacity" "$cpu_util" "$mem_util" "$blocker" >>$tmp_output
        set node_index (math $node_index + 1)
    end

    # Format output with proper column alignment
    if command -q column
        column -t -s (printf '\t') $tmp_output
    else
        # Fallback: just output without alignment
        cat $tmp_output
    end

    # Cleanup
    rm -f $tmp_output

    return 0
end
