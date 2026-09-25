#!/usr/bin/env bash
# Runs once, when the Codespace container is first created.
set -euo pipefail

echo "==> Installing Tailscale"
curl -fsSL https://tailscale.com/install.sh | sh

echo "==> postCreate finished. Tailscale will connect on start (postStart.sh)."
