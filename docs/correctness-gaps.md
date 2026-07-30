# Correctness gaps — development tasks

*Status: open. Found in a code review (June 2026) of the money-adjacent paths: the dispute clock,
the action funnel, and pairing. None are exploitable today; all are the kind of gap that turns into
a real incident under concurrency, retries, or a forgetful future caller. Per the charter
(*The app is the business*), the reliability bar here is higher than typical CRUD — these should be
closed before launch.*

Each task lists the evidence (file:line), why it matters, a concrete fix design, and the gate
(tests that must exist and pass). Tasks follow the repo's Definition of Done
([`roadmap.md`](roadmap.md) → *Definition of Done*): service-level tests for the invariant,
integration coverage where a user-visible flow changes, Brakeman clean.

Severity legend: **P1** = fix before launch; **P2** = fix soon, latent hazard; **P3** = housekeeping.

---

## CG-1 (P1) — Dispute clock: make auto-accept and reminders genuinely idempotent

**The claim vs. the code.** [`app/README.md`](../app/README.md) describes the clock as *"idempotent
under retry."* `Tags::Clock` (`app/app/services/tags/clock.rb`) is idempotent only under a single,
serial worker. The job runs every 5 minutes (`app/config/recurring.yml` → `dispute_clock`); a run
that outlives its interval, a Solid Queue retry after partial failure, or a second worker process
all break the assumption. Auto-accept firing twice — or firing after a user disputed — is the exact
failure mode the product promises not to have.

### CG-1a — Lock the tag in `auto_accept!`

**Evidence.** `clock.rb:44–66`. The guards (`tag.review?`, `clock_due_at` checks) run on an
unlocked, possibly stale instance; the mutation is a plain `tag.update!`. Two interleaved workers
can both pass the guards. Separately, a user action that should stop the clock (`dispute!` /
`accept!` set `clock_due_at: nil` via `Tags::Actions`) can commit between this method's guard and
its write — auto-accept then overwrites a live dispute.

**Fix.**

1. Wrap the body in `tag.with_lock do ... end` (which reloads), and re-run **all** guards inside
   the lock: `return false unless tag.review? && tag.clock_due_at.present? && tag.clock_due_at <= now`.
2. Keep the audit write inside the same transaction as the state change (already true), and keep
   `notify` / `Broadcaster.refresh` outside it (already true).
3. In `fire_auto_accepts` (`clock.rb:36–42`), tolerate a tag being claimed by a competing worker:
   `auto_accept!` returning `false` is normal, not an anomaly — don't alert on it.

**Gate.**
- Service test: call `auto_accept!` twice on the same due tag → resolved once, exactly **one**
  `tag.auto_accepted` audit event, second call returns `false` with no `OperationalAlert`.
- Service test: dispute the tag, then call `auto_accept!` with a stale instance loaded before the
  dispute → no state change, tag remains `disputed`.
- Existing `process_due` tests still green.

### CG-1b — Reminders: claim the mark *before* acting, atomically

**Evidence.** `clock.rb:77–87` (`maybe_remind`). Current order: check `clock_reminded_*_at` is
blank → write the `tag.reminder_sent` audit event → `update_column` → notify. Two consequences:

- **Crash window:** a failure between the audit write and `update_column` leaves the mark unset;
  the next tick sends the reminder (email + audit event) again. The audit log — the product — gets
  duplicate immutable entries it can never clean up.
- **Race:** two workers both pass the `present?` check and both send.

**Fix.** Invert the order and make the claim atomic. Use a guarded UPDATE as the claim — its
row count is the lock:

```ruby
def maybe_remind(tag, mark, at, now)
  return false unless now >= at && now < tag.clock_due_at
  column = "clock_reminded_#{mark}_at"
  claimed = Tag.where(id: tag.id, column => nil).update_all(column => now) == 1
  return false unless claimed

  AuditEvent.record!(action: "tag.reminder_sent", ...)
  notify(tag, :reminder, mark: mark)
  true
end
```

