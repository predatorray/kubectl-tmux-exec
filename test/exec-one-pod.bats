#!/usr/bin/env bats

load test-helper

function setup() {
    setup_one_pod
}

function teardown() {
    teardown_one_pod
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
