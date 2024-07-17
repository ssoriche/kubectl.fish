#!/usr/bin/env fish

function kubectl-really-all
    set resources (kubectl api-resources --output name --namespaced --verbs list | string join ',' | string trim -r -c ',')
    kubectl get $resources --ignore-not-found $argv
end
