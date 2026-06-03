# WeighTags

Neutral, multiplayer system of record for weigh-tag reconciliation between commodity growers and
buyers. See [`../docs/charter.md`](../docs/charter.md) for the vision and [`../docs/roadmap.md`](../docs/roadmap.md)
for the build plan. This README covers the Rails app only.

## Stack

Rails 8 · Hotwire (Turbo + Stimulus) · PostgreSQL · Solid Queue/Cache/Cable · Tailwind CSS v4 ·
ViewComponent. Boring-by-default per the charter — one runtime, one database, no Redis.

## What's implemented

The full roadmap — Foundation (G0) and Waves A–D — is built and gated. Below by feature.

**Foundation (G0)**
- Rails 8 app on Postgres; seven core tables (`users`, `orgs`, `memberships`, `tags`, `loads`,
  `invoice_batches`, `audit_events`) plus supporting `partnerships`, `sessions`.
- **Append-only audit invariant enforced at the database** — a Postgres trigger raises on any
  `UPDATE`/`DELETE` of `audit_events`. The SQL schema format (`db/structure.sql`) carries the trigger
  into every environment, including test. (`db/migrate/*_enforce_audit_events_append_only.rb`)

**Wave A — spine & ingest**
- **A1** Identity & tenancy: User/Org/Membership separation, Rails 8 auth (email+password), multi-org
  switching, org-scoped data access — app-level scoping plus **Postgres row-level security** (forced
  policies on `tags`/`loads`/`invoice_batches`, scoped to the request's orgs; cross-org denial tested).
- **A5** Ghost-account invite & claim: naming a partner with an email creates a placeholder org and
  sends a magic link; the invitee views the diff with no password, then claims and becomes first admin.
- **A2** App shell, landing page, helpful empty states, the warm clerical design language and the
  charter status palette as ViewComponents.
- **A3** CSV import (flagship): loose header mapping, per-row validation, a mapping + validation
  **preview**, all-or-nothing commit, and a downloadable **error report** for rejected rows.
- **A4** Direct scale-house entry: pre-fill from last entry, truck/driver autocomplete, save-and-add-another.

**Wave B — reconciliation core**
- **B1** Auto-pair on BOL → shared Load (one-sided renders as awaiting-partner with explicit `—`).
- **B3** Load diff view: sender-left / delta-center / receiver-right, Variance Status callout,
  per-side provenance, Activity Log — identical regardless of which party is logged in.
- **B4** Per-side actions + state machine: Accept, **Dispute** (first-class, one-click), Edit own tag
  (required reason, prior values preserved), Propose/Accept Compromise, Add note. Every transition
  writes an append-only audit event.
- **B5** Dispute clock (Solid Queue): starts when both sides post a load that needs review; reminders
  at T+N/2 and T+N−1; auto-accept at T+N defaulting to the sender's values; a dispute pauses it.
  Idempotent under retry, with reminder + auto-accept emails (evidential copy) and structured logs.
- Realtime: Turbo Streams broadcast a morph-refresh to both parties on any change.

- **B2** Smart pairing: a one-sided tag with a near-miss BOL (Levenshtein ≤ 2) corroborated by date,
  truck, or weight surfaces a suggestion; the Load forms only after **both** parties confirm.

**Wave C — system of record & money bridge**
- **C1** Cross-load activity feed: every audited event on visible loads + the org's own actions,
  filterable; attribution durable across departures.
- **C2** Search / filter / aggregate / export: BOL/truck/driver, ship-date range, partner, status
  (incl. "Closed, not yet invoiced") and invoice number; aggregate totals; CSV export of the filtered rows.
- **C3** Per-partner tolerances + dispute windows; changes re-color open loads and retarget the clock.
- **C4** Invoice batches: sender marks closed tags invoiced under an external number; receiver verifies
  via badge + search; **print-clean PDF** (Prawn) and a public, indexable verification page.

**Wave D — org maturity & launch-readiness**
- **D1** Admin management: invite/promote/demote/end membership (audit-preserving), sole-admin banner.
- **D2** Self-serve signup → first tag → invite, with the post-claim "invite a colleague" nudge.
- **D3** Domain verification (email-confirmation or DNS TXT) + same-domain admin recovery.
- **D4** Notifications: every relevant event posts to an in-app inbox **and** emails; never the only copy.
- **D5** Observability: `OperationalAlert`/`Alerter` on auto-accept misfires, notification delivery
  failures, and CSV ingest errors; structured logs on state transitions.

### ViewComponents
`StatusPillComponent` (palette by register), `DeltaCellComponent` (absolute + %, tolerance colouring),
`VarianceStatusComponent` (within/exceeds callout).

## Deploy
Dockerized, deployed with **Kamal 2** (`config/deploy.yml`, `Dockerfile`, `.kamal/secrets`): one app
container + a job host (`bin/jobs` for the dispute clock) + a Postgres accessory, zero-downtime via
kamal-proxy with `/up` health checks. Production should connect as the non-superuser `weightags_app`
role so RLS binds. Fill in host/registry/domain, then `kamal setup` / `kamal deploy`.

## Develop

```bash
bin/setup                 # install gems, prepare DB
bin/rails db:seed         # demo grower↔buyer relationship across the status spectrum
bin/dev                   # Puma + Tailwind watcher
bin/rails test            # full suite (money-adjacent paths covered)
```

Demo logins after seeding (password `password`): `rachel@sycamore.test` (grower),
`jessica@pacific.test` (buyer).

Database connection is read from `WEIGHTAGS_DB_{USER,PASSWORD,HOST,PORT}` (defaults suit a local
Postgres). The design source of truth stays in [`../docs/design/prototype/`](../docs/design/prototype/).
