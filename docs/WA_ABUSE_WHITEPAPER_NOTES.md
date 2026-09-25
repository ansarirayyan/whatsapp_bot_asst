# WhatsApp "Stopping Abuse" Whitepaper — Analysis for Bot Ban Avoidance

**Generated:** July 9, 2026 at 04:30 AM PT  
**Source document:** "Stopping Abuse: How WhatsApp Fights Bulk Messaging and Automated Behavior" — WhatsApp, February 6, 2019 (12 pages)  
**Companion document:** `BAN_RISK_EVIDENCE.md` — read that first for the hypotheses being tested here  
**Epistemic note:** This paper is WhatsApp's public-facing PR/policy document, not a technical specification. It is deliberately high-level. Thresholds, exact signals, and ML feature weights are not disclosed. Read all "confirmations" as consistent-with, not proof-of.

---

## Section 1: Detection Mechanisms WhatsApp Explicitly Describes

WhatsApp describes a three-stage detection pipeline. Quoting/paraphrasing with page citations.

### Stage 1 — At Registration (pp. 6–7)

**What the paper says:**

> "even basic account information along with an IP address and associated carrier information can be used to teach our machine learning systems the difference between bulk and normal registrations" (p. 7)

> "our systems can detect if a similar phone number has been recently abused or if the computer network used for registration has been associated with suspicious behavior" (p. 7)

> "we're able to detect and ban many accounts before they register — preventing them from sending a single message. In the same three month period, roughly 20% of account bans happened at registration time." (p. 7)

> "Phone numbers originating from areas with a history of fraud may indicate to WhatsApp there is a problem with an account." (p. 5)

**Signals named at registration:**
- IP address
- Carrier/network identity
- Whether the phone number prefix/area has a history of fraud
- Whether the computer network (IP range / ASN) has been "associated with suspicious behavior"
- Whether a similar phone number was recently abused

**Key takeaway:** Registration-time detection is real, documented, and accounts for ~20% of all bans. Bans can happen BEFORE any message is sent.

---

### Stage 2 — While Messaging (pp. 7–8)

**What the paper says:**

> "We evaluate how they behave in real time. All messages are end-to-end encrypted, which means that WhatsApp cannot see the content of messages passing through our system, though we are able to analyze the frequency of account activity." (p. 7)

> "an account that registered five minutes before attempting to send 100 messages in 15 seconds is almost certain to be engaged in abuse, as is an account that attempts to quickly create dozens of groups or add thousands of users to a series of existing groups. We ban these accounts immediately and automatically." (p. 7)

> "a new account might message dozens of recipients who do not have the sender's account in their contacts. This could be the beginning of a spam attack... we consider historical information (for instance, how suspicious their registration was)" (p. 7)

> "we display at the top of a chat thread when a user is typing. Spammers attempting to automate messaging may lack the technical ability to forge this typing indicator. If an account continually sends messages without triggering the typing indicator, it can be a signal of abuse, and we will ban the account." (pp. 7–8)

> "if an active computer network has recently been used by known abusers, we have more reason to believe a new account on that network is likely to be abusive." (p. 8)

> "we maintain limits on how many groups an account can create within a certain time period and ban accounts with suspicious group behavior, if appropriate, even if their activity rates are low or have yet to demonstrate high reach." (p. 8)

> "our detection systems evaluate hundreds of factors" (p. 7)

