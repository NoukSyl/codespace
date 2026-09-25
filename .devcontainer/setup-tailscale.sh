#!/usr/bin/env bash
# Installs and connects Tailscale on the Codespace's own root filesystem
# (NOT inside the Windows QEMU/docker container). This gives the Codespace
# itself a Tailscale IP, which you can use to reach the VNC server
# published by docker on port 5900 -- e.g. <tailscale-ip>:5900.
set -euo pipefail

# Skip automatically if not running inside a GitHub Codespace.
if [ -z "${CODESPACES:-}" ]; then
  echo "[tailscale] Not inside a GitHub Codespace, skipping."
  exit 0
fi

# Skip if Tailscale is already up (e.g. Codespace was just restarted/rebuilt
# and a previous session is still authenticated).
if command -v tailscale >/dev/null 2>&1 && tailscale status >/dev/null 2>&1; then
  echo "[tailscale] Already running."
  tailscale ip -4 || true
  exit 0
fi

# Install Tailscale if it isn't present yet.
if ! command -v tailscale >/dev/null 2>&1; then
  echo "[tailscale] Installing..."
  curl -fsSL https://tailscale.com/install.sh | sudo sh
fi

# Start the daemon (tailscaled). Codespaces containers are privileged and
# have /dev/net/tun, matching what codespaces.yml already grants the
# Windows container, so the normal (non-userspace) networking mode should
# work. If /dev/net/tun is unexpectedly unavailable, fall back automatically.
if [ -e /dev/net/tun ]; then
  sudo tailscaled >/tmp/tailscaled.log 2>&1 &
else
  echo "[tailscale] /dev/net/tun not available, falling back to userspace-networking mode."
  sudo tailscaled --tun=userspace-networking >/tmp/tailscaled.log 2>&1 &
fi
disown
sleep 2

# Prompt for the auth key interactively. This only works if you attach to
# an interactive shell (e.g. this script is run from the Codespace's
# terminal via postStartCommand in an interactive session, or you run it
# manually with: bash .devcontainer/setup-tailscale.sh
echo ""
echo "=== Tailscale setup ==="
echo "Paste a Tailscale auth key (from https://login.tailscale.com/admin/settings/keys)."
read -r -p "Auth key (leave blank to skip / use browser login instead): " TS_AUTHKEY

if [ -n "$TS_AUTHKEY" ]; then
  sudo tailscale up --authkey="$TS_AUTHKEY" --hostname="codespace-$(hostname)" --accept-routes
else
  echo "[tailscale] No key entered, starting interactive browser login instead."
  sudo tailscale up --hostname="codespace-$(hostname)" --accept-routes
fi

echo ""
echo "[tailscale] Connected. Tailscale IP:"
tailscale ip -4

echo ""
echo "Connect your VNC client directly to: $(tailscale ip -4):5900"
