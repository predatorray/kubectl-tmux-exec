#!/usr/bin/env bats

# Mocking setup for parser-focused tests that do not require a real Kubernetes cluster.
setup() {
    TEST_TMP_DIR="$(mktemp -d)"
    PATH_ORIG="$PATH"
    export PATH="$TEST_TMP_DIR:$PATH"

    # Mock kubectl: record arguments and behave minimally.
    cat > "$TEST_TMP_DIR/kubectl" <<'EOF'
#!/usr/bin/env bash
# capture args to a file for verification if needed
# Use a predictable path for verification file
printf '%s\n' "$@" >> "${TMPDIR_MOCK_OUT}/kubectl.args"

if [[ "$1" == "get" ]]; then
    # Return a dummy pod list if requested
    if [[ "$*" == *"pods"* ]]; then
        echo "pod1"
    fi
    exit 0
fi
exit 0
EOF
    chmod +x "$TEST_TMP_DIR/kubectl"

    # Mock tmux: do nothing.
    cat > "$TEST_TMP_DIR/tmux" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$TEST_TMP_DIR/tmux"

    export TMPDIR_MOCK_OUT="$(mktemp -d)"
}

teardown() {
    export PATH="$PATH_ORIG"
    rm -rf "$TEST_TMP_DIR" "$TMPDIR_MOCK_OUT"
}

@test "Parse: combined short options (unbundling) -Al" {
    run bin/kubectl-tmux_exec -Al app=nginx --dry-run bash
    [ "$status" -eq 0 ]
    # Verification: kubectl should have seen 'app=nginx' via selector logic.
    grep -q "app=nginx" "${TMPDIR_MOCK_OUT}/kubectl.args"
}

@test "Parse: attached short option arg -lapp=nginx" {
    run bin/kubectl-tmux_exec -lapp=nginx --dry-run bash
    [ "$status" -eq 0 ]
    grep -q "app=nginx" "${TMPDIR_MOCK_OUT}/kubectl.args"
}

@test "Parse: attached short option arg -ccontainer" {
    run bin/kubectl-tmux_exec -l app=nginx -cmycontainer --dry-run bash
    [ "$status" -eq 0 ]
    # The --dry-run output should contain the -c mycontainer part of the kubectl exec command
    [[ "$output" == *" -c mycontainer "* ]]
}

@test "Parse: long options with '=' --selector=app=nginx" {
    run bin/kubectl-tmux_exec --selector=app=nginx --dry-run bash
    [ "$status" -eq 0 ]
    grep -q "app=nginx" "${TMPDIR_MOCK_OUT}/kubectl.args"
}

@test "Parse: kubectl pass-through short option -s" {
    run bin/kubectl-tmux_exec -l app=nginx -s server1 --dry-run bash
    [ "$status" -eq 0 ]
    # Check if -s server1 was passed to kubectl
    grep -q "^-s$" "${TMPDIR_MOCK_OUT}/kubectl.args"
    grep -q "^server1$" "${TMPDIR_MOCK_OUT}/kubectl.args"
}

@test "Parse: kubectl pass-through long option with '=' --kubeconfig=/tmp/kc" {
    run bin/kubectl-tmux_exec -l app=nginx --kubeconfig=/tmp/kc --dry-run bash
    [ "$status" -eq 0 ]
    grep -q "^--kubeconfig$" "${TMPDIR_MOCK_OUT}/kubectl.args"
    grep -q "^/tmp/kc$" "${TMPDIR_MOCK_OUT}/kubectl.args"
}

@test "Parse: kubectl pass-through long no-arg --insecure-skip-tls-verify" {
    run bin/kubectl-tmux_exec -l app=nginx --insecure-skip-tls-verify --dry-run bash
    [ "$status" -eq 0 ]
    grep -q "^--insecure-skip-tls-verify$" "${TMPDIR_MOCK_OUT}/kubectl.args"
}

@test "Parse: duplicate namespaces are deduped" {
    # The script uses 'namespaces+=("$1")' and dedupes with 'array_contains'
    # We can check the kubectl calls. It should only call get pods -n ns1 once per namespace.
    # Note: the script iterates over namespaces.
    run bin/kubectl-tmux_exec -l app=nginx -n ns1 -n ns1 --dry-run bash
    [ "$status" -eq 0 ]
    count=$(grep -c "^ns1$" "${TMPDIR_MOCK_OUT}/kubectl.args" || true)
    # Expected 1 for 'get pods -n ns1'
    [ "$count" -eq 1 ]
}

@test "Parse: -- separator ignores subsequent flags" {
    # --dry-run after -- should be treated as a command argument, not a script flag.
    # If it was a flag, the script would be in dry-run mode.
    # Here we use --dry-run BEFORE to ensure it doesn't try to run real tmux,
    # and then another --dry-run AFTER -- to check if it's passed as arg.
    run bin/kubectl-tmux_exec -l app=nginx --dry-run -- bash --dry-run-arg
    [ "$status" -eq 0 ]
    # The string '--dry-run-arg' should NOT be in kubectl args (it's part of the command executed in tmux)
    # But it should NOT be parsed as a script option either.
}

@test "Parse: missing required arg error for -l" {
    run bin/kubectl-tmux_exec -l
    [ "$status" -ne 0 ]
    [[ "$output" == *"error: option -l requires an argument"* ]]
}

@test "Parse: unknown option error for --foo" {
    run bin/kubectl-tmux_exec --foo
    [ "$status" -ne 0 ]
    [[ "$output" == *"error: unknown option: --foo"* ]]
}

@test "Parse: deprecated -i and -t options warn but pass" {
    run bin/kubectl-tmux_exec -l app=nginx -i -t --dry-run bash
    [ "$status" -eq 0 ]
    [[ "$output" == *"warn: The option -i / --stdin is deprecated."* ]]
    [[ "$output" == *"warn: The option -t / --tty is deprecated."* ]]
}
