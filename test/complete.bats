#!/usr/bin/env bats

setup() {
    PATH="${BATS_TEST_DIRNAME}/stub:${PATH}"
    export KUBECTL_STUB_LOG="${BATS_TEST_TMPDIR}/kubectl.log"
}

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

    local expected_output="${ALL_OPTIONS}
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-')
    [ $? -eq 0 ]

    local expected_output="${ALL_OPTIONS}
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -A[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-A')
    [ $? -eq 0 ]

    local expected_output="${ALL_OPTIONS}
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -n[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-n')
    [ $? -eq 0 ]

    local expected_output="${ALL_OPTIONS}
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--')
    [ $? -eq 0 ]

    local expected_output="${ALL_LONG_OPTIONS}
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -- [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--' '')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -- bash -[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--' 'bash' '-')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -l app=nginx bash [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-l' 'app=nginx' 'bash' '')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -l app=nginx ba[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-l' 'app=nginx' 'ba')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --context [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--context' '')
    [ $? -eq 0 ]

    local expected_output="\
ctx1
ctx2
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -l [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-l' '')
    [ $? -eq 0 ]

    local expected_output="\
app=nginx
tier=web
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --file[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--file')
    [ $? -eq 0 ]

    local expected_output="${ALL_LONG_OPTIONS}
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --file [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--file' '')
    [ $? -eq 0 ]

    local expected_output=":8"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --file=[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--file=')
    [ $? -eq 0 ]

    local expected_output=":8"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --file - --session-mode [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--file' '-' '--session-mode' '')
    [ $? -eq 0 ]

    local expected_output="\
auto
new-session
current-session
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --session-mode[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--session-mode')
    [ $? -eq 0 ]

    local expected_output="${ALL_LONG_OPTIONS}
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --session-mode=[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--session-mode=')
    [ $? -eq 0 ]

    local expected_output="\
auto
new-session
current-session
:4"
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
tiled
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --select-layout=ti[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--select-layout=ti')
    [ $? -eq 0 ]

    local expected_output="\
even-horizontal
even-vertical
main-horizontal
main-vertical
tiled
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --namespace ns1 --namespace [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--namespace' 'ns1' '--namespace' '')
    [ $? -eq 0 ]

    local expected_output="\
default
kube-system
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --namespace ns1 --namespace ns2 [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--namespace' 'ns1' '--namespace' 'ns2' '')
    [ $? -eq 0 ]

    local expected_output="${ALL_OPTIONS}
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --namespace=ns1 -nns2 [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--namespace=ns1' '-nns2' '')
    [ $? -eq 0 ]

    local expected_output="${ALL_OPTIONS}
:4"
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

@test "kubectl tmux-exec -n [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-n' '')
    [ $? -eq 0 ]

    local expected_output="\
default
kube-system
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --namespace=[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--namespace=')
    [ $? -eq 0 ]

    local expected_output="\
default
kube-system
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --cluster [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--cluster' '')
    [ $? -eq 0 ]

    local expected_output="\
cluster1
cluster2
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --user=[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--user=')
    [ $? -eq 0 ]

    local expected_output="\
user1
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -c [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-c' '')
    [ $? -eq 0 ]

    local expected_output="\
nginx
sidecar
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -l app=nginx,[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-l' 'app=nginx,')
    [ $? -eq 0 ]

    local expected_output="\
app=nginx,app=nginx
app=nginx,tier=web
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --selector=app=nginx,ti[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--selector=app=nginx,ti')
    [ $? -eq 0 ]

    local expected_output="\
app=nginx,app=nginx
app=nginx,tier=web
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --kubeconfig k --context c1 --context=c2 -nns1 -l app=nginx -c [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--kubeconfig' 'k' '--context' 'c1' '--context=c2' '-nns1' '-l' 'app=nginx' '-c' '')
    [ $? -eq 0 ]

    local expected_calls="\
--request-timeout 5s --kubeconfig k --context c1 get pods --namespace ns1 --selector app=nginx -o jsonpath={range .items[*].spec.containers[*]}{.name}{\"\n\"}{end}
--request-timeout 5s --kubeconfig k --context c2 get pods --namespace ns1 --selector app=nginx -o jsonpath={range .items[*].spec.containers[*]}{.name}{\"\n\"}{end}"
    [ "${expected_calls}" = "$(cat "${KUBECTL_STUB_LOG}")" ]
}

@test "kubectl tmux-exec -A -n ns1 -c [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-A' '-n' 'ns1' '-c' '')
    [ $? -eq 0 ]

    local expected_calls="\
--request-timeout 5s get pods --all-namespaces -o jsonpath={range .items[*].spec.containers[*]}{.name}{\"\n\"}{end}"
    [ "${expected_calls}" = "$(cat "${KUBECTL_STUB_LOG}")" ]
}

@test "kubectl tmux-exec --insecure-skip-tls-verify -s url --request-timeout=1s --file f -n [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--insecure-skip-tls-verify' '-s' 'url' '--request-timeout=1s' '--file' 'f' '-n' '')
    [ $? -eq 0 ]

    local expected_calls="\
--request-timeout 5s --insecure-skip-tls-verify -s url --request-timeout 1s get namespaces -o jsonpath={range .items[*]}{.metadata.name}{\"\n\"}{end}"
    [ "${expected_calls}" = "$(cat "${KUBECTL_STUB_LOG}")" ]
}

@test "kubectl tmux-exec -n [tab] when kubectl fails" {
    local output
    output=$(KUBECTL_STUB_FAIL=1 bin/kubectl_complete-tmux_exec '-n' '')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}
