#!/usr/bin/env bash
set -euo pipefail

echo "==> Checking Docker CLI"
docker --version

echo "==> Checking Docker daemon"
if docker info >/dev/null 2>&1; then
    echo "Docker daemon is reachable."
else
    echo "ERROR: Docker daemon is NOT reachable."
    echo "Check the docker-outside-of-docker feature / Codespaces Docker setup."
    exit 1
fi

echo "==> Checking KVM on host (via a throwaway container)"
if docker run --rm --device=/dev/kvm alpine sh -c 'test -r /dev/kvm && test -w /dev/kvm' >/dev/null 2>&1; then
    echo "KVM accessible."
else
    echo "ERROR: /dev/kvm is not accessible from the host Docker daemon."
    echo "This Codespaces machine type may not support nested virtualization."
    exit 1
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

echo "==> Starting Windows VM container (dockurr/windows)"

docker rm -f windows >/dev/null 2>&1 || true

docker run -d \
    --name windows \
    --restart always \
    --device=/dev/kvm \
    --device=/dev/net/tun \
    --cap-add NET_ADMIN \
    -p 8006:8006 \
    -p 3389:3389/tcp \
    -p 3389:3389/udp \
    -v windows-data:/storage \
    -e VERSION="11" \
    -e RAM_SIZE="4G" \
    -e CPU_CORES="2" \
    -e DISK_SIZE="64G" \
    --stop-timeout 120 \
    dockurr/windows

echo "==> postCreate finished."
echo "Open the forwarded port 8006 to watch the Windows install; RDP will be on 3389 once it's done."
