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

readonly RESOURCES_WITH_PODS="\
daemonsets/
deployments/
pods/
jobs/
replicasets/
replicationcontrollers/
services/
statefulsets/"

@test "kubectl tmux-exec [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '')
    [ $? -eq 0 ]

    local expected_output="\
nginx-1
web-0
${RESOURCES_WITH_PODS}
${ALL_OPTIONS}
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec dep[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec 'dep')
    [ $? -eq 0 ]

    # no space after the slash, since there is no pod to complete
    local expected_output="\
deployments/
:6"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec p[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec 'p')
    [ $? -eq 0 ]

    local expected_output="\
pods/
:6"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -l app=nginx [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-l' 'app=nginx' '')
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

    local expected_output="\
nginx-1
web-0
${RESOURCES_WITH_PODS}
${ALL_OPTIONS}
:4"
    [ "${expected_output}" = "${output}" ]
    grep -q -- 'get pods --namespace ns1 ' "${KUBECTL_STUB_LOG}"
    grep -q -- 'get pods --namespace ns2 ' "${KUBECTL_STUB_LOG}"
}

@test "kubectl tmux-exec --namespace=ns1 -nns2 [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--namespace=ns1' '-nns2' '')
    [ $? -eq 0 ]

    local expected_output="\
nginx-1
web-0
${RESOURCES_WITH_PODS}
${ALL_OPTIONS}
:4"
    [ "${expected_output}" = "${output}" ]
    grep -q -- 'get pods --namespace ns1 ' "${KUBECTL_STUB_LOG}"
    grep -q -- 'get pods --namespace ns2 ' "${KUBECTL_STUB_LOG}"
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
app=nginx,tier=web
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --selector=app=nginx,ti[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--selector=app=nginx,ti')
    [ $? -eq 0 ]

    local expected_output="\
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
    [ "${expected_calls}" = "$(sort "${KUBECTL_STUB_LOG}")" ]
}

@test "kubectl tmux-exec -A -n ns1 -c [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-A' '-n' 'ns1' '-c' '')
    [ $? -eq 0 ]

    local expected_calls="\
--request-timeout 5s get pods --all-namespaces -o jsonpath={range .items[*].spec.containers[*]}{.name}{\"\n\"}{end}"
    [ "${expected_calls}" = "$(sort "${KUBECTL_STUB_LOG}")" ]
}

@test "kubectl tmux-exec --insecure-skip-tls-verify -s url --request-timeout=1s --file f -n [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--insecure-skip-tls-verify' '-s' 'url' '--request-timeout=1s' '--file' 'f' '-n' '')
    [ $? -eq 0 ]

    local expected_calls="\
--request-timeout 5s --insecure-skip-tls-verify -s url --request-timeout 1s get namespaces -o jsonpath={range .items[*]}{.metadata.name}{\"\n\"}{end}"
    [ "${expected_calls}" = "$(sort "${KUBECTL_STUB_LOG}")" ]
}

@test "kubectl tmux-exec -n [tab] when kubectl fails" {
    local output
    output=$(KUBECTL_STUB_FAIL=1 bin/kubectl_complete-tmux_exec '-n' '')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -l app!=nginx,!tier,[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-l' 'app!=nginx,!tier,')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --context c1 --context=c1 -n ns1 -nns1 -c [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--context' 'c1' '--context=c1' '-n' 'ns1' '-nns1' '-c' '')
    [ $? -eq 0 ]

    local expected_calls="\
--request-timeout 5s --context c1 get pods --namespace ns1 -o jsonpath={range .items[*].spec.containers[*]}{.name}{\"\n\"}{end}"
    [ "${expected_calls}" = "$(sort "${KUBECTL_STUB_LOG}")" ]
}

@test "kubectl tmux-exec --context c1 --context c2 -n ns1 -n ns2 -c [tab] queries in parallel" {
    local output
    local start="${SECONDS}"
    output=$(KUBECTL_STUB_SLEEP=2 bin/kubectl_complete-tmux_exec '--context' 'c1' '--context' 'c2' '-n' 'ns1' '-n' 'ns2' '-c' '')
    [ $? -eq 0 ]
    [ "$((SECONDS - start))" -lt 6 ]

    local expected_output="\
nginx
sidecar
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -n [tab] does not pass stdin to kubectl" {
    local output
    local start="${SECONDS}"
    output=$(KUBECTL_STUB_READ_STDIN=1 bin/kubectl_complete-tmux_exec '-n' '' < <(sleep 5))
    [ $? -eq 0 ]
    [ "$((SECONDS - start))" -lt 5 ]
}

@test "kubectl tmux-exec we[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec 'we')
    [ $? -eq 0 ]

    local expected_output="\
web-0
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec -n ns1 deploy/[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '-n' 'ns1' 'deploy/')
    [ $? -eq 0 ]

    local expected_output="\
deploy/nginx
:4"
    [ "${expected_output}" = "${output}" ]
    grep -q -- 'get deploy --namespace ns1 -o jsonpath=' "${KUBECTL_STUB_LOG}"
}

@test "kubectl tmux-exec Abc/[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec 'Abc/')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec deploy/nginx ba[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec 'deploy/nginx' 'ba')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec deploy/nginx -c [tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec 'deploy/nginx' '-c' '')
    [ $? -eq 0 ]

    local expected_output="\
nginx
sidecar
:4"
    [ "${expected_output}" = "${output}" ]
}

@test "kubectl tmux-exec --file pods.txt ba[tab]" {
    local output
    output=$(bin/kubectl_complete-tmux_exec '--file' 'pods.txt' 'ba')
    [ $? -eq 0 ]

    local expected_output=":4"
    [ "${expected_output}" = "${output}" ]
}
