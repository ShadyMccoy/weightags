# CLAUDE.md — agent orientation

Guidance for any agent (or person) working in this repo. Keep it short; it's loaded into context
every session. **Do not put load-bearing decisions only in an agent's local memory — it is not shared.
Record them in the tracked docs below.**

## What this project is

WeighTags — weigh-tag reconciliation between commodity growers and buyers. A neutral, **multiplayer**
system of record that auto-pairs tags on BOL, surfaces discrepancies in a shared diff view, and
resolves disputes on a deterministic clock. Currently in **charter phase** — no app scaffolded yet
(`app/` holds a placeholder `hello.rb`).

## Source of truth — read these first

| Doc | Role |
|---|---|
| [`docs/charter.md`](docs/charter.md) | **Canonical.** Vision, market, data model, architecture, milestones. When in doubt, this wins. |
| [`docs/roadmap.md`](docs/roadmap.md) | The build plan: feature-by-feature, each with its own gate. |
| [`docs/design/`](docs/design/) | Design language, status palette, mockups, and the live prototype. |
| [`docs/design/prototype/`](docs/design/prototype/) | React/Tailwind **design source of truth** — design-only, *not* production. |

If a decision is made in conversation, **fold it into the relevant doc** — don't rely on memory to
carry it. The charter is the arbiter; this file and the roadmap defer to it.

## Load-bearing decisions (all detailed in the docs above)

- **Stack:** Rails 8 + Hotwire (Turbo + Stimulus) + Postgres + Solid Queue, deployed with Kamal.
  Boring-by-default; new infra needs justification. (charter → *Architecture*)
- **Build posture:** build the **feature-complete SaaS first, then listen for signal**. A thin
  money-adjacent tool yields dishonest signal; the scope is contained enough that completeness is
  cheap. (roadmap → *How to read*)
- **Gates are per-feature, not per-solution.** Each feature is done when its own gate is green; the
  build is launch-ready when all are. Market/signal gates come only *after* launch. (roadmap)
- **UI is engineering.** A screen translated to production Rails (Hotwire — ViewComponents + Turbo)
  with the correct status palette and multiplayer layout is a gated deliverable, not decoration. New
  screens are prototyped in `docs/design/prototype/` first.
- **The wedge is evidential, not contractual.** The default-accept timeout produces a neutral record
  of "shown, notified, uncontested" — not a claim of legal acceptance. UI copy avoids "accepted." It
  is also the audit-log moat — the same asset. (charter → *Strategic wedge*, *Risks*)
- **Adoption motion = records gravity + dispute-moment activation.** One party adopts for solo value;
  the counterparty is pulled in wanting the data and activates at a discrepancy via a one-click
  **Dispute**. Activation funnel: **invoice → look up tag → Dispute.** The timeout is a backstop, not
  the lead. (charter → *Strategic wedge*; roadmap → adoption funnel, feature B4)
- **Build symmetric; let adoption be asymmetric.** Symmetric multiplayer is an *architecture*
  invariant (data ownership, sender-left/receiver-right, symmetric actions, audit attribution). It is
  *not* an adoption constraint — adoption is often asymmetric, and that's fine. (charter → *Positioning
  principle*)
- **The app is the business.** Money-adjacent paths covered; audit invariants DB-enforced; reliability
  is the value proposition, not a bolt-on. (charter → *The app is the business*)

## Working conventions

- Platform is Windows (PowerShell). Production target is Linux (Docker via Kamal).
- Once scaffolded, the app lives in `app/` (Rails); the prototype stays design-only in `docs/`.
- Commit/push only when asked.
