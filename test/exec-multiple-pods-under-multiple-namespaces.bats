#!/usr/bin/env bats

load test-helper

ns1=
ns2=
pod_name_under_ns1=
pod_name_under_ns2=
app_label=

function setup() {
    app_label="label-$(random_lowercase_string 4)"

    ns1="$(create_namespace)"
    pod_name_under_ns1="alpine-$(random_lowercase_string 8)"
    create_pod_with_name_and_app_label_under_ns "${pod_name_under_ns1}" "${app_label}" "${ns1}"

    ns2="$(create_namespace)"
    pod_name_under_ns2="alpine-$(random_lowercase_string 8)"
    create_pod_with_name_and_app_label_under_ns "${pod_name_under_ns2}" "${app_label}" "${ns2}"
}

function teardown() {
    if [[ -n "${pod_name_under_ns1}" ]]; then
        delete_pod_by_name "${pod_name_under_ns1}" "${ns1}"
    fi
    if [[ -n "${pod_name_under_ns2}" ]]; then
        delete_pod_by_name "${pod_name_under_ns2}" "${ns2}"
    fi

    if [[ -n "${ns1}" ]]; then
        delete_namespace "${ns1}"
    fi
    if [[ -n "${ns2}" ]]; then
        delete_namespace "${ns2}"
    fi

    tmux kill-server || true
}

@test "Exec multiple pods under different namespaces" {
    local written="data-$(random_lowercase_string 8)"

    bin/kubectl-tmux_exec -d -n "${ns1}" -n "${ns2}" -l app="${app_label}" -- sh -c "echo ${written} > /tmp/foobar"

    wait_until_no_sessions

    local file_content=

    file_content="$(kubectl -n "${ns1}" exec "${pod_name_under_ns1}" -- cat /tmp/foobar)"
    [ "${file_content}" == "${written}" ]

    file_content="$(kubectl -n "${ns2}" exec "${pod_name_under_ns2}" -- cat /tmp/foobar)"
    [ "${file_content}" == "${written}" ]
}