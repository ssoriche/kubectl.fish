#!/usr/bin/env fish

# kt - Switch kubectl configuration files
#
# DESCRIPTION:
#     Manage Kubernetes configuration files by quickly switching between
#     different kubeconfig files. When called without arguments, lists all
#     available configurations. When called with a filename, sets the
#     KUBECONFIG environment variable to that file.
#
# USAGE:
#     kt                      # List available configs
#     kt CONFIG               # Switch to CONFIG
#     kt /path/to/config      # Use absolute path
#
# SEARCH PATHS:
#     - ~/.kube/configs/
#     - ~/.ssh/kubeconfigs/
#
# EXAMPLES:
#     kt                      # Show all configs (* marks current)
#     kt production           # Switch to production config
#     kt ~/.kube/dev          # Use absolute path
#     kt staging              # Switch to staging config
#
# AUTHOR:
#     Original: kt.fish repository (ssoriche/kt.fish)
#     Enhanced for kubectl.fish collection

function kt -d "Switch kubectl configuration files"
    # Handle help option
    if contains -- --help $argv; or contains -- -h $argv
        echo "kt - Switch kubectl configuration files"
        echo ""
        echo "USAGE:"
        echo "  kt                      # List available configs"
        echo "  kt CONFIG               # Switch to CONFIG"
        echo "  kt /path/to/config      # Use absolute path"
        echo ""
        echo "DESCRIPTION:"
        echo "  Manage Kubernetes configuration files by quickly switching between"
        echo "  different kubeconfig files. When called without arguments, lists all"
        echo "  available configurations. When called with a filename, sets the"
        echo "  KUBECONFIG environment variable to that file."
        echo ""
        echo "SEARCH PATHS:"
        echo "  - ~/.kube/configs/"
        echo "  - ~/.ssh/kubeconfigs/"
        echo ""
        echo "EXAMPLES:"
        echo "  kt                      # Show all configs (* marks current)"
        echo "  kt production           # Switch to production config"
        echo "  kt ~/.kube/dev          # Use absolute path"
        echo "  kt staging              # Switch to staging config"
        return 0
    end

    set -l file $argv[1]

    # List mode: show all available configs
    if test -z "$file"
        for dir in ~/.kube/configs ~/.ssh/kubeconfigs
            if not test -d $dir
                continue
            end

            for cand in (ls $dir 2>/dev/null)
                if test -n "$KUBECONFIG"; and test "$KUBECONFIG" = "$dir/$cand"
                    echo "* $cand"
                else
                    echo "  $cand"
                end
            end
        end
        return 0
    end

    # Switch mode: set KUBECONFIG to specified file

    # Check if file is an absolute path
    if test -f "$file"
        set -gx KUBECONFIG $file
        echo "Switched to: $file"
        return 0
    end

    # Search in standard directories
    for dir in ~/.kube/configs ~/.ssh/kubeconfigs
        if test -f "$dir/$file"
            set -gx KUBECONFIG "$dir/$file"
            echo "Switched to: $dir/$file"
            return 0
        end
    end

    # File not found
    echo "Error: Cannot find kubeconfig '$file'" >&2
    echo "Search paths:" >&2
    echo "  - ~/.kube/configs/" >&2
    echo "  - ~/.ssh/kubeconfigs/" >&2
    echo "Use 'kt' to list available configs or 'kt --help' for more information" >&2
    return 1
end
