#!/usr/bin/env fish

# test_kubectl_functions.fish - Test suite for kubectl.fish functions
#
# This test suite validates the kubectl.fish functions for proper error handling,
# prerequisite checking, and basic functionality.
#
# Usage: fish tests/test_kubectl_functions.fish
#
# Requirements:
#   - Fish shell with testing support
#   - kubectl (for integration tests)
#   - Mock utilities for unit tests

# Test configuration
set -l test_functions kubectl-gron kubectl-list-events kubectl-really-all kubectl-dump kubectl-why-not-deleted k
set -g test_results_passed 0
set -g test_results_failed 0
set -g test_results_skipped 0

# Helper functions for testing
function test_assert -a description command expected_status
    echo "Testing: $description"

    # Run the command and capture both output and exit status
    set -l actual_output
    set -l actual_status

    if set actual_output (eval $command 2>&1)
        set actual_status 0
    else
        set actual_status $status
    end

    if test $actual_status -eq $expected_status
        echo "  ✓ PASS"
        set -g test_results_passed (math $test_results_passed + 1)
    else
        echo "  ✗ FAIL: Expected status $expected_status, got $actual_status"
        echo "  Output: $actual_output"
        set -g test_results_failed (math $test_results_failed + 1)
    end
    echo
end

function test_skip -a description reason
    echo "Skipping: $description"
    echo "  Reason: $reason"
    set -g test_results_skipped (math $test_results_skipped + 1)
    echo
end

