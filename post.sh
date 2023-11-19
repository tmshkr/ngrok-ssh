#!/bin/bash -e

# Wait until there are no users logged in
while ss -tnp | grep sshd | grep $INPUT_SSH_PORT ; do
  echo "Waiting for all users to log out..."
  sleep 5
done

echo "All users logged out. Exiting..."