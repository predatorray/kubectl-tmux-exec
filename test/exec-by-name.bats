#!/usr/bin/env bats

# Tests for the NAME argument (a pod name or TYPE/NAME) that do not require a real Kubernetes cluster.
setup() {
    TEST_TMP_DIR="$(mktemp -d)"
    PATH_ORIG="$PATH"
    export PATH="$TEST_TMP_DIR:$PATH"
    export KUBECTL_ARGS_LOG="${TEST_TMP_DIR}/kubectl.args"

    # Mock kubectl, in every namespace:
    #   - a pod "web-0";
    #   - a deployment "nginx" (selector: app=nginx,env in (a,b)), which controls the replicaset "nginx-new", which
    #     controls the pods "nginx-1" and "nginx-2". The orphaned replicaset "nginx-old" controls the pod "nginx-old-1",
    #     the pod "imposter" is controlled by something else and the pod "bare" is not controlled at all, all of which
    #     share the same labels;
    #   - a statefulset "db" (selector: app=db), which controls the pod "db-0" but not the pod "db-imposter";
    #   - a service "nginx" with the same selector as the deployment, and a service "headless" without a selector;
    #   - a configmap "conf".
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

function resource() {
    local api_version="$1" kind="$2" sel="$3"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${api_version}" "${kind}" "${name}" "${namespace}" "uid-${kind}-${name}-${namespace}" "${sel}"
    if [[ "${all_namespaces}" -eq 1 ]]; then
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${api_version}" "${kind}" "${name}" 'other' "uid-${kind}-${name}-other" "${sel}"
    fi
}

ns="${namespace}"
output="$(case "$*" in
    'get pods '*'custom-columns'*)
        if [[ "${selector}" == 'app=nginx,env in (a,b)' ]]; then
            printf '%s %s\n' nginx-1 "${ns}" nginx-2 "${ns}" nginx-old-1 "${ns}" imposter "${ns}" bare "${ns}"
        fi
        ;;
    'get pods '*'go-template'*)
        if [[ "${selector}" == 'app=nginx,env in (a,b)' ]]; then
            echo "nginx-1 ${ns} uid-p1 uid-rs-nginx-new-${ns}"
            echo "nginx-2 ${ns} uid-p2 uid-rs-nginx-new-${ns}"
            echo "nginx-old-1 ${ns} uid-p3 uid-rs-nginx-old-${ns}"
            echo "imposter ${ns} uid-p4 uid-something-else"
            echo "bare ${ns} uid-p5"
        elif [[ "${selector}" == 'app=db' ]]; then
            echo "db-0 ${ns} uid-p6 uid-StatefulSet-db-${ns}"
            echo "db-imposter ${ns} uid-p7 uid-something-else"
        fi
        ;;
    'get replicasets '*)
        if [[ "${selector}" == 'app=nginx,env in (a,b)' ]]; then
            echo "nginx-new ${ns} uid-rs-nginx-new-${ns} uid-Deployment-nginx-${ns}"
            echo "nginx-old ${ns} uid-rs-nginx-old-${ns}"
        fi
        ;;
    'get pod '*|'get po '*)
        [[ "${name}" == 'web-0' ]] && resource v1 Pod ''
        ;;
    'get deploy '*)
        [[ "${name}" == 'nginx' ]] && resource apps/v1 Deployment 'app=nginx,env in (a,b),'
        ;;
    'get sts '*)
        [[ "${name}" == 'db' ]] && resource apps/v1 StatefulSet 'app=db,'
        ;;
    'get svc '*)
        [[ "${name}" == 'nginx' ]] && resource v1 Service 'app=nginx,env in (a,b),'
        [[ "${name}" == 'headless' ]] && resource v1 Service ''
        ;;
    'get cm '*)
        [[ "${name}" == 'conf' ]] && resource v1 ConfigMap ''
        ;;
    'get Abc '*)
        echo 'unknown'
        ;;
