#!/usr/bin/env bash
# Runs every time the Codespace container starts (including resume).
set -uo pipefail

echo "==> Starting sshd"
sudo mkdir -p /run/sshd
sudo /usr/sbin/sshd
echo "==> sshd is listening on port 22"

if [ -z "${NETBIRD_SETUP_KEY:-}" ]; then
  echo "!! NETBIRD_SETUP_KEY is not set."
  echo "   Add it as a Codespaces secret (repo/org Settings > Secrets and variables > Codespaces)."
  echo "   Create a setup key from your NetBird dashboard: Team > Setup Keys."
  echo "   Until then, run manually once the key is available:"
  echo "     sudo netbird up --setup-key \$NETBIRD_SETUP_KEY --foreground-mode &"
  exit 0
fi

# Kill any stale netbird client from a previous start so we don't get stuck state.
sudo pkill -f "netbird up" 2>/dev/null || true
sleep 1

echo "==> Starting NetBird and joining the network"
MGMT_FLAG=()
if [ -n "${NETBIRD_MANAGEMENT_URL:-}" ]; then
  MGMT_FLAG=(--management-url "${NETBIRD_MANAGEMENT_URL}")
fi

# This container has no systemd, so instead of the usual background daemon
# mode, --foreground-mode runs the whole NetBird client as one plain process,
# which we then push into the background ourselves with nohup/&.
sudo nohup netbird up --setup-key "${NETBIRD_SETUP_KEY}" "${MGMT_FLAG[@]}" \
  --foreground-mode --allow-server-ssh > /tmp/netbird.log 2>&1 &

# Wait for NetBird to finish registering and report its assigned IP.
NB_IP=""
for i in $(seq 1 20); do
  NB_IP=$(sudo netbird status 2>/dev/null | grep -o 'NetBird IP: [0-9.]*' | head -n1 | cut -d' ' -f3)
  if [ -n "$NB_IP" ]; then
    break
  fi
  sleep 1
done

if [ -z "$NB_IP" ]; then
  echo "!! NetBird did not report an IP in time. Check /tmp/netbird.log"
  sudo cat /tmp/netbird.log
  exit 1
fi

cat <<EOF

==> NetBird is up. This peer's NetBird IP: ${NB_IP}

    Connect from any machine that is ALSO joined to this same NetBird
    network (with your matching private key) using:

        ssh root@${NB_IP}

    Unlike ngrok, there is no public tunnel URL. The connecting machine
    must have the NetBird client installed and logged into this same
    network (netbird up --setup-key ...) before it can reach this address,
    and that address stays the same across restarts.
EOF
