# WhatsApp Bot / Group-Observer Assistant

**Generated:** July 8, 2026

> A personal assistant that sits in WhatsApp group chats, reads conversations,
> and lets you ask Claude to summarize, catch up, or answer questions about
> what's being discussed. Mostly observe; very low send volume.

---

## BAN-RISK WARNING — Read This First

This project uses an **unofficial** WhatsApp client library.
Unofficial clients violate WhatsApp's Terms of Service.

- Observe-heavy bots: estimated <2% ban rate over 12 months (based on 2026 community data)
- Proactive/sending bots: estimated 15–30% ban rate over 12 months
- Risk cannot be eliminated — only reduced through disciplined behavior
- The official WhatsApp Cloud/Business API cannot join arbitrary group chats; it is unsuitable for this use case
- Use a **dedicated SIM-based number** (not VoIP) that you never use as your primary WhatsApp
- Warm up the number for 2–4 weeks before connecting it to the bot

See `docs/RESEARCH.md` for the full ban-avoidance analysis.

---

## Chosen Stack

| Component | Choice | Rationale |
|---|---|---|
| WhatsApp bridge | **whatsmeow** (Go) | Battle-tested, 6.7k stars, active commits, native multi-device, used by lharries/whatsapp-mcp |
| Message store | **SQLite** | Local, private, fast for search |
| MCP server | **Python** (lharries/whatsapp-mcp pattern) | Exposes read/search tools to Claude |
| AI assistant | **Claude** (via MCP) | Reads message store, answers questions about group conversations |
| Auth | QR-code pairing (multi-device) | One-time scan on phone; persists across sessions |

**Foundation**: Build on or closely follow [lharries/whatsapp-mcp](https://github.com/lharries/whatsapp-mcp) —
a Go bridge + Python MCP server that already implements exactly this architecture.

---

## Architecture Overview

```
Dedicated WhatsApp Number
        |
        | (QR code pairing / multi-device)
        v
  Go WhatsApp Bridge (whatsmeow)
        |  listens to all messages in joined groups
        v
  SQLite Message Store (local)
        |
        v
  Python MCP Server
        |  tools: list_chats, list_messages, search_contacts,
        |          get_message_context, summarize (via Claude)
        v
  Claude (MCP client — Claude Desktop or Claude Code)
```

See `docs/ARCHITECTURE.md` for the full Mermaid + ASCII diagram with component responsibilities.

---

## Quickstart (Placeholder)

> Full setup instructions will be added once the implementation is underway.

### Prerequisites

- Go 1.21+
- Python 3.10+
- A dedicated WhatsApp number (real SIM, NOT VoIP)
- Claude Desktop or Claude Code (for MCP client)

### Steps

1. Clone this repo
2. Build the Go bridge: `cd whatsapp-bridge && go build .`
3. Start the bridge; scan the QR code with your dedicated WhatsApp number
4. Configure and start the Python MCP server
5. Point your Claude client at the MCP server
6. Ask Claude to summarize a group chat

---

## Privacy Note

All messages are stored **locally** in SQLite. They are only sent to Claude
(Anthropic's API) when you explicitly invoke an MCP tool. Nothing is stored in
the cloud by this project.

---

## License

Personal/private project. Not affiliated with WhatsApp or Meta.
