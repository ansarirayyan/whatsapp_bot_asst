# WhatsApp Unofficial Client Ban Risk — Evidence Report

**Generated:** July 9, 2026 at 5:53 AM PT  
**Scope:** Brand-new prepaid/eSIM/MVNO number, whatsmeow-based multi-device bridge (lharries/whatsapp-mcp), restriction within seconds of linking, ~5-hour cooldown

> **Epistemic note:** WhatsApp publishes no public specification of its ban criteria. Meta has never documented what signals trigger account restriction or what thresholds exist. The material below is sourced from: (a) official WhatsApp Help Center pages, (b) community GitHub issues/discussions on whatsmeow and Baileys, (c) third-party commercial documentation from API providers, and (d) independent security research. Each claim carries a confidence score and a tag — **VERIFIED** (official source or independently reproducible), **ANECDOTAL** (community reports without controlled evidence), or **SPECULATION** (inference with no direct confirmation). Layers of certainty are explicitly separated.

---

## Fabricated Source Alert

Multiple third-party articles (blog.kraya-ai.com, achiya-automation.com) cite "Meta's 2025 Policy Enforcement Report" with a statistic of "68% of Indian businesses using unofficial tools report at least one ban event in 12 months." **This document does not appear to exist as a published Meta report.** No link, archive, or official source is traceable. Treat any statistic traced to this citation as **[UNVERIFIED / likely fabricated]**. This is noted wherever that figure appears below.

---

## Q1 — Why does a brand-new number get restricted within seconds of linking an unofficial multi-device client?

### 1a. Is it (a) the new number having no history?

**Assessment:** Plausible, moderately supported — confidence 0.65.  
Tag: **ANECDOTAL + INFERENCE**

Multiple commercial API provider guides state that new numbers are under heightened scrutiny immediately after registration. whapi.cloud's documentation explicitly warns: "Do not scan the QR code immediately after registering the number in WhatsApp" — new numbers are described as "immediately under suspicion." [Source: https://support.whapi.cloud/help-desk/blocking/warming-up-new-phone-numbers-for-whatsapp-api]

