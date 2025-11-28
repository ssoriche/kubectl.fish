#!/usr/bin/env fish

# __kubectl_find_template - Locate kubectl custom-columns template files
#
# DESCRIPTION:
#     Internal helper function to locate template files for kubectl-get.
#     Searches configured template directories for .tmpl or .template files.
#
# USAGE:
#     __kubectl_find_template TEMPLATE_NAME
#
# SEARCH ORDER:
#     1. $KUBECTL_TEMPLATES_DIR (if set)
#     2. ~/.kube/templates/
#
# RETURNS:
#     Full path to template file, or empty string if not found
#
# EXAMPLES:
#     # Find pods-wide template
#     set template_path (__kubectl_find_template pods-wide)
#
#     # Check if template exists
#     if set template_path (__kubectl_find_template my-template)
#         echo "Found template at: $template_path"
#     end
#
# AUTHOR:
#     kubectl.fish collection

function __kubectl_find_template -a template_name -d "Locate kubectl custom-columns template files"
    # Validate template name provided
    if test -z "$template_name"
        return 1
    end

    # Build search paths
    set -l search_paths

    # Priority 1: User-specified directory via environment variable
    if set -q KUBECTL_TEMPLATES_DIR
        set search_paths $KUBECTL_TEMPLATES_DIR
    else
        # Priority 2: Standard kubectl location
        set search_paths ~/.kube/templates
    end

    # Expand home directory in paths
    set search_paths (string replace '~' $HOME -- $search_paths)

    # Try multiple extensions
    set -l extensions tmpl template

    # Search for template file
    for dir in $search_paths
        # Skip if directory doesn't exist
        if not test -d $dir
            continue
        end

        for ext in $extensions
            set -l template_path "$dir/$template_name.$ext"
            if test -f $template_path
                echo $template_path
                return 0
            end
        end
    end

    # Template not found
    return 1
end
