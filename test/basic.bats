#!/usr/bin/env bats

@test "Print usage" {
    bin/kubectl-tmux_exec --help
    [ $? -eq 0 ]
}

@test "Use as a plugin" {
    kubectl tmux-exec --help
    [ $? -eq 0 ]
}
