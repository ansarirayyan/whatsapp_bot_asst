# How to NOT Get the WhatsApp Bot Number Banned (Again)

**Status:** Verified — second-pass review against sourced evidence
**Builds on:** `docs/BAN_RISK_EVIDENCE.md` (sourced evidence — read that for citations and full reasoning)

---

## 1. The honest bottom line

Running an unofficial client (whatsmeow) means WhatsApp can likely detect us **at the pairing handshake itself** — our number got restricted within *seconds* of linking, before a single message was sent. That means there is **no guaranteed-safe configuration**: everything below lowers the odds and slows escalation, but cannot eliminate the risk. The strategy is twofold: (1) stack every plausible risk reducer, and (2) treat the number as a **burner** — keep losses survivable, never put anything on it you can't afford to lose.

> The only genuinely ban-safe path is the official WhatsApp Business API. Everything in this guide is best-effort risk management on an undocumented, shifting detection system.

---

## The split: what YOU do vs. what the bot handles

Ban risk has two halves — and the **human half is the one that matters most.** The config side (my job) is mostly cheap hygiene; the behavioral side (your job) is where the real leverage is.

### ✅ Handled in the bot's config (you don't touch this — I did it)
- **Device identity:** presents as "Chrome," not "whatsmeow" (~0.3 — cosmetic, but free).
- **whatsmeow kept current** (an outdated client gets auto-rejected — this already bit us once).
- **Outbound throttle + human-paced random delays** — no burst/blast patterns.
- **Reactive-only mode** available — the bot replies, never cold-initiates (the single best-supported behavioral protection, ~0.7).
- **One stable, long-lived session** with gentle backoff — no reconnect storms.

### 👤 What ONLY YOU can do (the load-bearing levers — do these)
1. **Age the number 2–4 weeks before linking.** Use it like a real human first — real chats, receive more than you send, join a group, make a call or two. **We skipped this, and it's likely why the restriction was instant.**
2. **Never re-link during a cooldown.** It likely escalates toward a permanent ban. Wait the full timer out, then keep using it manually for several more days.
3. **Don't link right after registering.** Brand-new numbers are under maximum scrutiny.
4. **Set a profile photo, display name, and About** before linking.
5. **Keep it a real cellular number** (your eSIM qualifies — though MVNO prepaid is slightly weaker than a long-standing SIM).
6. **Treat it as a burner.** Nothing irreplaceable on it, ever.

*(The rest of this guide is the detail behind the above.)*

---

## 2. Right now: the account is in cooldown (~5 hours)

