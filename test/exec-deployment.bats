#!/usr/bin/env bats

load test-helper

deploy_name=
ns=

function setup() {
    ns="$(create_namespace)"
    deploy_name="alpine-$(random_lowercase_string 8)"
    kubectl apply -n "${ns}" -f - << EOT
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${deploy_name}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${deploy_name}
    matchExpressions:
    - key: tier
      operator: In
      values:
      - backend
  template:
    metadata:
      labels:
        app: ${deploy_name}
        tier: backend
    spec:
      containers:
      - name: alpine
        image: alpine
        command:
        - sleep
        - infinite
EOT
    kubectl rollout status -n "${ns}" "deploy/${deploy_name}" --timeout=120s
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
    done < <(kubectl get pods -n "${ns}" -l "app=${deploy_name}" -o custom-columns=':metadata.name' --no-headers)
    [ "${#pods[@]}" -eq 2 ]

    for pod in "${pods[@]}"; do
        local file_content
        file_content="$(kubectl exec -n "${ns}" "${pod}" -- cat /tmp/foobar)"
        [ "${file_content}" == "${written}" ]
    done
}
