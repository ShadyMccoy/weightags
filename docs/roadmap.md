# WeighTags — Development Roadmap

*Draft v3 — derived from [charter.md](charter.md). The charter is the source of truth; where this
roadmap and the charter disagree, the charter wins and this document is wrong.*

---

## In plain English (start here)

*The rest of this doc is the precise build plan with exact pass/fail criteria. This section is the
same plan, explained like you're smart but new to it. If the two ever disagree, the detailed
sections below win.*

### What are we even building?

When a farmer hauls a truckload of grapes (or grain) to a buyer, **both sides weigh the
load** and write down a number. Then they compare. When the numbers don't match — and they often
don't — someone's getting shorted, and it turns into phone calls, emails, and arguments. Today this
happens on paper tickets and spreadsheets that each side keeps separately, so there's no shared
truth.

WeighTags is a **neutral scoreboard both sides can see at once.** Each side uploads its weigh-tickets
("tags"), the system automatically matches the grower's ticket to the buyer's ticket for the same
load, and shows them side by side with the difference in the middle. If there's a disagreement, you
hit one button — **Dispute** — and there's a fair, ticking clock to resolve it. Think Google Docs,
but for "how much did this truck actually weigh," with a permanent receipt of who saw what and when.

Two ideas to hold onto:

- **Multiplayer.** It's not one company's tool — it's a shared record between two parties. The
  grower's data is on the left, the buyer's on the right, both see the same screen, and every action
  is stamped with who did it.
- **Evidential, not contractual.** If nobody disputes a load before the clock runs out, the system
  records "this was *shown, notified, and uncontested*." It is **not** saying "you legally agreed."
  That neutral record — the full history of who saw what — is the thing competitors can't easily copy.

### The big strategic bet

Most startups ship a tiny version first and see if anyone bites. **We're doing the opposite: build
the whole thing first, *then* see if it pulls.** Why? Because this is a money tool. Nobody trusts a
half-built product with their billing. A flimsy demo would give us a *fake* "nobody wants this"
signal when the real problem was that it looked untrustworthy. The whole product is small enough that
just finishing it is cheaper than running dishonest experiments. So: **finish, launch, then listen.**

### How we know when a piece is "done"

Two different kinds of checkpoints — don't mix them up:

- **Feature gates** = "is this *piece* built right?" Every feature has a short, yes/no checklist.
  These are pure engineering questions (does it work, is it tested, is the screen correct). Notably,
  **the UI counts as engineering** — a screen built with the right colors and layout is a real
  deliverable, not "decoration we'll polish later."
- **Signal gates** = "is the *market* responding?" These are the only "should we keep going / change
  direction" decisions, and **they all happen after launch.** By the time we're asking a market
  question, the product is already finished.

There is deliberately **no single "is the whole thing done?" meeting.** The build is launch-ready
when every individual feature's checklist is green — it's a mechanical roll-up, not a judgment call.

### The order we build in

Foundation first, then four waves. Each builds on the last:

| | | In plain terms |
|---|---|---|
| **Phase 0** | Foundation | Lay the plumbing *before* any feature: set up the framework, the database, auto-deploy, and the rule that **the history log can never be edited or deleted** (enforced by the database itself, not just by being careful). Reliability is the product, so we pay for it up front. |
| **Wave A** | Spine & ingest | Logins and orgs, the app shell, and **getting data in**: bulk CSV upload (the flagship — "it's in the *name*"), typing tags in by hand at the scale house, and inviting a partner who doesn't have an account yet. |
| **Wave B** | Reconciliation core | The heart: **auto-match** the two sides' tickets into one shared "Load," show them **side by side with the difference**, let each side Accept / Dispute / Edit / propose a compromise, and run the **dispute clock** that auto-resolves stale loads. |
| **Wave C** | Record & money bridge | Make it a real system of record: an unforgeable **history log**, **search/filter/export**, per-partner tolerance settings, and **invoice batches + printable PDFs** — connecting reconciled loads to the bill without us touching the money itself. |
| **Wave D** | Org maturity & launch-ready | The grown-up stuff so strangers can use it with zero hand-holding: admin tools, self-serve signup, domain verification, **notifications**, and **alerting** so *we* find out when something breaks, not the customer. |

### How the product actually spreads (the clever part)

We don't sell to both sides. The plan:

