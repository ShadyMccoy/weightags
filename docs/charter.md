# WeighTags — Project Charter

*Draft v11*

## Vision

Eliminate the manual friction in reconciling weigh tags between commodity growers and buyers. Replace the email-and-Excel workflow with a shared system that auto-pairs tags on BOL, surfaces discrepancies in a single diff view, resolves disputes on a deterministic clock, and serves as a queryable system of record for each party going forward.

## Problem

Growers and buyers both weigh truckloads independently — for legitimate reasons (scale calibration trust, in-transit shrinkage, separate books). Reconciling the two sets of tags currently costs hours of bookkeeper time per week, generates ambiguous email trails, and creates billing disputes that are hard to settle without a paper record.

## Strategic wedge

**Records gravity, not coordination pressure.** The wedge starts from a common asymmetry: one party keeps better records than the other, and the other keeps asking for them. The better-records party (A) adopts WeighTags for their *own* convenience — post the day's tags once, stop emailing spreadsheets, look organized — and is essentially done. Because those tags are addressed to the counterparty (B), B gets low-friction access to exactly the records B has been chasing. A adopted for single-player value; B is pulled in because B *wants the data*. There is no coordination campaign and no pressure — the gravity is B's own desire for A's records. Single-sided adoption is the deliberate on-ramp, not a compromise.

**The dispute moment is the counterparty's activation.** B's first real interaction is almost always a discrepancy — *"this invoice is wrong because of weigh tag XYZ."* Today that's an email or a phone call. The conversion is A's easy answer: *"next time that happens, just click Dispute here."* B's ad-hoc complaint becomes a structured, audited, one-click action — and now B is a real user on the same shared record. The single-player on-ramp becomes multiplayer at the exact moment B has a reason to engage. The activation funnel is therefore concrete: **invoice → look up the tag → Dispute.** A frictionless invoice-number lookup and a dead-simple contextual Dispute button are the conversion surface, not bookkeeping niceties.

**The default-accept timeout is a backstop, not the lead.** If B never engages, the Load still closes on our record after N days, defaulting to A's tag values. The teeth of that are **evidential, not contractual.** We make no claim that B "legally accepted" — the platform is not a party to the deal. What the timeout produces is a neutral, timestamped record that B was shown the numbers, notified on a fixed schedule, and did not contest. *Silence on a neutral record* is what carries weight in the parties' own later dispute resolution — the same third-party-record force the audit log gives us (see *Positioning principle*). Evidence binds without buy-in, where "acceptance" would not — which is also why the wedge reads as neutral rather than coercive: a record of what happened, not a clock that declares a concession.

Converts an active-coordination problem ("get the buyer to sign up") into the combination of **records gravity** (B comes for the data), a **one-click conversion at the dispute moment**, and an **evidential timeout** as the floor beneath both.

## Positioning principle

WeighTags is a **multiplayer** product: a neutral medium where two parties coordinate, each with equal agency, equal data ownership, and equal visibility. The platform is the meeting point, not the master. It is not a party to the underlying commercial agreements, not a legal arbiter, and does not enforce contracts.

This is structurally different from how the rest of the category works:

- **The master pattern.** One party owns the platform; the counterparty is a guest in their portal. Bushel is the prototype — the grain company owns the system, the grower logs in as a guest. Most B2B SaaS works this way; CRMs, customer portals, and AR/AP tools all assume one operator and one or more guests.
- **The integrator pattern.** The platform wires two existing systems together via API. Scale software, ERP middleware, and trading APIs are all integrators. The two parties remain in their own tools; the platform is plumbing between them.
- **The multiplayer pattern (ours).** Both parties have their own org, their own login, their own data — and a shared canonical record that neither solely owns. The platform is *neither* a master nor a pipe; it is the room they meet in.

The audit log we keep — timestamps, view records, notification history, value changes — is a defensible third-party record the parties can use in their own dispute resolution, like an email server's logs in a discovery process. The platform makes communication and audit easier; the parties remain responsible for their commercial relationship.

