#!/usr/bin/env bash
# Runs every time the Codespace container starts (including resume).
set -uo pipefail

echo "==> Starting tailscaled"
sudo mkdir -p /var/lib/tailscale /var/run/tailscale
sudo tailscaled \
  --state=/var/lib/tailscale/tailscaled.state \
  --socket=/var/run/tailscale/tailscaled.sock \
  >/tmp/tailscaled.log 2>&1 &
sleep 2

if [ -z "${TAILSCALE_AUTHKEY:-}" ]; then
  echo "!! TAILSCALE_AUTHKEY is not set."
  echo "   Add it as a Codespaces secret (repo/org Settings > Secrets and variables > Codespaces)"
  echo "   so this script can authenticate automatically. Until then, run manually:"
  echo "     sudo tailscale up --ssh"
  exit 0
fi

echo "==> Bringing up Tailscale (with SSH host enabled)"
sudo tailscale up \
  --authkey="${TAILSCALE_AUTHKEY}" \
  --hostname="codespace-${CODESPACE_NAME:-$(hostname)}" \
  --ssh \
  --accept-routes

echo "==> Connected. This machine's Tailscale IP:"
tailscale ip -4 || true

echo "==> SSH is available via Tailscale SSH (no keys to manage):"
echo "    ssh vscode@codespace-${CODESPACE_NAME:-$(hostname)}"
echo "    (from any device logged into the same tailnet)"
