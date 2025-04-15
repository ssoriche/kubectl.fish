function k -d "function to access fish kubectl functions" --wraps kubectl
    set -f k_func "kubectl-$argv[1]"
    if command -s kubecolor &>/dev/null
        set -f k_cmd (command -v kubecolor) &>/dev/null
    else
        set -f k_cmd (command -v kubectl) &>/dev/null
    end
    if functions -d -- $k_func &>/dev/null
        $k_func $argv[2..-1]
    else
        $k_cmd $argv
    end
end
