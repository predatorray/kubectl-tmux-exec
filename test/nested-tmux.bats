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

@test "Reuse tmux session" {
    tmux new-session -d bin/kubectl-tmux_exec -l app="${app_label}" sh
    [ "$(tmux ls | wc -l)" -eq 1 ]
}

@test "Nest tmux session" {
    tmux new-session -d bin/kubectl-tmux_exec -l app="${app_label}" --session-mode new-session sh
    sleep 2
    local tmux_exit_code=0
    tmux ls || tmux_exit_code="$?"
    [ "${tmux_exit_code}" -eq 1 ]
}
