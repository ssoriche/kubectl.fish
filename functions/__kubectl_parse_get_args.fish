#!/usr/bin/env fish

# __kubectl_parse_get_args - Parse kubectl get arguments for enhanced syntax
#
# DESCRIPTION:
#     Internal helper function to parse kubectl get arguments and detect
#     enhanced syntax for templates (^template-name) and jq expressions (.field).
#     Returns structured data for kubectl-get to process.
#
# USAGE:
#     __kubectl_parse_get_args ARGS...
#
# DETECTS:
#     - ^template-name: Template syntax for custom-columns
#     - .field: jq expression syntax (excluding ./paths)
#     - All other kubectl flags (preserved)
#
# OUTPUT FORMAT:
#     Lines with key:value pairs:
#         template:TEMPLATE_NAME
#         jq:JQ_EXPRESSION
#         args:REMAINING_ARGS
#
# EXAMPLES:
#     # Parse template syntax
#     __kubectl_parse_get_args pods ^pods-wide -n default
#     # Output:
#     # template:pods-wide
#     # jq:
#     # args:pods -n default
#
#     # Parse jq expression
#     __kubectl_parse_get_args pods .items[0].metadata.name
#     # Output:
#     # template:
#     # jq:.items[0].metadata.name
#     # args:pods
#
# AUTHOR:
#     kubectl.fish collection

function __kubectl_parse_get_args -d "Parse kubectl get arguments for enhanced syntax"
    set -l template_name ""
    set -l jq_expr ""
    set -l kubectl_args

    # Parse argv looking for special syntax
    for arg in $argv
        if string match -q '^*' -- $arg
            # Template syntax: ^template-name
            set template_name (string sub -s 2 -- $arg)
        else if string match -q '.*' -- $arg
            # jq syntax: .field (but not ./path or ../path)
            if not string match -q './*' -- $arg
                set jq_expr $arg
            else
                # It's a relative path, not jq syntax
                set kubectl_args $kubectl_args $arg
            end
        else
            # Regular kubectl argument
            set kubectl_args $kubectl_args $arg
        end
    end

    # Output as structured data
    echo "template:$template_name"
    echo "jq:$jq_expr"
    echo "args:"(string join " " -- $kubectl_args)
end
