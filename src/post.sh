#!/bin/bash -e
if [ $GITHUB_ACTIONS == true ]; then
  export USER=$(whoami)
  export HOME=$(eval echo ~$USER)
else
  export USER="dev"
  export HOME="$PWD/dev"
fi

export ssh_dir="$HOME/.ssh"
export ngrok_dir="$HOME/.ngrok"

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
