# Completions for kubectl-get (enhanced kubectl get)
# Template completion for ^template-name syntax

# Complete template names when current token starts with ^
complete -c kubectl-get -a '(commandline -ct | string match -q "^*" && __kubectl_complete_templates | string replace -r "^" "^")' -f
