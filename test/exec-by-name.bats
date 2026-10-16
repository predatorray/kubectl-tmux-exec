#!/usr/bin/env bats

# Tests for the NAME argument (a pod name or TYPE/NAME) that do not require a real Kubernetes cluster.
setup() {
    TEST_TMP_DIR="$(mktemp -d)"
    PATH_ORIG="$PATH"
    export PATH="$TEST_TMP_DIR:$PATH"
    export KUBECTL_ARGS_LOG="${TEST_TMP_DIR}/kubectl.args"

    # Mock kubectl: emulate a pod "web-0", a deployment "nginx" and a service "headless" without any selector.
    cat > "$TEST_TMP_DIR/kubectl" <<'MOCK'
#!/usr/bin/env bash
echo "$*" >> "${KUBECTL_ARGS_LOG}"

all_namespaces=0
namespace='default'
name=''
selector=''
args=("$@")
for (( i = 0; i < ${#args[@]}; i++ )); do
    case "${args[$i]}" in
        -A) all_namespaces=1 ;;
        -n) namespace="${args[$((i + 1))]:-default}" ;;
        -l) selector="${args[$((i + 1))]}" ;;
        metadata.name=*) name="${args[$i]#metadata.name=}" ;;
    esac
done

case "$*" in
    'get pods '*)
        if [[ "${selector}" == 'app=nginx,env in (a,b)' ]]; then
            printf 'nginx-1 %s\nnginx-2 %s\n' "${namespace}" "${namespace}"
        fi
        ;;
    'get pod '*|'get po '*)
        if [[ "${name}" == 'web-0' ]]; then
            printf 'Pod\tweb-0\tdefault\t\n'
        fi
        ;;
    'get deploy '*)
        if [[ "${name}" == 'nginx' ]]; then
            printf 'Deployment\tnginx\t%s\tapp=nginx,env in (a,b),\n' "${namespace}"
            if [[ "${all_namespaces}" -eq 1 ]]; then
                printf 'Deployment\tnginx\tother\tapp=nginx,env in (a,b),\n'
            fi
        fi
        ;;
    'get svc '*)
        if [[ "${name}" == 'headless' ]]; then
            printf 'Service\theadless\tdefault\t\n'
        fi
        ;;
esac
exit 0
MOCK
    chmod +x "$TEST_TMP_DIR/kubectl"

    cat > "$TEST_TMP_DIR/tmux" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
    chmod +x "$TEST_TMP_DIR/tmux"
}

teardown() {
    export PATH="$PATH_ORIG"
    rm -rf "$TEST_TMP_DIR"
}

@test "Exec by name: a plain name is a pod" {
    run bin/kubectl-tmux_exec --dry-run web-0 bash
    [ "$status" -eq 0 ]
    [[ "$output" == *" exec -i -t web-0 -- bash"* ]]
    grep -q '^get pod .*--field-selector metadata.name=web-0' "${KUBECTL_ARGS_LOG}"
}

@test "Exec by name: po/NAME is a pod" {
    run bin/kubectl-tmux_exec --dry-run po/web-0 -- bash
    [ "$status" -eq 0 ]
    [[ "$output" == *" exec -i -t web-0 -- bash"* ]]
}

@test "Exec by name: all the running pods of a deployment" {
    run bin/kubectl-tmux_exec --dry-run deploy/nginx -c nginx -- bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"-n default exec -i -t -c nginx nginx-1 -- bash"* ]]
    [[ "$output" == *"-n default exec -i -t -c nginx nginx-2 -- bash"* ]]
    grep -q -- '--field-selector status.phase=Running' "${KUBECTL_ARGS_LOG}"
}

@test "Exec by name: the deployments under all namespaces" {
    run bin/kubectl-tmux_exec --dry-run -A deploy/nginx bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"-n default exec -i -t nginx-1 -- bash"* ]]
    [[ "$output" == *"-n other exec -i -t nginx-2 -- bash"* ]]
    grep -q '^get deploy .*-A --field-selector metadata.name=nginx' "${KUBECTL_ARGS_LOG}"
}

@test "Exec by name: the deployments under multiple namespaces" {
    run bin/kubectl-tmux_exec --dry-run -n ns1 -n ns2 deploy/nginx bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"-n ns1 exec -i -t nginx-1 -- bash"* ]]
    [[ "$output" == *"-n ns2 exec -i -t nginx-2 -- bash"* ]]
}

@test "Exec by name: a resource without any selector" {
    run bin/kubectl-tmux_exec --dry-run svc/headless bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"warn: svc/headless in the namespace default does not have a selector."* ]]
    [[ "$output" == *"No pods found."* ]]
}

@test "Exec by name: resource not found" {
    run bin/kubectl-tmux_exec --dry-run deploy/missing bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"No pods found."* ]]
}

@test "Exec by name: invalid resource name" {
    run bin/kubectl-tmux_exec --dry-run deploy/ bash
    [ "$status" -ne 0 ]
    [[ "$output" == *"error: invalid resource name: deploy/"* ]]
}

@test "Exec by name: the name and -l are mutually exclusive" {
    run bin/kubectl-tmux_exec --dry-run deploy/nginx -l app=nginx bash
    [ "$status" -ne 0 ]
    [[ "$output" == *"error: you must specify exactly one of option -l, option -f, or a NAME"* ]]
}

@test "Exec by name: the first non-option argument is the command when -l is specified" {
    run bin/kubectl-tmux_exec --dry-run -l 'app=nginx,env in (a,b)' bash
    [ "$status" -eq 0 ]
    [[ "$output" == *" exec -i -t nginx-1 -- bash"* ]]
}

@test "Exec by name: no command" {
    run bin/kubectl-tmux_exec --dry-run deploy/nginx
    [ "$status" -ne 0 ]
    [[ "$output" == *"error: you must specify at least one command for the container"* ]]
}
