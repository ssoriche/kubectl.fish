function kubectl -d "Smart kubectl wrapper with plugin support"
    # Handle help option only when no other args (so `kubectl --help` still
    # passes through to real kubectl). Use a sentinel: if --help/-h is the
    # ONLY argument, treat as our wrapper help; otherwise forward.
    if test (count $argv) -eq 1; and begin
            test "$argv[1]" = --help; or test "$argv[1]" = -h
        end
        echo "kubectl - Smart kubectl wrapper with plugin support"
        echo ""
        echo "USAGE:"
        echo "  kubectl [subcommand|kubectl-function-name] [args...]"
        echo "  k       [subcommand|kubectl-function-name] [args...]   # abbreviation"
        echo ""
        echo "BEHAVIOR:"
        echo "  1. If first arg matches a kubectl-* fish function, run that function."
        echo "  2. If 'get' is used with ^template or .jq syntax, route to kubectl-get."
        echo "  3. Otherwise, run the real kubectl binary."
        echo ""
        echo "EXAMPLES:"
        echo "  kubectl get pods                    # Standard kubectl"
        echo "  kubectl get pods ^pods-wide         # Enhanced get with template"
        echo "  kubectl get pods .items[0].metadata.name  # Enhanced get with jq"
        echo "  kubectl gron pods                   # kubectl-gron function"
        echo "  kubectl list-events                 # kubectl-list-events function"
        echo ""
        echo "ENHANCED GET SYNTAX:"
        echo "  ^template-name                # Use custom-columns template"
        echo "  .field                        # Extract JSON field with jq"
        echo "  (See 'kubectl-get --help' for details.)"
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
        echo "For real kubectl help, run: command kubectl --help"
        return 0
    end

    # No-args: defer to real kubectl (it prints its own usage)
    if test (count $argv) -eq 0
        command kubectl
        return $status
    end

    # 1. Check if first argument corresponds to a kubectl-* function
    set -l k_func "kubectl-$argv[1]"
    if functions -q $k_func
        $k_func $argv[2..-1]
        return $status
    end

    # 2. Detect enhanced get syntax
    if test "$argv[1]" = get
        set -l has_enhanced 0
        for arg in $argv[2..-1]
            if string match -q '^*' -- $arg
                set has_enhanced 1
                break
            else if string match -q '.*' -- $arg
                if not string match -q './*' -- $arg
                    set has_enhanced 1
                    break
                end
            end
        end
        if test $has_enhanced -eq 1
            kubectl-get $argv[2..-1]
            return $status
        end
    end

    # 3. Fall through to real kubectl
    command kubectl $argv
    return $status
end