WASenderApi similarly notes: "An account that has been active for 6 months is far more resilient than one that was registered yesterday." [Source: https://wasenderapi.com/blog/stop-getting-banned-the-ultimate-whatsapp-anti-ban-strategy-for-unofficial-apis-in-2025]

The achiya-automation guide describes the first 24 hours as a "honeymoon surveillance period" where Meta watches everything. [Source: https://achiya-automation.com/en/blog/whatsapp-spam-detection-2026/]

**Critical caveat:** None of these providers cite internal Meta documentation or controlled experiments. These are operator folk wisdom codified into guides — all may be reasoning backwards from observed ban patterns.

### 1b. Is it (b) the unofficial-client fingerprint detected at the handshake?

**Assessment:** Strongly supported as a real mechanism, but evidence it alone causes *immediate* restriction on a new number (vs older numbers) is inferred — confidence 0.75 that fingerprinting is real; confidence 0.55 that it's the dominant cause of instant-on-link restriction specifically.  
Tag: **ANECDOTAL (mechanism)** + **VERIFIED (that WhatsApp sends disconnect notifications mentioning unofficial clients)**

The whatsmeow Discussion #567 ("WhatsApp has improved the ban rules for the message automation system") documents that WhatsApp sends specific disconnect notifications: *"Those numbers use a unofficial WA Version."* This indicates server-side detection of the client type beyond user reports. [Source: https://github.com/tulir/whatsmeow/discussions/567]

The achiya-automation article describes a four-layer detection system with Layer 1 being "Protocol Fingerprinting" — "The WebSocket handshake, encryption key negotiation order, and session establishment timing differ measurably from legitimate WhatsApp Web clients." The same article states: "Meta maintains a fingerprint database of known unofficial clients, and connections matching known fingerprints get flagged immediately, regardless of message volume." **This specific claim is [UNVERIFIED]** — the article provides no source for how it knows Meta maintains such a database or what signals are fingerprinted. It is plausible based on the observed "banned before sending any messages" pattern reported across GitHub issues, but should not be treated as documented fact.

**Supporting evidence for fingerprinting being real:**  
Independent security researcher Tal Be'ery documented that WhatsApp message IDs vary systematically by platform (Web clients generate IDs starting with "3EB0" followed by 18 hex digits; Android produces longer IDs; Apple uses "3A" prefixes), enabling platform identification from message metadata. [Source: https://medium.com/@TalBeerySec/i-know-which-device-you-used-last-summer-fingerprinting-whatsapp-users-devices-71b21ac8dc70]  
This confirms device type fingerprinting via content metadata is technically feasible and WhatsApp-internal. Whether WhatsApp uses it proactively to ban clients at connection time is inferred, not confirmed.

The whatsapp-web.js GitHub issue #3608 documents the specific error: *"Account is linked to an unauthorized application. WhatsApp has restricted device linking for this account and has disconnected all previously linked devices."* — closed as not planned (maintainers treat it as WhatsApp policy enforcement, not a library bug). [Source: https://github.com/wwebjs/whatsapp-web.js/issues/3608]

### 1c. Is it (c) the generic "Other device" DeviceProps label?

**Assessment:** Probably not the primary trigger — confidence 0.35 that the display label is what matters.  
Tag: **SPECULATION / ANECDOTAL**

The whatsmeow Discussion #469 confirms that `DeviceProps` is user-configurable in whatsmeow: the maintainer confirmed "It's a public variable, you can just change the fields inside it." Users discussed `store.DeviceProps.PlatformType = waCompanionReg.DeviceProps_CHROME.Enum()` to display "Chrome" instead of "Other device." [Source: https://github.com/tulir/whatsmeow/discussions/469]

However, this discussion contains no evidence that changing the label reduced ban rates. The "Other device" label reflects `DeviceProps` being unset — it is the surface manifestation, not the underlying detection vector. Detection based on WebSocket timing, key exchange ordering, and message ID structure would remain unchanged regardless of what name the companion device registers with.

### 1d. Combination?

**Assessment:** Most likely — confidence 0.70 that it is a combination of (a) and (b).  
Tag: **INFERENCE**

The pattern of restriction within seconds of linking, before any messages are sent, is most consistent with server-side fingerprinting of the client during the pairing/handshake phase. The new number's lack of trust history likely lowers the threshold at which WhatsApp acts on suspicious pairing signals. For an aged, established account, the same fingerprint might trigger a warning or monitoring state rather than immediate restriction — but this is pure inference.

**What nobody outside Meta knows:** The exact signals WhatsApp uses during companion device registration, the thresholds, whether new-number status modifies those thresholds, and whether this is rule-based or ML-based. This is fundamentally unknowable without access to Meta's internal systems.

**Sources:**
- https://github.com/tulir/whatsmeow/discussions/567
- https://github.com/tulir/whatsmeow/issues/810
- https://github.com/wwebjs/whatsapp-web.js/issues/3608
- https://achiya-automation.com/en/blog/whatsapp-spam-detection-2026/
- https://medium.com/@TalBeerySec/i-know-which-device-you-used-last-summer-fingerprinting-whatsapp-users-devices-71b21ac8dc70
- https://support.whapi.cloud/help-desk/blocking/warming-up-new-phone-numbers-for-whatsapp-api

---

## Q2 — Does "warming up" a number demonstrably reduce linked-device ban risk?

### Short answer: Probably yes for behavioral ban risk. Unlikely to prevent protocol-fingerprint-triggered restriction at link time. Evidence base is anecdotal throughout. Confidence: 0.55.

**What warming-up is:**  
Using the number like a normal human — setting a profile photo, sending/receiving messages with real contacts, building account age — before linking any automation. Commercial providers advocate a 10-30 day process of graduated activity.

**Evidence FOR warming up reducing ban risk:**

The whatsmeow Discussion #567 community consensus includes an explicit recommendation: "You should always warm up a number before connecting to whatsmeow. Best is that some of your friends send you some messages to your number." This is the most direct community evidence from whatsmeow's own discussion space. [Source: https://github.com/tulir/whatsmeow/discussions/567]  
Tag: **ANECDOTAL** — no control group, no quantification.

Multiple commercial API providers (Green-API, whapi.cloud, WASenderApi, warmer.wadesk.io) describe warming as "vital" or "crucial." [Sources: https://green-api.com/en/docs/faq/warming-up-whatsapp-number/ | https://support.whapi.cloud/help-desk/blocking/warming-up-new-phone-numbers-for-whatsapp-api | https://wasenderapi.com/blog/stop-getting-banned-the-ultimate-whatsapp-anti-ban-strategy-for-unofficial-apis-in-2025 | https://warmer.wadesk.io/blog/whatsapp-account-warm-up]  
Tag: **ANECDOTAL** — all providers have a commercial incentive to recommend warming services. None cite controlled experiments. Green-API explicitly states guidance is "based on observations and analysis of WhatsApp usage practices."

**Evidence AGAINST / Limitations:**

1. The whatsmeow Issue #810 ("Your account may be at risk" warning) documents that accounts using whatsmeow are flagged *"even for legitimate, low-volume usage not involving bulk messaging"* — i.e., simply replying to incoming messages. [Source: https://github.com/tulir/whatsmeow/issues/810] This suggests protocol-level detection regardless of behavioral history.

2. The whatsapp-web.js Issue #3608 restriction applied during QR code scanning — *before any messaging behavior* occurred — suggesting ban triggers exist at the pairing handshake layer that warm-up history would not address.

3. No warming guide addresses the specific scenario of an unofficial multi-device client. Every warming guide implicitly assumes the linking step will succeed and that warming helps with behavioral ban risk (spam detection). They do not address whether account age/history affects the protocol-fingerprint check at link time.

**Honest state of the evidence:**  
- Controlled data: zero. There are no published A/B tests comparing warmed vs. unwarmed numbers with unofficial clients.  
- Community consensus: moderate — the recommendation is widespread in developer communities but is based on collective observation, not experiment.  
- The mechanism that warming plausibly addresses (behavioral spam scoring) may be orthogonal to the mechanism causing immediate restriction on a new number (protocol fingerprinting at link time).

**Steelman of the warming narrative:** It is coherent that WhatsApp's risk engine uses account age and behavioral history as trust signals that modulate how aggressively it responds to suspicious pairing signals. A number with 3 months of organic usage might get a warning rather than a restriction on the same unofficial client pairing. This is a reasonable inference from the system's design purpose, but it has no direct evidentiary support.

---

## Q3 — Does setting realistic DeviceProps (Chrome/Firefox/Desktop vs. "Other device") measurably reduce ban risk?

### Short answer: Very likely not sufficient on its own. Confidence: 0.30 that DeviceProps label change matters; 0.70 that deeper fingerprinting survives a label change.

**What changes with DeviceProps:**  
The label shown in the paired devices list (WhatsApp Settings > Linked Devices). Setting `PlatformType = CHROME` makes the device appear as "Chrome" instead of "Other device." [Source: https://github.com/tulir/whatsmeow/discussions/469]

**Why it probably doesn't defeat detection:**

1. The fingerprinting research by Tal Be'ery demonstrates that WhatsApp can identify device platform from message ID structure, timing patterns, and session behavior — signals that whatsmeow would produce in a Chrome-emulating vs. unset configuration identically (whatsmeow doesn't change its message ID generation based on DeviceProps). [Source: https://medium.com/@TalBeerySec/i-know-which-device-you-used-last-summer-fingerprinting-whatsapp-users-devices-71b21ac8dc70]

2. The whatsmeow Discussion #567 disconnect notification explicitly states "Those numbers use a unofficial WA Version" — this is a server-side verdict, not derived from the device label (which the server also sets and can cross-check against protocol behavior).

3. whatsapp-web.js Issue #3608's ban message references "unauthorized application" — a categorization the server reaches through protocol analysis, not what the client reports itself to be.

**What DeviceProps might affect:**  
Display cosmetics; possibly some surface-level pattern matching if WhatsApp uses the label as one lightweight signal. It would not change WebSocket handshake parameters, key exchange ordering, session establishment timing, or message ID generation — the signals that constitute genuine protocol fingerprinting.

**Honest answer:** Setting a realistic DeviceProps label costs nothing and is worth doing, but treating it as a meaningful anti-detection measure is not supported by evidence. It is cosmetic unless WhatsApp's detection is shallower than the evidence suggests.  
Tag: **SPECULATION** — nobody outside Meta knows whether this matters, but the available evidence suggests it doesn't.

**Sources:**
- https://github.com/tulir/whatsmeow/discussions/469
- https://github.com/tulir/whatsmeow/discussions/567
- https://medium.com/@TalBeerySec/i-know-which-device-you-used-last-summer-fingerprinting-whatsapp-users-devices-71b21ac8dc70

---

## Q4 — What actually reduces linked-device ban risk? (Ranked by evidence quality)

### Tier 1 — Moderately supported (ANECDOTAL but consistent across independent sources)

**A. Account age / number maturation before linking**  
Multiple independent community sources (whatsmeow Discussion #567, whapi.cloud, Green-API, WASenderApi) consistently recommend waiting days-to-weeks before linking automation. The whatsmeow community specifically says "warm up a number first." Not a controlled finding, but the recommendation is widespread enough and consistent enough to treat as the highest-confidence folk heuristic.  
Confidence: 0.65 that this reduces behavioral ban risk; 0.45 that it reduces protocol-fingerprint-triggered restriction at link time.  
[Source: https://github.com/tulir/whatsmeow/discussions/567 | https://green-api.com/en/docs/faq/warming-up-whatsapp-number/]

**B. Respond-only model (reactive, not proactive)**  
The achiya-automation article claims reactive bots (only respond to incoming messages) have "<2% ban rate over 12 months" vs. 15-30% for proactive bots sending to new contacts. **This specific figure is [UNVERIFIED]** — no source is given — but the directional claim (reactive = lower risk) aligns with community consensus in whatsmeow Discussion #199 where users report success with inbound-only automations.  
Confidence: 0.70 directionally, specific percentages unverifiable.  
[Source: https://achiya-automation.com/en/blog/whatsapp-spam-detection-2026/ | https://github.com/tulir/whatsmeow/discussions/199]

**C. Real SIM (not VoIP) number**  
WhatsApp officially blocks VoIP numbers from registration in some contexts. whapi.cloud states: "virtual numbers have the highest probability of being banned, as they are most often used for spamming." [Source: https://support.whapi.cloud/help-desk/blocking/how-to-not-get-banned]  
MVNO/prepaid numbers (physical SIM or real eSIM with a real cellular carrier number) are not VoIP and are in a different risk category than disposable online SMS services. The distinction between prepaid physical SIM and MVNO eSIM vs. voip is not explicitly documented anywhere authoritative.  
Confidence: 0.65 that real SIM lowers risk vs. VoIP; 0.40 for prepaid MVNO eSIM specifically.  
Tag: **ANECDOTAL**

**D. Stable sessions / avoid rapid reconnects**  
The achiya article states: "stable, long-lived sessions look legitimate, while frequent reconnections create suspicious patterns." whatsmeow Issue #14 showed the ban occurring after a stream end / 503 error cycle suggesting connection instability is flagged. [Source: https://achiya-automation.com/en/blog/whatsapp-spam-detection-2026/ | https://github.com/tulir/whatsmeow/issues/14]  
Confidence: 0.60.  
Tag: **ANECDOTAL**

### Tier 2 — Weakly supported (ANECDOTAL with plausible mechanism)

**E. Message delays / low volume**  
Green-API recommends minimum 15-second intervals between messages; whatsmeow Discussion #199 shows users achieving stability by spacing messages ≥500ms and limiting volume to known contacts. [Source: https://green-api.com/en/docs/faq/warming-up-whatsapp-number/ | https://github.com/tulir/whatsmeow/discussions/199]  
Relevant for behavioral ban detection, not for the initial link-time restriction.  
Confidence: 0.65 for behavioral ban reduction; 0.00 for link-time restriction.

**F. Meta Verified on Business account**  
One user in whatsmeow Issue #810 reported: "enabling Meta Verified on their business account appeared to stop warnings." Single report, not replicated. [Source: https://github.com/tulir/whatsmeow/issues/810]  
Confidence: 0.25 — single anecdotal report.  
Tag: **ANECDOTAL**

### Tier 3 — Speculative (SPECULATION, no direct evidence)

**G. Realistic DeviceProps (Chrome/DESKTOP)**  
See Q3 above. Cosmetically plausible, no evidence it affects the protocol-level detection.

**H. IP/datacenter vs. residential**  
The achiya article mentions "shared infrastructure detection" — multiple instances on same IP/subnet creating correlated ban patterns. Not relevant to the single-number scenario but worth noting for multi-account setups.  
Tag: **SPECULATION**

---

## Q5 — Temporary vs. permanent bans: what's known about escalation?

### The ~5-hour cooldown

The described scenario (restriction lifting after ~5 hours) is consistent with first-offense temporary restriction. Official WhatsApp documentation on temporary bans does not specify exact durations for the shortest cooldowns but references self-resolving timers. [Source: https://faq.whatsapp.com/1848531392146538]

Community sources document temporary ban durations ranging from 30 minutes to 72 hours, with first offenses typically shorter. A 5-hour restriction is plausibly a first-time "soft" restriction triggered by linking an unofficial client on a new number — this is a reasonable inference but **not definitively documented anywhere**.  
Tag: **ANECDOTAL (duration range)** + **INFERENCE (5-hour classification)**

### Escalation pattern: temporary → permanent

The kraya-ai article documents an escalation ladder:
- 1st violation → temporary (24-48 hours typically, but shorter on first offense)
- 2nd violation within 30 days → longer temporary (48-72 hours)
- 3rd-4th violation within 60 days → permanent ban

[Source: https://blog.kraya-ai.com/whatsapp-temporary-vs-permanent-ban]  
Tag: **ANECDOTAL** — reasonable pattern inference from operator experience, not Meta-published thresholds.

The banappealgenerator.com source similarly states: "3-4 temp bans → permanent." [Source: https://www.banappealgenerator.com/whatsapp-temporarily-banned/]  
Multiple sources are consistent but none are citing internal Meta data.  
Confidence: 0.60 that repeated violations escalate to permanent; 0.40 on the specific 3-4 count threshold.

### Does re-linking during cooldown escalate bans?

**This specific scenario has no reliable public documentation.**

Community consensus cautions against it. The kraya-ai article states: "Don't try workarounds like reinstalling WhatsApp, clearing data, or changing your phone. These don't speed up recovery" — but this speaks to the user's primary phone app, not re-linking a companion device.  
[Source: https://blog.kraya-ai.com/whatsapp-temporary-vs-permanent-ban]

The whatsmeow Discussion #567 notes: "risks of getting a final ban is quite high if reconnecting too quickly." This is developer community consensus advising against aggressive reconnection attempts.  
[Source: https://github.com/tulir/whatsmeow/discussions/567]

**Inference:** Re-linking an unofficial client during an active restriction period most likely resets or extends the ban and may escalate it toward permanent. The mechanism is plausible — the restriction was likely triggered by detecting the unofficial client, so immediately re-connecting the same client pattern would register as continued policy violation. But this is **[INFERENCE, not documented fact]**.  
Confidence: 0.60 that re-linking during cooldown is harmful.

### What's unknowable:
- The exact escalation thresholds
- Whether the 5-hour cooldown was a soft "probation" vs. a ban in the same class as 24-hour restrictions
- Whether the same number can be safely reconnected after cooldown resolves, or whether the number is now on a watchlist
- Whether there's any permanent record vs. a sliding window

---

## Source Index

| URL | Type | Reliability |
|-----|------|-------------|
| https://faq.whatsapp.com/1848531392146538 | Official WhatsApp Help | High (authoritative but vague) |
| https://faq.whatsapp.com/465883178708358 | Official WhatsApp Help | High (authoritative but vague) |
| https://faq.whatsapp.com/717472490411581 | Official WhatsApp Help | High |
| https://engineering.fb.com/2021/07/14/security/whatsapp-multi-device/ | Meta Engineering Blog | High (technical, 2021) |
| https://github.com/tulir/whatsmeow/discussions/567 | Developer community | Moderate (maintainer's project, no maintainer response visible) |
| https://github.com/tulir/whatsmeow/discussions/199 | Developer community | Moderate |
| https://github.com/tulir/whatsmeow/discussions/469 | Developer community | Moderate (maintainer confirmed DeviceProps is public) |
| https://github.com/tulir/whatsmeow/issues/807 | Developer community | Moderate (open unresolved issue) |
| https://github.com/tulir/whatsmeow/issues/810 | Developer community | Moderate |
| https://github.com/tulir/whatsmeow/issues/14 | Developer community | Moderate (closed as duplicate of #810) |
| https://github.com/WhiskeySockets/Baileys/issues/1850 | Developer community | Moderate |
| https://github.com/wwebjs/whatsapp-web.js/issues/3608 | Developer community | Moderate |
| https://github.com/chatwoot/chatwoot/issues/8424 | Developer community | Moderate |
| https://medium.com/@TalBeerySec/i-know-which-device-you-used-last-summer-fingerprinting-whatsapp-users-devices-71b21ac8dc70 | Independent security research | Moderate-High (technically rigorous, addresses fingerprinting) |
| https://green-api.com/en/docs/faq/warming-up-whatsapp-number/ | Commercial API provider | Low-Moderate (operator experience, commercial interest) |
| https://green-api.com/en/docs/faq/what-types-of-blocks-can-whatsapp-impose/ | Commercial API provider | Low-Moderate |
| https://support.whapi.cloud/help-desk/blocking/warming-up-new-phone-numbers-for-whatsapp-api | Commercial API provider | Low-Moderate |
| https://support.whapi.cloud/help-desk/blocking/how-to-not-get-banned | Commercial API provider | Low-Moderate |
| https://wasenderapi.com/blog/stop-getting-banned-the-ultimate-whatsapp-anti-ban-strategy-for-unofficial-apis-in-2025 | Commercial API provider | Low-Moderate |
| https://achiya-automation.com/en/blog/whatsapp-spam-detection-2026/ | Commercial blog | Low (cites unverifiable statistics, "4-layer detection" claim unsourced) |
| https://blog.kraya-ai.com/whatsapp-temporary-vs-permanent-ban | Commercial blog | Low |
| https://blog.kraya-ai.com/whatsapp-automation-ban-risk | Commercial blog | Low (cites "Meta 2025 Policy Enforcement Report" which appears fabricated) |
| https://warmer.wadesk.io/blog/whatsapp-account-warm-up | Commercial product (sells warming service) | Very Low (conflict of interest, no evidence) |
| https://www.banappealgenerator.com/whatsapp-temporarily-banned/ | Commercial blog | Low |

---

## Bottom Line: Blunt Assessment

**Does warm-up actually help?**  
Probably, for behavioral ban risk — but "probably" is doing a lot of work here. The evidence is operator anecdote and community folk wisdom, not controlled experiment. Confidence: 0.55.

The more important caveat: warm-up is likely irrelevant to the specific scenario described — restriction within seconds of linking an unofficial client on a brand-new number. If WhatsApp's detection fires at the protocol handshake layer (which the evidence suggests it does, given bans before any messages are sent), then the account's message history is not in play at that moment. The initial 5-hour restriction on a new number was almost certainly triggered by the unofficial client signature at pairing time, not by behavioral spam signals. Warming up a number for 30 days may lower the *threshold* at which WhatsApp restricts on detecting an unofficial client (i.e., it may escalate from immediate restriction to warning, or not restrict at all on first link), but this is inference with no controlled support.

**Most-supported risk reducers (in order of evidence quality):**  
1. Respond-only bot (no proactive outbound to new contacts) — consistent community evidence, plausible mechanism  
2. Account age > 2-4 weeks before linking automation — consistent operator recommendation, mechanism is plausible  
3. Real SIM (not VoIP/disposable) number — widely stated, some official-level support (WhatsApp blocks VoIP registration)  
4. Stable sessions, avoid rapid reconnects during or after restriction  
5. Low message volume, long delays between sends  

**Top 3 caveats:**  
1. **None of the above prevents the initial restriction.** If WhatsApp fingerprints unofficial clients at the handshake, all of these mitigations are orthogonal to the first-link restriction event. They may affect whether the restriction is permanent vs. temporary, or whether subsequent links after cooldown resolve succeed — but no evidence confirms even this.  
2. **The evidence base is almost entirely operator anecdote.** No company outside Meta can publish controlled data on WhatsApp ban triggers without reverse-engineering NDA risk. Every guide you will find is built from observed patterns, not ground truth.  
3. **The only zero-ban-risk path is the official WhatsApp Business API through a Meta Business Solution Provider.** Everything else involves an uncertain, undocumented, shifting risk surface. [Source: https://faq.whatsapp.com/465883178708358]

**What to do in the described scenario:**  
- Wait out the full cooldown without re-linking. Do not reconnect the unofficial client until the restriction has fully cleared.  
- Use the number manually (official app only) for several days after the cooldown before attempting to re-link.  
- Set `DeviceProps.PlatformType` to `CHROME` or `DESKTOP` before re-linking (costs nothing, may do nothing, but it's not worse).  
- On re-link, start with zero proactive messaging — only respond to inbound.  
- Accept that the number may be on a watchlist and a second restriction, triggered sooner, is possible.  
- If the use case requires reliable automation at scale, the official Business API is the only documented path that does not carry this risk.

**Overall confidence in this report:** 0.65 — the analysis is well-sourced given the available public information, but the core question (what exactly triggers WhatsApp's immediate restriction) has no authoritative public answer. The honest answer is: nobody outside Meta knows for certain.
