#!/usr/bin/env bash
# make-qr.sh — Start the WhatsApp bridge, wait for a pairing QR, render it to PNG.
#
# Usage:
#   bash /home/rayyan/whatsapp_bot_asst/tools/make-qr.sh
#
# Output (stdout):
#   ALREADY_PAIRED          — session exists; no QR will be emitted
#   QR_READY /tmp/wa_pairqr.png <bridge_pid>  — PNG is ready; bridge still running so you can scan
#   NO_QR_TIMEOUT           — bridge ran for 40s but no code appeared (killed)

set -euo pipefail

BRIDGE_DIR="/home/rayyan/whatsapp_bot_asst/vendor/whatsapp-mcp/whatsapp-bridge"
BRIDGE_BIN="${BRIDGE_DIR}/whatsapp-bridge"
STORE_DIR="${BRIDGE_DIR}/store"
CODE_FILE="/tmp/wa_paircode.txt"
PNG_FILE="/tmp/wa_pairqr.png"
PYTHON="/home/rayyan/whatsapp_bot_asst/tools/.venv/bin/python"
RENDER_SCRIPT="/home/rayyan/whatsapp_bot_asst/tools/render-qr.py"
TIMEOUT_SECS=40

# --- clean up stale files from a previous run ---
rm -f "$CODE_FILE" "$PNG_FILE"

# --- check for existing session (bridge won't emit a QR if already paired) ---
# The store dir with whatsapp.db and a non-empty device record = already paired.
if [[ -d "$STORE_DIR" ]]; then
    DB="${STORE_DIR}/whatsapp.db"
    if [[ -f "$DB" ]]; then
        # If the DB has device rows the bridge treats the session as active.
        ROW_COUNT=$(sqlite3 "$DB" "SELECT COUNT(*) FROM device;" 2>/dev/null || echo 0)
        if [[ "$ROW_COUNT" -gt 0 ]]; then
            echo "ALREADY_PAIRED"
            exit 0
        fi
    fi
fi

# --- start bridge in background (must cd into its dir so store/ is relative) ---
cd "$BRIDGE_DIR"
"$BRIDGE_BIN" >/tmp/wa_bridge.log 2>&1 &
BRIDGE_PID=$!

# --- poll for code file ---
ELAPSED=0
while [[ $ELAPSED -lt $TIMEOUT_SECS ]]; do
    if [[ -s "$CODE_FILE" ]]; then
        break
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

if [[ ! -s "$CODE_FILE" ]]; then
    # Timed out — kill the bridge we started
    kill "$BRIDGE_PID" 2>/dev/null || true
    echo "NO_QR_TIMEOUT"
    exit 1
fi

# --- render PNG ---
"$PYTHON" "$RENDER_SCRIPT"

echo "QR_READY ${PNG_FILE} ${BRIDGE_PID}"
echo "(Bridge PID ${BRIDGE_PID} is still running — scan the QR within ~60s to complete pairing)"