A crash after the claim but before the audit/notify now loses one reminder instead of duplicating
it — the right failure direction for an evidential record (the audit log must never overstate what
was sent; under-sending one reminder is recoverable noise, a phantom "notified" entry is not).
If that trade-off is judged wrong later, the alternative is `with_lock` around the whole
check-audit-mark-notify sequence; the claim-first form is preferred because it doesn't hold a row
lock across mailer enqueue.

**Gate.**
- Service test: run `fire_reminders` twice at the same instant → one audit event, one notification
  per mark.
- Service test: simulate the crash (stub `AuditEvent.record!` to raise on first call) → mark is
  set, no duplicate audit event on the next tick, and the failure surfaces via the job/alerter
  rather than silently.

### CG-1c — Prevent overlapping job runs

**Evidence.** `app/config/recurring.yml` schedules `DisputeClockJob` every 5 minutes;
`app/config/queue.yml` allows multiple worker processes via `JOB_CONCURRENCY`. Nothing prevents
tick N+1 starting while tick N is still walking `running.find_each`.

**Fix.** Add Solid Queue concurrency control to the job:

```ruby
class DisputeClockJob < ApplicationJob
  queue_as :default
  limits_concurrency key: "dispute_clock", to: 1
end
```

This is belt-and-suspenders on top of CG-1a/1b (which make overlap *harmless*); this makes it
*rare*. Both layers are wanted: the limit can't protect against a retried half-finished run, and
the row-level fixes can't stop two full scans burning the DB.

**Gate.** Job test asserting the concurrency key is configured (a regression guard, since this is
configuration rather than logic). CG-1a/1b tests carry the correctness weight.

---

## CG-2 (P1) — `edit_weigh!`: one transaction for the weigh edit and the tag reopen

**Evidence.** `app/app/services/tags/actions.rb:36–61`. The method runs in three separate
transactional units:

1. `weigh.save!` (the edit) — own implicit transaction,
2. `AuditEvent.record!("weigh.edited", ...)` — own implicit transaction,
3. `transition("tag.reopened", ...)` — the explicit transaction (reproject + tag audit).

If step 3 fails (validation, deadlock, raised callback), the weigh is permanently edited and
audited but the Tag never reprojected or reopened: stale canonical values, stale state, no
`tag.reopened` event, and a counterparty who was never re-notified. On a money-adjacent record
that's a silent integrity break, not a cosmetic one.

**Fix.** Wrap the whole method body in one `ActiveRecord::Base.transaction`. The inner
`transition` transaction nests harmlessly (Rails joins it to the outer one); `Broadcaster.refresh`
and `notify` already run after `transition`'s transaction block — verify they end up **after the
outer commit** (move them, and `Clock.start!`, to after the outer transaction explicitly if
needed). The shape:

```ruby
def edit_weigh!(attributes:, reason:)
  guard!(...)
  ActiveRecord::Base.transaction do
    # weigh.save!, weigh audit, tag reopen + tag audit (transition's tx joins this one)
  end
  # broadcast, notify, Clock.start! — post-commit only
end
```

Note `transition` currently broadcasts/notifies *inside* the method but *outside its own*
transaction — when nested, "outside the inner block" is still **inside the outer transaction**.
The fix must restructure so side effects fire post-commit (simplest: give `transition` a
`defer_side_effects:` mode, or inline the transition logic for this one action).

**Gate.**
- Service test: force the reopen step to fail (e.g. stub `tag.save!` to raise) → the weigh's
  values are **unchanged** and no `weigh.edited` audit event exists.
- Service test: happy path unchanged — weigh edited, both audit events present, tag reprojected,
  clock restarted when the edit lands in `review`.
- Integration test `reconciliation_flow_test` / edit flow still green.

---

## CG-3 (P2) — Service-boundary hygiene: stop accepting unfiltered controller params

**Evidence.** `actions.rb:40`: `attributes.respond_to?(:to_unsafe_h) ? attributes.to_unsafe_h : ...`.
The only current caller permits properly (`app/app/controllers/tags_controller.rb:95–97`), so this
is **latent**, not live. But the service explicitly volunteering to unwrap *unpermitted* params
means the next caller (API action extension, console script, a future controller) can mass-assign
anything on the weigh — `tag_id`, `org_id`, `side` — and the guard rails are gone.