1. **One side (call them A) adopts it alone** because it's genuinely useful even solo — a clean record
   of all their loads. So A's solo experience has to be *excellent*.
2. **A invites their partner B**, who gets pulled in because they *want to see A's data* — no password
   needed just to look.
3. **The magic moment is a disagreement.** B is checking an invoice, looks up a tag, sees the numbers
   are off, and hits **one-click Dispute.** That single click is the whole conversion — it turns a
   passive viewer into an active user. That's why the Dispute button gets first-class, obvious,
   in-context treatment instead of being buried in a menu.

The auto-resolve clock is just a **safety net** underneath all this, not the main attraction.

### After launch: how we judge it (and when we'd quit)

Once it's live in front of real grower↔buyer relationships, we stop building and start watching. The
test isn't "did we hit a big revenue number" — it's "**is the line sloping up at small numbers?**"
Specifically: does the inviter keep posting? Does the invitee actually *engage* (dispute things)
instead of just letting the clock run? Does an invitee eventually invite *their own* counterparty
(that's the network spreading)? Will someone *pay*?

And we're honest about quitting. There are pre-committed **kill criteria** checked every 3 months in
year one — e.g. "people pay but nobody organically invites anyone new," or "trajectory clearly isn't
heading toward ~50 paying customers," or even "the work stopped being interesting." The bar to keep
going is low *on purpose*, because we're measuring the slope, not the size.

---

## How to read this

The posture is **build the complete SaaS first, then listen for signal** — WeighTags is a
well-contained project, and a thin money-adjacent tool generates dishonest signal because customers
won't trust a half-built reconciliation product with real billing (see *The end goal* and the charter's
*Why this matters specifically for WeighTags*). So the engineering work is roadmapped to the
**feature-complete vision**, not a minimal slice.

This draft gates that work **per feature, not per solution.** There is no single "is the whole thing
done" checkpoint. Instead:

- **Feature gates** — every feature below carries its own gate: a small set of binary done-criteria
  on top of a shared *Definition of Done*. A feature is not "done" until its gate is green; the build
  is launch-ready when **every** feature gate is green (a mechanical roll-up, not a separate judgment
  call). Feature gates are pure engineering — completeness, trust, and **UI** (a screen translated to
  production Rails (Hotwire) with the correct status palette and multiplayer invariants is an
  engineering deliverable, not decoration).
- **Signal gates** — the only solution-level gates, and they all sit **after launch** (Phase 2). They
  decide *direction and continuation* — iterate, pick a vertical, scale, hold, or kill — never whether
  to finish a feature. By the time a signal gate fires, the features are done.

```
 Phase 0           Phase 1 — Build the feature-complete SaaS              Phase 2
 Foundation   ┌── Wave A ──┬── Wave B ──┬── Wave C ──┬── Wave D ──┐   Launch & Listen
 (G0 gate)    │  spine &   │ reconcile  │ record &   │ org &      │   (signal gates
              │  ingest    │  core      │ money      │ launch-rdy │    on kill cadence)
              └─ each feature carries its own gate (✓ = green) ──┘
              build is launch-ready when every feature gate is green
```

---

## The end goal (what the signal gates point at)

From the charter's *Estimates* and *Kill criteria*: the goal is **not** a revenue number — it is a
**positive slope at small numbers**. Success anchor: 500 paying customers / $120K ARR, near-zero CAC,
fat margins, reached without forcing because the default-accept wedge does the acquisition work. The
wedge's force is **evidential, not contractual** (charter *Strategic wedge*) — a neutral record of
"shown, notified, uncontested," which is also the audit-log moat. Every signal gate asks one question:
**does the wedge pull?** The feature gates ask a different question we answer for ourselves first: **is
each piece complete and trustworthy enough to make that test honest?**

---

## Definition of Done (inherited by every feature gate)

Every feature gate below adds its specifics *on top of* these. A feature is not done until all of
these hold, plus its own criteria:

- **Functional end-to-end** behind a feature flag; reachable in a deployed environment.
- **Tested** — suite green; any money-adjacent path (Load state change, clock event, invoice action,
  ingest) has **explicit** coverage.
- **Audited** — any state change the feature introduces writes an append-only `audit_events` row;
  the invariant stays DB-enforced.
