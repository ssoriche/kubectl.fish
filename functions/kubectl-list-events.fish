#!/usr/bin/env fish

function kubectl-list-events -d "view kubernetes events by timestamp" --wraps kubectl
    begin
        echo -e "TIME\tNAMESPACE\tTYPE\tREASON\tOBJECT\tSOURCE\tMESSAGE"
        kubectl get events -o json $argv \
            | jq -r '.items | map(. + {t: (.eventTime//.lastTimestamp)}) | sort_by(.t)[] | [.t, .metadata.namespace, .type, .reason, .involvedObject.kind + "/" + .involvedObject.name, .source.component + "," + (.source.host//"-"), .message] | @tsv'
    end | column -t -s "$(printf '\t')" | less -S
end
