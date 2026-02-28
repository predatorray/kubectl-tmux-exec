#!/usr/bin/env bats

@test "Print usage" {
    bin/kubectl-tmux_exec --help
    [ $? -eq 0 ]
}
