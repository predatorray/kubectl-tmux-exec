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
