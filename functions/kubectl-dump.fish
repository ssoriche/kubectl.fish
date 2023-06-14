#!/usr/bin/env fish

function kubectl-dump -d "dump kubernetes resources as yaml" --wraps 'kubectl get'
    kubectl get $argv -o yaml
end
