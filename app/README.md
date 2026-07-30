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

### Headless API (Ingest excellence)
A small JSON API makes the app usable without the browser — **upload weighs, sync statuses**. It
exposes a single outward `weigh_tag` object (the internal `Tag`/`Weigh` split never leaks) and is
layered on the same domain services the UI uses (`Weighs::Poster`, `Tags::Query`), so it can't drift
from the screen. Bearer-token auth (`ApiKey`, digest-only storage, self-serve under **API** in the nav,
admin-only); every request binds to the key's org under the same Postgres RLS as the web app, and
posted weighs attribute to the key's user in the audit log. Endpoints: `GET/POST /api/v1/weigh_tags`,
`GET /api/v1/weigh_tags/:id`. Described by a public **OpenAPI 3.1** spec (`config/openapi.yaml`, served
at `/openapi.yaml`) with a rendered **Redoc** reference at `/api/docs`. Overview:
[`../docs/api.md`](../docs/api.md).

## Deploy
Dockerized, deployed to **Railway**: one service built from `./Dockerfile` (service root `/app`,
config in `railway.json`) plus one managed Postgres, rolling deploys gated on the `/up` health check.
Solid Queue runs inside Puma (`SOLID_QUEUE_IN_PUMA=true`) at **one replica** — a second supervisor
would race the dispute clock. Production uses a single database; Solid Queue/Cache/Cable tables live
in the primary schema. Full procedure, env vars, and the `weightags.com` DNS setup:
[`../docs/dev-to-prod.md`](../docs/dev-to-prod.md).

`config/deploy.yml` (Kamal 2) is retained but unused; nothing in the app depends on the host beyond
`DATABASE_URL` and `PORT`.

> **RLS caveat:** the policies on `tags`/`weighs`/`invoice_batches` do **not** currently bind in
> production — the platform connection is a superuser and the `weightags_app` role does not survive a
> `structure.sql` load. Tenancy rests on app-level scoping. See
> [`../docs/correctness-gaps.md`](../docs/correctness-gaps.md) **CG-7**.

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