esac)"

# the same as the real kubectl
if [[ "${output}" == 'unknown' ]]; then
    echo >&2 "error: the server doesn't have a resource type \"${args[1]}\""
    exit 1
elif [[ -z "${output}" ]]; then
    echo >&2 "No resources found in ${namespace} namespace."
else
    echo "${output}"
fi
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

@test "Exec by name: only the pods controlled by a deployment" {
    run bin/kubectl-tmux_exec --dry-run deploy/nginx -c nginx -- bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"-n default exec -i -t -c nginx nginx-1 -- bash"* ]]
    [[ "$output" == *"-n default exec -i -t -c nginx nginx-2 -- bash"* ]]
    [[ "$output" != *"nginx-old-1"* ]]
    [[ "$output" != *"imposter"* ]]
    [[ "$output" != *"bare"* ]]
    # not filtered by the pod phase, the same as -l
    run grep -q -- 'status.phase' "${KUBECTL_ARGS_LOG}"
    [ "$status" -eq 1 ]
}

@test "Exec by name: only the pods controlled by a statefulset" {
    run bin/kubectl-tmux_exec --dry-run sts/db bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"-n default exec -i -t db-0 -- bash"* ]]
    [[ "$output" != *"db-imposter"* ]]
}

@test "Exec by name: all the pods that match the selector of a service" {
    run bin/kubectl-tmux_exec --dry-run svc/nginx bash
    [ "$status" -eq 0 ]
    for pod in nginx-1 nginx-2 nginx-old-1 imposter bare; do
        [[ "$output" == *" exec -i -t ${pod} -- bash"* ]]
    done
}

@test "Exec by name: the deployments under all namespaces" {
    run bin/kubectl-tmux_exec --dry-run -A deploy/nginx bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"-n default exec -i -t nginx-1 -- bash"* ]]
    [[ "$output" == *"-n other exec -i -t nginx-1 -- bash"* ]]
    [[ "$output" != *"imposter"* ]]
    grep -q '^get deploy .*-A --field-selector metadata.name=nginx' "${KUBECTL_ARGS_LOG}"
}

@test "Exec by name: the deployments under multiple namespaces" {
    run bin/kubectl-tmux_exec --dry-run -n ns1 -n ns2 deploy/nginx bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"-n ns1 exec -i -t nginx-1 -- bash"* ]]
    [[ "$output" == *"-n ns2 exec -i -t nginx-2 -- bash"* ]]
}

@test "Exec by name: a service without any selector" {
    run bin/kubectl-tmux_exec --dry-run svc/headless bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"warn: invalid service 'headless' in the namespace default: Service is defined without a selector"* ]]
    [[ "$output" == *"No pods found."* ]]
}

@test "Exec by name: an unsupported resource" {
    run bin/kubectl-tmux_exec --dry-run cm/conf bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"warn: cannot exec into cm/conf in the namespace default: selector for ConfigMap (v1) not implemented"* ]]
    [[ "$output" == *"No pods found."* ]]
}

@test "Exec by name: resource not found" {
    run bin/kubectl-tmux_exec --dry-run deploy/missing bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"warn: deploy/missing not found"$'\n'* ]]
    [[ "$output" != *"No resources found"* ]]
    [[ "$output" == *"No pods found."* ]]
}

@test "Exec by name: resource not found in the namespaces of the contexts" {
    run bin/kubectl-tmux_exec --dry-run -n ns1 --context c1 deploy/missing bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"warn: deploy/missing not found in the namespace ns1 of the context c1"* ]]

    run bin/kubectl-tmux_exec --dry-run -A deploy/missing bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"warn: deploy/missing not found in any namespace"* ]]
}

@test "Exec by name: unknown resource type" {
    run bin/kubectl-tmux_exec --dry-run Abc/foobar bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"error: the server doesn't have a resource type \"Abc\""* ]]
    [[ "$output" != *"not found"* ]]
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
