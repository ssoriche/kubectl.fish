# Completions for kubectl wrapper (kubectl.fish)
# Template completion for ^template-name syntax after "kubectl get"

# Condition: "get" is a subcommand in the current command line
function __kubectl_has_get
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; and test "$cmd[2]" = get
end

# Complete template names when current token starts with ^
complete -c kubectl -n __kubectl_has_get -a '(commandline -ct | string match -q "^*" && __kubectl_complete_templates | string replace -r "^" "^")' -f
