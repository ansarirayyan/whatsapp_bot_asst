# WhatsApp MCP Bridge — Setup Guide

**Generated:** July 9, 2026 at 12:25 AM PT
**Status:** Build complete; awaiting first QR scan

---

## Overview

This project uses [lharries/whatsapp-mcp](https://github.com/lharries/whatsapp-mcp) — a Go whatsmeow bridge + Python MCP server. The upstream code is vendored locally at `vendor/whatsapp-mcp/` (gitignored — never committed to the public repo).

---

## Prerequisites (installed user-local, no sudo)

| Tool | Version | Location |
|------|---------|----------|
| Go | go1.26.5 linux/amd64 | `~/.local/go/bin/go` |
| uv | 0.11.28 | `~/.local/bin/uv` |
| gcc | 14.2.0 (system) | `/usr/bin/gcc` — required for go-sqlite3 CGO |

---

## First-time rebuild steps

If `vendor/` is missing (fresh clone), re-run from scratch:

```bash
# 1. Re-vendor upstream
git clone https://github.com/lharries/whatsapp-mcp.git vendor/whatsapp-mcp

# 2. Build the Go bridge (CGO required — gcc must be on PATH)
export PATH="$HOME/.local/go/bin:$PATH"
cd vendor/whatsapp-mcp/whatsapp-bridge
go build -o whatsapp-bridge .

# 3. Install Python MCP deps
export PATH="$HOME/.local/bin:$PATH"
cd ../whatsapp-mcp-server
uv sync
```

---

## Built artifact locations

| Artifact | Path |
|----------|------|
| Go bridge binary | `vendor/whatsapp-mcp/whatsapp-bridge/whatsapp-bridge` (24 MB ELF) |
| Python venv | `vendor/whatsapp-mcp/whatsapp-mcp-server/.venv/` |
| Session / message DBs | `vendor/whatsapp-mcp/whatsapp-bridge/store/` (created at runtime) |

All of the above are gitignored. **Never commit them.**

---

## Step 1 — Get the pairing QR (manual, needs phone)

The bridge must run from its own directory so it writes the SQLite session files to `./store/` (relative to CWD).

```bash
cd /home/rayyan/whatsapp_bot_asst/vendor/whatsapp-mcp/whatsapp-bridge
./whatsapp-bridge
```

On first run (no existing session), the bridge will:
1. Create `store/whatsapp.db` (whatsmeow session) and `store/messages.db`
2. Print a **full ASCII half-block QR code** to the terminal via `qrterminal.GenerateHalfBlock(...)`
3. Wait up to **3 minutes** for the QR to be scanned
4. On success, print `Successfully connected and authenticated!` and start the REST server on `:8080`

**The QR is ASCII art rendered with Unicode half-block characters** (▄/▀). Scan it with the WhatsApp mobile app: Settings > Linked Devices > Link a Device.

> IMPORTANT: The phone number/account you link must already have an active WhatsApp account on a physical phone. The number is the "identity" of the bot — messages it sends appear from that number.

On subsequent runs (session exists), the bridge reconnects silently — no QR shown.

---

## Step 2 — Run the Python MCP server (parallel to bridge)

The MCP server talks to the bridge's REST API on `localhost:8080`. Both must be running.

```bash
# In a second terminal, keep this running alongside the bridge:
/home/rayyan/.local/bin/uv \
  --directory /home/rayyan/whatsapp_bot_asst/vendor/whatsapp-mcp/whatsapp-mcp-server \
  run main.py
```

---

## Step 3 — Register with Claude Code

Run once to register the MCP server:

```bash
claude mcp add whatsapp -- \
  /home/rayyan/.local/bin/uv \
  --directory /home/rayyan/whatsapp_bot_asst/vendor/whatsapp-mcp/whatsapp-mcp-server \
  run main.py
```

Or add the following JSON block to your project `.mcp.json`:

```json
{
  "mcpServers": {
    "whatsapp": {
      "command": "/home/rayyan/.local/bin/uv",
      "args": [
        "--directory",
        "/home/rayyan/whatsapp_bot_asst/vendor/whatsapp-mcp/whatsapp-mcp-server",
        "run",
        "main.py"
      ]
    }
  }
}
```

---

## Available MCP tools (once connected)

`search_contacts`, `list_messages`, `list_chats`, `get_chat`, `get_direct_chat_by_contact`, `get_contact_chats`, `get_last_interaction`, `get_message_context`, `send_message`, `send_file`, `send_audio_message`, `download_media`

---

## Troubleshooting

- **QR not displaying**: terminal must support Unicode. If running over SSH, use a modern terminal emulator.
- **Re-pair after session expiry** (~20 days): delete `store/whatsapp.db` and restart the bridge — a new QR will appear.
- **Out-of-sync messages**: delete both `store/messages.db` and `store/whatsapp.db`, restart bridge, re-scan QR.
- **Device limit**: WhatsApp allows ~4 linked devices. Remove old ones in Settings > Linked Devices on your phone.
- **FFmpeg (optional)**: only needed to auto-convert non-Opus audio to `.ogg` for voice messages. Install with `apt install ffmpeg` if sudo becomes available.

---

## Ban-avoidance environment variables

These env vars control the ban-avoidance behavioural reducers baked into our
local `main.go` patch (see `patches/whatsapp-bridge-main.patch`).

### Outbound send throttle

All values are in **milliseconds**. The defaults are active when the variables
are absent; set all three to `0` to bypass throttling entirely.

| Variable | Default | Purpose |
|---|---|---|
| `WA_SEND_MIN_MS` | `1500` | Lower bound of the per-send random delay |
| `WA_SEND_MAX_MS` | `5000` | Upper bound of the per-send random delay |
| `WA_SEND_GAP_MS` | `1200` | Minimum wall-clock gap between any two consecutive sends |

Before every outbound `client.SendMessage` call the bridge:
1. Waits until at least `WA_SEND_GAP_MS` ms have elapsed since the last send.
2. Sleeps an additional random duration uniformly drawn from
   `[WA_SEND_MIN_MS, WA_SEND_MAX_MS]`.

A global mutex serialises all senders so concurrent callers queue rather than
race.

### Reactive-only mode

| Variable | Default | Values |
|---|---|---|
| `WA_REACTIVE_ONLY` | _(unset = off)_ | `true` or `1` to enable |

When enabled, the `/api/send` handler queries the local `messages.db` SQLite
store for any inbound message (`is_from_me = 0`) from the target JID **before**
sending. If no inbound message exists (i.e. the contact has never messaged us),
the send is refused with HTTP 403 and a JSON error body:

```json
{"success":false,"message":"WA_REACTIVE_ONLY is enabled: <jid> has not messaged us first — cold sends are blocked"}
```

This is **store-backed** — it survives bridge restarts. On a DB error the gate
fails open (logs a warning, allows the send) rather than silently dropping
messages.

Default is **off** so existing integrations are unaffected.

### Example launch with all flags set

```bash
export WA_SEND_MIN_MS=2000
export WA_SEND_MAX_MS=6000
export WA_SEND_GAP_MS=1500
export WA_REACTIVE_ONLY=true

cd /home/rayyan/whatsapp_bot_asst/vendor/whatsapp-mcp/whatsapp-bridge
./whatsapp-bridge
```

### Reconnect behaviour (no env var needed)

whatsmeow's built-in auto-reconnect is on by default (`EnableAutoReconnect=true`).
On disconnection it backs off `N × 2 s` (linear, starts at 2 s) before each
retry — no storm risk. Our code calls `client.Connect()` exactly once; there is
no manual reconnect loop.

---

## Security reminders

- `vendor/` is gitignored — the upstream code and all build artifacts **never land in the public repo**.
- The session DBs (`store/`) contain your WhatsApp auth credentials — they are also gitignored.
- This bridge has access to your personal WhatsApp. Follow the [lethal trifecta](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/) caution in the upstream README.