**Fix.**

1. In `edit_weigh!`, raise on `ActionController::Parameters` instead of unwrapping:
   `raise ArgumentError, "pass a permitted hash" if attributes.is_a?(ActionController::Parameters) && !attributes.permitted?` —
   or simpler, require a plain `Hash` and have controllers call `.to_h` on permitted params.
2. Whitelist within the service regardless of caller: `attrs.slice(:gross, :tare, :net, :moisture,
   :grade, :notes)` — the service owns which fields are editable, not the controller. (Controller
   permit lists then become UI concerns, and the API can reuse the service safely later — the
   charter's "same domain services" rule.)
3. Sweep the other services (`Weighs::Poster`, `Csv::WeighImport`, `InvoiceBatches::Create`) for
   the same pattern and apply the same rule. `Weighs::Poster` is the important one — it is the
   shared web/API/CSV ingest funnel.

**Gate.**
- Service test: `edit_weigh!` with `tag_id`/`org_id`/`side` in the attributes → those fields are
  ignored (or it raises), weigh stays on its tag and org.
- Brakeman stays clean.

---

## CG-4 (P2) — `Tags::Pairer`: survive the simultaneous-post race

**Evidence.** `app/app/services/tags/pairer.rb:30` uses `Tag.find_or_create_by!`, which is
find-then-create (TOCTOU). The unique index `index_loads_on_pair_and_bol`
(`db/structure.sql:884`, on `tags (sender_org_id, receiver_org_id, bol)`) means a true race
**cannot** create a duplicate Tag — instead the loser raises `ActiveRecord::RecordNotUnique` and
the user's (or API caller's) post fails with a 500 for a condition that should have paired cleanly.
Both parties posting the same BOL within the same moment is not exotic — it's the product's happy
path under enthusiastic adoption.

**Fix.**

1. Use `create_or_find_by!` semantics: rescue `RecordNotUnique` and retry the find once. (Plain
   `create_or_find_by!` inverts the cost — it always attempts the INSERT — but here creates and
   finds are both common; the rescue-and-retry around the existing `find_or_create_by!` is the
   minimal change.)
2. While here: `recompute` (`pairer.rb:50–64`) reprojects without locking the Tag. Two concurrent
   attaches (one per side) can interleave reproject/save. Wrap `attach` + `recompute` in
   `tag.with_lock` so the second attach sees the first side's weigh and the final state is
   `matched`/`review`, never a stale `pending`.

**Gate.**
- Service test: stub the first `find_or_create_by!` to raise `RecordNotUnique` (tag created by a
  "concurrent" insert beforehand) → Pairer returns the existing tag and the weigh attaches; no
  error escapes.
- Service test: post both sides, assert the final tag state reflects both weighs regardless of
  attach order.

---

## CG-5 (P2, decision) — Within-tolerance auto-close: code and charter disagree

**Evidence.** `Tag#reproject` (`app/app/models/tag.rb:109–124`) moves a both-sided,
within-tolerance Tag straight to `matched` with `resolution: clean_match` and a `resolved_at`
timestamp; `closed_unbilled` (`tag.rb:35`) includes `matched`, so it is immediately invoiceable
with **no human action**. The charter's state table ([`charter.md`](charter.md) → *Tag states*)
specifies *"Double-sided · ready to close — Both Weighs posted; within tolerance. **One-click
acceptance.**"* — i.e. a human closes it.

This is a **product decision**, not a bug fix; per [`CLAUDE.md`](../CLAUDE.md), whichever way it
goes must be folded into the charter, not left in code-vs-doc tension.

**Recommendation: amend the charter to match the code.** Auto-close-on-match is lower friction
(the wedge's whole posture), the dispute path back out exists (`can_dispute?` includes `matched` —
`tag.rb:142–144` — and the system test covers contesting a matched tag), and the timeout backstop
already establishes the principle that silence closes records. The evidential framing holds:
"both parties' numbers agreed within the configured tolerance" *is* the neutral fact.