- **UI correct** (if it has a surface) — translated from [`design/prototype/`](design/prototype/),
  status palette by register (amber = attention, red = active conflict only), sender-left/receiver-
  right preserved, one-sided tags show explicit `—`, read-first/edit-deliberate.
- **Observable** where it touches a money-adjacent path — structured logs, and an alert if it can fail
  silently.
- **Shipped on green main** via continuous deploy — no long-lived branch, no manual release.

---

## Phase 0 — Foundation (gate G0)

Prerequisite infrastructure, built before any feature, because the charter funds reliability as work,
not a bolt-on (*The app is the business*).

**Build:** `rails new` Rails 8 + Hotwire (Turbo + Stimulus) + Postgres + Solid Queue in `app/`
(replaces `hello.rb`); minimum viable Kamal infra (one app container on a small VPS, one Postgres
primary, public URL; Fly/Render a valid alternative target); green-main continuous deploy with
auto-rollback on health-check failure; migrations for the seven tables; **append-only audit invariant
enforced at the DB level**; production ESP (Postmark/SES) wired via Action Mailer; structured logging
+ one realtime trace; [`design/prototype/`](design/prototype/) established as the design source of truth.

**Gate G0 — done when:**
- A trivial change deploys from green main and auto-rolls-back on a forced health-check failure (proven once).
- A test attempting `UPDATE`/`DELETE` on `audit_events` fails at the DB.
- A test email is delivered through the production ESP to a real inbox.
- CI green; runtime/flake/deploy-time dashboards exist.

---

## Phase 1 — Build the feature-complete SaaS

Features are grouped into four dependency-ordered waves. Within a wave, features can be built in
parallel except where *Depends on* says otherwise. Each carries its own gate (inheriting the
*Definition of Done* above).

### What the features are *for* — the adoption funnel

The build serves the charter's adoption motion (*Strategic wedge* — records gravity + dispute-moment
conversion), and that motion ranks which features are load-bearing for *activation*, not just
completeness:

1. **A's solo record must be excellent** — A adopts for single-player value and must want it even if B
   never shows. Load-bearing: **A3** (CSV import), **A4** (direct entry), **C2** (search / export).
2. **B's read access must be frictionless** — B is pulled in by wanting A's data. Load-bearing:
   **A5** (no-password invitee view), **B3** (diff view).
3. **The conversion is invoice → tag → Dispute** — B's first real action is a discrepancy at invoice
   time. Load-bearing: **C2 / C4** (find the tag by invoice number) → **B4 (Dispute)**, which is *the
   activation event*, not merely one of several symmetric actions. Its UX gets first-class attention:
   contextual, one-click, obvious at the moment B notices the discrepancy.

The timeout (**B5**) is the backstop beneath this funnel, not its driver.

### Dependency map

| Feature | Depends on |
|---|---|
| **A1** Identity & tenancy | G0 |
| **A2** App shell, landing, empty states | A1 |
| **A3** CSV import (flagship) | A1 |
| **A4** Direct entry + manual entry | A1 |
| **A5** Ghost-account invite & org claim | A1, A3 |
| **B1** Auto-pair on BOL → Load | A3/A4 |
| **B2** Smart pairing + mutual confirmation | B1 |
| **B3** Load diff view | B1 |
| **B4** Per-side actions + state machine | B3 |
| **B5** Dispute clock (Solid Queue) + manual override | B4 |
| **C1** Audit trail + activity feed | B4 |
| **C2** Search / filter / aggregate / export | B1 |
| **C3** Per-relationship tolerances + windows | B3, B5 |
| **C4** Invoice batches + PDF | B4 |
| **D1** Admin management + sole-admin warning | A1 |
| **D2** Self-serve signup | A1 |
| **D3** Domain verification + admin recovery | A1, D1 |
| **D4** Notifications (email + inbox) | B5, C4 (events) |
| **D5** Observability & alerts | B5, A3, D4 |

---

### Wave A — Spine & ingest

**A1 — Identity & tenancy.** User / Org / Membership separation; auth (email+password primary,
magic-link for recovery + invite); org-scoped data isolation (RLS default + app-level for shared
records); multi-org switching.
*Gate:* a user belongs to ≥2 orgs and switches between them; cross-org data access is denied by RLS in
a test; magic-link recovery works; audit attribution references the user, role not embedded.