Every design decision either reinforces multiplayer (sender-left/receiver-right consistent regardless of who's logged in; symmetric actions; org-owned data on both sides; both parties cited in the audit log) or weakens it. When in doubt, default to symmetric.

**Symmetry is an architecture invariant, not an adoption constraint.** The multiplayer model governs how the *system is built* — data ownership, UI layout, the actions available to each side, audit attribution. It does not dictate how adoption *starts*. Adoption is frequently asymmetric: one party leads (keeps better records, adopts first), the other is pulled in (see *Strategic wedge* — records gravity). That asymmetry at the front door is expected and fine; once both parties are in, the symmetric architecture governs the relationship. **Build symmetric; let adoption be asymmetric.**

## Market paths and pillars of success

### Operating posture

WeighTags is launched cheaply and listens for signal. We are not picking a vertical, picking a geography, or running a GTM motion upfront. The bet is that *if* there's a real workflow pain at small/mid operator scale, the product will surface it; *if* there isn't, we'll know early and at low cost.

Concretely: minimum viable infrastructure (a single small VPS deployed via Kamal, or a managed host like Fly / Render), public beta visible to anyone with a link, one or two warm seeds to bootstrap the wedge, and continuous observation of what real usage looks like. No paid acquisition, no sales motion, no commitment to a vertical until signal points at one.

This posture is deliberate, not lazy. It minimizes cost-of-discovery for a market we don't yet understand, and it protects against premature commitment to a path that wouldn't pay.

### Who we're for

Small-to-mid operators on both sides — the mom-and-pop, the per-relationship, the parties for whom a $20/month subscription is a reasonable line item and a 5-day onboarding is unacceptable. Not enterprises with procurement processes; not large coops with internal IT; not consolidators who would rather build their own master platform than join someone else's. The customers Bushel and the master-platform vendors implicitly leave on email-and-Excel.

### What "signal" means

The things we'd actually act on:

- An inviter posts tags week-over-week (the wedge is working)
- An invited partner engages — logs in, reviews, acts (not just lets auto-accept fire)
- An invitee invites their own counterparties on a different relationship (the network is propagating)
- Concentrated usage from one vertical or geography (a wedge with a center)
- Specific feature requests that recur across customers (the next investment is obvious)
- A paid customer refers another paying customer (organic word-of-mouth, the cheapest channel of all)

### Branches we'd take if signals appear

- **Winery signal** → invest in crush.wine integration. Zero CAC; your existing customer base on one side; the v2 API is the natural extension.
- **Grain cross-network signal** → defensible niche. Bushel only reconciles between Bushel-powered partners; the other ~60% of US grain origination plus all cross-network trades is still on email-and-Excel.
- **Diffuse signal across verticals** → stay vertical-agnostic; double down on the generic multiplayer product.
- **No signal after a fair shot** → kill without ego. The cost of discovery was low, the work built real engineering and product muscle, move on.

### Distribution channels

Consistent with the posture (near-zero CAC, no paid acquisition), only organic, compounding channels
are in scope at launch; vertical channels are held for Phase 2 signal.

- **SEO magnets (primary).** Free tools that rank *and* on-ramp — a weigh-tag CSV template that *is*
  the import schema; shrink / moisture / dockage calculators; glossary and "cross-network
  reconciliation" pages naming the gap Bushel structurally can't close.
- **Product-led distribution.** The invoice-batch PDF's verification URL is a public, indexable,
  branded record-verification page seeded every time a customer attaches a PDF — the audit-log moat
  doing acquisition for free. Design it as a discovery surface, not just a utility.
- **Channel partners.** Farm bookkeepers / ag CPAs referring their client book — hits both sides of a
  relationship at once, near-zero CAC, the cheapest word-of-mouth.
- **Warm seeds + the wedge itself.** One or two known relationships from the operator's network; the
  wedge does the rest.
- **Held for vertical signal.** Vertical forums and shows (e.g. Unified Wine & Grape Symposium, GEAPS
  Exchange, crush.wine network) activate only once Phase 2 concentration appears — booths commit
  capital and a vertical, which the upfront posture forbids.

### Competitive landscape

- **Bushel** owns enterprise grain. Their reach is real: 40% of US grain origination by volume, $60B in grain settled annually, 60,000 growers, 2,000 grain buying locations, SOC 2 Type II audited. Their reconciliation product (*Bushel Fulfillment / Commercial Portal*) works *only between Bushel-powered partners* — it does not solve cross-network. Their pricing is asymmetric (enterprise on the elevator side; $199–$599/year acquisition pricing on the grower side). They're not in specialty crops at all.
- **Vertical Software, AgriChain, CompuWeigh, scale-software vendors** are scale-house operator software — different problem. They digitize one party's operations; they do not reconcile between parties.
- **The structural gap.** Every competitor is either a *master* or an *integrator* (see *Positioning principle*). No one is genuinely *multiplayer*. That's the niche, and it's structural, not feature-level. It cannot be closed by an incumbent adding a feature; it would require them to give up the platform-of-record posture that justifies their pricing.

### Pillars of success beyond technical merit

- **Multiplayer-first.** Both parties have equal agency, equal data ownership, equal visibility. Sender-left/receiver-right consistent regardless of who's logged in. Symmetric default for every *product/architecture* decision — though adoption itself is often asymmetric (see *Positioning principle*: build symmetric, let adoption be asymmetric). This is the single biggest differentiation against the competitive set; if we lose it, we become a worse master platform.
- **Ingest excellence.** It's in the name. CSV (v0), refined manual entry (v1), production public API (v2) — all rock solid. Without this, nothing else matters.
- **Audit defensibility.** The log is, to a real degree, the product. It has to hold up in a real commercial dispute. Append-only at the database level; attribution durable across job changes and org migrations.
- **Low-friction wedge.** Default-accept timeout plus free partner means invitee adoption cost is near zero. If invitee friction creeps up, the wedge stops pulling and the whole acquisition model breaks.
- **Mom-and-pop fit.** Pricing, UX, onboarding, and operational model designed for small-mid operators on both sides. Resist every feature request that pulls toward enterprise scope.
- **Scope discipline.** We do one thing well. Each adjacent temptation — CRM-lite, accounting-lite, market-data, weather — is either a partner integration or a no, never an internal feature.
- **Domain credibility (latent).** AgTracker and crush.wine experience is available if vertical signal appears. Not deployed upfront; held in reserve.

### Estimates

At $20/month flat per company, partner free, this is the shape of the business:

| Paying customers | ARR | What it means |
|---|---|---|
| 50 | $12K | Wedge is pulling. The thesis works at small scale. |
| 100 | $24K | Meaningful early traction. |
| 250 | $60K | Sustainable side income. |
| 500 | $120K | **Huge success.** Real network underneath. |
| 1,000+ | $240K+ | Upside beyond expectation; decide whether to invest more deliberately. |

500 paying customers is the success anchor. Infrastructure cost is pennies at that scale, so $120K ARR is essentially $120K of revenue with negligible variable cost — a real income stream from a side project launched on minimal capital. This is the right shape for the bet: small numbers, real network, sustainable indefinitely.

Worth noting the network footprint, not just the dollar number: 500 paying customers × 2–3 invited partners each = 1,000–1,500 free users on top, so the active-account count is more like 1,500–2,000. The dollar number is modest; the network depth is substantial.

Two consequences fall out of this pricing shape:

- **CAC has to be near zero.** A $200 CAC implies 10-month payback at $20/month. The wedge has to do the acquisition work; we cannot afford a sales motion at this price, and we don't want one.
- **Margins should be fat.** Rails on a small VPS (Kamal) is cheap, Postgres is cheap, email is cheap — and because Solid Queue / Solid Cache / Solid Cable are all Postgres-backed, there's no Redis line item either. 85–90% gross margin at scale is realistic. The constraint is customer count, not unit economics.

These numbers are oriented as a sense of *what success looks like at this posture*, not a forecast. We're not aiming for $1M ARR; we're aiming for a sustainable, narrow, multiplayer product that earns its own keep.

### Feedback mechanisms

- **Repeat-usage measurement.** Week-2 and month-2 retention on both inviter and invitee sides.
- **Invite-to-engagement rate.** How many invited partners actually log in vs. let auto-accept fire. The wedge's pulse.
- **Time-to-first-reconciled-load.** From first tag posted to first closed load. A measure of friction.
- **Disputed-tag retrospectives.** What happened, what would have made it faster, what the customer wishes the product knew. Both for our product backlog and for customer workflow insight.
- **Vertical and geographic pattern detection in inbound usage.** Are we seeing concentration? Where?
- **Quarterly customer conversations** once volume supports it. Earlier than that, opportunistic interviews with anyone who'll talk.
- **Kill-criteria review** at fixed intervals (every 3 months in year 1).

### Kill criteria

Conditions under which we stop investing rather than double down:

- 6 months post-public-launch, zero repeat customers
- 3 months post-paid-launch with paying customers, no organic invites propagating (the wedge isn't pulling)
- After a fair trial, the trajectory isn't pointing toward at least 50 paying customers — the wedge isn't doing the acquisition work that the price point requires
- A clearly superior incumbent emerges in our target segment and we cannot differentiate against them
- Operating cost exceeds revenue with no plausible path to closing the gap within 12 months
- The work stops being interesting — sustainability matters; this is a long-running asset by design, and a project that drains the operator is one that doesn't get the maintenance investment described in *The app is the business*

The bar is low by design. We're not optimizing for big numbers; we're checking whether the slope is positive at small numbers. If the trajectory's right, 50 becomes 100 becomes 250 over time without forcing anything. If the trajectory's flat at small numbers, no amount of investment fixes the underlying market signal.

## Goals (MVP)

- Reduce manual ticket-pairing to near zero (auto-match on BOL, smart pairing for typos)
- Single source of truth per load, visible to both parties in real time
- Auditable record of every state transition (post, view, dispute, accept, edit, compromise, auto-accept, invoiced)
- One party can adopt without the counterparty pre-existing
- Serve as a queryable system of record for each party's weigh tag history — value persists past the live coordination event
- Track the bridge from reconciled weigh tags to external invoices, so the workflow loop closes cleanly even without the platform generating the invoice
- Organizational continuity — an org's history and partner relationships outlive any one user's tenure at that org

## Non-goals (MVP)

- Not a scale-software replacement — we ingest, not generate
- Not an invoicing engine in the generative sense — we track *which* tags went to *which* external invoice, not the invoice's pricing or total
- Not a payment processor
- Not a legal arbiter or contract enforcer
- Not commodity-specific logic — generic tag schema with optional fields
- Not mobile-first — responsive web, optimized for desktop
- Not a farm management platform, CRM, accounting system, or ERP — we do one thing (reconcile weigh tags between two parties) and resist the gravitational pull toward platform sprawl
- Not blind / sealed-bid submission — analytics surfaces patterns more powerfully than restriction does

## Users

- Grower / buyer: post tags, review counterparty tags, dispute, accept, propose compromise
- Bookkeeper / admin: reports, exports, partner / tolerance / user management, invoice batches
- Demographic skews older, Excel-comfortable, not deeply technical

## User stories

### As a grower / sender (typically posting first)

- Upload my day's weigh tags via CSV, so they're shared with the partner without emailing a spreadsheet.
- Invite a partner who isn't on the platform yet, so I can adopt the system unilaterally.
- See which of my tags are awaiting the partner, matched, disputed, or accepted, so I know where attention is needed.
- Dispute specific values on a matched load, so the discrepancy is documented and we can resolve it.
- Accept the partner's numbers when I'm willing to concede, so the weigh tag is closed quickly without an edit.
- Edit my own tag when I've discovered a recording error, with a required reason captured in the audit log.
- Propose a compromise value when neither side's number is clearly correct, so we can settle quickly without a long back-and-forth.
- Export reconciled weigh tags to CSV, so my accounting team can invoice from agreed numbers.

### As a buyer / receiver (engaging for the first time via invite)

- Click a link in an email and see the tags posted to me without creating a password first, so I can review before committing to signup.
- Upload my own tags via CSV, so the system can match them against the sender's.
- Accept the sender's tags as-is without uploading my own, so I can engage with low friction when the numbers look right.
- See my numbers and the sender's side by side with deltas, so I can quickly identify discrepancies.
- Dispute, accept, edit, or propose a compromise — the same actions available to senders, symmetric.
- Get clear reminders before the dispute window closes, so I don't accidentally let auto-accept fire.
- Claim my account properly when ready, so all tags previously addressed to me remain accessible.

### As a bookkeeper or admin on either side (workflow)

- Configure the dispute window with a specific partner (e.g., 14 days), so the platform's timeout matches our actual commercial agreement.
- Configure tolerances per partner (e.g., ±1% net, ±0.2% moisture), so the platform's "within tolerance" flag reflects what we actually treat as acceptable drift.
- Download the full audit log for a load, so I can attach it to dispute resolution outside the platform.

### As an admin (organizational continuity)

- Invite a colleague at my organization by email, so they can post and review tags on our behalf.
- Promote a member to admin, so the organization always has a backup admin in case I'm unavailable.
- Deactivate a departing user's membership, preserving their historical actions in the audit log while removing their access going forward.
- Verify my organization's domain (DNS TXT record or email-confirmation), so other email holders at the same domain can request admin recovery if needed.
- See a persistent banner when my org has only one admin, so I'm reminded to add a backup before there's a problem.
- After claiming a placeholder org via invite, get nudged to invite a colleague, so the organization isn't tied to a single account.

### As a scale operator (direct entry at the scale house)

- Type a weigh tag directly into the platform as the truck pulls off the scale, so it gets to my partner in real time instead of waiting for an end-of-day CSV upload.
- Have common fields (commodity, partner, sender / receiver, scale ID, my own name) pre-fill from my last entry, so I'm only entering what actually changes per truck.
- Autocomplete truck numbers and driver names from recent entries, so frequent trucks are one keystroke and a tab.
- Save a tag and immediately start a new one without leaving the form, so a steady stream of trucks doesn't require steady navigation.
- Have my partner see the tag immediately after I save it, so they can begin reconciling without waiting on me to finish the day.

### As a user across job changes

- Leave an organization without losing my personal account, so I can be invited into a different org at my next job and pick up where I left off.
- See which organizations I'm currently a member of and switch between them, so I can work across multiple relationships from one login.

### As a bookkeeper or admin on the sender side (invoice batches)

- Select a batch of closed weigh tags and mark them as invoiced by entering my external invoice number, so the platform tracks the bridge between reconciled tags and the invoice I'm sending.
- Filter weigh tags by *Closed, not yet invoiced*, so my regular bookkeeping workflow has a clear queue of pending items each week.
- Download a printable PDF summary of an invoice batch (header, invoice number, included weigh tags, totals, verification URL), so I can attach it as backup to the invoice email I send my partner.

### As a bookkeeper or admin on the receiver side (invoice verification)

- Search weigh tags by invoice number, so when I receive an invoice from a partner I can quickly confirm the line items match the platform's reconciled values.
- See an *Invoiced* badge on weigh tags that have been linked to a partner's invoice, so I know which tags are accounted for in their billing cycle.

### As any user, using weightags as a system of record

- Search and filter my weigh tags by BOL, date, partner, truck, driver, or status, so I can find specific records on demand without digging through old emails or spreadsheets.
- Export a filtered view of weigh tags to CSV, so I can hand data to my accountant, import into bookkeeping software (QuickBooks, Business Central, etc.), or attach to a regulatory filing.
- See aggregate totals (count, gross, tare, net) for any filtered range, so I can answer *"how many pounds did we ship in October?"* or *"what's our total receiving for this harvest?"* without manually summing.
- Pull a season-long activity record with a specific partner, so I can review the relationship at year-end or prepare for contract renewal.
- Download a comprehensive ledger of closed loads with their audit trails, so I have defensible documentation for tax filings, crop insurance claims, organic certification, or USDA program audits.

### As either party, on any load

- See a complete history of who did what when, so the audit trail is available if a commercial dispute escalates.
- Add notes or comments to a load, so context travels with the data without a separate email thread.
- Receive email notifications when relevant events occur (new tags posted to me, clock started, dispute filed, auto-accept fired, partner edited their tag, tags marked invoiced), so I don't need to keep the app open.

## Site aesthetic

Clean, clerical, friendly, hygienic. A vault for the parties' data and a neutral exchange between them — trustworthy but welcoming, neither a toy that misplaces things nor a courtroom that punishes mistakes. Closer to a well-run accountant's office or a good credit union than to a modern SaaS dashboard or a stern legal docket.

### Design principles

- **Vault, not toy.** Stable record IDs visible, explicit timestamps with timezone, immutable audit trails surfaced. No animations that suggest data could be moved or undone casually.
- **Friendly and easy, not bureaucratic.** Plain-language copy, helpful empty states, encouraging confirmations. Sensible defaults so users aren't forced into every decision. Competent but warm.
- **Neutral ground.** Symmetric visual treatment of both parties. Sender always on the left, receiver always on the right — across all views, for all users, regardless of who's logged in. Goods flow left-to-right; the eye gets a consistent scan pattern.
- **Clerical precision.** Aligned grids, ruled lines, tabular numerals with consistent precision, conservative palette (warm neutrals plus one or two reserved accents).
- **Density over whitespace — but readable.** Information on screen, scannable without scrolling or expanding rows, but not packed to the point of strain. Older users especially.
- **Read-first, edit-deliberate.** Default read-only; editing requires explicit intent, a reason, and an audit entry.
- **Predictable layout.** Buttons stay put. No clever animations or hide-and-reveal.
- **Familiar verbs.** "Sort," "Filter," "Export," "Edit," "Accept," "Dispute," "Compromise," "Mark as invoiced."
- **Print-friendly tables and PDF artifacts.**

### Reference points (in spirit)

Closest fit for friendly-but-clerical: **Mercury** and **Bench Accounting**. Other useful anchors: **Stripe Dashboard**, **Microsoft Dynamics 365 Business Central**, **Carta**, QuickBooks Online tables, well-designed credit union and government interfaces, classic ledger aesthetics.

### Status palette

Color is the primary signal for workflow state. Seven values, organized by what they ask of the viewer's attention:

| Register | States | Hex | What it says |
|---|---|---|---|
| Personal / private | Draft | `#8b7d6b` (warm gray-brown) | Your own incomplete work, not yet shared |
| Active workflow (amber family) | Pending | `#d97706` (amber-orange) | Waiting on the partner; no action from you yet |
|  | Review | `#b45309` (darker amber) | Deltas above tolerance; your action required |
| Conflict | Disputed | `#dc2626` (red) | Active dispute filed |
| Resolved / clean | Matched | `#059669` (green) | Both posted; deltas within tolerance |
|  | Resolved | `#0891b2` (cyan) | Was disputed, now closed |
|  | Invoiced | `#4f46e5` (indigo) | Closed weigh tag linked to an external invoice batch |

Two design rules follow from the registers:

- **Amber is reserved for "this needs attention."** The two amber shades (Pending and Review) sit in the same family but at different luminances. Pending is brighter; Review is darker. They're never visually adjacent on a page — Pending lives at the row level and Review at the row level, and in the summary cards they're separated by another card.
- **Red is reserved for active conflict.** A delta exceeding tolerance is amber (a fact about the numbers), not red. Red only ever describes the workflow state, not the data. This means a single Load can carry both colors — amber delta cell, red status pill — without contradiction, because they describe different things.

### What to avoid — both failure modes

**Toy.** Card-based dashboards as primary navigation; heavy whitespace and oversized typography; hidden actions behind hover; animation-heavy transitions and skeleton loaders; marketing copy inside the app; emoji-heavy status indicators; gamification; cartoon illustrations; "Oops!"-style error voice; visual treatments favoring one party.

**Bureaucratic.** Legalese; cold pure-white backgrounds; terse or hostile error messages; dense walls of jargon; defaults that punish users for not knowing how the system works.

### Concretely

Tables as primary display, subtle row striping, warm-neutral background. Compact but readable forms. Modals only for consequential confirmations. Side-by-side diff with delta column — sender-left, delta-center, receiver-right. Status pills with distinct color per state. Persistent record IDs and timestamps. Activity feed reachable from any load. Plain-language copy. Helpful empty-state guidance. Sensible defaults wherever possible. Printable PDF artifacts for invoice batch summaries and audit log exports.

## Canonical screens

A working React + Vite + Tailwind v4 prototype implements the design language described above. The artifact lives at [`docs/design/prototype/`](design/prototype/) (originally exported from a Figma Make session as `WeighTagsFigma-v3.zip`, then iterated on directly in code and unpacked into the repo). The four screens below are the ones in implementation today. Each is captioned with the state it shows and the design decisions visible in it; together they exercise the full status palette and the core diff pattern.

Figma frame links are placeholders — to be filled in once the canonical frames are pulled back into the Figma file.

### Weigh tags list — receiver org's home view

![Weigh tags list](mockups/01-list.png)

Logged in as Jessica Miller at Heartland Grain Co. Seven mock weigh tags across the full state spectrum (Matched, Review, Pending Receiver, Resolved, Invoiced, Disputed). Figma frame: *[to add]*

Design decisions visible:

- **Four summary cards across the top, color-keyed:** Pending Receiver (neutral), Needs review (amber `#b45309`), Disputed (red `#dc2626`), Matched Today (green `#059669`). The eye scans left to right through escalation registers. *Disputed* and *Needs review* are visually adjacent but distinguishable; both are not red because that would collapse the two-register distinction described in the data model.
- **Table as primary surface, not cards.** Dense, scannable, with tabular numerals throughout. One row per Load. Eleven columns fit the viewport without horizontal scroll at 1400px.
- **Sender on the left of Receiver on the right** (Sender Net column then Receiver Net column then Δ). Goods-flow direction is enforced even when the viewer is a receiver.
- **Δ column color-coded.** When the magnitude exceeds the 0.5% tolerance, it renders amber (review register). Within tolerance, it's the default text color (no semantic weight; the reader's eye doesn't catch on it).
- **Status pill is the rightmost column** so the workflow state is the last thing the eye lands on per row.
- **One-sided weigh tags show `—` in the missing party's Net and Δ columns.** No empty cells, no zeros — explicit absence.
- **Footer carries chrome only:** copyright, the *System of Record for Commodity Weight Reconciliation* tagline, timezone, last-sync timestamp. Reinforces the vault feel without competing for attention.

### Weigh tag detail — clean match (`WT-2026-0527-001`)

![Matched detail](mockups/02-detail-matched.png)

Both parties' tags joined, deltas within tolerance, status auto-matched. Figma frame: *[to add]*

Design decisions visible:

- **General Information panel above the diff.** Fields that apply to the Load as a whole (BOL, Ship Date, Truck, Driver, Commodity, Sender, Receiver) are factored out. The comparison table holds only what differs between the two sides.
- **Comparison table is symmetric.** Field labels left; sender column; centered Δ column on a slightly darker stripe; receiver column. Green checkmark next to *Sender* and *Receiver* headers when that side has posted (an X when missing).
- **Delta cell shows both absolute and percentage.** `−30` over `(−0.06%)`. Color follows tolerance: green when within, amber when exceeding. The same component renders both registers — only the threshold changes the color.
- **Per-side fields beyond the weights.** Moisture, Timestamp, Weighed By, Scale ID, Notes. These are the audit trail visible at a glance: who weighed it, on which scale, when, with what observation. Each side carries its own. Sender notes might be empty while receiver notes carry a real observation; the layout handles asymmetry gracefully.
- **Variance Status footer below the table.** A single one-line callout: *Within tolerance (±0.5%)* in green, or *Exceeds tolerance (±0.5%)* in amber. Tells the reader the headline conclusion without scanning the cells.
- **Activity Log as a table at the bottom.** Timestamp, Action, Details, Actor. The same striped, tabular treatment as the comparison table — audit feels like a continuation of the data, not a separate thing.

### Weigh tag detail — review needed (`WT-2026-0527-002`, Soybeans, −0.74% net)

![Review detail](mockups/03-detail-review.png)

Both parties posted; net delta −0.74% exceeds the 0.5% tolerance; awaiting human action. Figma frame: *[to add]*

Design decisions visible:

- **Amber *Review* pill** in the header. Distinct from Pending (also amber-orange, `#d97706`) by being a slightly darker amber (`#b45309`). The two are never adjacent on a page — Pending lives in summary card 1, Review in summary card 2.
- **Action ribbon expands** with *Accept* (outlined) and *Dispute* (filled black). Only appears on Review state — the matched detail has no actions to take.
- **Review-needed alert** between the General Information panel and the comparison table. Amber `#b45309` background tint and border. Pulls the reviewer's eye to the reason (*"Net weight variance exceeds 0.5% threshold"*) before they scan the numbers.
- **Per-side Notes show context the headline numbers lose.** Receiver: *"Some spillage observed during unload."* The reviewer now has a hypothesis for the variance before clicking anything.
- **Activity Log includes the system action.** *Flagged for review — Net weight variance 0.74% exceeds threshold — requires review.* The auto-flagging is itself an audit event.

### Weigh tag detail — disputed (`WT-2026-0527-004`, Milo, −2.11%)

![Disputed detail](mockups/04-detail-disputed.png)

A formal dispute filed; receiver's scale recalibrated that morning; sender requests third-party verification. Figma frame: *[to add]*

Design decisions visible:

- **Red *Disputed* pill** (`#dc2626`). This is the alarm register, reserved for active conflict — not used anywhere else.
- **Dispute-filed alert in red.** Carries the structured reason (*Significant weight variance — 2.1%*) and the free-text dispute notes (*Sender disputes receiver measurement — requesting third-party verification*) as a stronger-weight second line. The two-layer treatment makes the categorical fact (what bucket of dispute) skimmable while keeping the specific complaint legible.
- **Delta cell is amber, not red.** This is the key two-color decision: amber describes the numbers (*these deltas exceed tolerance*), red describes the workflow state (*this load is in formal dispute*). The same load can carry both colors because they're about different things. Future-proofs against the case where a load is disputed but the dispute is about *something other than* a weight variance.
- **Per-side Notes carry the dispute context inline.** Sender: *"Scale certified 05/15/2026."* Receiver: *"Scale recalibrated this morning — readings verified."* Both sides' provenance for trusting their own number is visible at a glance.
- **Activity Log entry attributes the dispute** to Rachel Green at Redstone Farms (the sender). Org attribution is parenthetical after the actor name — supports the *role is not embedded in audit log* rule by keeping org context queryable but not authoritative.

### Still to design

Canonical screens not yet drafted, in roughly the order they're needed:

- Landing / marketing page
- Empty-state home for a brand-new sender (no weigh tags yet)
- CSV upload preview (column mapping, per-row validation, summary before commit)
- Invite-partner email (template + claim link)
- Invitee first-arrival view (placeholder Org claim flow, no password yet)
- Direct entry form for a scale operator (scale-house tablet use case)
- Invoice batch creation (multi-select closed tags, invoice number entry, PDF preview)
- Invoice batch PDF summary (printable artifact attached to invoice email)
- Settings: per-partner tolerances and dispute window
- Members and roles (org admin view)
- Partner list and per-partner detail (relationship-level view)
- Full audit log / activity feed (cross-load, filterable)
- Compromise proposal flow (the midpoint-or-other negotiated-value action)
- Edit-own-tag flow (with required reason field, pre-commit confirmation)

## Data model

The model separates *who acts* from *what persists*, and a *measurement* from the *shipment* it
describes. Core entities, each with its own lifecycle.

**Naming (v12 — supersedes earlier drafts).** What earlier drafts called a *Load* is now the **Tag**:
the shipment itself, identified by the BOL that travels from A to B. What earlier drafts called a *Tag*
is now the **Weigh**: a single weighing. The user-facing term **"weigh tag"** is a Tag together with its
Weighs (literally Weigh + Tag). This dissolves the old internal-vs-external naming split — the model
word now *is* "tag."

### User

A person with an account, identified by email. Persists across job changes — leaving an organization doesn't delete the user account. A user can be a member of zero, one, or many organizations over their lifetime.

### Org

A persistent business entity (Sycamore Ridge Farms, Pacific Hulling Co.). Holds weigh tag history, partner relationships, settings, tolerances, dispute windows, and invoice batches. Has its own name, optionally a verified domain, optionally a tax ID. An org outlives any single user's tenure.

### Membership

Links a User to an Org with a role (admin, member) and a time range (joined date; optional end date if the user has departed). Audit attribution references the user directly; role is *not* embedded in audit entries — it lives here, queryable when needed, but historical events stand on their own.

### Weigh

What a scale recorded — one weighing event, and the **ground truth** of the system. A Weigh belongs to
one Org (the party that recorded it) and to exactly one Tag (the shipment). It carries that party's
measurements (gross, tare, net, moisture, grade); provenance for trusting that specific recording — who
weighed it (`weighed_by`), which scale (`scale_id`), when (`weighed_at`, distinct from the shipment's
ship date), and free-text notes (e.g. *"spillage observed during unload"*); a `role` (origin/sender,
destination/receiver, or third-party); and **`recorded_ref`** — the shipment reference *as that party
keyed it*. `recorded_ref` is never overwritten, so a typo'd or differing reference (PO vs BOL vs
Shipment #) is preserved as evidence, not lost.

Weighs are permanent, owned attestations — immutable except through a deliberate edit that preserves the
prior values in the audit log. A Weigh always belongs to exactly one Tag; it is never orphaned (a move
*reassigns* it). The provenance fields are the foundation of the audit trail: a disagreement surfacing
months later is resolved by reading them. The UI presents them per-side in the comparison table.

### Tag (the shipment)

The canonical record of one physical truckload — the BOL/shipment identity plus the agreed values
downstream consumers use. **A Tag is a thin projection over its Weighs:** it groups the Weighs asserted
to be the same shipment and folds them (together with the action log) into a current state and canonical
values.

- clean match → canonical equals both (they agree; stored as the sender's weigh)
- acceptance → canonical equals the accepted weigh
- compromise → canonical is a negotiated value matching neither weigh
- auto-accept (timeout) → canonical defaults to the sender's weigh

A Tag normally has two Weighs (origin + destination) but may have **more** — e.g. a third-party
verification weigh; the UI shows two primary columns and renders extras as additional rows. **Identity
is the shipment, not the BOL string:** the BOL is a fallible *label* (each Weigh keeps its own
`recorded_ref`); the Tag carries a canonical reference plus any known aliases. **A Tag is
garbage-collected when it has no Weighs** — if its last Weigh is moved away, the husk is discarded while
the real facts (the Weighs, and the audit events) persist. The agreement lives on the Tag; the
measurements live on the Weighs.

### Shipment identity, ingest & reconciliation

A Weigh reaches a Tag by one of three ingest paths:

1. **Weigh-in against an existing Tag (preferred).** Because the sender usually posts first, the
   receiver pulls up the partner's open shipments and appends their weigh to the matching one — no
   re-keyed BOL, no typo, no pairing. Identity is shared from the start; this is the cooperative happy
   path and it makes reconciliation the exception, not the rule.
2. **Direct entry / CSV.** When a party posts blind, the system mints or looks up a Tag and **auto-pairs
   on exact BOL**.
3. **When references differ** (typo, or different reference types), two Tags exist that are really one.
   Reconciliation closes the gap: exact **auto-pair**; **fuzzy match** (Levenshtein + date/truck/weight
   corroboration) → a suggestion; and **manual merge / split**. Every such operation is just "point this
   Weigh at that Tag": merge re-homes weighs and GCs the emptied husk; split mints a Tag and moves
   weighs; all are reversible and audited.

### Governance of shipment identity

Optimistic and symmetric — the platform **records and notifies; it does not gatekeep**. Either
**participant** (never an outsider; you may touch only your *own* Weigh) may weigh-in, relabel,
link/merge, or split. Safety comes from **reversibility + attribution + notification**, not permission
walls: every identity operation is an audited event, notifies the counterparty, and has an inverse.
**Mutual confirmation is required only when an operation would alter a *settled* record** — a resolved
or invoiced Tag — which must be reopened/un-invoiced deliberately first. An open-tag fuzzy match needs a
**single confirm + notice**, not mutual confirmation: the cooperative path stays low-friction (the
wedge), and the careful path is reserved for where money is on the line. People reorganizing weigh tags
are trying to help; the audit log and the undo make that safe to assume.

### Invoice batch

A grouping of closed weigh tags marked as invoiced under a single external invoice number. Carries: external invoice number, invoice date, sender org, recipient org, optional notes, list of tag IDs (each closed tag belongs to at most one batch), creator (which user marked it), creation timestamp, optional PDF artifact. The platform does not generate the invoice or know its monetary total — only the bridge between the reconciled tags and the external invoice.

### Tag states

A Tag's state is part of the projection it folds from its Weighs plus the action log.

| State | Meaning |
|---|---|
| **One-sided** | Only one Weigh posted; partner hasn't. Dispute clock hasn't started. |
| **Double-sided · ready to close** | Both Weighs posted; within tolerance. One-click acceptance. |
| **Double-sided · review** | Both Weighs posted; deltas above tolerance. Needs action. |
| **Disputed** | One party has filed a structured dispute. Clock paused; partner must respond. |
| **Compromise proposed** | A negotiated value has been proposed; awaiting partner acceptance. |
| **Re-review** | One party has edited their Weigh after partner saw it; partner reviews again. |
| **Closed** | Resolved by acceptance (manual or auto), compromise, or matched values. Carries the resolution provenance. |
| **Closed · invoiced** | A closed Tag linked to an invoice batch. Filterable separately from *closed, not yet invoiced*. |

### Audit log

Append-only and **immutable at the database level** (a trigger rejects every `UPDATE`/`DELETE`). Each
entry references the actor (user) and the action, timestamped. Role is *not* embedded — entries say
*"Mary Lin disputed BOL 10849"* not *"Mary Lin (admin at Pacific Hulling) disputed BOL 10849."* It
**outlives the projection**: events carry a denormalized BOL, so when a husk Tag is garbage-collected its
events survive (e.g. *"merged 1O849 into 10849"*). Historical facts stay true: a user's past actions
remain attributed to them even after they leave their org — which is why the audit association must
*never* cascade-destroy events when a Tag is GC'd.

## Key workflows

1. Weigh submission — **weigh-in against the partner's existing Tag** (preferred: select the inbound
   shipment, append your weigh; no re-keyed BOL), CSV in the defined schema, or direct entry through a
   scale-house form (autocomplete pre-fill, save-and-add-another; manual single-entry fallback)
2. Auto-pair on BOL into a shared Tag (a Tag groups the Weighs of one shipment)
3. Reconciliation for differing references: fuzzy match (Levenshtein + date/truck/weight corroboration)
   → single-confirm-plus-notice on open Tags; manual merge / split, both reversible and audited
4. Shared diff view on Tag detail (sender-left / receiver-right) with a centered delta column (absolute +
   percentage), a *Variance Status* callout, and an Activity Log table for every state transition
5. Per-side actions: Accept, Dispute (structured reason), Edit (own weigh, requires reason), Propose
   Compromise, Add note
6. Dispute clock: starts when both sides have posted; default-accept at the sender's weigh values after N days
7. Ghost-account invite: weighs addressed to an email create a placeholder Org. The invitee claims it via
   magic link, becoming the first admin. Onboarding nudge prompts them to invite a colleague.
8. Bulk action: select closed Tags and mark as invoiced with an external invoice number; printable PDF summary
9. Search, filter, aggregate, and export across historical Tags (including by invoice number)
10. Admin management: invite users to an Org, promote/demote roles, end memberships, verify Org domain

## Architecture

### Stack with rationale

- **Ruby on Rails 8 + Hotwire (Turbo + Stimulus) + Active Record + Postgres.** The product's central UX — two parties watching the same Load update in real time, with deliberate state transitions — is served by **Turbo Streams** broadcasting server-rendered partials over a WebSocket to every subscriber, the modern Rails answer to live, reactive UI. *Turbo Frames* scope in-place updates (expand the action ribbon, swap a status pill) without a full navigation; *Turbo Streams* push those same partials in real time when the counterparty acts; *Stimulus* supplies the small island of client behaviour the form needs (truck/driver autocomplete, modal confirmations, save-and-add-another). This is explicitly a **modern, Hotwire-reactive Rails app — not a classic full-page-reload CRUD app.** Crucially there is no separate JS framework and no API-serialization layer: the server renders HTML, and Turbo makes it feel live. The dense business-app aesthetic — tables, ledgers, side-by-side diffs — is more natural in server-rendered ERB (factored through **ViewComponent** for the Status Pill, Variance Status callout, Activity Log, and Weigh Tag Comparison table) than in a React SPA. Single language across the app (Ruby), the most batteries-included web framework in existence, and the deepest library and hiring pool of any option lower the cost of every future feature. Trade-off acknowledged: for *very* high-frequency updates, LiveView's stateful server-side diffing is marginally smoother than Turbo's broadcast-a-partial model — but our update cadence is human-paced (a post, an edit, a dispute), squarely in Turbo's sweet spot, and Rails' ecosystem maturity and familiarity more than compensate.

- **Postgres for storage.** Financial-adjacent data needs real constraints, transactions, and foreign keys. The matching engine is set-based SQL — auto-pair on BOL is literally a join; smart pairing is `pg_trgm` / Levenshtein (`fuzzystrmatch`) plus a few `WHERE` clauses, expressed through Active Record / Arel. The audit log is an append-only table guarded by triggers and a `BEFORE UPDATE/DELETE` rule. Aggregation queries over historical data are native Postgres territory. Postgres is also the substrate for **Solid Queue** (jobs), **Solid Cache** (caching), and **Solid Cable** (WebSockets) — the Rails 8 defaults — so a *single* storage system handles application data, background jobs, realtime, caching, and audit, with **no Redis** to operate.

- **Solid Queue for scheduled and background jobs.** The dispute clock (fire reminder at T+N/2 and T+N-1, auto-accept at T+N) is exactly its sweet spot: Solid Queue's recurring/scheduled jobs with retries, concurrency controls, and uniqueness, driven through Active Job. Postgres-backed (the Rails 8 default) means no Redis. Swappable for GoodJob or Sidekiq later if a specific need appears, but the default is the boring choice.

- **Turbo Streams over Solid Cable for realtime.** *"Buyer just disputed"* / *"grower is viewing now"* patterns are model-side one-liners — `broadcast_replace_to`, `broadcast_append_to` — scoped to the parties subscribed to that Load's stream. Solid Cable (Rails 8 default) is Postgres-backed, so realtime adds no new infrastructure either.

- **Auth: Rails 8 built-in authentication generator (email + password), magic-link for recovery and invite onboarding.** Active users rely on browser autofill. The Rails 8 `bin/rails generate authentication` scaffold gives sessions, password reset, and a clean schema as a starting point; signed/expiring magic-link tokens (`ActiveRecord::SignedId` / `generates_token_for`) are layered on for *Forgot password?* and for invited partners' first touch — they arrive via magic link with no password yet. (Devise is the fallback if we outgrow the built-in generator, but the generator is the boring-by-default choice now.)

- **Strict CSV schema with per-row validation.** We control the format. Validation at the import boundary (a dedicated import service object backed by Active Model validations, streamed with Ruby's stdlib `CSV`) keeps the domain clean and produces a per-row error report.

- **Append-only audit log.** Every state transition writes an immutable event, enforced at the DB level with triggers and constraints, not in application code that can drift. References actor (user) and action (with relevant entity IDs); role is not embedded.

- **Tables: `users`, `orgs`, `memberships`, `tags` (shipments), `weighs` (measurements),
  `invoice_batches`, `audit_events`.** Plus supporting tables (`partnerships`, `pairing_suggestions`,
  `notifications`, `operational_alerts`). `weighs.tag_id` points each measurement at its shipment; a Tag
  is GC'd when it has no weighs. Clean separation of who-is-who, what-was-measured, and what-happened.

- **PDF rendering.** For invoice batch summaries and audit-log exports. **Grover** (headless Chrome via Puppeteer) rendering an ERB/ViewComponent template — so the PDF and the on-screen artifact share one template — or **Prawn** if we want a pure-Ruby, no-Chrome dependency. Decided per artifact; Grover is the default for anything that should match a styled page.

- **Org-scoped data isolation.** Multi-tenant from day one. Default association scoping and query objects enforce org boundaries in application code; Postgres **row-level security** is the default safety net underneath where it fits cleanly. Cross-org *shared* records are handled explicitly: a Load is visible to both grower and buyer Orgs, and an invoice batch to sender and recipient Orgs — these are deliberate joins through the relationship, never a leak in the default scope.

### Explicitly not doing

- Not microservices — premature; a Rails "majestic monolith" gives logical isolation (and, if we ever need module boundaries, Packwerk) without operational cost.
- Not an SPA — older users don't need it; Hotwire gives server-rendered HTML the reactivity it needs, and there is no API layer to maintain or version.
- Not eventual consistency — financial data; strong consistency from a single Postgres primary is the right default.
- Not blind / sealed-bid submission — analytics surfaces patterns more powerfully and without friction.
- Not generative invoicing — invoice batches track the bridge; the invoice itself is generated by the sender's accounting system.
- Not embedding role inside audit log entries — historical events stand on their own; role is queryable from membership data whenever needed.
- Not a heavy front-end build pipeline — import maps / Propshaft (or a thin esbuild + Tailwind step) only; we resist the gravitational pull toward a Node toolchain the product doesn't need.

### Alternatives considered

- **Phoenix LiveView + Ecto + Oban.** On paper the most natural fit for shared-state realtime UI, and stateful server-side diffing is genuinely smoother than broadcasting partials for high-frequency updates. Rejected for *this* build because Rails wins on ecosystem maturity, library breadth (CSV, PDF, auth, admin, background jobs), hiring pool, and operator familiarity — and our human-paced update cadence never needs LiveView's edge.
- **Supabase + Next.js + AG Grid.** Rejected — the React SPA aesthetic skews against the dense business-app feel, and it reintroduces an API-serialization layer Hotwire lets us skip.
- **Django + HTMX.** The closest philosophical cousin — server-rendered, hypermedia-driven, no SPA. Rails chosen over it for Hotwire's tighter first-party integration (Turbo Streams + Action Cable + Stimulus shipped and supported together) and the richer Ruby web ecosystem.
- **Filament (Laravel).** Most polished admin UI out of the box, but the stack is less familiar than Rails and the admin-panel framing pulls toward the *master* pattern we're explicitly avoiding.

### Deployment

Deployed with **Kamal 2** (the Rails 8 default) — a Dockerized app shipped to a single small VPS to start, scaling to a few app containers behind a load balancer if volume warrants. Postgres runs as a managed instance (or a second box) so the database is backed up and operated independently of app deploys. A managed PaaS (Fly, Render) is an equally valid target and may be the faster path for v0; the architecture is host-agnostic. Kamal gives zero-downtime deploys, easy rollback, and no proprietary lock-in — consistent with *boring by default* and *deploys are cheap, fast, frequent, and reversible* below.

### Design prototype

A working React + Vite + Tailwind v4 prototype implements the visual design language (see *Canonical screens*). The prototype is for design iteration only — not the production stack. The production application is a **modern Rails app (Hotwire)**; the prototype's role is to pin down typography, spacing, color palette, table density, status pill treatment, and component patterns (Variance Status callout, Activity Log, Weigh Tag Comparison table) before they're translated into server-rendered **ViewComponents + ERB**, wired up with Turbo and Stimulus. Keeping design and production stacks separate during early iteration is deliberate: the React prototype is fast to change and cheap to throw away; the Rails implementation is the thing that needs to last. Tailwind carries across the boundary — the same utility classes the prototype uses are compiled into the Rails app (via `tailwindcss-rails`), so the translation is component structure and data wiring, not a visual re-derivation.

The prototype was originally exported from a Figma Make session and has been iterated on directly in code. Source lives at [`docs/design/prototype/`](design/prototype/).

## The app is the business

WeighTags is not a venture that builds a product and moves on to the next thing. The codebase *is* the business — every line we write becomes operational infrastructure that paying customers rely on for commercial settlement. The team's job is to operate that infrastructure indefinitely, not to ship a thing and look elsewhere.

This framing has consequences for how we engineer, deploy, and invest in the codebase.

### Operating principles

- **The codebase is a long-lived asset.** Maintainability is funded work, not stolen time. Refactoring happens deliberately each cycle, before debt compounds into a rewrite. An ugly module that works today is a tax on every future feature; the tax gets paid in the cycle it's noticed.
- **Deploys are cheap, fast, frequent, and reversible.** Continuous deployment from green main via Kamal. Multiple deploys per day are normal, not exceptional. A bad deploy rolls back on health-check failure. The pipeline itself is a product the team owns and improves; CI runtime, flake rate, and deploy time are tracked metrics.
- **Money-adjacent paths are covered.** Every Load state transition, every dispute-clock event, every auto-accept fire, every invoice batch action has explicit test coverage (model and system specs — RSpec or Minitest, with system tests driving real Turbo interactions). Audit-log invariants are enforced at the database level with constraints and triggers, not in application code that can drift.
- **Observability is built in, not bolted on.** Structured logs on every state transition. Traces on every realtime broadcast. Alerts on dispute-clock anomalies, auto-accept misfires, notification delivery failures, and CSV ingest errors. The goal is to see problems before customers do.
- **Production incidents are material.** Blameless postmortems, action items tracked to completion, runbooks updated, alert thresholds re-tuned. The audit log we keep for customers also serves us when something goes wrong on our side.
- **Boring by default.** Rails + Postgres + Solid Queue is one runtime, one database, one job queue — and with Solid Cache and Solid Cable also on Postgres, there's no Redis or separate broker to babysit. Adding new infrastructure requires explicit justification against operational cost. Boring is the goal because boring is what scales without a team to babysit it.
- **A refactoring budget is real budget.** A standing share of every cycle goes to paying down debt, hardening tests, improving observability, and improving developer experience. The exact share is calibrated to debt pressure, but it is never zero, and it is never the residual after features.

### Why this matters specifically for WeighTags

The product is in a category where reliability *is* the value proposition. A customer using us is choosing us *over* email-and-Excel — and email-and-Excel, for all its faults, doesn't lose messages, doesn't fire auto-accept on the wrong load, doesn't get its row counts wrong. Our reliability bar is higher than typical SaaS because our mistakes inform real money downstream.

The disciplines above are how we earn the right to be a system of record. Skipping them is the same business decision as not buying liability insurance: cheap until it isn't.

### Self-supporting

"The app supports itself" also means revenue covers costs. The pricing model, gross margin target, and minimum viable customer count are open questions that need to land before v2. Tracked in *Market paths and pillars of success* below.

## Risks / open questions

- **Service reliability.** Incorrect auto-accept firing, lost notifications, or data loss would draw us into disputes that didn't need to happen. Higher SaaS reliability bar than typical CRUD because state transitions inform real money downstream.
- **UI clarity around platform state vs. parties' actual agreement.** Copy should lean on the *evidential* frame — *"recorded,"* *"notified,"* *"uncontested as of [date]"* — rather than even *"accepted,"* which overstates the platform's role. We record and notify; we do not adjudicate (see *Strategic wedge*).
- **BOL reliability across target commodities.** Validated in domain, worth confirming with first customers.
- **Dispute window default and tolerance defaults.** Must be configurable per relationship.
- **Email deliverability.** Critical; production ESP (Postmark / SES) from day 1, wired through Action Mailer.
- **Single-sided invite friction.** Does this feel pushy to invited partners? Adoption-side risk worth measuring early. The *evidential* framing (a neutral record of what was shown and notified, not a declared concession) is the intended mitigation — but whether invitees *perceive* it as neutral is the thing to measure, not assume.
- **Data handling.** Commercially sensitive information for both sides; security, isolation, access logs.
- **Data retention policy.** Tax, audit, and insurance use cases assume long retention (7+ years). Pricing and storage cost implications worth thinking through before launch.
- **Sole-admin departure.** If an Org has only one admin and that user leaves, the Org could be orphaned. Mitigations: persistent warning banner; onboarding nudge to invite a colleague; domain-verified admin recovery; support-mediated recovery as last resort.
- **Email deactivation post-departure.** A departing user's work email may be cut off before they've handed over admin. Mitigation: encourage personal email as backup recovery on the account, or domain-verified recovery for the Org itself.
- **Realtime fan-out at scale.** Solid Cable on Postgres is right-sized for our human-paced cadence and modest concurrency, but it is the one component to watch if a single Load ever attracts many simultaneous viewers; the mitigation (swap Solid Cable's adapter, or move Action Cable to a dedicated process) is well-trodden and deferred until usage demands it.

## Milestones

### v0 — private alpha (1 grower / 1 buyer, hand-held)

CSV upload from one side. Magic-link invite to counterparty. Auto-match on BOL and basic smart pairing. Side-by-side diff (Hotwire, Turbo Frames). Manual timeout management (no Solid Queue / background jobs yet — fire reminders and auto-accept by hand). Manual export. Single-user-per-org acceptable; admin management deferred.

### v1 — paid pilot (3-5 relationships)

Multi-org auth + RBAC, with proper User / Org / Membership separation. CSV import with validation + error report. Full state machine with Solid Queue-driven timeouts, reminders, and notifications. Realtime Load updates via Turbo Streams. Compromise resolution. Audit trail visible to both sides. Search, filter, and export across historical weigh tags. Per-relationship tolerances and dispute windows. Invoice batches (sender marks tags as invoiced; receiver verifies via badge and search; PDF summary export). Admin management UI (invite, promote, end membership). Persistent sole-admin warning.

### v2 — public launch

Configurable everything. Counterparty address book. Notifications inbox. Self-serve signup. Domain verification and domain-based admin recovery. Print-friendly views and PDF export beyond invoice batches. Public API (the v2 ingest channel) layered on the same domain services the UI uses.

## Hypothesis: Insights / Analytics (post-MVP, lower speculation)

Once volume accumulates, aggregate views of historical weigh tag data become valuable in their own right: pattern detection across a partner relationship (average net delta, distribution of disputes, dispute resolution time), and cross-partner comparison from a single user's perspective. The audit log already captures the underlying data; insights are aggregation queries with a view layer.

Meaningfully less speculative than the settlement expansion below — the infrastructure is built into the MVP, the use case is clearly latent, and the upsell path is natural. Probably v2 or just post-v2.

## Hypothesis: settlement expansion (speculative, post-MVP)

The platform *may* extend from tracking invoice batches into generating the invoices themselves — adding pricing per unit, applying contract terms, producing the final billed amount. From there, payment tracking, and eventually payment rails. Not a committed roadmap; a direction informed by the observation that reconciled tags often face a second reconciliation downstream (bill vs. tag, payment vs. bill), and that the invoice-batch concept already sits one step from invoice generation.

**Signal that would support pursuing it:** customers asking for price-per-unit / total-due fields on invoice batches; repeat downstream disputes; bookkeeper time still significant after tags reconciled; willingness to pay materially more for settlement.

**Signal that would invalidate it:** customers happy taking reconciled CSV and the invoice-batch bridge into existing accounting; per-customer pricing complexity too fragmented for a generic invoicing layer; compliance / regulatory cost exceeds value.

The architecture leaves room without committing: the invoice batch entity is already there, ready to grow pricing and total-due fields if signal supports it.
