#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

echo "=== Windows-in-Docker + Tailscale setup ==="
echo

ENV_FILE=".env"

# --- Get the Tailscale auth key ---------------------------------------

existing_key=""
if [ -f "$ENV_FILE" ]; then
  existing_key=$(grep -E '^TS_AUTHKEY=' "$ENV_FILE" 2>/dev/null | cut -d'=' -f2- || true)
fi

if [ -n "$existing_key" ] && [ "$existing_key" != "tskey-auth-xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxx" ]; then
  echo "พบ TS_AUTHKEY เดิมใน .env อยู่แล้ว"
  read -r -p "ต้องการใช้ key เดิม หรือใส่ใหม่? [ใช้เดิม/ใหม่] (Enter = ใช้เดิม): " choice
  if [[ "${choice,,}" == "ใหม่" || "${choice,,}" == "new" ]]; then
    existing_key=""
  fi
fi

if [ -z "$existing_key" ]; then
  echo "ขอ Tailscale auth key (สร้างได้ที่ https://login.tailscale.com/admin/settings/keys)"
  echo "แนะนำ: ติ๊ก Reusable และไม่ติ๊ก Ephemeral เพื่อให้เครื่องไม่หลุดออกจาก tailnet ทุกครั้งที่ restart"
  # -s hides input since this is a secret
  read -r -s -p "TS_AUTHKEY: " ts_authkey
  echo
  if [ -z "$ts_authkey" ]; then
    echo "ไม่ได้ใส่ key — ยกเลิก" >&2
    exit 1
  fi
else
  ts_authkey="$existing_key"
fi

cat > "$ENV_FILE" << EOF
TS_AUTHKEY=${ts_authkey}
EOF
echo "บันทึก .env แล้ว"
echo

# --- Bring the stack up -------------------------------------------------

echo "กำลังรัน docker compose up -d ..."
docker compose up -d

echo
echo "รอ Tailscale เชื่อมต่อ (ไม่เกิน ~60 วินาที)..."

ts_ip=""
for i in $(seq 1 30); do
  sleep 2
  ts_ip=$(docker exec windows-tailscale tailscale ip -4 2>/dev/null || true)
  if [ -n "$ts_ip" ]; then
    break
  fi
done

echo
if [ -n "$ts_ip" ]; then
  echo "=== พร้อมใช้งาน ==="
  echo "Tailscale IP ของเครื่อง Windows: $ts_ip"
  echo
  echo "เชื่อมต่อโดยตรงผ่าน VNC client (ไม่ผ่าน noVNC):"
  echo "  ${ts_ip}:5900"
  echo
  echo "หรือผ่าน RDP:"
  echo "  ${ts_ip}:3389"
  echo
  echo "ดู log เพิ่มเติม: docker compose logs -f tailscale"
  echo "ดู log ของ Windows VM: docker compose logs -f windows"
else
  echo "ยังไม่เห็น Tailscale IP ภายในเวลาที่กำหนด"
  echo "เช็ค log ด้วย: docker compose logs tailscale"
  echo "สาเหตุที่พบบ่อย: auth key หมดอายุ/ถูกใช้ไปแล้ว หรือ key ผิด"
fi
