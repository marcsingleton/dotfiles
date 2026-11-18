#!/bin/bash

# Start ssh session with local clipboard listener

LOCAL_PORT=3334
REMOTE_PORT=3334
REMOTE_SHELL=zsh

set -m

cleanup() {
    pkill -g "$listener_pid" 2> /dev/null
}

while true; do
    nc -l localhost "$LOCAL_PORT" | pbcopy
done &
listener_pid=$!
disown "$listener_pid"

trap cleanup EXIT

ssh -t -R $REMOTE_PORT:localhost:$LOCAL_PORT "$@" "export CLIP_PORT=$REMOTE_PORT; $REMOTE_SHELL"
