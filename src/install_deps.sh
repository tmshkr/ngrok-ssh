#!/bin/bash -e

apt_deps=()

if ! command -v "curl" >/dev/null 2>&1; then
  echo "Installing curl..."
  apt_deps+=("curl")
fi

if ! command -v "envsubst" >/dev/null 2>&1; then
  echo "Installing gettext-base..."
  apt_deps+=("gettext-base")
fi

if ! command -v "jq" >/dev/null 2>&1; then
  echo "Installing jq..."
  apt_deps+=("jq")
fi

if ! command -v "sshd" >/dev/null 2>&1; then
  echo "Installing sshd..."
  apt_deps+=("openssh-server")
  su -c "mkdir /run/sshd"
fi

if ! command -v "ss" >/dev/null 2>&1; then
  echo "Installing iproute2..."
  apt_deps+=("iproute2")
fi

if ! command -v "tmux" >/dev/null 2>&1; then
  echo "Installing tmux..."
  apt_deps+=("tmux")
fi

if [ ${#apt_deps[@]} -gt 0 ]; then
  echo "Installing ${#apt_deps[@]} dependencies..."
  su -c "apt-get update && apt-get install ${apt_deps[*]} -y"
fi

if ! command -v "ngrok" >/dev/null 2>&1; then
  echo "Installing ngrok..."
  curl -O https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
  tar -xzf ngrok-v3-stable-linux-amd64.tgz
  chmod +x ngrok
  mv ngrok /usr/local/bin/ngrok
  rm ngrok-v3-stable-linux-amd64.tgz
fi
