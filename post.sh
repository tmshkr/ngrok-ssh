#!/bin/bash -e

# Wait until there are no users logged in
while who | grep -q . ; do
  echo "Waiting for all users to log out..."
  sleep 5
done