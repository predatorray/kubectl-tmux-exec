#!/usr/bin/env bash

function random_lowercase_string() {
    local len="${1:-8}"
    local chars='1234567890abcdefghijklmnopqrstuvwxyz'
    for (( i = 1; i <= $len; i++ )); do
        local offset="(( ${RANDOM} % ${#chars} ))"
        echo -n "${chars:${offset}:1}"
    done
}

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

function create_pod_with_name_and_app_label_under_ns() {
    local pod_name="$1"
    local pod_app_label="$2"
    local ns="${3:-}"

    kubectl apply -n "${ns}" -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${pod_name}
  labels:
    app: ${pod_app_label}
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
        pod_status="$(kubectl -n "${ns}" get pods "${pod_name}" -o custom-columns=':status.phase' --no-headers)"
        echo "The pod status is ${pod_status}."
        (( --retries )) || {
            echo 'Timed out.'
            exit 1
        }
    done
}

function delete_pod_by_name() {
    local pod_name="$1"
    local ns="${2:-}"
    kubectl -n "${ns}" delete pod "${pod_name}"
}

function create_namespace() {
    local ns="ns-$(random_lowercase_string 8)"
    kubectl apply -f - > /dev/null << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: "${ns}"
EOF
    echo "${ns}"
}

function delete_namespace() {
    local ns="$1"
    kubectl delete ns "${ns}"
}
