#!/bin/bash -e

source ./setup-ssh-client.sh

ngrok_url=$(echo $NGROK_TUNNELS | jq -r '.[] | select(.name == "web") | .public_url')

curl --retry-all-errors --retry 10 $ngrok_url | grep "hello world"

echo "Stopping test server..."
ssh -F $HOME/.ssh/config $SSH_HOSTNAME pkill node
