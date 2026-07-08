# WhatsApp Bot / MCP — Research Report

**Generated:** July 8, 2026
**Status:** Initial landscape research

---

## 1. Official WhatsApp Cloud API / Business API — Can It Observe Group Chats?

**Short answer: No, not for arbitrary group chats. The official API is disqualified for this use case.**

### What the official API offers (2026)

Meta introduced a Groups API for WhatsApp Business Platform in early 2026. However, it has severe constraints:

- Requires an **Official Business Account (OBA) with a verified green tick**
- Only available to businesses with **100,000+ monthly business-initiated conversations** — an enterprise-tier gate
- Groups are **business-created only** (max 8 participants per group)
- Only **1 Cloud API business account** per group is permitted
- There is **no capability to join or observe arbitrary pre-existing group chats** — the API manages groups the business creates itself
- Participants join via invite links sent by the business; the API cannot autonomously discover or join external groups

**Source:** [Meta for Developers — Groups API](https://developers.facebook.com/documentation/business-messaging/whatsapp/groups)  
**Source:** [WhatsApp Groups API 2026 Guide — WUSeller](https://www.wuseller.com/whatsapp-business-knowledge-hub/whatsapp-groups-api-create-manage-groups-2026-guide/)

**Verdict:** The official API is a business↔customer messaging channel. It cannot lurk in a friend/work group chat as an observer participant. For this use case, an unofficial client is the only viable path.

---

## 2. Unofficial Library Comparison (2026)

Three leading options for a personal WhatsApp client that connects via the multi-device protocol:

### Comparison Table

| Library | Language | Stars (Jul 2026) | Forks | Last Release | Protocol | Browser needed? | License |
|---|---|---|---|---|---|---|---|
| **Baileys** (`@whiskeysockets/baileys`) | TypeScript / Node.js | **10.1k** | 3.2k | v7.0.0-rc13 (May 21 2026) | Multi-device WebSocket | No | Apache-2.0 |
| **whatsapp-web.js** | JavaScript / Node.js | ~25k (older, more stars but Puppeteer-based) | high | Active but slower pace | Multi-device via headless browser | **Yes (Puppeteer)** | Apache-2.0 |
| **whatsmeow** | Go | **6.7k** | 1.1k | No formal releases; 1,602+ commits | Multi-device (native) | No | MPL-2.0 |

Sources:
- [Baileys GitHub](https://github.com/whiskeysockets/Baileys)
- [whatsmeow GitHub](https://github.com/tulir/whatsmeow)
- [Baileys vs whatsapp-web.js comparison 2026](https://baileys.wiki/docs/intro/)

### Analysis

**Baileys (TypeScript, @whiskeysockets/baileys)**
- Most recently released: v7.0.0-rc13, May 21 2026 — actively maintained
- 4.4k dependent projects; large community
- Lightweight: pure WebSocket, no browser overhead
- Native multi-device support
- Enterprise support available from maintainer (Rajeh Taher / WhiskeySockets)
- TypeScript-native — good type safety
- Con: API can break with WhatsApp protocol changes; upstream updates needed

**whatsapp-web.js**
- Most GitHub stars overall, but uses Puppeteer (headless Chrome)
- Puppeteer adds memory/CPU overhead and an extra layer that can break
- Good for small bots; less scalable than Baileys
- Less suited for a persistent always-on observer

**whatsmeow (Go)**
- Lower-level, very stable, used in production systems
- No formal versioned releases (but 1,600+ commits on main = very active)
- MPL-2.0 license (copyleft for modifications to the library itself)
- Used by the most mature WhatsApp MCP project (lharries/whatsapp-mcp)
- Requires Go knowledge; less accessible if Node.js is the preference
- Best choice if building a long-running daemon bridge (low memory, no Node runtime)

**Recommendation for this use case:**

Use **whatsmeow (Go)** as the WhatsApp bridge if building on `lharries/whatsapp-mcp` (which already uses it), or use **Baileys** if building a TypeScript-only stack. Both are active and production-ready. Avoid whatsapp-web.js for an always-on observer (Puppeteer overhead, worse reliability for persistent connections).

---

## 3. Existing "WhatsApp MCP" Projects

### lharries/whatsapp-mcp (Primary Recommendation)

**URL:** https://github.com/lharries/whatsapp-mcp

This project is almost exactly what is needed. It is a mature, two-component system:

- **Go WhatsApp Bridge** (`whatsapp-bridge/`): Uses whatsmeow to connect via multi-device protocol. Handles QR-code authentication (scan once on phone). Stores all received messages in SQLite.
- **Python MCP Server** (`whatsapp-mcp-server/`): Implements the Model Context Protocol, exposing tools Claude can call.

**MCP tools exposed:**
- `search_contacts` — find contacts by name/number
- `list_chats` — see all active chats
- `get_chat` — get details of a specific chat (including groups)
- `list_messages` — paginated message history for a chat
- `get_message_context` — messages before/after a specific message
- `get_last_interaction` — last activity in a chat
- `send_message` — send text (optional; raises ban risk slightly)
- `send_file`, `send_audio_message` — send media
- `download_media` — retrieve received media to local filesystem

**Auth:** QR code pairing, persists until session expires (~20 days, then re-scan needed)

**Verdict:** Build on this directly. Fork it, configure it for the dedicated number, disable or restrict `send_message` to reduce outbound volume.

**Privacy caveat (from README):** Messages are stored locally, but are sent to Claude's API when a tool is invoked. Accept this tradeoff explicitly.

---

### jlucaso1/whatsapp-mcp-ts (TypeScript Alternative)

**URL:** https://github.com/jlucaso1/whatsapp-mcp-ts

- Uses **Baileys** instead of whatsmeow
- TypeScript throughout (no Go bridge)
- 67 stars, newer project, fewer integrations
- Same MCP tool surface (list_chats, list_messages, send_message, etc.)

**Verdict:** A viable pure-TypeScript alternative if the Go bridge is a problem. Less battle-tested than lharries/whatsapp-mcp.

---

## 4. Ban Avoidance — The Crux

### The Fundamental Tension

| Path | Ban Risk | Group Lurking |
|---|---|---|
| Official WhatsApp Cloud API | Zero | No — impossible |
| Unofficial client (Baileys / whatsmeow) | Real but manageable | Yes |

There is no zero-risk path that also allows observing arbitrary group chats. Accept this tradeoff explicitly before proceeding.

### What the Data Says (2026)

From analysis of 50+ real cases (source: [Achiya Automation 2026 report](https://achiya-automation.com/en/blog/whatsapp-spam-detection-2026/)):

- **Observe-heavy / reactive-only bots:** <2% ban rate over 12 months
- **Proactive sending bots (high volume):** 15–30% ban rate over 12 months
- WhatsApp bans ~8 million accounts globally per month (mostly spam)
- The detection system targets **behavior**, not connection method

**This use case (mostly observe, very low outbound) sits in the <2% risk bucket if mitigations are followed.**

### Concrete Mitigations

**Number selection (critical):**
- Use a **real SIM-based number** — VoIP numbers (Google Voice, Twilio, etc.) get "extra scrutiny" at registration and are flagged more aggressively
- NEVER use your primary personal number
- Register the dedicated number normally in the WhatsApp app first

**Warm-up period (do this before connecting the bot):**
- Days 1–2: Add 5–10 real contacts, send 10–20 normal messages
- Days 3–7: Build up to 20–30 message exchanges, keep activity human-paced
- Weeks 2–4: Use normally; join a few groups manually from the phone
- Wait at least 3–4 weeks before connecting the bot
- Source: [WhatsApp warm-up guide — WaDeskio](https://warmer.wadesk.io/blog/whatsapp-account-warm-up)

**Bot behavior:**
- Run the bridge **persistently** (one long-running session) — rapid connect/disconnect cycles are flagged
- Keep outbound messages extremely low; aim for >30% reply rate if sending at all
- Never send to unknown contacts; never broadcast identical messages
- Keep the number active at human pace
- Do not exceed ~60 messages/hour if sending; stay well below that

**Specific 2026 detection signals:**
- Reply rate below 15% → ban risk
- >60 outbound messages/hour → flagged
- Block rate over 2% → quality drops to "Low"
- Identical messages sent >15 times/hour → pattern flagged
- Session patterns from rapid API reconnects → flagged

**The honest bottom line:**
For an observe-heavy assistant (joined to groups, reads everything, rarely sends), the risk is real but low — estimated <2%/year. The main risk vectors are: (1) a fresh number that wasn't warmed up, (2) connecting via VoIP, (3) accidentally triggering high outbound volume. None of these are hard to avoid with discipline.

---

## Sources

1. [Meta for Developers — WhatsApp Groups API](https://developers.facebook.com/documentation/business-messaging/whatsapp/groups)
2. [WhatsApp Groups API 2026 Guide — WUSeller](https://www.wuseller.com/whatsapp-business-knowledge-hub/whatsapp-groups-api-create-manage-groups-2026-guide/)
3. [WhatsApp API 2026 Updates — Woztell](https://woztell.com/whatsapp-api-2026-updates-pacing-limits-usernames/)
4. [Baileys GitHub — @whiskeysockets/baileys](https://github.com/whiskeysockets/Baileys)
5. [whatsmeow GitHub — tulir/whatsmeow](https://github.com/tulir/whatsmeow)
6. [Baileys introduction / docs](https://baileys.wiki/docs/intro/)
7. [lharries/whatsapp-mcp GitHub](https://github.com/lharries/whatsapp-mcp)
8. [jlucaso1/whatsapp-mcp-ts GitHub](https://github.com/jlucaso1/whatsapp-mcp-ts)
9. [WhatsApp Unofficial API Ban Risk — Wapisimo](https://wapisimo.dev/blog/en/whatsapp-unofficial-api-ban-risk)
10. [WhatsApp Bot Ban Analysis 2026 — Achiya Automation](https://achiya-automation.com/en/blog/whatsapp-spam-detection-2026/)
11. [WhatsApp Warm-Up Guide 2026 — WaDeskio](https://warmer.wadesk.io/blog/whatsapp-account-warm-up)
12. [Warm Up WhatsApp Number — Quackr](https://quackr.io/blog/warm-up-whatsapp-number/)
