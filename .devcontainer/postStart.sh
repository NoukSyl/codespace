#!/usr/bin/env bash
set -uo pipefail

echo "==> Starting SSH"

sudo mkdir -p /run/sshd

if ! pgrep -x sshd >/dev/null 2>&1; then
    sudo /usr/sbin/sshd
fi

echo "SSH started."

echo "==> Ensuring Windows VM container is running"

if docker ps --format '{{.Names}}' | grep -qx windows; then
    echo "Windows container already running."
else
    if docker start windows >/dev/null 2>&1; then
        echo "Windows container started."
    else
        echo "WARNING: could not start 'windows' container (was postCreate.sh run?)."
    fi
fi

echo "==> Starting NetBird"

if [ -z "${NETBIRD_SETUP_KEY:-}" ]; then
    echo "WARNING: NETBIRD_SETUP_KEY is not set."
    exit 0
fi

sudo pkill -f "netbird up" 2>/dev/null || true
sleep 1

sudo nohup netbird up \
    --setup-key "$NETBIRD_SETUP_KEY" \
    --foreground-mode \
    --allow-server-ssh \
    >/tmp/netbird.log 2>&1 &

sleep 5

sudo netbird status || true

echo "==> postStart finished."
