#!/usr/bin/env bash
# Runs every time the Codespace container starts (including resume).
set -uo pipefail

TS_SOCK=/var/run/tailscale/tailscaled.sock
TS_STATE=/var/lib/tailscale/tailscaled.state

echo "==> Starting tailscaled"
sudo mkdir -p /var/lib/tailscale /var/run/tailscale

# Only start it if it isn't already running from a previous resume.
if ! sudo test -S "$TS_SOCK"; then
  sudo tailscaled \
    --state="$TS_STATE" \
    --socket="$TS_SOCK" \
    >/tmp/tailscaled.log 2>&1 &

  # Wait (up to 15s) for the socket to actually appear instead of a fixed sleep.
  for i in $(seq 1 15); do
    if sudo test -S "$TS_SOCK"; then
      break
    fi
    sleep 1
  done

  if ! sudo test -S "$TS_SOCK"; then
    echo "!! tailscaled failed to start. Log:"
    sudo cat /tmp/tailscaled.log
    exit 1
  fi
fi
echo "==> tailscaled is running"

if [ -z "${TAILSCALE_AUTHKEY:-}" ]; then
  echo "!! TAILSCALE_AUTHKEY is not set."
  echo "   Add it as a Codespaces secret (repo/org Settings > Secrets and variables > Codespaces)"
  echo "   so this script can authenticate automatically. Until then, run manually:"
  echo "     sudo tailscale up --ssh"
  exit 0
fi

echo "==> Bringing up Tailscale (with SSH host enabled)"
if ! sudo tailscale up \
  --authkey="${TAILSCALE_AUTHKEY}" \
  --hostname="codespace-${CODESPACE_NAME:-$(hostname)}" \
  --ssh \
  --accept-routes; then
  echo "!! 'tailscale up' failed. Check the authkey (expired/already used/invalid) and try:"
  echo "     sudo tailscale up --ssh"
  exit 1
fi

echo "==> Connected. This machine's Tailscale IP:"
if ! tailscale ip -4; then
  echo "!! Could not read Tailscale IP even though 'tailscale up' reported success."
  exit 1
fi

echo "==> SSH is available via Tailscale SSH (no keys to manage):"
echo "    ssh vscode@codespace-${CODESPACE_NAME:-$(hostname)}"
echo "    (from any device logged into the same tailnet)"
