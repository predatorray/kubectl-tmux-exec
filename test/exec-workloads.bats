#!/usr/bin/env bats

load test-helper

ns=
name=

function setup() {
    ns="$(create_namespace)"
    name="alpine-$(random_lowercase_string 8)"
}

function teardown() {
    if [[ -n "${ns}" ]]; then
        delete_namespace "${ns}"
    fi
    tmux kill-server || true
}

# Prints the pod template of a container that sleeps forever, with the labels given as YAML, indented by $2 spaces.
function pod_template() {
    local labels="$1"
    local indent="$2"
    sed "s/^/$(printf "%${indent}s" '')/" << EOT
metadata:
  labels:
    test-id: ${name}
${labels}
spec:
  containers:
  - name: alpine
    image: alpine
    command:
    - sleep
    - infinite
EOT
}

# Waits until COUNT pods with the label test-id=NAME are ready.
function wait_for_pods() {
    local count="$1"
    local retries=60
    while [[ "$(kubectl get pods -n "${ns}" -l "test-id=${name}" -o name | wc -l)" -lt "${count}" ]]; do
        (( --retries )) || {
            echo 'Timed out.'
            return 1
        }
        sleep 1
    done
    kubectl wait -n "${ns}" --for=condition=Ready pod -l "test-id=${name}" --timeout=120s
}

# Execs into TYPE/NAME, and asserts that the command was executed in all the COUNT pods with the label test-id=NAME.
function assert_exec_all_pods() {
    local resource="$1"
    local count="$2"
    local written="data-$(random_lowercase_string 8)"

    bin/kubectl-tmux_exec -d -n "${ns}" "${resource}" -- sh -c "echo ${written} > /tmp/foobar"

    wait_until_no_sessions

    local pods=()
    while read -r pod; do
        pods+=("${pod}")
    done < <(kubectl get pods -n "${ns}" -l "test-id=${name}" -o custom-columns=':metadata.name' --no-headers)
    [ "${#pods[@]}" -eq "${count}" ]

    for pod in "${pods[@]}"; do
        local file_content
        file_content="$(kubectl exec -n "${ns}" "${pod}" -- cat /tmp/foobar)"
        [ "${file_content}" == "${written}" ]
    done
}

@test "Exec all pods of a replicaset by rs/NAME" {
    kubectl apply -n "${ns}" -f - << EOT
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: ${name}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${name}
  template:
$(pod_template "    app: ${name}" 4)
EOT
    wait_for_pods 2

    assert_exec_all_pods "rs/${name}" 2
}

@test "Exec all pods of a replicationcontroller by rc/NAME" {
    kubectl apply -n "${ns}" -f - << EOT
apiVersion: v1
kind: ReplicationController
metadata:
  name: ${name}
spec:
  replicas: 2
  selector:
    app: ${name}
  template:
$(pod_template "    app: ${name}" 4)
EOT
    wait_for_pods 2

    assert_exec_all_pods "rc/${name}" 2
}

@test "Exec all pods of a daemonset by ds/NAME" {
    kubectl apply -n "${ns}" -f - << EOT
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ${name}
spec:
  selector:
    matchLabels:
      app: ${name}
  template:
$(pod_template "    app: ${name}" 4)
EOT
    local nodes
    nodes="$(kubectl get nodes -o name | wc -l)"
    wait_for_pods "${nodes}"

    assert_exec_all_pods "ds/${name}" "${nodes}"
}

@test "Exec all pods of a job by job/NAME" {
    # The selector of a job is generated, e.g. matchLabels: {batch.kubernetes.io/controller-uid: ...}
    kubectl apply -n "${ns}" -f - << EOT
apiVersion: batch/v1
kind: Job
metadata:
  name: ${name}
spec:
  parallelism: 2
  completions: 2
  template:
$(pod_template "    app: ${name}" 4 | sed '/^    spec:$/a\      restartPolicy: Never')
EOT
    wait_for_pods 2

    assert_exec_all_pods "job/${name}" 2
}

@test "Exec all pods of a deployment whose selector uses NotIn, Exists and DoesNotExist" {
    kubectl apply -n "${ns}" -f - << EOT
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${name}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${name}
    matchExpressions:
    - key: tier
      operator: NotIn
      values:
      - frontend
      - cache
    - key: track
      operator: Exists
    - key: canary
      operator: DoesNotExist
  template:
$(pod_template "    app: ${name}
    tier: backend
    track: stable" 4)
EOT
    kubectl rollout status -n "${ns}" "deploy/${name}" --timeout=120s
    wait_for_pods 2

    assert_exec_all_pods "deploy/${name}" 2
}
