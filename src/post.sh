#!/bin/bash -e

export ssh_dir="$ACTION_PATH/run/.ssh"
export ngrok_dir="$ACTION_PATH/run/.ngrok"

# Wait until there are no users logged in
while ss -tnp | grep sshd | grep $INPUT_SSH_PORT; do
  echo "Waiting for all users to log out..."
  sleep 5
done

echo "All users logged out. Cleaning up..."
echo "Terminating processes..."
pkill ngrok || true
kill $(cat $ssh_dir/sshd.pid) || true
echo "Deleting $ssh_dir"
rm -rf $ssh_dir || true
echo "Deleting $ngrok_dir"
rm -rf $ngrok_dir || true
