# Dev → Prod process

How a change gets from an edit to `weightags.com`. This is the operational
contract; the [charter](charter.md) governs *what* we build, this governs *how it
ships*. Keep it boring and repeatable.

**Host: Railway.** The charter (→ *Architecture*) names Kamal-on-a-VPS as the
reference deploy and explicitly allows a managed PaaS as "an equally valid target
… the architecture is host-agnostic." Railway is that target: one Docker service
built from `app/Dockerfile`, one managed Postgres, TLS and rolling deploys from
the platform. `app/config/deploy.yml` (Kamal) is retained as an unused escape
hatch — nothing in the app depends on the host beyond `DATABASE_URL` and `PORT`.

## Environments

| Environment | What it is | Who sees it | Data |
|---|---|---|---|
| **development** | local checkout; `cd app && docker compose up` (Rails + Postgres 16) | just us | throwaway |
| **preview** | a Railway *environment* off the same service, on its own `*.up.railway.app` URL | shareable, **not** production | its own Postgres |
| **production** | the live public app at `weightags.com` | real users | Railway managed Postgres |

There is no always-on staging. Preview is the dress rehearsal; it is only "live"
once routing + HTTP + app smoke all agree.

## The gate: `bin/ci`

`app/bin/ci` (defined in `app/config/ci.rb`) is the single source of truth for
"is this change shippable". It runs, in order:

1. **Setup** — `bin/setup --skip-server`
2. **Style** — `bin/rubocop`
3. **Security: gem audit** — `bin/bundler-audit`
4. **Security: importmap audit** — `bin/importmap audit`
5. **Security: Brakeman** — static analysis, `--exit-on-warn --exit-on-error`
   (note: `bin/brakeman` uses `--ensure-latest`, so an out-of-date brakeman gem
   fails the step for a non-security reason — keep the gem current)
6. **Tests** — `bin/rails test` (model/service + integration; system tests are a
   separate `bin/rails test:system` run and need a real browser)
7. **Seeds** — `env RAILS_ENV=test bin/rails db:seed:replant`

Nothing reaches production that is not green here.

### Running it without a local Ruby

The Windows workstation has no Ruby and no Postgres server — `docker compose`
supplies both. Run any gate step inside the dev image:

```bash
cd app
docker compose up -d db
docker compose run --rm -e RAILS_ENV=test web bash -c "bundle exec rails db:prepare && bundle exec rails test"
docker compose run --rm web bundle exec rubocop
```

`Dockerfile.dev` installs `postgresql-client-16` from PGDG on purpose: Debian
bookworm ships client 15, and `pg_dump` refuses to dump a newer server, which
silently breaks the `db/structure.sql` rewrite that `db:migrate` performs.

> **Still missing:** a GitHub Actions workflow running `bin/ci` against a
> `postgres` service on every PR and push to `main`. Until that exists the gate
> is only as good as the person who remembered to run it.

## The flow

**Today: deploys are pushed from a workstation via `railway up`.** The repo lives
under the `sheetgenius` org, so wiring Railway's GitHub app needs org-level
authorization that hasn't been granted yet. Push-to-deploy is the intended end
state, not the current one.

```
edit locally
   │  cd app && docker compose run --rm web bundle exec rubocop
   │           docker compose run --rm -e RAILS_ENV=test web bash -c "bundle exec rails db:prepare && bundle exec rails test"
   ▼
commit + push to main  (source of truth: GitHub sheetgenius/weightags)
   ▼
deploy from a CLEAN tree, stamped with the commit
   │  cd app
   │  git status --porcelain          # must be empty — see below
   │  railway up -m "$(git rev-parse --short HEAD) $(git log -1 --format=%s)"
   │  railway logs --build            # watch the build
   ▼
prove it  →  the change is live only after verification passes
```

Deploys are rolling: Railway starts the new container, waits for the `/up`
health check, then drains the old one. A failed health check leaves the previous
deployment serving.

### Why the clean-tree rule is not optional

`railway up` uploads the **working tree**, not the committed state. It honours
`.gitignore`, but any uncommitted edit ships silently, and a CLI deployment
carries no `repo`/`commitHash` metadata — so there is no way after the fact to
ask *which commit is serving*. For an app whose value proposition is an audit
trail, "we can't tell what's in production" is the wrong failure mode.

Deploying only from a clean tree, with the short SHA in the deployment message,
restores that link cheaply: `railway deployment list` then reads as a commit log.
Connecting GitHub removes the discipline requirement entirely, which is why it
remains the goal.

## Railway service configuration

One service, built from the Dockerfile, plus a Postgres database.

