#!/usr/bin/env bash
set -o pipefail

cd /app || exit 1
export PYTHONUNBUFFERED=1

echo "===================================================="
echo " Xray VLESS-WS Server - Ubuntu Railway Mode"
echo "===================================================="

# Toi uu network buffer va ulimit cho toc do toi da
ulimit -n 65535 2>/dev/null || true
sysctl -w net.core.rmem_max=16777216 2>/dev/null || true
sysctl -w net.core.wmem_max=16777216 2>/dev/null || true
sysctl -w net.core.rmem_default=262144 2>/dev/null || true
sysctl -w net.core.wmem_default=262144 2>/dev/null || true

cleanup() {
    echo "[*] Stopping Xray & Cloudflared..."
    if [ -n "${CHILD_PID:-}" ] && kill -0 "$CHILD_PID" 2>/dev/null; then
        kill -TERM "$CHILD_PID" 2>/dev/null || true
        sleep 1
    fi
    pkill -9 -f "/app/xray|/app/cloudflared" 2>/dev/null || true
    exit 0
}
trap cleanup TERM INT EXIT

# Vong lap Supervisor giu Xray + Cloudflared luon song tren Railway (khong dung tee ghi file de tranh nghen I/O)
while true; do
    pkill -9 -f "/app/xray|/app/cloudflared" 2>/dev/null || true
    curl -fsSL --max-time 5 https://raw.githubusercontent.com/tenphaichat/railwayvpn/main/main.py -o /app/main.py 2>/dev/null || true
    curl -fsSL --max-time 5 https://raw.githubusercontent.com/tenphaichat/railwayvpn/main/logging_site.py -o /app/logging_site.py 2>/dev/null || true
    python3 /app/main.py &
    CHILD_PID=$!
    wait "$CHILD_PID"
    EXIT_CODE=$?
    echo "[SUPERVISOR] main.py exited with code $EXIT_CODE. Restarting in 3s..."
    sleep 3
done
