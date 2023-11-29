#!/bin/bash -e
if [ $GITHUB_ACTIONS != true ]; then
  HOME="$PWD/dev"
  USER="dev"
fi

if [ -z "$USER" ]; then
  USER=$(whoami)
fi

export ssh_dir="$HOME/.ssh"
export ngrok_dir="$HOME/.ngrok"

mkdir -m 700 $ssh_dir
mkdir -m 700 $ngrok_dir

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

echo "Configuring ngrok..."
envsubst <"$ACTION_PATH/.ngrok/ngrok.yml" >"$ngrok_dir/ngrok.yml"
ngrok_config="$ngrok_dir/ngrok.yml"

if [ -n "$INPUT_NGROK_CONFIG_FILE" ]; then
  echo "Adding custom ngrok config file..."
  ngrok_config="$ngrok_config,$GITHUB_WORKSPACE/$INPUT_NGROK_CONFIG_FILE"
fi

if [ -z "$INPUT_NGROK_AUTHTOKEN" ]; then
  echo "You must provide your ngrok authtoken. Visit https://dashboard.ngrok.com/get-started/your-authtoken to get it."
  exit 1
fi

echo "Configuring sshd..."
envsubst <"$ACTION_PATH/.ssh/config" >"$ssh_dir/config"
envsubst <"$ACTION_PATH/.ssh/rc" >"$ssh_dir/rc" '$ssh_dir'
echo "cd $GITHUB_WORKSPACE" >>"$HOME/.bash_profile"

if [ -n "$INPUT_BASH_PROFILE" ]; then
  echo "Adding custom bash_profile..."
  cat "$GITHUB_WORKSPACE/$INPUT_BASH_PROFILE" >>"$HOME/.bash_profile"
fi

if [ -n "$INPUT_SSH_HOST_PRIVATE_KEY" ] && [ -n "$INPUT_SSH_HOST_PUBLIC_KEY" ]; then
  echo "Setting SSH host's public and private keys..."
  echo "$INPUT_SSH_HOST_PRIVATE_KEY" >>"$ssh_dir/ssh_host_key"
  echo "$INPUT_SSH_HOST_PUBLIC_KEY" >>"$ssh_dir/ssh_host_key.pub"
else
  echo "Generating SSH host's public and private keys..."
  ssh-keygen -q -t rsa -f "$ssh_dir/ssh_host_key" -N ''
fi
echo SSH_HOST_PUBLIC_KEY=$(cat "$ssh_dir/ssh_host_key.pub") >>"$GITHUB_OUTPUT"

# Setup ssh login credentials
if [ "$INPUT_USE_GITHUB_ACTOR_KEY" == true ]; then
  curl -s "https://api.github.com/users/$GITHUB_ACTOR/keys" | jq -r '.[].key' >>"$ssh_dir/authorized_keys"
  if [ $? -ne 0 ]; then
    echo "Couldn't get public SSH key for user: $GITHUB_ACTOR"
    echo "Visit https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account to learn how to add one to your GitHub account."
  else
    echo "Configured SSH key(s) for user: $GITHUB_ACTOR"
  fi
fi

if [ -n "$INPUT_SSH_CLIENT_PUBLIC_KEY" ]; then
  echo "$INPUT_SSH_CLIENT_PUBLIC_KEY" >>"$ssh_dir/authorized_keys"
fi

if ! grep -q . "$ssh_dir/authorized_keys" || [ "$INPUT_SET_RANDOM_PASSWORD" == true ]; then
  echo "Setting random password for user: $USER"
  random_password=$(openssl rand -base64 32)
  if [ $GITHUB_ACTIONS == true ]; then
    echo "$USER:$random_password" | sudo chpasswd
  fi
fi

echo "Starting SSH server..."
/usr/sbin/sshd -f "$ssh_dir/config"

echo "Starting ngrok..."
ngrok start --all --config "$ngrok_config" --log "$ngrok_dir/ngrok.log" >/dev/null &

# Get ngrok tunnels and print them
tunnels="$(curl -s --retry-connrefused --retry 10 http://localhost:4040/api/tunnels)"
echo "NGROK_TUNNELS=$(echo $tunnels | jq -c '.tunnels | map(del(.config, .metrics))')" >>"$GITHUB_OUTPUT"

print_tunnels() {
  echo $tunnels | jq -c '.tunnels[]' | while read tunnel; do
    local tunnel_name=$(echo $tunnel | jq -r ".name")
    local tunnel_url=$(echo $tunnel | jq -r ".public_url")
    if [ "$tunnel_name" = "ssh" ]; then
      hostname=$(echo $tunnel_url | cut -d'/' -f3 | cut -d':' -f1)
      port=$(echo $tunnel_url | cut -d':' -f3)

      echo "SSH_HOSTNAME=$hostname" >>"$GITHUB_OUTPUT"
      echo "SSH_PORT=$port" >>"$GITHUB_OUTPUT"
      echo "SSH_USER=$USER" >>"$GITHUB_OUTPUT"

      echo "*********************************"
      printf "\n"
      echo "SSH command:"
      echo "ssh $USER@$hostname -p $port"
      printf "\n"
      if [ -n "$random_password" ]; then
        echo "SSH_PASSWORD=$random_password" >>"$GITHUB_OUTPUT"
        echo "Random password:"
        echo "$random_password"
        printf "\n"
      fi
    else
      echo "*********************************"
      printf "\n"
      echo "$tunnel_name:"
      echo "$tunnel_url"
      printf "\n"
    fi
  done
}

while true; do
  print_tunnels
  if [ -f "$ssh_dir/connections" ] || [ "$INPUT_WAIT_FOR_CONNECTION" == false ]; then
    break
  fi
  echo "Waiting for SSH user to login..."
  sleep 5
done
