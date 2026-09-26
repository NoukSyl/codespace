#!/usr/bin/env bash
set -uo pipefail

echo "==> Starting SSH"

sudo mkdir -p /run/sshd

if ! pgrep -x sshd >/dev/null 2>&1; then
    sudo /usr/sbin/sshd
fi

echo "SSH started."

echo "==> Ensuring Windows VM container is running"

if sudo docker ps --format '{{.Names}}' | grep -qx windows; then
    echo "Windows container already running."
else
    if sudo docker start windows >/dev/null 2>&1; then
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

sudo pkill -f "netbird" 2>/dev/null || true
sleep 1

echo "Starting NetBird daemon..."
sudo nohup netbird service run >/tmp/netbird-daemon.log 2>&1 &

echo "Waiting for daemon socket..."
for i in $(seq 1 15); do
    if [ -S /var/run/netbird.sock ]; then
        break
    fi
    sleep 1
done

if [ -S /var/run/netbird.sock ]; then
    echo "Daemon is up, logging in..."
    sudo netbird up \
        --setup-key "$NETBIRD_SETUP_KEY" \
        --allow-server-ssh

    sudo netbird status || true
else
    echo "WARNING: netbird daemon socket never appeared after 15s; see /tmp/netbird-daemon.log"
fi

echo "==> postStart finished."
