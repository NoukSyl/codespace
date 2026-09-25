#!/usr/bin/env bash
# Runs once when the Codespace container is first created.
set -euo pipefail

echo "==> Installing / verifying SSH"

# openssh is installed by the Dockerfile.
ssh-keygen -A

echo "==> Configuring sshd"

sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' \
    /etc/ssh/sshd_config

sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' \
    /etc/ssh/sshd_config

sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' \
    /etc/ssh/sshd_config

grep -q '^PermitRootLogin ' /etc/ssh/sshd_config || \
    echo 'PermitRootLogin prohibit-password' >> /etc/ssh/sshd_config

grep -q '^PasswordAuthentication ' /etc/ssh/sshd_config || \
    echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config

grep -q '^PubkeyAuthentication ' /etc/ssh/sshd_config || \
    echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config

echo "==> Setting up authorized_keys for root"

mkdir -p /root/.ssh
chmod 700 /root/.ssh

if [ -n "${SSH_AUTHORIZED_KEY:-}" ]; then
    printf '%s\n' "${SSH_AUTHORIZED_KEY}" > /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo "Root authorized_keys installed."
else
    echo "!! WARNING: SSH_AUTHORIZED_KEY is not set."
    echo "   Add your public key as the Codespaces secret:"
    echo "   SSH_AUTHORIZED_KEY"
fi

echo "==> Installing NetBird"

curl -fsSL https://pkgs.netbird.io/install.sh | sh

echo "==> Checking Docker CLI"

docker --version

echo "==> Checking Docker daemon connection"

if docker info >/dev/null 2>&1; then
    echo "Docker daemon is reachable."
else
    echo "!! Docker daemon is not reachable."
    echo "   This container does NOT start its own dockerd."
fi

echo "==> Checking KVM"

if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    echo "KVM accessible."
else
    echo "!! /dev/kvm is not accessible."
fi

echo "==> Checking TUN"

if [ -e /dev/net/tun ]; then
    echo "/dev/net/tun exists."
else
    echo "!! /dev/net/tun is missing."
fi

echo "==> postCreate finished."