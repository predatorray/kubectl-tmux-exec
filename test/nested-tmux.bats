#!/usr/bin/env bats

load test-helper

function setup() {
    setup_one_pod
}

function teardown() {
    teardown_one_pod
    tmux kill-server || true
}

@test "Reuse tmux session" {
    tmux new-session -d bin/kubectl-tmux_exec -l app="${POD_APP_LABEL}" sh
    [ "$(tmux ls | wc -l)" -eq 1 ]
}

@test "Nest tmux session" {
    tmux new-session -d bin/kubectl-tmux_exec -l app="${POD_APP_LABEL}" --session-mode new-session sh
    sleep 2
    local tmux_exit_code=0
    tmux ls || tmux_exit_code="$?"
    [ "${tmux_exit_code}" -eq 1 ]
}
