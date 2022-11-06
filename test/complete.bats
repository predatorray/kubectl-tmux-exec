#!/usr/bin/env bats

readonly ALL_OPTIONS="\
-A
-h
-V
-i
-t
-d
-C
-c
-l
-f
-n
-s
--help
--version
--dry-run
--stdin
--tty
--detach
--remain-on-exit
--all-namespaces
--enable-control-mode
--insecure-skip-tls-verify
--container
--selector
--select-layout
--session-mode
--file
--namespace
--context
--container
--cluster
--password
--request-timeout
--server
--token
--user
--username
--kubeconfig"

readonly ALL_LONG_OPTIONS="\
--help
--version
--dry-run
--stdin
--tty
--detach
--remain-on-exit
--all-namespaces
--enable-control-mode
--insecure-skip-tls-verify
--container
--selector
--select-layout
--session-mode
--file
--namespace
--context
--container
--cluster
--password
--request-timeout
--server
--token
--user
--username
--kubeconfig"

@test "kubectl tmux-exec [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '')
    [ $? -eq 0 ]

    local expected_output="${ALL_OPTIONS}"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '')
    [ $? -eq 0 ]

    local expected_output="${ALL_OPTIONS}"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -A[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-A')
    [ $? -eq 0 ]

    local expected_output="${ALL_OPTIONS}"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--')
    [ $? -eq 0 ]

    local expected_output="${ALL_LONG_OPTIONS}"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -- [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--' '')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --context [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--context')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -l [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-l' '')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --file[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--file')
    [ $? -eq 0 ]

    local expected_output=":8"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --file [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--file' '')
    [ $? -eq 0 ]

    local expected_output=":8"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --file - --session-mode [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--file' '-' '--session-mode')
    [ $? -eq 0 ]

    local expected_output="\
auto
new-session
current-session"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --select-layout [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--select-layout' '')
    [ $? -eq 0 ]

    local expected_output="\
even-horizontal
even-vertical
main-horizontal
main-vertical
tiled"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --namespace ns1 --namespace [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--namespace' 'ns1' '--namespace' '')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --namespace ns1 --namespace ns2 [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--namespace' 'ns1' '--namespace' 'ns2' '')
    [ $? -eq 0 ]

    local expected_output="${ALL_OPTIONS}"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --kubeconfig [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--kubeconfig' '')
    [ $? -eq 0 ]

    local expected_output=":8"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --kubeconfig ~/.kube/config -l foo=bar -- [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--kubeconfig' '~/.kube/config' '-l' 'foo=bar' '--' '')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}
