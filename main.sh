#!/bin/bash -e

export ssh_dir="$GITHUB_WORKSPACE/.ssh"
export ngrok_dir="$GITHUB_WORKSPACE/.ngrok"
mkdir -p $ssh_dir
mkdir -p $ngrok_dir

echo "Configuring sshd..."
envsubst < "$ssh_dir/sshd_config.template" > "$ssh_dir/sshd_config"

echo "Configuring ngrok..."
envsubst < "$ngrok_dir/ngrok.yml.template" > "$ngrok_dir/ngrok.yml"

if [ -z "$NGROK_AUTHTOKEN" ]; then
  echo "You must provide your ngrok authtoken. Visit https://dashboard.ngrok.com/get-started/your-authtoken to get it."
  exit 1
fi

# Download, install, and configure ngrok
if ! command -v "ngrok" > /dev/null 2>&1; then
  echo "Installing ngrok..."
  wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
  tar -xzf ngrok-v3-stable-linux-amd64.tgz
  chmod +x ngrok
  mv ngrok /usr/local/bin/ngrok
  rm ngrok-v3-stable-linux-amd64.tgz
fi


# Setup SSH server
curl -s "https://api.github.com/users/$GITHUB_ACTOR/keys" | jq -r '.[].key' >> "$ssh_dir/authorized_keys"

if [ $? -ne 0 ]; then
    echo "Couldn't get public SSH key for user: $GITHUB_ACTOR"
    echo "SSH key must be configured. Visit https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account to learn how to add one to your GitHub account."
    exit 1
fi

echo "Configured SSH key(s) for user: $GITHUB_ACTOR"

echo 'Creating SSH server key...'
ssh-keygen -q -f "$ssh_dir/ssh_host_rsa_key" -N ''

echo "Configuring sshd..."
envsubst < "$ssh_dir/sshd_config.template" > "$ssh_dir/sshd_config"

echo "Starting SSH server..."
/usr/sbin/sshd -f "$ssh_dir/sshd_config"

echo "Starting tmux session..."
tmux new-session -d -s $USER

# Start ngrok
echo "Starting ngrok..."
ngrok start --all --config "$ngrok_dir/ngrok.yml" --log "$ngrok_dir/ngrok.log" > /dev/null &
printf "\n\n\n"

# Get ngrok tunnels and print them
tunnels="$(curl -s --retry-connrefused --retry 10  http://localhost:4040/api/tunnels)"
echo $tunnels | jq -c '.tunnels[]' | while read tunnel; do
    tunnel_name=$(echo $tunnel | jq -r ".name")
    tunnel_url=$(echo $tunnel | jq -r ".public_url")
    
    if [ "$tunnel_name" = "ssh" ]; then
      hostname=$(echo $tunnel_url | cut -d'/' -f3 | cut -d':' -f1)
      port=$(echo $tunnel_url | cut -d':' -f3)
      echo "SSH command:"
      echo "ssh $USER@$hostname -p $port"
      printf "\n"
      echo "After logging in, you can attach to the $USER tmux session:"
      echo "tmux attach"
      printf "\n\n\n"
    else
      echo "$tunnel_name:"
      echo $tunnel_url
      printf "\n\n\n"
    fi
done