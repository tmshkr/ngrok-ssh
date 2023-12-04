#! /bin/bash -e

echo "Setting up SSH client..."

ssh_config="
Host $SSH_HOSTNAME
  HostName $SSH_HOSTNAME
  User $SSH_USER
  Port $SSH_PORT
  IdentityFile $HOME/.ssh/id_rsa
  StrictHostKeyChecking yes
  UserKnownHostsFile $HOME/.ssh/known_hosts
"

mkdir -m 600 -p $HOME/.ssh
echo "$SSH_CLIENT_PUBLIC_KEY" >$HOME/.ssh/id_rsa.pub
echo "$SSH_CLIENT_PRIVATE_KEY" >$HOME/.ssh/id_rsa
echo "$ssh_config" >$HOME/.ssh/config
echo "[$SSH_HOSTNAME]:$SSH_PORT $SSH_HOST_PUBLIC_KEY" >$HOME/.ssh/known_hosts
chmod 600 $HOME/.ssh/*