| Setting | Value | Why |
|---|---|---|
| Root directory | `/app` | the Rails app is a subdirectory; the Dockerfile's `COPY . .` expects `app/` as the build context |
| Config as code | `app/railway.json` | builder `DOCKERFILE`, health check `/up`, 1 replica, restart `ON_FAILURE` |
| Replicas | **1** | Solid Queue runs inside Puma; a second replica means a second supervisor on the same queue — see below |

### Environment variables

| Variable | Value | Notes |
|---|---|---|
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | reference the Postgres service, don't paste a literal |
| `SECRET_KEY_BASE` | 128 hex chars | generate with `openssl rand -hex 64`; **not** in git |
| `SOLID_QUEUE_IN_PUMA` | `true` | runs the job supervisor (and the dispute clock) in the web process |
| `APP_HOST` | `weightags.com` | drives mailer links **and** `config.hosts`; set to the preview URL on preview |
| `RAILS_MAX_THREADS` | `5` | Puma threads and the Postgres connection cap |
| `RAILS_LOG_LEVEL` | `info` | `debug` logs PII — don't, in production |

`RAILS_ENV=production` is already baked into the Dockerfile. `RAILS_MASTER_KEY`
is **not** set and is not needed: nothing in the app reads
`Rails.application.credentials` (every use in `config/` is commented out), and
`SECRET_KEY_BASE` is supplied directly. `config/credentials.yml.enc` is
effectively orphaned — its `master.key` is not in this checkout. If you ever add
a real credential, generate a fresh credentials file and put the key in Railway.

### Why one replica

`config/recurring.yml` schedules `DisputeClockJob` every 5 minutes, and
[`correctness-gaps.md`](correctness-gaps.md) CG-1 records that `Tags::Clock` is
idempotent *only under a single serial worker*. Two supervisors racing the clock
can auto-accept twice, or auto-accept a tag someone just disputed — the precise
failure the product promises not to have. Until CG-1 is closed, keep
`numReplicas: 1` and do not add a second job service.

`config/puma.rb` parses `SOLID_QUEUE_IN_PUMA` rather than testing truthiness,
because in Ruby the string `"false"` is truthy — a bare `if ENV[...]` would start
the in-Puma supervisor even where the config says not to.

### One database, not four

Production runs a single Postgres. Solid Queue, Solid Cache, and Solid Cable
share it; their tables live in the primary schema via
`db/migrate/20260729000001_create_solid_queue_cache_and_cable_tables.rb`.

This replaced a four-database layout that could not bootstrap: it pointed
`cache`/`queue`/`cable` at `migrations_paths` directories that do not exist in
this repo, and because `config.active_record.schema_format = :sql` (load-bearing
for the audit-log trigger) the loader looked for
`db/{cache,queue,cable}_structure.sql`, which also do not exist. On a fresh
production database the `solid_*` tables were therefore never created — the
dispute clock would not run, `:solid_cache_store` reads would raise, and Turbo
Stream broadcasts would fail. Development never caught it because development
uses `:memory_store` and the default async job adapter, and never starts
`bin/jobs`. The generator outputs (`db/{queue,cache,cable}_schema.rb`) stay in
the repo as upstream reference only; nothing loads them.

### Row-level security does **not** bind in this configuration

Railway issues `DATABASE_URL` as the `postgres` **superuser**, and superusers bypass RLS
unconditionally. The RLS policies on `tags`/`weighs`/`invoice_batches` are present and armed in a
fresh database, but they are never evaluated, and the `weightags_app` role they target does not even
exist there (`pg_dump --schema-only --no-privileges` dumps neither roles nor grants).

Tenancy therefore rests entirely on the app-level scoping in
`app/controllers/concerns/tenancy.rb`, which is the primary control and does work. The
defense-in-depth layer the charter promises is off. Tracked as
[`correctness-gaps.md`](correctness-gaps.md) **CG-7 (P1)** — close it before treating RLS as a
guarantee, and do not describe the deployment as RLS-protected until then.

### Active Storage is unused — and would be ephemeral if it weren't

`config.active_storage.service = :local`, so uploads land on the container
filesystem, which Railway replaces on every deploy. Nothing in the app attaches
files today (no `has_one_attached`/`has_many_attached` anywhere), so this is
harmless now. **Before shipping any upload feature**, attach a Railway volume at
`/rails/storage` or switch the service to S3 — the Kamal config carried a
`weightags_storage` volume for exactly this reason and Railway has no equivalent
by default.

Related: boot logs a benign `Using vips to process variants requires the libvips
library` warning. `image_processing` is a stock Gemfile entry and the production
image has no libvips; since nothing processes variants, it is noise. Installing
libvips only becomes necessary alongside image uploads.

### Ports

Railway injects `PORT` and expects the container to listen there. Thruster does
not read `PORT` — it listens on `HTTP_PORT` (default 80) and *sets* `PORT` for
the Rails child from `TARGET_PORT` (default 3000). `bin/docker-entrypoint`
therefore maps `PORT` onto `HTTP_PORT` and keeps Puma on a distinct port behind
it. Nothing to configure in the dashboard.