**A2 — App shell, landing, empty states.** Navigation chrome, landing/marketing page, and helpful
empty-state home for a brand-new sender (charter *Still to design*).
*Gate:* a new org with zero tags sees a guiding empty state, not a blank table; landing page renders;
footer chrome (timezone, last-sync) present per canonical list screen.

**A3 — CSV import (flagship — *Ingest excellence*, "it's in the name").** Strict schema, per-row
validation, **column-mapping + validation preview** before commit, and an **error report** for
rejected rows. Built complete, not basic.
*Gate:* a malformed file is rejected row-by-row with a downloadable error report; a valid file previews
mapped columns and commits exactly the previewed rows; partial-failure is all-or-nothing per the
preview; ingest errors alert us (money-adjacent).

**A4 — Direct entry + manual entry.** Scale-house form: pre-fill from last entry, autocomplete
truck/driver, save-and-add-another; plus a manual single-entry fallback (charter *Key workflow 1*).
*Gate:* an operator saves consecutive tags without leaving the form; common fields pre-fill from the
last entry; truck/driver autocomplete from recent entries; a saved tag is visible to the partner
immediately (Turbo Streams).

**A5 — Ghost-account invite & org claim.** Tags addressed to an email create a placeholder Org;
invitee claims via magic link, no password first; onboarding nudge to invite a colleague (charter
*Key workflow 7*). Copy uses the **evidential** frame (shown / notified / uncontested), never "accepted."
*Gate:* an invite to a non-existent partner creates a placeholder org and a working claim link; the
invitee views the diff before setting a password; claiming makes prior tags accessible; the nudge fires.

---

### Wave B — Reconciliation core

**B1 — Auto-pair on BOL → Load.** Set-based join pairing one tag from each side into a shared Load;
Load is visible to both orgs.
*Gate:* two tags with the same BOL from opposing orgs auto-form one Load visible to both; one-sided
tags render as Left-only/Right-only with explicit `—`.

**B2 — Smart pairing + reconciliation (identity resolution).** Fuzzy reference match (Levenshtein +
date/truck/weight corroboration) on differing references, plus **manual merge / split**. Governance is
optimistic and symmetric per the charter (*Governance of shipment identity*): on **open** Tags a single
confirm + notice links a suggested match; **mutual confirmation is required only when a merge/split would
alter a settled (resolved/invoiced) record.** Merge re-homes weighs and GCs the emptied husk; split
mints a Tag and moves weighs; every op is reversible, notified, and audited. (Earlier drafts required
mutual confirmation for all pairing — relaxed here so the cooperative wedge stays low-friction.) The
**weigh-in-against-the-partner's-Tag** ingest path (charter *Key workflow 1*) makes this the exception,
not the rule.
*Gate:* a near-miss reference surfaces a suggestion; one participant confirming links it on an open Tag
and notifies the other; either party can split it back (reversible); a merge/split touching an invoiced
Tag is refused until un-invoiced; every op is audited; a GC'd husk leaves its audit events intact.

**B3 — Load diff view.** Sender-left / receiver-right comparison, centered delta column (absolute +
%), Variance Status callout, per-side provenance (moisture, weighed_by, scale_id, weighed_at, notes),
Activity Log table (canonical screens 02–04).
*Gate:* deltas compute and color by tolerance (within = neutral, exceeds = amber); both sides'
provenance shows; layout holds with one side missing; identical regardless of which party is logged in.

**B4 — Per-side actions + state machine.** Accept, Dispute (structured reason), Edit own tag (required
reason), Propose Compromise, Add note, Re-review on post-view edits; the full Load state machine with
deliberate transitions and resolution provenance. **Dispute is the activation event** of the adoption
funnel (charter *Strategic wedge*), so its UX is first-class: contextual on the Load/tag, one click to
start, obvious at the moment a discrepancy is noticed — not buried in a symmetric action ribbon.
*Gate:* every charter Load state is reachable by its action and writes the correct audit entry; edit
preserves prior values; compromise can set canonical values matching neither tag; **Dispute is
reachable in one click from a discrepancy (including from an invoice-number lookup) and from the
invitee's no-password view**; **every transition has explicit test coverage.**