**Do:**
- **Wait out the FULL cooldown.** Note when the restriction started; don't touch linking until it has clearly lifted.
- **Use the official WhatsApp app normally** on the phone — receive messages, reply to a friend, behave like a human. (Low-cost, plausibly helps signal "real user." Confidence it helps: ~0.4. Confidence it doesn't hurt: high.)
- After the cooldown lifts, **keep using the number manually for several days before re-linking.** Don't re-link the moment the timer expires.

**Do NOT:**
- **Re-link the bridge during the cooldown.** Community consensus and inference both say this likely resets or extends the restriction and pushes toward permanent ban. Confidence ~0.6 it's harmful — but the downside is catastrophic and the upside is zero, so treat it as forbidden.
- Reinstall WhatsApp, clear data, swap phones, or otherwise "fight" the restriction. These don't speed recovery and add churn signals.
- Attempt to link from a *different* unofficial client "to test." Same fingerprint class, same risk.

---

## 3. Before the NEXT link attempt — checklist, ranked by evidence quality

Ranked strongest-supported first. **None of these are proven to prevent the link-time restriction** — the handshake fingerprint likely fires regardless. What they plausibly buy: a higher trust score, so detection results in a warning or monitoring state instead of an instant restriction, and slower escalation afterward.

| # | Action | Evidence tag | Confidence |
|---|--------|-------------|------------|
| 1 | **Keep it a real-SIM/eSIM cellular number, not VoIP/disposable.** Already true for us — keep it that way on any rotation. | Anecdotal + partial official support (WhatsApp blocks VoIP registration) | ~0.65 vs. VoIP generally; **~0.40 for prepaid MVNO eSIM specifically** — WhatsApp may treat MVNO prepaid numbers as closer to disposable than a long-standing postpaid SIM. Our eSIM is in this lower-confidence zone. |
| 2 | **Age the number 2–4 weeks and use it like a human first**: real conversations with real contacts, receive more than you send, join a group, make a call or two. | Anecdotal, but the most consistent recommendation across independent sources — including the whatsmeow community itself | **~0.65 for behavioral ban risk reduction; ~0.45 that it softens the link-time reaction.** These are separate mechanisms — don't conflate them. |
| 3 | **Don't link immediately after (re)registering.** Multiple operator guides specifically warn against scanning the QR right after registration — brand-new numbers are under maximum scrutiny. | Anecdotal | ~0.6 |
| 4 | **Set a profile photo, display name, and About text** before linking. Makes the account look human, costs nothing. | Folklore with plausible mechanism | ~0.4 |
| 5 | **Our DeviceProps=Chrome patch** (already applied). Changes the linked-device label from "whatsmeow"/"Other device" to "Chrome." | Speculation — likely cosmetic; deeper protocol fingerprinting (handshake timing, message-ID structure) is unchanged by it | ~0.3 that it matters; keep it anyway — free |
| 6 | **Link from a residential IP, not a datacenter/VPS**, if we have the option. | Speculation; mostly relevant to multi-account setups | ~0.3 |
| 7 | Meta Verified on a Business account reportedly stopped warnings for one user. | Single anecdote, unreplicated | ~0.25 — don't spend money on this yet |

**Honest framing:** Items 1–3 are the load-bearing ones. Items 4–7 are cheap hygiene — do them because they cost nothing, not because they're proven.

**On re-linking this specific number:** it may now be on a watchlist. A second restriction, possibly faster or longer, is a live possibility even if we do everything right. Plan for it (see §5).

---

## 4. Running the bot to stay alive

Once linked, the goal is to look like a human using WhatsApp Web — because that's what we're impersonating.

- **Reactive only.** The bot **never initiates** conversations with new contacts. It only replies to inbound messages. This is the single best-supported behavioral rule (directional confidence ~0.7). No broadcasts, no outreach, no "just checking in" messages to numbers that haven't messaged us first.
- **Low volume.** Keep total daily message count modest. There's no known safe threshold; operator guides suggest spacing sends 15+ seconds apart. If the bot is replying in an active conversation, natural conversational pacing is fine — the point is no burst or blast patterns.
- **Human-paced replies.** Add a small randomized delay (a few seconds) before responding. An instant reply to every message at any hour is a machine tell. Whether Meta actually uses this signal is unknown — but it's cheap.
- **ONE stable, long-lived session.** Connect once and stay connected. This means:
  - No reconnect loops. If the connection drops, back off with increasing delays — do not hammer reconnects. Rapid reconnect cycles are anecdotally flagged (confidence ~0.6), and reconnecting aggressively after an error is exactly the pattern that precedes bans in whatsmeow issue reports.
  - Keep the bridge linked **continuously** rather than connect/disconnect per use. Each fresh pairing is another pass through the fingerprinted handshake — the most dangerous moment we know of. Minimize how often we go through it.
  - Keep the phone (primary device) online and the official app in normal use.
- **Watch for warning signs.** If we see "Your account may be at risk" warnings or unexpected disconnect notices: stop the bot, don't reconnect immediately, reassess. A warning is the cheap version of a ban — treat it as one.
- **Log connection events** (link time, disconnects, errors, any warnings) so if a ban happens we can reconstruct what preceded it. Our sample size is currently 1; every event is data.

---

## 5. Escalation ladder — what a ban means and how to respond

Community-reported pattern (anecdotal, no Meta-published thresholds; confidence ~0.6 on the pattern, lower on specific counts):

| Event | Likely meaning | Response |
|---|---|---|
| ~5h restriction (what we got) | First-offense soft restriction | Wait it out fully, humanize, re-link cautiously after several days |
| 24–72h restriction | Second or third strike | Same, but longer humanization period; seriously consider rotating numbers |
| Repeated temp bans (~3–4 **within ~60 days**) | Reported to precede permanent ban | Stop re-linking this number with the bridge, period |
| "Account is linked to an unauthorized application" / permanent ban | Number is done | Do not appeal-and-retry-in-a-loop. Rotate. |

**Rules:**
- **Never fight a cooldown by re-linking.** Every re-link during or immediately after a restriction is plausibly another strike.
- **If permabanned: it's a burner.** That was the plan. Get a new real-SIM number, and this time apply the full §3 checklist from day one (age it 2–4 weeks before first link — we skipped that step last time, which is likely part of why the restriction was instant).
- **Keep nothing irreplaceable on the bot number.** No important contacts, no payment linkage, no identity anchoring. Export any chat data you care about regularly.

---

## 6. What we can't promise

- **No ground truth exists.** Meta publishes no ban criteria, no thresholds, no detection details. Every recommendation in this guide is operator anecdote, community consensus, or inference — the evidence report tags each claim, and nothing here exceeds ~0.7 confidence.
- **Detection can change without notice.** WhatsApp has tightened unofficial-client detection over time (documented in whatsmeow community discussions). What works this month may not work next month.
- **The handshake fingerprint may be undefeatable from our side.** If Meta fingerprints whatsmeow's protocol behavior (handshake timing, key-exchange ordering, message-ID structure), no amount of warm-up, labels, or good behavior changes that signature. Warm-up and the link-time restriction are likely **orthogonal** — don't expect a well-aged number to be immune at pairing.
- **Beware fabricated statistics.** The widely-cited "Meta 2025 Policy Enforcement Report / 68% of Indian businesses" figure appears to be fabricated — it traces to no real Meta publication. If a claim in a blog post sounds precise, assume it's made up unless sourced.
- **Terms of Service:** unofficial clients violate WhatsApp's ToS. Bans are Meta enforcing their stated policy, not a bug we can fix. The only documented no-ban-risk path is the official Business API — if the use case ever needs reliability, that's the answer.

---

*Flattened / what an expert would push back on: this guide treats "handshake fingerprinting" as the near-certain cause of the instant restriction, but that inference rests on timing only. The evidence gives 0.75 confidence that protocol fingerprinting is a real detection mechanism, but only 0.55 confidence that it is the dominant cause of the instant restriction on a new number specifically. An alternative explanation is aggressive new-number heuristics that treat ANY companion-device link within hours of registration as suspicious regardless of client identity, in which case number aging matters more than this guide's ranking implies. Both mechanisms suggest the same mitigations, so the practical advice is identical either way — but don't over-index on "fingerprinting is definitely why" when the honest answer is we don't know.*
