#!/usr/bin/env bash
# Runs every time the Codespace container starts (including resume).
set -uo pipefail

echo "==> Starting sshd"
sudo mkdir -p /run/sshd
sudo /usr/sbin/sshd
echo "==> sshd is listening on port 22"

if [ -z "${NGROK_AUTHTOKEN:-}" ]; then
  echo "!! NGROK_AUTHTOKEN is not set."
  echo "   Add it as a Codespaces secret (repo/org Settings > Secrets and variables > Codespaces)."
  echo "   Get a token at https://dashboard.ngrok.com/get-started/your-authtoken"
  echo "   Until then, run manually once the token is available:"
  echo "     ngrok config add-authtoken \$NGROK_AUTHTOKEN"
  echo "     ngrok tcp 22"
  exit 0
fi

echo "==> Configuring ngrok"
ngrok config add-authtoken "${NGROK_AUTHTOKEN}"

# Kill any stale ngrok from a previous start so we don't get a stuck port.
pkill -f "ngrok tcp 22" 2>/dev/null || true
sleep 1

echo "==> Starting ngrok TCP tunnel to port 22"
nohup ngrok tcp 22 --log=stdout > /tmp/ngrok.log 2>&1 &

# Wait for ngrok's local API to report the public tunnel address.
NGROK_URL=""
for i in $(seq 1 15); do
  NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null \
    | grep -o '"public_url":"tcp://[^"]*"' \
    | head -n1 \
    | sed -E 's/"public_url":"tcp:\/\/(.*)"/\1/')
  if [ -n "$NGROK_URL" ]; then
    break
  fi
  sleep 1
done

if [ -z "$NGROK_URL" ]; then
  echo "!! ngrok did not report a tunnel URL in time. Check /tmp/ngrok.log"
  sudo cat /tmp/ngrok.log
  exit 1
fi

HOST="${NGROK_URL%%:*}"
PORT="${NGROK_URL##*:}"

cat <<EOF

==> ngrok tunnel is up.
    Connect from any machine (with your matching private key) using:

        ssh -p ${PORT} root@${HOST}

    Note (free ngrok tier): this host:port changes every time the tunnel
    restarts. Re-run this script's output (or check /tmp/ngrok.log,
    or http://127.0.0.1:4040 while the Codespace is open) to get the
    current address each time.
EOF