**Signals named during messaging:**
- Message send rate / frequency
- Time since registration (new accounts under more scrutiny)
- Messaging strangers (recipients not in sender's contacts)
- Typing indicator presence/absence — explicitly named as an anti-automation signal
- Group creation rate and group add rate
- Network reputation of the account's current IP
- Historical suspicion score from registration phase

---

### Stage 3 — In Response to Negative Feedback (p. 9)

**What the paper says:**

> "if an account accumulates negative feedback, such as when other users submit reports or block the account, our systems evaluate the account and take appropriate action." (p. 9)

> "Whenever a user receives a message for the first time from an unknown number, we immediately display options that enable them to 'report' or 'block' the sender's account." (p. 9)

> "when someone reports the first message they receive from an unknown number, we have higher confidence that the report is legitimate." (p. 9)

> "In cases when the reported number did not initiate the communication, we work to ensure there was no coordination among others to falsely report the account." (p. 9)

**Signals named from user feedback:**
- User reports weighted by context: stranger messaging stranger = highest-confidence report
- Block rate
- Whether the reported account initiated contact with the reporter
- ML categorization of reports to understand abuser motivation

**Note on false reports:** WhatsApp explicitly describes protection against coordinated false reporting, indicating they look at the reporting relationship, not just raw report counts. This is somewhat reassuring for bots that only respond to inbound contacts.

---

### Stage 4 — Modified/Unofficial Clients (p. 10)

> "some attackers attempt to modify WhatsApp software and trade unauthorized APK files to get around the constraints coded into the client itself. These modifications cannot circumvent our detection systems that run on our servers and apply to all users without exception. Still, we are improving our ability to detect these modified versions of WhatsApp as they both violate our Terms of Service and pose a security risk." (p. 10)

This is the closest the paper comes to addressing unofficial clients like whatsmeow. It:
- Explicitly confirms that server-side detection exists for modified clients
- States it cannot be circumvented by client-side modifications
- Notes they are ACTIVELY IMPROVING this detection (2019 — almost certainly more mature now)

---

### Machine Learning Architecture (p. 10)

> "Features are the specific signals — such as number of reports, rate of messaging, reputation of other users sharing the same computer network, and so on..." (p. 10)

> "if they determine that an account's behavior at registration matches the behavior of other accounts that were banned, we will ban the account even before it can send any messages. If these systems previously caught accounts after they sent 50 messages, a machine learning model trained on the features and labels from those accounts will catch similar attempts much faster." (p. 10)

> "Here we worked to adapt the so-called 'Facebook Immune System' for use on social media to our messaging service." (p. 10)

This describes a self-improving classifier loop: every banned account improves the next generation of detection. The system explicitly targets accounts that look like previously-banned accounts at registration time — pattern matching that doesn't require the new account to send any messages.

---

## Section 2: What the Paper Confirms or Refutes vs. BAN_RISK_EVIDENCE.md Hypotheses

### Hypothesis 1a — New number has no history (confidence was 0.65)

**SUPPORTED. Confidence update: 0.70.**

The paper explicitly confirms that new accounts receive scrutiny, and that the reputation of the phone number and its network directly impacts registration-time decisions. The paper also confirms that registration-time bans happen (~20%), meaning the detection fires before any behavior is possible. "Reputation of new accounts" is named as an ML feature (p. 8).

**What it adds:** The paper makes clear that even at registration, signals come from the *IP/network*, not just the phone number. A brand-new number linking from a datacenter IP or a VPN server with prior abuse history can be banned at registration time for network reasons, even if the number itself is pristine.

### Hypothesis 1b — Unofficial client fingerprint at handshake (confidence was 0.75 for mechanism, 0.55 for being the dominant instant-restriction cause)

**PARTIALLY SUPPORTED for mechanism existence. Confidence: ~0.70 for mechanism existence, unchanged ~0.55 for "dominant cause of instant-on-link restriction."**

The paper confirms (p. 10) that server-side detection for modified clients is real and "cannot be circumvented" by client-side changes. It explicitly says WhatsApp was improving this detection.

**Critical caveat on applicability:** This whitepaper was published February 2019. WhatsApp multi-device was not launched until August 2021. The "registration" stage described in the paper refers to phone number activation (SMS verification), not companion device QR-code pairing. The paper cannot speak to whether companion device linking triggers fingerprint-based detection — that is a separate, later system not described here.

The closest confirmation is the modified-client detection passage (p. 10), but it doesn't say WHERE in the lifecycle this fires — at the protocol handshake, at first message, or retroactively.

### Hypothesis 1d — Combination of (a) and (b) (confidence was 0.70)

**STILL MOST SUPPORTED. Confidence: 0.72.**

The paper describes a multi-factor system where registration-time signals INFORM and modulate later-stage decisions (p. 7: "we consider historical information (for instance, how suspicious their registration was)"). A new number on a suspicious network gets flagged at registration, which then lowers the threshold for action during messaging. This is fully consistent with the "combination" hypothesis.

### Does the paper support "caught at registration/connection" as the explanation for instant restriction?

**Yes, with nuance.** The paper confirms:
- Bans happen at registration, before any message is sent (~20% of all bans)
- Network reputation is the key signal, not just phone number age
- ML classifiers match new accounts to patterns of previously-banned accounts

The most likely explanation for a fresh number getting restricted within seconds of linking: the linking IP or phone number pattern matched the ML classifier's "looks like past abusers" profile. Whether this fires specifically at the multi-device pairing step (companion device handshake) or at a slightly later point is not addressable by this 2019 paper.

### Does "warm-up helps" get confirmed or refuted?

**Partially confirmed for behavioral bans. Not addressed for registration/link-time bans.**

The paper's ML model description (p. 10) says the system learns from behavior of existing accounts and builds reputation. An aged account with normal messaging history would have established non-suspicious patterns. The paper also describes suspicion scores from registration persisting into the messaging phase ("how suspicious their registration was").

**What warm-up cannot fix** (this paper doesn't contradict BAN_RISK_EVIDENCE.md): If the link happens from a flagged IP or if the account matches a banned-account profile at pairing time, registration-phase detection would still fire regardless of account age. The paper confirms registration-time detection is purely about signals at that moment, not behavioral history.

---

## Section 3: Actionable Takeaways for the Bot (Ranked by Direct Paper Support)

### Tier 1 — Directly and explicitly supported by the paper

**A. Link from a clean, non-datacenter IP.**  
The paper explicitly names "computer network used for registration" as a ban signal. If the IP or ASN range has been "associated with suspicious behavior," the account can be banned before sending a single message. A residential IP (home connection, not VPS/datacenter) has the lowest association risk.  
Paper support: Direct. Page 7.  
Confidence this helps: 0.75.

**B. Implement the typing indicator in whatsmeow when sending messages.**  
The paper names this explicitly: "If an account continually sends messages without triggering the typing indicator, it can be a signal of abuse, and we will ban the account." This is the ONE specific anti-automation signal the paper names by name. whatsmeow supports sending typing presence (`whatsmeow.ChatPresenceComposing`).  
Paper support: Direct. Pages 7–8.  
Confidence this helps for behavioral ban avoidance: 0.80.  
Confidence this helps at link time: 0.00 (irrelevant to link-time bans).

**C. Do not message strangers (contacts not in your address book).**  
The paper explicitly calls out "new account might message dozens of recipients who do not have the sender's account in their contacts" as a suspicious pattern. User reports from strangers carry maximum confidence weight. A respond-only bot (only replies to inbound) avoids this signal entirely.  
Paper support: Direct. Pages 7, 9.  
Confidence this helps: 0.80 for behavioral/report-triggered bans.

**D. Keep message send rate low; never burst-send.**  
"Account that registered five minutes before attempting to send 100 messages in 15 seconds is almost certain to be engaged in abuse." Rate and timing are the primary behavioral signals.  
Paper support: Direct. Page 7.  
Confidence this helps: 0.80.

**E. Do not rapidly create groups or mass-add users.**  
Paper explicitly limits group creation rate and flags high group creation even at low message volumes. Not relevant if the bot only operates in existing conversations, but worth knowing.  
Paper support: Direct. Page 8.  
Confidence this helps: N/A if no group operations; high if groups are involved.

---

### Tier 2 — Implied by paper, not explicitly stated

**F. Wait for cooldown to fully expire before re-linking.**  
The paper describes a system that evaluates "historical information" from registration when making messaging-phase decisions. Re-linking during an active restriction likely re-triggers the same classification. Not explicitly stated, but consistent with the described architecture.  
Paper support: Implied. Page 7–8.  
Confidence this helps: 0.60 (unchanged from BAN_RISK_EVIDENCE.md — paper adds no new evidence here).

**G. Use a phone number from a non-fraud-history area/carrier.**  
"Phone numbers originating from areas with a history of fraud may indicate to WhatsApp there is a problem with an account." MVNO numbers from carriers not historically associated with bulk-SIM fraud are lower risk. This is not specific enough to validate or invalidate prepaid MVNO eSIMs.  
Paper support: Implied. Page 5.  
Confidence this helps: 0.60 for real SIM vs. VoIP; still 0.40 for prepaid MVNO eSIM specifically.

**H. Use the number organically (warm-up) before linking the bot.**  
The paper describes ML features including "reputation of new accounts" and using registration behavior to predict future banning. Warm-up presumably builds positive signal. Not explicitly called out as a mitigation.  
Paper support: Implied. Page 8, 10.  
Confidence this reduces behavioral ban risk: 0.60 (unchanged — BAN_RISK_EVIDENCE.md had 0.55, paper mildly increases this).

---

### Tier 3 — Not addressed by the paper

**I. Setting realistic DeviceProps (Chrome/DESKTOP) in whatsmeow.**  
The paper does not address companion device labeling at all. Its statement that server-side detection "cannot be circumvented" by client modifications suggests label changes don't defeat the actual detection signals. Still worth doing (costs nothing), still unlikely to matter.  
Paper support: None direct. Implied not effective by p. 10.  
Confidence: Unchanged from BAN_RISK_EVIDENCE.md — 0.30 that it matters.

---

## Section 4: Honest Caveats — Where the Paper Is Vague or Where We Are Over-Reading

1. **This paper is from 2019, pre-multi-device.** WhatsApp multi-device (companion device / QR linking) launched in 2021. The paper's "registration" stage describes phone number SMS verification — not QR code companion pairing. Everything said about "registration-time" signals may or may not apply to the companion device linking flow. The paper cannot be used to confirm or deny whether the instant-restriction on linking is a "registration" detection or a separate companion-device detection layer.

2. **"Computer network" is not defined.** The paper says network reputation matters but doesn't specify what it means by "computer network" — it could be IP, subnet, ASN, or something more complex. We are inferring "residential vs. datacenter" from this; the paper doesn't say that explicitly. The inference is reasonable but not confirmed.

3. **"Roughly 20% at registration" is a 2019 statistic.** Given the paper explicitly says they were improving detection and that ML models catch violations "much faster" over time, the 2026 figure is likely higher. Don't treat 20% as the current baseline.

4. **The typing indicator passage doesn't say how heavily it's weighted.** It says "can be a signal" and "we will ban the account" — but this is illustrative, not a precise threshold. The paper names it as one of "combinations of actions or inactions" the AI analyzes. Don't treat absence of typing indicator as a guaranteed-ban trigger; it's one feature among hundreds.

5. **The paper's ban statistics (2M/month, 75% without user reports) are PR numbers.** They demonstrate scale but don't tell us anything about our specific scenario (single account, unofficial multi-device client, first-time restriction).

6. **"Facebook Immune System" reference (p. 10)** is a named system but the paper doesn't describe its architecture in any useful detail. Don't over-read this as a specific technical claim.

7. **The paper describes the GOAL, not the IMPLEMENTATION.** "We combine signals to make rapid determinations" tells us the approach but not the exact feature weights, threshold values, or what triggers a ban vs. a soft warning vs. monitoring. The gap between WhatsApp's stated intentions and their actual implementation is unknowable from this document.

8. **The modified-client detection passage (p. 10) was written about APK-modified Android clients, not about multi-device companion apps.** Unofficial Android WhatsApp mods (WhatsApp Plus, GBWhatsApp, etc.) are a different attack surface from whatsmeow-based companion device clients. The detection system for one may or may not be the same as for the other.

---

## Summary Table

| Detection Stage | Paper Confirms? | Our Scenario Relevance | Actionable? |
|---|---|---|---|
| Registration: IP/network reputation | YES (direct) | HIGH — linking IP is a signal | Use clean residential IP |
| Registration: Phone number history | YES (direct) | MEDIUM — new number no history | Warm up before linking |
| Registration: Pattern matching vs. historical bans | YES (direct) | HIGH — explains instant bans | Reduce matching signals |
| Messaging: Send rate/burst | YES (direct) | MEDIUM — bot is low-volume | Keep rates low regardless |
| Messaging: Typing indicator absence | YES (direct) | HIGH — whatsmeow must send this | Implement typing presence |
| Messaging: Strangers (not in contacts) | YES (direct) | HIGH — respond-only model | Respond-only, no cold outreach |
| Messaging: Group creation | YES (direct) | LOW — likely not creating groups | Avoid group creation |
| User reports from strangers | YES (direct) | HIGH | Respond-only model mitigates this |
| Modified/unofficial client detection | YES (confirmed as real, server-side) | HIGH | No client-side fix possible |
| Multi-device / companion device QR linking | NOT ADDRESSED (2019 paper, pre-multi-device) | DIRECTLY RELEVANT to our scenario | Gap in evidence |

---

## Bottom Line: What the Paper Changes

**Confidence updates from BAN_RISK_EVIDENCE.md:**

| Hypothesis | Before | After paper | Direction |
|---|---|---|---|
| 1a (new number history) | 0.65 | 0.70 | UP — paper confirms registration-time signals |
| 1b (client fingerprint mechanism exists) | 0.75 | 0.75 | UNCHANGED — paper confirms server-side detection for modified clients but doesn't speak to companion device specifically |
| 1b (fingerprint = dominant cause of instant restriction) | 0.55 | 0.55 | UNCHANGED — paper can't address QR linking specifically |
| 1d (combination) | 0.70 | 0.72 | SLIGHTLY UP — paper's multi-signal architecture is consistent with combination |
| Warm-up reduces behavioral ban risk | 0.55 | 0.60 | SLIGHTLY UP — "reputation of new accounts" ML feature implicitly supports warming |
| Warm-up reduces link-time restriction | 0.45 | 0.45 | UNCHANGED — paper doesn't speak to companion device linking |

**The most important insight the paper adds that BAN_RISK_EVIDENCE.md underemphasized:**

The linking IP / network reputation is a FIRST-CLASS signal at registration time — named before phone number history. If the instant restriction is happening at the companion device linking stage, and if that stage runs similar checks to "registration," then *the IP the bot is running on matters as much as or more than the phone number's history*. A VPS or cloud IP that has been used by other whatsmeow bots that got banned could be flagged at the network level, causing instant restriction of any new account linking from it regardless of how well that number was warmed up.

**The one new concrete action this paper adds to our playbook:**  
Implement `ChatPresenceComposing` (typing indicator) in whatsmeow before every outbound message. The paper names this as a specific, documented anti-automation detection mechanism. It is the only explicit mechanism named. Cost: trivial. Upside: removes one documented ban signal.
