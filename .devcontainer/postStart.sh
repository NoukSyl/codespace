#!/usr/bin/env bash
set -uo pipefail

echo "==> Starting SSH"

sudo mkdir -p /run/sshd

if ! pgrep -x sshd >/dev/null 2>&1; then
    sudo /usr/sbin/sshd
fi

echo "SSH started."

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