**B5 — Dispute clock (Solid Queue) + manual override.** Clock starts when both sides post; reminders at
T+N/2 and T+N−1; auto-accept at T+N defaulting to sender's tag; idempotent under retry; manual
override retained as an operational safety valve.
*Gate:* **auto-accept fires correctly and only correctly** — right Load, sender's values, right time,
idempotent under forced Solid Queue retry; reminders deliver at both marks; a dispute pauses the clock;
auto-accept misfires and clock anomalies alert us. (Highest-stakes feature; this gate is the strictest.)

---

### Wave C — System of record & money bridge

**C1 — Audit trail + activity feed.** Per-Load activity log plus a cross-load, filterable feed; role
not embedded in entries; attribution durable across job changes.
*Gate:* every state transition appears in both the Load log and the cross-load feed; entries say
"Mary Lin disputed BOL 10849" (no embedded role); a departed user's past actions stay attributed.

**C2 — Search / filter / aggregate / export.** Filter by BOL, date, partner, truck, driver, status,
**invoice number**; aggregate totals (count, gross, tare, net) for any filtered range; CSV export of
the filtered view (charter system-of-record stories).
*Gate:* a filtered view exports exactly its rows to CSV; aggregate totals match the filtered set;
"Closed, not yet invoiced" is a selectable filter; search by invoice number returns linked tags.

**C3 — Per-relationship tolerances + dispute windows.** Configurable per partner; actually drive the
"within tolerance" flag and the clock duration (charter *Risks*).
*Gate:* changing a partner's tolerance re-colors the delta/Variance Status; changing the window changes
when reminders + auto-accept fire for that partner; defaults apply when unset.