**Tasks.**

1. Decide (product owner call). If amending the charter: update the *Tag states* table and the
   *Key workflows* list to describe matched-within-tolerance as auto-closing, with dispute as the
   reopening path; note the decision date.
2. If instead implementing the charter as written: `reproject` lands on a new non-closed
   `ready_to_close` state; add an explicit close action through `Tags::Actions`; exclude it from
   `closed_unbilled`; update `Tags::Query::STATUS_OPTIONS`, the API status mapping
   (`docs/api.md` statuses table), StatusPill, seeds, and every test that asserts `matched`
   semantics. (Materially larger; not recommended without a user-signal reason.)

**Gate.** Charter and code tell the same story; a doc-only change if the recommendation is taken.

---

## CG-6 (P3) — Housekeeping: stale names and a dangling manifest reference

Small, zero-risk, worth batching into one commit:

1. **`ops/manifest.json`** → `database.schema_source` and `migrations.schema_source` point at
   `app/db/schema.rb`, which does not exist — the app uses SQL schema format
   (`app/db/structure.sql`; the format is load-bearing for the audit trigger). Point both at
   `app/db/structure.sql` (confirm against the BitterGrid manifest schema first — if the platform
   only reads it to detect "has migrations," the value may be cosmetic, but a dangling path in a
   deploy manifest is a trap either way).
2. **`app/README.md`** G0 section lists core tables as `…, tags, loads, invoice_batches` —
   pre-v12 leftover; the table is `weighs`.
3. **Index names predate the v12 rename** (`db/structure.sql:884,1059`):
   `index_loads_on_pair_and_bol` (on `tags`) and — actively confusing —
   `index_tags_on_org_counterparty_bol` (on `weighs`). Optional migration using `rename_index`;
   cosmetic, but these names will mislead exactly when someone is debugging the indexes (e.g.
   during CG-4). If touched, regenerate `structure.sql` in the same change.

**Gate.** `bin/rails db:prepare && bin/rails test` green; manifest change validated against a
deploy (or explicitly deferred to the next deploy window).

---

## CG-7 (P1) — Row-level security is inert in production: no non-superuser role exists

*Found July 2026 while deploying to Railway. Pre-existing; not introduced by the deploy work.*

**The claim vs. the code.** The charter calls Postgres RLS "the default safety net underneath"
app-level scoping, and `db/migrate/20260602067000_enable_row_level_security.rb` says the app
"should connect as the non-superuser `weightags_app` role in production so these policies bind
(superusers bypass RLS by design)." Neither half of that is achievable as written.

**Evidence.**

1. **Nothing ever switches role.** `app/controllers/concerns/tenancy.rb:23–25` and
   `app/controllers/api/v1/base_controller.rb:45` set the `app.accessible_org_ids` GUC that the
   policies read, but no code anywhere issues `SET ROLE`/`SET LOCAL ROLE`. Grep for
   `SET ROLE|set_role|weightags_app` across `app/ lib/ config/` returns only the migration and
   `test/models/row_level_security_test.rb`.
2. **The role cannot be connected as.** The migration creates it `NOLOGIN NOSUPERUSER` with no
   password, so `DATABASE_URL` can never point at it. There is no second login role either.
3. **The role does not survive a fresh database.** `db/structure.sql` is produced by
   `pg_dump --schema-only --no-privileges`, which dumps neither roles nor grants. `weightags_app`
   appears **0** times in `structure.sql`, and there are **0** `GRANT` statements. The policies,
   `FORCE ROW LEVEL SECURITY`, and `app_accessible_org_ids()` all *do* survive — so a fresh
   production database has armed policies, no role to enforce them against, and no grants.
4. **The platform connection is a superuser.** Railway's managed Postgres issues `DATABASE_URL` as
   the `postgres` superuser. Superusers bypass RLS unconditionally — `FORCE ROW LEVEL SECURITY`
   raises the bar only for the table *owner*, not for superusers or `BYPASSRLS` roles.

