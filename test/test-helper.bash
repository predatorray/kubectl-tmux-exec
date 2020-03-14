#!/usr/bin/env bash

function wait_until_no_sessions() {
    local retries=30
    while tmux ls 2>&1 >/dev/null; do
        (( --retries )) || {
            echo 'Timed out.'
            return 1
        }
        sleep 1
    done
}