### Line endings

`.gitattributes` pins `app/bin/*`, the Dockerfiles, and `app/db/structure.sql` to
LF. Windows checkouts use `core.autocrlf=true`, and a CRLF shebang makes the
Linux kernel look for an interpreter named `/bin/bash -e\r` — the container dies
with "bad interpreter". Git already stored these as LF; the attributes stop a
future checkout or commit from flipping them.

## Domain: weightags.com via Cloudflare

**Current state (July 2026):** the app is live on the platform-assigned
`https://weightags-web-production.up.railway.app`. `weightags.com` is registered
with DNS on Cloudflare (`kami`/`keaton.ns.cloudflare.com`) but publishes **no A
record and no www** — nothing is served from it yet.

> **Blocked: custom domains are plan-gated.** `railway domain weightags.com`
> returns `Unauthorized` for both the apex and `www`, while `railway domain` with
> no argument successfully generated the `*.up.railway.app` domain, and
> `whoami`/`status`/`variables`/`up` all work. The custom-domain capability
> specifically is unavailable on the current workspace plan (Trial allows 1,
> Hobby 2 per service). Upgrading the workspace unblocks the steps below; no code
> change is involved.

Railway needs **two** records, and the domain will not verify with only the
CNAME — a missing TXT returns 404 even after the CNAME resolves.

1. In Railway → service → Settings → Networking → **Custom Domain**, add
   `weightags.com`. Railway shows a target like `xxxxxx.up.railway.app` plus a
   TXT verification record.
2. In Cloudflare DNS for `weightags.com`:
   - `CNAME  @    xxxxxx.up.railway.app` — Cloudflare flattens CNAMEs at the
     zone apex automatically, so this is legal here even though the DNS spec
     forbids apex CNAMEs.
   - the `TXT` record exactly as Railway gives it.
   - `CNAME  www  xxxxxx.up.railway.app` if you want www to work too (add it as
     a second custom domain in Railway; Hobby allows 2 per service).
3. **Set the proxy to DNS only (grey cloud) first.** Proxied (orange cloud)
   domains can prevent Railway from issuing a Let's Encrypt certificate, and
   Cloudflare then serves traffic using Railway's default `*.up.railway.app`
   cert. Get a clean Railway-issued cert on grey cloud, and only then decide
   whether you want Cloudflare in front.
4. If you do enable the orange cloud, set Cloudflare SSL/TLS to **Full** — not
   Full (Strict). Full (Strict) only works with a Cloudflare origin certificate
   installed on the origin, which Railway does not do.

After DNS propagates, set `APP_HOST=weightags.com` so mailer links and
`config.hosts` match, and confirm the cert is Railway's, not the wildcard.

## Proof — what counts as "live"

A push, a green build, or an HTTP 200 alone proves nothing. Claim → command →
decisive field:

| Claim | Command | Proof |
|---|---|---|
| deploy succeeded | `railway deployment list --service weightags-web` | newest row is `SUCCESS` |
| exact commit serving | same command | newest row's message starts with the short SHA you deployed (only if the clean-tree rule above was followed) |
| app healthy | `curl -fsS https://weightags.com/up` | HTTP 200 |
| serving our cert | `curl -vI https://weightags.com 2>&1 \| grep -i "subject\|issuer"` | CN is `weightags.com`, not `*.up.railway.app` |
| database migrated | `railway ssh --service weightags-web -- ./bin/rails db:migrate:status` | every migration `up`, incl. `20260729000001` |
| jobs running | `railway ssh --service weightags-web -- ./bin/rails runner 'puts SolidQueue::Process.count'` | 4 processes (Supervisor(fork), Dispatcher, Worker, Scheduler) |
| dispute clock armed | `railway ssh --service weightags-web -- ./bin/rails runner 'puts SolidQueue::RecurringTask.pluck(:key)'` | includes `dispute_clock` |
| renders | browser screenshot of `/` | screenshot artifact |

Use `railway ssh`, **not** `railway run`: `railway run` executes locally with
Railway's env injected, and this workstation has no Ruby. `railway ssh` runs
inside the deployed container, which is also what makes it a proof about
production rather than about a laptop. Note the supervisor's `kind` is
`Supervisor(fork)` — querying for `kind: 'Supervisor'` returns 0 and looks like
a dead queue.

A deployment marked `SUCCESS` means *the health check answered*, not that the
feature works. Verify the specific claim.

## Rollback

Railway keeps previous deployments: service → Deployments → **Redeploy** on the
last good one, or `railway redeploy`. Rolling back the image does **not** roll
back a migration — write migrations so the previous release can still run
against the new schema (additive first, destructive in a later deploy).
