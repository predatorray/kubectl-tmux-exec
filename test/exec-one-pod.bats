#!/usr/bin/env bats

load test-helper

readonly POD_NAME='alpine'
readonly POD_APP_LABEL='alpine'

function setup() {
    kubectl apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
  labels:
    app: ${POD_APP_LABEL}
spec:
  containers:
  - name: alpine
    image: alpine
    command:
    - sleep
    - infinite
EOF
    local pod_status=''
    local retries=30
    while [[ "${pod_status}" != 'Running' ]]; do
        sleep 1
        pod_status="$(kubectl get pods "${POD_NAME}" -o custom-columns=':status.phase' --no-headers)"
        echo "The pod status is ${pod_status}."
        (( --retries )) || {
            echo 'Timed out.'
            exit 1
        }
    done
}

function teardown() {
    kubectl delete pod "${POD_NAME}"
    sleep 1
}

@test "Exec one pod by label" {
    local written='foobar-label'
    bin/kubectl-tmux_exec -d -l app="${POD_APP_LABEL}" -- sh -c "echo ${written} > /tmp/foobar"
    
    wait_until_no_sessions

    local file_content=
    file_content="$(kubectl exec "${POD_NAME}" cat /tmp/foobar)"
    
    [ "${file_content}" == "${written}" ]
}

@test "Exec one pod by file" {
    # set -x
    local written='foobar-file'
    bin/kubectl-tmux_exec -d -f - -- sh -c "echo ${written} > /tmp/foobar" <<< "${POD_NAME}"

    wait_until_no_sessions

    local file_content
    file_content="$(kubectl exec "${POD_NAME}" cat /tmp/foobar)"
    
    [ "${file_content}" == "${written}" ]
}
