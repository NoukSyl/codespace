#!/usr/bin/env bash
# Runs once, when the Codespace container is first created.
set -euo pipefail

echo "==> Installing openssh-server"
sudo apt-get update -y
sudo apt-get install -y openssh-server

echo "==> Configuring sshd (key-only auth, root login allowed but password login disabled)"
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
echo "PermitRootLogin prohibit-password"   | sudo tee -a /etc/ssh/sshd_config >/dev/null
echo "PasswordAuthentication no"           | sudo tee -a /etc/ssh/sshd_config >/dev/null

echo "==> Regenerating SSH host keys"
sudo ssh-keygen -A

echo "==> Setting up authorized_keys for root"
sudo mkdir -p /root/.ssh
sudo chmod 700 /root/.ssh
if [ -n "${SSH_AUTHORIZED_KEY:-}" ]; then
  echo "${SSH_AUTHORIZED_KEY}" | sudo tee /root/.ssh/authorized_keys >/dev/null
  sudo chmod 600 /root/.ssh/authorized_keys
  echo "Root authorized_keys installed."
else
  echo "!! WARNING: SSH_AUTHORIZED_KEY secret is not set."
  echo "   Add your public key (the contents of e.g. ~/.ssh/id_ed25519.pub) as a"
  echo "   Codespaces secret named SSH_AUTHORIZED_KEY, then rebuild the container."
  echo "   Without it, nobody can log in — password auth is disabled on purpose."
fi

echo "==> Installing ngrok"
curl -fsSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list >/dev/null
sudo apt-get update -y
sudo apt-get install -y ngrok

echo "==> postCreate finished."