**C4 — Invoice batches + PDF.** Sender multi-selects closed tags and marks invoiced under an external
invoice number; receiver verifies via badge + search; printable PDF summary (Grover). Platform
tracks the bridge, not the monetary total (charter *Non-goals*).
*Gate:* a closed tag belongs to at most one batch; an invoiced tag shows the badge to the receiver;
the PDF (header, invoice #, tags, totals, verification URL) renders print-clean; batch actions audited.

---

### Wave D — Org maturity & launch-readiness

**D1 — Admin management + sole-admin warning.** Invite users, promote/demote roles, end membership
(preserving historical audit attribution); persistent banner when an org has one admin.
*Gate:* an admin invites + promotes a colleague; ending a membership removes access but preserves
audit history; the sole-admin banner shows until a second admin exists.

**D2 — Self-serve signup.** A stranger signs up, creates an org, posts tags, and invites a partner
with zero operator involvement (pulled forward so launch needs no hand-holding).
*Gate:* full signup → first tag → first invite completes with no operator action; the post-claim nudge
to invite a colleague fires.

**D3 — Domain verification + admin recovery.** Verify org domain (DNS TXT or email-confirmation);
domain-verified admin recovery closes the orphaned-org risk (charter *Risks*).
*Gate:* a domain verifies via TXT or email; a same-domain user can request admin recovery on a
verified org; recovery is audited.

**D4 — Notifications (email + inbox).** Email on every relevant event (new tags, clock started,
dispute filed, auto-accept fired, partner edited, tags invoiced) plus an in-app notifications inbox.
*Gate:* each listed event sends an email **and** posts to the inbox; no notification is the *only*
copy of a state change; delivery failures alert us, not the customer.

**D5 — Observability & alerts.** Alerts on dispute-clock anomalies, auto-accept misfires, notification
delivery failures, and CSV ingest errors; structured logs on every state transition; traces on
realtime broadcasts (charter *Observability*).
*Gate:* a synthetic auto-accept misfire, a held notification, and a malformed CSV each raise an alert
in a test; every state transition emits a structured log.

---

### Launch-ready roll-up

The build is launch-ready when **A1–A5, B1–B5, C1–C4, D1–D5 gates are all green.** This is a checklist,
not a judgment gate — there is no separate "is the solution done" decision. Market judgment begins only
in Phase 2.

---

## Phase 2 — Launch & Listen (signal gates)

The finished SaaS goes in front of real relationships. This phase builds almost nothing new; its
product is **signal**. Launch motion (charter *Operating posture*): one or two warm seeds; public beta
visible to anyone with a link; no paid acquisition; vertical/geographic pattern detection on inbound
usage; instrumentation for the charter's *Feedback mechanisms*.

### Signal gates (evaluated on the charter's kill cadence — every 3 months in year 1)

These decide direction and continuation, **not** feature scope. The features are done.

| Signal | If present | If absent (per *Kill criteria*) |
|---|---|---|
| Inviter posts week-over-week | Wedge working; look for propagation | Strong prior the wedge doesn't pull |
| Invitee **engages** (not just lets auto-accept fire) | Healthy | Work invite friction / time-to-value; if still flat after a fair trial → lean Kill |
| **Complaint → Dispute conversion** — invitee's first action is a one-click in-platform Dispute, not an email | The activation funnel works; records-gravity is real | The "easy Dispute button" isn't converting the dispute moment — the core motion is broken; investigate before scaling |
| Invitee invites their **own** counterparty | Network propagating → consider scaling | 3 mo post-paid with no propagation → **Kill** |
| A **paying** customer | Pricing validated | Re-examine willingness-to-pay |
| Concentration in a vertical/geography | Take the matching **Branch** (winery / grain) | Diffuse → stay generic (a valid outcome) |
| Paid referral or recurring feature request | Invest there | — |

**Decision framework:** **Scale / commit to a vertical** on propagation + a center of gravity;
**Iterate** the friction levers on weak-but-present engagement; **Hold** as a steady-state business if
usage is real but diffuse (a success, not a failure); **Kill** per the charter cadence below.

---

## Post-launch — hypothesis branches (signal-gated, not scheduled)

- **Insights / Analytics** (lower speculation) — per-partner aggregates, cross-partner comparison.
  Gate: volume accumulated *and* customers ask relationship-level questions.
- **Settlement expansion** (speculative) — invoice generation (pricing, terms, total due) → payment
  tracking. Gate: customers ask for price/total-due on batches; repeat downstream disputes; willingness
  to pay materially more. Invalidated by: customers happy taking reconciled CSV into existing accounting.
- **Vertical investment** — on Phase 2 concentration signal: winery → crush.wine v2 API; grain → the
  cross-network niche Bushel structurally can't close.

---

## Cross-cutting engineering gates (continuous, every cycle)

Standing conditions every cycle, because the codebase **is** the business. A release regressing any is
blocked regardless of feature:

- **Money-adjacent coverage never decreases.**
- **UI invariants hold every release** (palette by register; sender-left/receiver-right; symmetric
  actions; read-first/edit-deliberate). Correctness, not polish.
- **Audit invariants stay DB-enforced.**
- **Refactoring budget is non-zero** — never the residual after features.
- **Boring-by-default** — new infra beyond Rails + Postgres + Solid Queue needs explicit justification.
- **Pipeline health tracked** — CI runtime, flake rate, deploy time with thresholds.
- **Incidents are material** — blameless postmortem + tracked actions + runbook update on any
  money-adjacent incident.

---

## Kill-checkpoint cadence

Per charter (*Feedback mechanisms*): **kill-criteria review every 3 months in year 1**, evaluated in
Phase 2 (features already built; these judge the market, not the product). The bar is low *by design* —
we check the *slope*, not the absolute number.

| Checkpoint | Kill condition |
|---|---|
| 3 mo post-paid-launch | Paying customers but no organic invite propagation. |
| 6 mo post-launch | Zero repeat customers. |
| Any review | Trajectory not pointing toward ≥50 paying customers after a fair trial. |
| Any review | A clearly superior in-segment incumbent we can't differentiate against. |
| Any review | Operating cost > revenue with no plausible 12-month path. |
| Any review | The work stops being interesting. |

---

## Sequencing notes

- **Foundation first.** Audit invariant + rollback pipeline are cheapest on an empty repo, dearest to
  retrofit onto a live system of record.
- **Gates are per feature, not per solution.** Each feature is done when its own gate is green; the
  build is launch-ready when all are. There is no monolithic "is the whole thing done" gate — that
  coarseness is what this draft removes.
- **The dispute clock (B5) has the strictest gate.** A wrong auto-accept is the charter's top
  reliability risk; it ships *with* its alerting (D5 dependency) and a manual override, gated on
  correct-and-only-correct firing under retry.
- **CSV import (A3) is a flagship, gated complete** — validation, mapping preview, error report from
  the start; *Ingest excellence* is in the name.
- **Multiplayer + UI are inside every feature gate**, never a later pass.
- **Signal gates sit after the whole build.** They decide vertical / iterate / scale / hold / kill —
  never whether to finish a feature.
