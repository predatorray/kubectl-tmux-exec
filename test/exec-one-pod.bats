#!/usr/bin/env bats

load test-helper

pod_name=
app_label=

function setup() {
    pod_name="alpine-$(random_lowercase_string 8)"
    app_label="label-$(random_lowercase_string 4)"
    create_pod_with_name_and_app_label_under_ns "${pod_name}" "${app_label}"
}

function teardown() {
    if [[ -n "${pod_name}" ]]; then
        delete_pod_by_name "${pod_name}"
    fi
    tmux kill-server || true
}

@test "Exec one pod by label" {
    local written="data-$(random_lowercase_string 8)"

    bin/kubectl-tmux_exec -d -l app="${app_label}" -- sh -c "echo ${written} > /tmp/foobar"
    
    wait_until_no_sessions

    local file_content=
    file_content="$(kubectl exec "${pod_name}" cat /tmp/foobar)"
    
    [ "${file_content}" == "${written}" ]
}

@test "Exec one pod by file" {
    local written="data-$(random_lowercase_string 8)"

    bin/kubectl-tmux_exec -d -f - -- sh -c "echo ${written} > /tmp/foobar" <<< "${pod_name}"

    wait_until_no_sessions

    local file_content
    file_content="$(kubectl exec "${pod_name}" cat /tmp/foobar)"
    
    [ "${file_content}" == "${written}" ]
}

@test "Exec one pod by label but providing duplicate namespaces" {
    local written="data-$(random_lowercase_string 8)"

    bin/kubectl-tmux_exec -d -n default -n default -l app="${app_label}" -- sh -c "echo ${written} > /tmp/foobar"
    
    wait_until_no_sessions

    local file_content=
    file_content="$(kubectl exec "${pod_name}" cat /tmp/foobar)"
    
    [ "${file_content}" == "${written}" ]
}
