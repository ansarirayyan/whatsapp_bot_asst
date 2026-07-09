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

## Security reminders

- `vendor/` is gitignored — the upstream code and all build artifacts **never land in the public repo**.
- The session DBs (`store/`) contain your WhatsApp auth credentials — they are also gitignored.
- This bridge has access to your personal WhatsApp. Follow the [lethal trifecta](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/) caution in the upstream README.
