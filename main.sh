#!/bin/bash -e
if [ $GITHUB_ACTIONS == false ]; then
  HOME="$PWD/dev"
  USER="dev"
fi

export ssh_dir="$HOME/.ssh"
export ngrok_dir="$HOME/.ngrok"
export github_vars=$(printenv | grep "^GITHUB" | awk -F= '{print $1"=\""$2"\""}' | tr '\n' ' ')
export runner_vars=$(printenv | grep "^RUNNER" | awk -F= '{print $1"=\""$2"\""}' | tr '\n' ' ')
export input_vars=$(printenv | grep "^INPUT" | awk -F= '{print $1"=\""$2"\""}' | tr '\n' ' ')
export ssh_vars="CI=true $github_vars $runner_vars $input_vars"

mkdir -m 700 $ssh_dir
mkdir -m 700 $ngrok_dir

echo "Configuring sshd..."
envsubst < "$ACTION_PATH/.ssh/config" > "$ssh_dir/config"
envsubst < "$ACTION_PATH/.ssh/rc" > "$ssh_dir/rc" '$ssh_dir'

echo "Configuring ngrok..."
envsubst < "$ACTION_PATH/.ngrok/ngrok.yml" > "$ngrok_dir/ngrok.yml"
ngrok_config="$ngrok_dir/ngrok.yml"

if [ -n "$INPUT_NGROK_CONFIG_FILE" ]; then
  echo "Adding custom ngrok config file..."
  ngrok_config="$ngrok_config,$GITHUB_WORKSPACE/$INPUT_NGROK_CONFIG_FILE"
fi


if [ -z "$INPUT_NGROK_AUTHTOKEN" ]; then
  echo "You must provide your ngrok authtoken. Visit https://dashboard.ngrok.com/get-started/your-authtoken to get it."
  exit 1
fi

# Setup ssh login credentials
if [ "$INPUT_USE_GITHUB_ACTOR_KEY" == true ]; then
  curl -s "https://api.github.com/users/$GITHUB_ACTOR/keys" | jq -r '.[].key' >> "$ssh_dir/authorized_keys"
  if [ $? -ne 0 ]; then
    echo "Couldn't get public SSH key for user: $GITHUB_ACTOR"
    echo "Visit https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account to learn how to add one to your GitHub account."
  else
    echo "Configured SSH key(s) for user: $GITHUB_ACTOR"
  fi
fi

if [ -n "$INPUT_SSH_PUBLIC_KEY" ]; then
  echo "$INPUT_SSH_PUBLIC_KEY" >> "$ssh_dir/authorized_keys"
fi

if ! grep -q . "$ssh_dir/authorized_keys" || [ "$INPUT_SET_RANDOM_PASSWORD" == true ]; then
  echo "Setting random password for user: $USER"
  random_password=$(openssl rand -base64 32)
  if [ $GITHUB_ACTIONS == true ]; then
    echo "$USER:$random_password" | sudo chpasswd
  fi
fi

# Download and install ngrok
if ! command -v "ngrok" > /dev/null 2>&1; then
  echo "Installing ngrok..."
  wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
  tar -xzf ngrok-v3-stable-linux-amd64.tgz
  chmod +x ngrok
  mv ngrok /usr/local/bin/ngrok
  rm ngrok-v3-stable-linux-amd64.tgz
fi

echo 'Creating SSH server key...'
ssh-keygen -q -f "$ssh_dir/ssh_host_rsa_key" -N ''

echo "Starting SSH server..."
/usr/sbin/sshd -f "$ssh_dir/config"

echo "Starting ngrok..."
ngrok start --all --config "$ngrok_config" --log "$ngrok_dir/ngrok.log" > /dev/null &

# Get ngrok tunnels and print them
echo_tunnels() {
  tunnels="$(curl -s --retry-connrefused --retry 10  http://localhost:4040/api/tunnels)"
  echo $tunnels | jq -c '.tunnels[]' | while read tunnel; do
    tunnel_name=$(echo $tunnel | jq -r ".name")
    tunnel_url=$(echo $tunnel | jq -r ".public_url")
      if [ "$tunnel_name" = "ssh" ]; then
        hostname=$(echo $tunnel_url | cut -d'/' -f3 | cut -d':' -f1)
        port=$(echo $tunnel_url | cut -d':' -f3)
        echo "*********************************"
        printf "\n"
        echo "SSH command:"
        echo "ssh $USER@$hostname -p $port"
        printf "\n"
        if [ -n "$random_password" ]; then
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
  echo_tunnels
  if [ -f "$ssh_dir/connections" ] || [ "$INPUT_WAIT_FOR_CONNECTION" == false ]; then
    break
  fi
  echo "Waiting for SSH user to login..."
  sleep 5
done