**Confirmed empirically**, not inferred. Booting the production image against a fresh Postgres 16
with a platform-shaped `DATABASE_URL` and querying that database directly:

```
current_user | is_superuser        ->  postgres | on
weightags_app in pg_roles          ->  NO - role absent
relrowsecurity/relforcerowsecurity ->  t / t  on tags, weighs, invoice_batches
pg_policies                        ->  3
```

Three armed, forced policies; no role to enforce them against; a superuser connection.

Re-confirmed on the **live Railway deployment** (Postgres 18.4): `is_superuser` is `on` there too.

**Net effect.** In production the policies are never evaluated. Tenancy rests entirely on the
app-level scoping in `Tenancy` — which is the primary control and does work — but the defense-in-depth
layer the charter promises is off, and nothing surfaces that fact.

**Why it matters.** This is the layer that is supposed to contain a missing `.where(org:)` in one
controller action. A neutral multiplayer system of record leaking one counterparty's weights to
another is the product's worst failure mode, and RLS is the stated backstop.

**It also silently breaks the gate.** Because the role is absent from `structure.sql`,
`RowLevelSecurityTest` errors with `PG::UndefinedObject: role "weightags_app" does not exist` on any
database built by `db:prepare` (3 errors in a 129-test run). The suite reports errors, not failures,
so "129 runs, 0 failures" reads as green at a glance. Whatever environment previously ran this
suite must have had the role created out of band.

**Fix design.**

1. Move role creation out of a one-time migration into something every environment gets: either a
   dedicated `db/roles.sql` applied by `db:prepare` (and by the deploy), or an idempotent
   `ActiveRecord` initializer-time `CREATE ROLE ... IF NOT EXISTS` guard. It must survive a
   `structure.sql` load, and grants must cover tables added later (`ALTER DEFAULT PRIVILEGES`).
2. Give the app a **login** role: `weightags_app` with a password, `NOSUPERUSER NOBYPASSRLS`, owning
   nothing. Point `DATABASE_URL` at it and keep the superuser credential for migrations only. On
   Railway that means a second connection string — migrations run as owner via the entrypoint,
   requests run as `weightags_app`. Rails supports this with a separate `migration` role or a
   `preDeployCommand` that uses the privileged URL.
3. Alternatively (weaker, but no new credential): `SET LOCAL ROLE weightags_app` inside the same
   transaction that sets the GUC. Rejected as the primary fix — it needs every request wrapped in a
   transaction, and grants must then be maintained for every new table (the `solid_*` tables added
   in `20260729000001` have none).
4. Add a guard test that **fails loudly** if the effective connection can bypass RLS, e.g. assert
   `current_setting('is_superuser') = 'off'` in production boot, so this can never regress silently.

**Gate.** `RowLevelSecurityTest` green on a database created purely by `bin/rails db:prepare` with no
manual setup; a new test asserting a superuser connection is rejected/flagged in production; `bin/ci`
green with **0 errors** as well as 0 failures.

---

## Suggested order & scope notes

| Order | Task | Why this order |
|---|---|---|
| 1 | CG-2 | Self-contained, highest blast-radius-per-line; unblocks nothing else. |
| 2 | CG-1a → 1b → 1c | The launch blocker. 1a and 1b are the substance; 1c is config. |
| 2.5 | CG-7 | Also a launch blocker, and it currently hides 3 errors in `bin/ci`. Independent of the others — can go in parallel. |
| 3 | CG-4 | Touches the same locking idiom as CG-1a; do while the pattern is fresh. |
| 4 | CG-3 | Mechanical once the rule is decided; sweep all services in one pass. |
| 5 | CG-5 | Needs a product decision; doc-only if the recommendation is taken. |
| 6 | CG-6 | Anytime; batch into one commit. |

Cross-cutting: every fix lands with its gate tests in the same commit (per-feature gates, roadmap
convention); no fix introduces a new dependency; concurrency tests that can't be written reliably
as true parallel tests are written as *interleaving* tests (stale instance / stubbed failure
ordering), which is what the gates above specify.
