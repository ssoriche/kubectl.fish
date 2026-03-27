#!/usr/bin/env fish

# __kubectl_complete_templates - List available kubectl template names for completion
#
# DESCRIPTION:
#     Internal helper function for Fish tab completion. Lists available
#     template names from the configured templates directory, stripping
#     file extensions. Used by completion files for k and kubectl-get.
#
# USAGE:
#     __kubectl_complete_templates
#
# SEARCH ORDER:
#     1. $KUBECTL_TEMPLATES_DIR (if set)
#     2. ~/.kube/templates/
#
# RETURNS:
#     One template name per line (without .tmpl/.template extension)
#
# EXAMPLES:
#     # List all templates
#     __kubectl_complete_templates
#     # Output:
#     # pods-wide
#     # nodes
#     # images
#
# AUTHOR:
#     kubectl.fish collection

function __kubectl_complete_templates -d "List available kubectl template names for completion"
    # Determine template directory (same logic as __kubectl_find_template)
    set -l search_dir
    if set -q KUBECTL_TEMPLATES_DIR
        set search_dir $KUBECTL_TEMPLATES_DIR
    else
        set search_dir ~/.kube/templates
    end

    # Expand home directory
    set search_dir (string replace '~' $HOME -- $search_dir)

    # Skip if directory doesn't exist
    if not test -d $search_dir
        return 0
    end

    # List template files and strip extensions
    for file in $search_dir/*.tmpl $search_dir/*.template
        if test -f $file
            basename $file | string replace -r '\.(tmpl|template)$' ''
        end
    end
end
