# Completions for k (smart kubectl wrapper)
# Template completion for ^template-name syntax after "k get"

# Condition: "get" is a subcommand in the current command line
function __kubectl_k_has_get
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; and test "$cmd[2]" = get
end

# Complete template names when current token starts with ^
complete -c k -n __kubectl_k_has_get -a '(commandline -ct | string match -q "^*" && __kubectl_complete_templates)' -f
