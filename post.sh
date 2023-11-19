#!/bin/bash -e
if [ $GITHUB_ACTIONS == false ]; then
  HOME="$PWD/dev"
  USER="dev"
fi

ssh_dir="$HOME/.ssh"
ngrok_dir="$HOME/.ngrok"


if [ "$INPUT_WAIT_FOR_CONNECTION" == true ] && [ ! -f "$ssh_dir/connections" ]; then
  while [ ! -f "$ssh_dir/connections" ]; do
    echo "Waiting for SSH user to login..."
    sleep 5
  done
fi


# Wait until there are no users logged in
while ss -tnp | grep sshd | grep $INPUT_SSH_PORT ; do
  echo "Waiting for all users to log out..."
  sleep 5
done


echo "All users logged out. Cleaning up..."
echo "Terminating processes..."
killall ngrok || true
kill $(cat $ssh_dir/sshd.pid) || true
echo "Deleting $ssh_dir"
rm -rf $ssh_dir || true
echo "Deleting $ngrok_dir"
rm -rf $ngrok_dir || true
