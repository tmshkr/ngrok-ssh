#!/bin/bash -e
if [ $GITHUB_ACTIONS == false ]; then
  HOME="$PWD/dev"
  USER="dev"
fi

ssh_dir="$HOME/.ssh"
ngrok_dir="$HOME/.ngrok"


# Wait until there are no users logged in
while ss -tnp | grep sshd | grep $INPUT_SSH_PORT ; do
  echo "Waiting for all users to log out..."
  sleep 5
done


echo "All users logged out. Cleaning up..."
echo "killall ngrok tmux"
killall ngrok tmux || true
echo "kill sshd process"
kill $(cat $ssh_dir/sshd.pid) || true
echo "Deleting $ssh_dir"
rm -rf $ssh_dir || true
echo "Deleting $ngrok_dir"
rm -rf $ngrok_dir || true
