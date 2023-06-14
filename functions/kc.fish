function kc -d "function to access fish kubectl functions" --wraps kubectl
    set -f kc_func "kubectl-$argv[1]"
    if command -s kc &>/dev/null
        set -f kc_cmd (command -v kc) &>/dev/null
    else if command -s kubecolor &>/dev/null
        set -f kc_cmd (command -v kubecolor) &>/dev/null
    else
        set -f kc_cmd (command -v kubectl) &>/dev/null
    end
    if functions -d -- $kc_func &>/dev/null
        $kc_func $argv[2..-1]
    else
        $kc_cmd $argv
    end
end
