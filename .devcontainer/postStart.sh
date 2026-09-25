#!/usr/bin/env bash
# Runs every time the Codespace container starts.
set -uo pipefail

echo "==> Starting sshd"

mkdir -p /run/sshd
/usr/sbin/sshd

echo "==> sshd is listening on port 22"

if [ -z "${NETBIRD_SETUP_KEY:-}" ]; then
    echo "!! NETBIRD_SETUP_KEY is not set."
    echo "   Add it as a Codespaces secret."
    exit 0
fi

# Remove stale NetBird foreground processes.
pkill -f "netbird up" 2>/dev/null || true
sleep 1

echo "==> Starting NetBird"

MGMT_FLAG=()

if [ -n "${NETBIRD_MANAGEMENT_URL:-}" ]; then
    MGMT_FLAG=(
        --management-url
        "${NETBIRD_MANAGEMENT_URL}"
    )
fi

nohup netbird up \
    --setup-key "${NETBIRD_SETUP_KEY}" \
    "${MGMT_FLAG[@]}" \
    --foreground-mode \
    --allow-server-ssh \
    > /tmp/netbird.log 2>&1 &

echo "==> Waiting for NetBird"

NB_IP=""

for i in $(seq 1 20); do
    NB_IP=$(
        netbird status 2>/dev/null |
        grep -o 'NetBird IP: [0-9.]*' |
        head -n1 |
        cut -d' ' -f3
    )

    if [ -n "$NB_IP" ]; then
        break
    fi

    sleep 1
done

if [ -z "$NB_IP" ]; then
    echo "!! NetBird did not report an IP."
    echo "==> NetBird log:"
    cat /tmp/netbird.log
    exit 1
fi

cat <<EOF

==> NetBird is up.

    NetBird IP: ${NB_IP}

    SSH:
        ssh root@${NB_IP}

EOF