function kubectl-why-not-deleted -d "Analyze why a Kubernetes resource is not being deleted" --wraps 'kubectl get'
    # Handle help option first
    if contains -- --help $argv; or contains -- -h $argv
        echo "kubectl-why-not-deleted - Analyze why a Kubernetes resource is not being deleted"
        echo ""
        echo "USAGE:"
        echo "  kubectl-why-not-deleted RESOURCE NAME [-n NAMESPACE]"
        echo ""
        echo "DESCRIPTION:"
        echo "  This function analyzes why a Kubernetes resource is not being deleted by checking"
        echo "  for finalizers, owner references, dependent resources, and providing actionable"
        echo "  insights. It helps debug stuck deletions by examining the resource's metadata"
        echo "  and relationships with other resources."
        echo ""
        echo "EXAMPLES:"
        echo "  kubectl-why-not-deleted pod my-pod"
        echo "  kubectl-why-not-deleted deployment my-app -n production"
        echo "  kubectl-why-not-deleted pvc my-volume-claim"
        echo "  kubectl-why-not-deleted namespace my-namespace"
        echo ""
        echo "DEPENDENCIES:"
        echo "  - kubectl: Kubernetes command-line tool"
        echo "  - jq: JSON processor for parsing resource metadata"
        echo ""
        echo "INSTALLATION:"
        echo "  # macOS"
        echo "  brew install jq"
        echo ""
        echo "  # Ubuntu/Debian"
        echo "  sudo apt-get install jq"
        return 0
    end

    # Check if we have the required arguments
    if test (count $argv) -lt 2
        echo "Error: Insufficient arguments provided" >&2
        echo "Usage: kubectl-why-not-deleted RESOURCE NAME [-n NAMESPACE]" >&2
        echo "Use 'kubectl-why-not-deleted --help' for more information" >&2
        return 1
    end

    # Check if kubectl is available
    if not command -q kubectl
        echo "Error: kubectl is not installed or not in PATH" >&2
        echo "Please install kubectl to use this function" >&2
        return 1
    end

    # Check if jq is available
    if not command -q jq
        echo "Error: jq is required but not installed" >&2
        echo "Install with: brew install jq (macOS) or apt-get install jq (Ubuntu)" >&2
        return 1
    end

    set -l resource_type $argv[1]
    set -l resource_name $argv[2]
    set -l namespace_args

    # Parse namespace argument if provided
    set -l i 3
    while test $i -le (count $argv)
        switch $argv[$i]
            case -n --namespace
                if test (math $i + 1) -le (count $argv)
                    set namespace_args -n $argv[(math $i + 1)]
                    set i (math $i + 2)
                else
                    echo "Error: -n/--namespace requires a value" >&2
                    return 1
                end
            case "*"
                set i (math $i + 1)
        end
    end

    echo "🔍 Analyzing why $resource_type/$resource_name is not being deleted..."
    echo ""

    # Get the resource in JSON format
    set -l resource_json (kubectl get $resource_type $resource_name $namespace_args -o json 2>/dev/null)

    if test $status -ne 0
        echo "❌ Error: Could not find $resource_type/$resource_name"
        if test (count $namespace_args) -eq 0
            echo "   Try specifying a namespace with -n <namespace>"
        end
        return 1
    end

    # Check if resource is marked for deletion
    set -l deletion_timestamp (echo $resource_json | jq -r '.metadata.deletionTimestamp // empty')

    if test -z "$deletion_timestamp"
        echo "ℹ️  Resource is NOT marked for deletion"
        echo "   The resource has not received a delete request yet."
        echo "   Use 'kubectl delete $resource_type $resource_name $namespace_args' to delete it."
        return 0
    end

    echo "🗑️  Resource IS marked for deletion (since: $deletion_timestamp)"
    echo ""

    # Check for finalizers
    set -l finalizers (echo $resource_json | jq -r '.metadata.finalizers[]? // empty')

    if test -n "$finalizers"
        echo "🔒 FINALIZERS blocking deletion:"
        for finalizer in $finalizers
            echo "   • $finalizer"
        end
        echo ""
        echo "💡 Finalizers must be processed by their respective controllers before deletion can complete."
        echo "   Common solutions:"
        echo "   - Wait for controllers to process finalizers"
        echo "   - Check controller logs for errors"
        echo "   - As last resort, manually remove finalizers (DANGEROUS):"
        echo "     kubectl patch $resource_type $resource_name $namespace_args --type='merge' -p '{\"metadata\":{\"finalizers\":null}}'"
        echo ""
    else
        echo "✅ No finalizers blocking deletion"
        echo ""
    end

    # Check for owner references
    set -l owner_refs (echo $resource_json | jq -r '.metadata.ownerReferences[]? | "\(.kind)/\(.name)"')

    if test -n "$owner_refs"
        echo "👑 OWNER REFERENCES:"
        for owner in $owner_refs
            echo "   • Owned by: $owner"

            # Check if owner still exists
            set -l owner_kind (echo $owner | cut -d'/' -f1)
            set -l owner_name (echo $owner | cut -d'/' -f2)

            set -l owner_exists (kubectl get $owner_kind $owner_name $namespace_args -o name 2>/dev/null)
            if test -n "$owner_exists"
                set -l owner_deletion (kubectl get $owner_kind $owner_name $namespace_args -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null)
                if test -n "$owner_deletion"
                    echo "     Status: Owner is also marked for deletion ($owner_deletion)"
                else
                    echo "     Status: Owner still exists and is NOT marked for deletion"
                end
            else
                echo "     Status: Owner no longer exists"
            end
        end
        echo ""
        echo "💡 Resources with owner references are typically deleted when their owner is deleted."
        echo ""
    else
        echo "✅ No owner references"
        echo ""
    end

    # Check for dependent resources (resources that this one owns)
    set -l resource_uid (echo $resource_json | jq -r '.metadata.uid')

    if test -n "$resource_uid"
        echo "🔗 Checking for DEPENDENT RESOURCES..."

        # Get all resources in the namespace that might be owned by this resource
        set -l dependents

        # Common resource types that might have owner references
        set -l resource_types pods replicasets deployments services configmaps secrets persistentvolumeclaims

        for rt in $resource_types
            set -l owned_resources (kubectl get $rt $namespace_args -o json 2>/dev/null | jq -r --arg uid "$resource_uid" '.items[]? | select(.metadata.ownerReferences[]?.uid == $uid) | "\(.kind)/\(.metadata.name)"' 2>/dev/null)

            if test -n "$owned_resources"
                for dep in $owned_resources
                    set dependents $dependents $dep
                end
            end
        end

        if test (count $dependents) -gt 0
            echo "   Found dependent resources:"
            for dep in $dependents
                echo "   • $dep"
            end
            echo ""
            echo "💡 These dependent resources should be deleted automatically with cascade deletion."
        else
            echo "   ✅ No dependent resources found"
        end
        echo ""
    end

    # Final summary and recommendations
    echo "📋 SUMMARY:"

    if test -n "$finalizers"
        echo "   🔴 Deletion blocked by finalizers"
        echo "   🎯 Action needed: Wait for controllers to process finalizers or investigate controller issues"
    else if test -n "$owner_refs"
        echo "   🟡 Resource has owner references"
        echo "   🎯 Typically handled automatically when owner is deleted"
    else
        echo "   🟢 No obvious blockers found"
        echo "   🎯 Resource should complete deletion soon"
    end

    echo ""
    echo "🔧 Useful debugging commands:"
    echo "   kubectl describe $resource_type $resource_name $namespace_args"
    echo "   kubectl get events $namespace_args --field-selector involvedObject.name=$resource_name"

    if test -n "$finalizers"
        echo "   kubectl get $resource_type $resource_name $namespace_args -o yaml | grep -A5 finalizers"
    end
end
