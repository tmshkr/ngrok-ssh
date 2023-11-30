#!/bin/bash -e
if [ $GITHUB_ACTIONS == true ]; then
  export USER=$(whoami)
  export HOME=$(eval echo ~$USER)
  source install_deps.sh
else
  export USER="dev"
  export HOME="$PWD/dev"
fi

export ssh_dir="$HOME/.ssh"
export ngrok_dir="$HOME/.ngrok"

mkdir -p -m 700 $ssh_dir
mkdir -p -m 700 $ngrok_dir

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

if ! grep -q . "$ssh_dir/authorized_keys"; then
  echo "No SSH authorized_keys configured. Exiting..."
  exit 1
fi

chmod 600 "$ssh_dir/authorized_keys"
echo "Starting SSH server..."
/usr/sbin/sshd -E "$ssh_dir/sshd.log" -f "$ssh_dir/config"

echo "Starting ngrok..."
ngrok start --all --config "$ngrok_config" --log "$ngrok_dir/ngrok.log" >/dev/null &

echo "Getting ngrok tunnels..."
NGROK_TUNNELS="$(curl -s --retry-all-errors --retry 10 http://localhost:4040/api/tunnels)"

print_tunnels() {
  echo $NGROK_TUNNELS | jq -c '.tunnels[]' | while read tunnel; do
    tunnel_name=$(echo $tunnel | jq -r ".name")
    tunnel_url=$(echo $tunnel | jq -r ".public_url")
    if [ "$tunnel_name" = "ssh" ]; then
      SSH_HOSTNAME=$(echo $tunnel_url | cut -d'/' -f3 | cut -d':' -f1)
      SSH_PORT=$(echo $tunnel_url | cut -d':' -f3)
      echo "SSH_HOSTNAME=$SSH_HOSTNAME" >>"$GITHUB_OUTPUT"
      echo "SSH_PORT=$SSH_PORT" >>"$GITHUB_OUTPUT"
      echo "SSH_USER=$USER" >>"$GITHUB_OUTPUT"

      echo "*********************************"
      printf "\n"
      echo "SSH command:"
      echo "ssh $USER@$SSH_HOSTNAME -p $SSH_PORT"
      printf "\n"
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

echo "NGROK_TUNNELS=$(echo $NGROK_TUNNELS | jq -c '.tunnels | map(del(.config, .metrics))')" >>"$GITHUB_OUTPUT"
echo SSH_HOST_PUBLIC_KEY=$(cat "$ssh_dir/ssh_host_key.pub") >>"$GITHUB_OUTPUT"
