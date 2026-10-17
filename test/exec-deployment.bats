#!/usr/bin/env bats

load test-helper

deploy_name=
ns=

# Creates a deployment of 2 replicas with the selector given as YAML.
function create_deployment() {
    local name="$1"
    local selector="$2"
    local labels="$3"
    kubectl apply -n "${ns}" -f - << EOT
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${name}
spec:
  replicas: 2
  selector:
${selector}
  template:
    metadata:
      labels:
${labels}
    spec:
      containers:
      - name: alpine
        image: alpine
        command:
        - sleep
        - infinite
EOT
    kubectl rollout status -n "${ns}" "deploy/${name}" --timeout=120s
}

function setup() {
    ns="$(create_namespace)"
    deploy_name="alpine-$(random_lowercase_string 8)"
    create_deployment "${deploy_name}" "\
    matchLabels:
      app: ${deploy_name}
    matchExpressions:
    - key: tier
      operator: In
      values:
      - backend" "\
        app: ${deploy_name}
        tier: backend"

    # The pods of this deployment also match the selector of the one above, but are not controlled by it.
    create_deployment "${deploy_name}-other" "\
    matchLabels:
      app: ${deploy_name}
      variant: other" "\
        app: ${deploy_name}
        tier: backend
        variant: other"

    # A service selects the pods of both the deployments.
    kubectl apply -n "${ns}" -f - << EOT
apiVersion: v1
kind: Service
metadata:
  name: ${deploy_name}
spec:
  selector:
    app: ${deploy_name}
    tier: backend
  ports:
  - port: 80
EOT
}

function teardown() {
    if [[ -n "${ns}" ]]; then
        delete_namespace "${ns}"
    fi
    tmux kill-server || true
}

@test "Exec all pods of a deployment by deploy/NAME" {
    local written="data-$(random_lowercase_string 8)"

    bin/kubectl-tmux_exec -d -n "${ns}" "deploy/${deploy_name}" -- sh -c "echo ${written} > /tmp/foobar"

    wait_until_no_sessions

    local pods=()
    while read -r pod; do
        pods+=("${pod}")
    done < <(kubectl get pods -n "${ns}" -l "app=${deploy_name},variant!=other" -o custom-columns=':metadata.name' --no-headers)
    [ "${#pods[@]}" -eq 2 ]

    for pod in "${pods[@]}"; do
        local file_content
        file_content="$(kubectl exec -n "${ns}" "${pod}" -- cat /tmp/foobar)"
        [ "${file_content}" == "${written}" ]
    done

    local other_pods=()
    while read -r pod; do
        other_pods+=("${pod}")
    done < <(kubectl get pods -n "${ns}" -l "app=${deploy_name},variant=other" -o custom-columns=':metadata.name' --no-headers)
    [ "${#other_pods[@]}" -eq 2 ]

    for pod in "${other_pods[@]}"; do
        run kubectl exec -n "${ns}" "${pod}" -- cat /tmp/foobar
        [ "$status" -ne 0 ]
    done
}

@test "Exec all pods that match the selector of a service by svc/NAME" {
    local written="data-$(random_lowercase_string 8)"

    bin/kubectl-tmux_exec -d -n "${ns}" "svc/${deploy_name}" -- sh -c "echo ${written} > /tmp/foobar"

    wait_until_no_sessions

    local pods=()
    while read -r pod; do
        pods+=("${pod}")
    done < <(kubectl get pods -n "${ns}" -l "app=${deploy_name}" -o custom-columns=':metadata.name' --no-headers)
    [ "${#pods[@]}" -eq 4 ]

    for pod in "${pods[@]}"; do
        local file_content
        file_content="$(kubectl exec -n "${ns}" "${pod}" -- cat /tmp/foobar)"
        [ "${file_content}" == "${written}" ]
    done
}

@test "Exec by an unknown resource type" {
    run bin/kubectl-tmux_exec -d -n "${ns}" Abc/foobar -- true
    [ "$status" -eq 0 ]
    [[ "$output" == *"error: the server doesn't have a resource type \"Abc\""* ]]
    [[ "$output" == *"No pods found."* ]]
}

@test "Exec by a resource that does not exist" {
    run bin/kubectl-tmux_exec -d -n "${ns}" deploy/missing -- true
    [ "$status" -eq 0 ]
    [[ "$output" == *"warn: deploy/missing not found in the namespace ${ns}"* ]]
    [[ "$output" != *"No resources found"* ]]
    [[ "$output" == *"No pods found."* ]]
}

@test "Exec by a resource that is not supported" {
    kubectl create configmap -n "${ns}" "${deploy_name}"

    run bin/kubectl-tmux_exec -d -n "${ns}" "cm/${deploy_name}" -- true
    [ "$status" -eq 0 ]
    [[ "$output" == *"selector for ConfigMap (v1) not implemented"* ]]
    [[ "$output" == *"No pods found."* ]]
}
