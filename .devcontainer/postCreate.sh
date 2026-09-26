#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking Docker CLI"
docker --version

echo "==> Checking Docker daemon"

if docker info >/dev/null 2>&1; then
    echo "Docker daemon is reachable."
else
    echo "ERROR: Docker daemon is NOT reachable."
    echo
    echo "DO NOT start dockerd inside this container."
    echo "Check the Docker socket / Codespaces Docker setup."
    exit 1
fi

echo "==> Checking KVM"

if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    echo "KVM accessible."
else
    echo "ERROR: /dev/kvm is not accessible."
    exit 1
fi

echo "==> Checking TUN"

if [ -e /dev/net/tun ]; then
    echo "/dev/net/tun exists."
else
    echo "WARNING: /dev/net/tun is missing."
fi

echo "==> Configuring SSH"

sudo mkdir -p /run/sshd
sudo ssh-keygen -A

sudo sed -i \
    's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' \
    /etc/ssh/sshd_config

sudo sed -i \
    's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' \
    /etc/ssh/sshd_config

sudo sed -i \
    's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' \
    /etc/ssh/sshd_config

echo "==> Setting root SSH key"

sudo mkdir -p /root/.ssh
sudo chmod 700 /root/.ssh

if [ -n "${SSH_AUTHORIZED_KEY:-}" ]; then
    printf '%s\n' "$SSH_AUTHORIZED_KEY" |
        sudo tee /root/.ssh/authorized_keys >/dev/null

    sudo chmod 600 /root/.ssh/authorized_keys
    echo "Root SSH key installed."
else
    echo "WARNING: SSH_AUTHORIZED_KEY is not set."
fi

echo "==> Installing NetBird"

curl -fsSL https://pkgs.netbird.io/install.sh | sudo sh

echo "==> postCreate finished."