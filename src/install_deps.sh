#!/bin/bash -e

if ! command -v "envsubst" >/dev/null 2>&1; then
  echo "Installing envsubst..."
  wget -q https://github.com/a8m/envsubst/releases/download/v1.4.2/envsubst-Linux-x86_64
  chmod +x envsubst-Linux-x86_64
  mv envsubst-Linux-x86_64 /usr/local/bin/envsubst
fi

if ! command -v "jq" >/dev/null 2>&1; then
  echo "Installing jq..."
  wget -q https://github.com/jqlang/jq/releases/download/jq-1.7/jq-linux-amd64
  chmod +x jq-linux-amd64
  mv jq-linux-amd64 /usr/local/bin/jq
fi

if ! command -v "ngrok" >/dev/null 2>&1; then
  echo "Installing ngrok..."
  wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
  tar -xzf ngrok-v3-stable-linux-amd64.tgz
  chmod +x ngrok
  mv ngrok /usr/local/bin/ngrok
  rm ngrok-v3-stable-linux-amd64.tgz
fi

if ! command -v "sshd" >/dev/null 2>&1; then
  echo "Installing sshd..."
  su -c "apt-get update && apt-get install openssh-server -y && mkdir /run/sshd"
fi

if ! command -v "ss" >/dev/null 2>&1; then
  echo "Installing iproute2..."
  su -c "apt-get update && apt-get install iproute2 -y"
fi

if ! command -v "tmux" >/dev/null 2>&1; then
  echo "Installing tmux..."
  su -c "apt-get update && apt-get install tmux -y"
fi