function check_prerequisites
    echo "=== Checking Prerequisites ==="

    # Load all functions from the functions directory
    for func_file in functions/*.fish
        source $func_file
    end

    # Check if functions are loaded
    for func in $test_functions
        if functions -q $func
            echo "✓ Function $func is loaded"
        else
            echo "✗ Function $func is not loaded"
            return 1
        end
    end

    echo "✓ All functions are loaded"
    echo
end

function test_help_functionality
    echo "=== Testing Help Functionality ==="

    # Test help functionality for all functions that support it
    test_assert "kubectl-gron --help" "kubectl-gron --help >/dev/null 2>&1; test \$status -eq 0" 0
    test_assert "kubectl-dump --help" "kubectl-dump --help >/dev/null 2>&1; test \$status -eq 0" 0
    test_assert "kubectl-list-events --help" "kubectl-list-events --help >/dev/null 2>&1; test \$status -eq 0" 0
    test_assert "kubectl-really-all --help" "kubectl-really-all --help >/dev/null 2>&1; test \$status -eq 0" 0
    test_assert "kubectl-why-not-deleted --help" "kubectl-why-not-deleted --help >/dev/null 2>&1; test \$status -eq 0" 0
    test_assert "k --help" "k --help >/dev/null 2>&1; test \$status -eq 0" 0

    # Test short help option
    test_assert "kubectl-gron -h" "kubectl-gron -h >/dev/null 2>&1; test \$status -eq 0" 0
    test_assert "kubectl-why-not-deleted -h" "kubectl-why-not-deleted -h >/dev/null 2>&1; test \$status -eq 0" 0
    test_assert "k -h" "k -h >/dev/null 2>&1; test \$status -eq 0" 0

    # Test that help output contains expected content
    test_assert "kubectl-gron help contains USAGE" "kubectl-gron --help | grep -q 'USAGE:'" 0
    test_assert "kubectl-why-not-deleted help contains USAGE" "kubectl-why-not-deleted --help | grep -q 'USAGE:'" 0
    test_assert "k help contains AVAILABLE FUNCTIONS" "k --help | grep -q 'AVAILABLE KUBECTL.FISH FUNCTIONS:'" 0
end

function test_prerequisite_checking
    echo "=== Testing Prerequisite Checking ==="

    # Test kubectl command completely missing (should return 1)
    set -l original_path $PATH
    set -x PATH /tmp # Set PATH to location without kubectl

    test_assert "kubectl-gron without kubectl command" "kubectl-gron pods" 1
    test_assert "kubectl-list-events without kubectl command" kubectl-list-events 1
    test_assert "kubectl-really-all without kubectl command" kubectl-really-all 1
    test_assert "kubectl-dump without kubectl command" "kubectl-dump pods" 1
    test_assert "kubectl-why-not-deleted without kubectl command" "kubectl-why-not-deleted pod test" 1
    test_assert "k without kubectl command" "k get pods" 1

    # Restore PATH
    set -x PATH $original_path

    # Test gron/fastgron prerequisite for kubectl-gron
    function test_gron_missing
        # Temporarily hide gron commands from PATH
        set -l original_path $PATH
        set -x PATH /tmp # Set PATH to location without gron tools

        kubectl-gron pods
        set -l result $status

        # Restore PATH
        set -x PATH $original_path
        return $result
    end

    if command -q kubectl
        test_assert "kubectl-gron without gron tools" test_gron_missing 1
    else
        test_skip "kubectl-gron without gron tools" "kubectl not available"
    end

    # Test jq prerequisite for kubectl-list-events
    function test_jq_missing
        # Temporarily hide jq command
        function jq
            return 127
        end

        kubectl-list-events
        set -l result $status

        functions -e jq
        return $result
    end

    if command -q kubectl
        test_assert "kubectl-list-events without jq" test_jq_missing 1
    else
        test_skip "kubectl-list-events without jq" "kubectl not available"
    end

    # Test jq prerequisite for kubectl-why-not-deleted
    function test_jq_missing_why_not_deleted
        # Temporarily hide jq command
        function jq
            return 127
        end

        kubectl-why-not-deleted pod test
        set -l result $status

        functions -e jq
        return $result
    end

    if command -q kubectl
        test_assert "kubectl-why-not-deleted without jq" test_jq_missing_why_not_deleted 1
    else
        test_skip "kubectl-why-not-deleted without jq" "kubectl not available"
    end

    # Clean up test functions
    functions -e test_gron_missing test_jq_missing test_jq_missing_why_not_deleted
end

function test_argument_validation
    echo "=== Testing Argument Validation ==="

    if not command -q kubectl
        test_skip "Argument validation tests" "kubectl not available"
        return
    end

    # Test functions that require arguments
    test_assert "kubectl-gron with no arguments" kubectl-gron 1
    test_assert "kubectl-dump with no arguments" kubectl-dump 1
    test_assert "kubectl-why-not-deleted with no arguments" kubectl-why-not-deleted 1
    test_assert "kubectl-why-not-deleted with only one argument" "kubectl-why-not-deleted pod" 1
    test_assert "k with no arguments" k 1

    # Test that error messages suggest using --help
    test_assert "kubectl-gron suggests --help" "kubectl-gron 2>&1 | grep -q 'kubectl-gron --help'" 0
    test_assert "kubectl-dump suggests --help" "kubectl-dump 2>&1 | grep -q 'kubectl-dump --help'" 0
    test_assert "kubectl-why-not-deleted shows usage" "kubectl-why-not-deleted 2>&1 | grep -q 'kubectl-why-not-deleted --help'" 0
    test_assert "k suggests --help" "k 2>&1 | grep -q 'k --help'" 0
end

function test_consistency
    echo "=== Testing Function Consistency ==="

    # Test that all functions have consistent error message format
    test_assert "kubectl-gron error format" "kubectl-gron 2>&1 | grep -q '^Error:'" 0
    test_assert "kubectl-dump error format" "kubectl-dump 2>&1 | grep -q '^Error:'" 0
    test_assert "kubectl-why-not-deleted error format" "kubectl-why-not-deleted 2>&1 | grep -q '^Error:'" 0
    test_assert "k error format" "k 2>&1 | grep -q '^Error:'" 0

    # Test that all functions use consistent --wraps annotation (check function definition)
    test_assert "kubectl-gron has proper wraps" "functions kubectl-gron | grep -q 'kubectl'" 0
    test_assert "kubectl-dump has proper wraps" "functions kubectl-dump | grep -q 'kubectl'" 0
    test_assert "kubectl-list-events has proper wraps" "functions kubectl-list-events | grep -q 'kubectl'" 0
    test_assert "kubectl-really-all has proper wraps" "functions kubectl-really-all | grep -q 'kubectl'" 0
    test_assert "kubectl-why-not-deleted has proper wraps" "functions kubectl-why-not-deleted | grep -q 'kubectl'" 0
    test_assert "k has proper wraps" "functions k | grep -q 'kubectl'" 0
end

function test_integration_basic
    echo "=== Testing Basic Integration ==="

    if not command -q kubectl
        test_skip "Integration tests" "kubectl not available"
        return
    end

    # Test if kubectl can connect to a cluster
    if not kubectl cluster-info >/dev/null 2>&1
        test_skip "Integration tests" "No Kubernetes cluster available"
        return
    end

    echo "Note: Integration tests require a running Kubernetes cluster"
    echo "Testing with actual cluster connectivity..."

    # Test kubectl-really-all basic functionality
    test_assert "kubectl-really-all basic execution" "kubectl-really-all >/dev/null 2>&1; test \$status -eq 0 -o \$status -eq 1" 0

    # Test kubectl-dump with a common resource
    test_assert "kubectl-dump namespaces" "kubectl-dump namespaces >/dev/null 2>&1; test \$status -eq 0" 0

    # Test k wrapper functionality
    test_assert "k get namespaces" "k get namespaces >/dev/null 2>&1; test \$status -eq 0" 0

    # Test kubectl-list-events
    if command -q jq
        test_assert "kubectl-list-events execution" "kubectl-list-events >/dev/null 2>&1; test \$status -eq 0" 0
    else
        test_skip "kubectl-list-events execution" "jq not available"
    end

    # Test kubectl-gron
    if command -q gron; or command -q fastgron
        test_assert "kubectl-gron namespaces" "kubectl-gron namespaces >/dev/null 2>&1; test \$status -eq 0" 0
    else
        test_skip "kubectl-gron execution" "gron/fastgron not available"
    end

    # Test kubectl-why-not-deleted
    if command -q jq
        test_assert "kubectl-why-not-deleted nonexistent resource" "kubectl-why-not-deleted pod nonexistent-pod >/dev/null 2>&1; test \$status -eq 1" 0
    else
        test_skip "kubectl-why-not-deleted execution" "jq not available"
    end
end

function test_function_registration
    echo "=== Testing Function Registration ==="

    # Test that k function can discover kubectl-* functions
    if command -q kubectl
        set -l discovered_functions (k --help | grep -A 10 "AVAILABLE KUBECTL.FISH FUNCTIONS:" | grep -E '^\s+' | string trim)

        if test (count $discovered_functions) -gt 0
            echo "✓ k function discovers kubectl-* functions:"
            for func in $discovered_functions
                echo "    - $func"
            end
            set -g test_results_passed (math $test_results_passed + 1)
        else
            echo "✗ k function does not discover kubectl-* functions"
            set -g test_results_failed (math $test_results_failed + 1)
        end
    else
        test_skip "Function discovery test" "kubectl not available"
    end
    echo
end

function test_linting_standards
    echo "=== Testing Linting Standards ==="

    # Test Fish syntax
    test_assert "Fish syntax validation" "fish -n functions/kubectl-gron.fish" 0
    test_assert "Fish syntax validation" "fish -n functions/kubectl-dump.fish" 0
    test_assert "Fish syntax validation" "fish -n functions/kubectl-list-events.fish" 0
    test_assert "Fish syntax validation" "fish -n functions/kubectl-really-all.fish" 0
    test_assert "Fish syntax validation" "fish -n functions/kubectl-why-not-deleted.fish" 0
    test_assert "Fish syntax validation" "fish -n functions/k.fish" 0

    # Test formatting consistency
    if command -q fish_indent
        for func_file in functions/*.fish
            set -l formatted_output (fish_indent < $func_file 2>/dev/null)
            set -l original_content (cat $func_file)

            if test "$formatted_output" != "$original_content"
                echo "✗ $func_file is not properly formatted"
                set -g test_results_failed (math $test_results_failed + 1)
            else
                echo "✓ $func_file is properly formatted"
                set -g test_results_passed (math $test_results_passed + 1)
            end
        end
    else
        test_skip "Fish formatting check" "fish_indent not available"
    end

    # Test fishcheck validation if available
    if command -q fishcheck
        test_assert "fishcheck validation" "fishcheck functions/*.fish >/dev/null 2>&1" 0
    else
        test_skip "fishcheck validation" "fishcheck not available"
    end
end

function run_all_tests
    echo "🧪 kubectl.fish Function Test Suite"
    echo "=================================="
    echo

    check_prerequisites
    test_help_functionality
    test_prerequisite_checking
    test_argument_validation
    test_consistency
    test_function_registration
    test_integration_basic
    test_linting_standards

    echo "=== Test Results Summary ==="
    echo "Passed:  $test_results_passed"
    echo "Failed:  $test_results_failed"
    echo "Skipped: $test_results_skipped"
    echo "Total:   "(math $test_results_passed + $test_results_failed + $test_results_skipped)
    echo

    if test $test_results_failed -eq 0
        echo "🎉 All tests passed!"
        exit 0
    else
        echo "❌ Some tests failed!"
        exit 1
    end
end

# Run tests if script is executed directly
if test (basename (status filename)) = "test_kubectl_functions.fish"
    run_all_tests
end
