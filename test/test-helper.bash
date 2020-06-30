#!/usr/bin/env bash

function wait_until_no_sessions() {
    local retries=30
    while tmux ls 2>&1 >/dev/null; do
        (( --retries )) || {
            echo 'Timed out.'
            return 1
        }
        sleep 1
    done
}

readonly POD_NAME='alpine'
readonly POD_APP_LABEL='alpine'

function setup_one_pod() {
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

function teardown_one_pod() {
    kubectl delete pod "${POD_NAME}"
    sleep 5
}