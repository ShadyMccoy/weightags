# Dev → Prod process

How a change gets from an edit to `weightags.com`. This is the operational
contract; the [charter](charter.md) governs *what* we build, this governs *how it
ships*. Keep it boring and repeatable.

## Environments

| Environment | What it is | Who sees it | Data |
|---|---|---|---|
| **development** | the hosted workcell (source checkout + app-scoped tooling) | just us | throwaway |
| **preview** | a live deploy at `weightags.preview.bittergrid.com` | shareable, **not** production | preview DB |
| **production** | the live public app at `weightags.com` | real users | managed Postgres |

There is no always-on staging. Preview is the dress rehearsal; it is only
"live" once routing + HTTP + app smoke all agree.

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
6. **Tests** — `bin/rails test` (36 files: model/service + integration + system)
7. **Seeds** — `env RAILS_ENV=test bin/rails db:seed:replant`

Nothing reaches production that is not green here **and** proven on preview.

### Where each step actually runs

The workcell has Ruby + gems but **no local Postgres server** (client only, no
sudo/docker), so it can run steps 2–5 (style + security) but **not** steps 6–7
(the DB-backed suite). Today those DB steps are validated by the **preview
deploy** (migrations + app smoke + database smoke).

> **Recommended next step (not yet done):** add a GitHub Actions workflow that
> runs the full `bin/ci` with a Postgres service container on every PR and push
> to `main`, so the test suite runs automatically instead of relying on preview
> smoke. This is the one missing piece of a complete gate for a money-adjacent
> app. See "CI" below.

## The flow

```
edit in workcell
   │  run the checks you can here:  cd app && bin/rubocop && bin/bundler-audit
   │                                bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
   ▼
commit to main  (source of truth: GitHub sheetgenius/weightags)
   ▼
preview deploy  →  verify live  →  screenshot + /up
   │  bitter app deploy --dry-run --database --host weightags.preview.bittergrid.com
   │  bitter app deploy --confirm  --database --host weightags.preview.bittergrid.com
   ▼
production deploy  (one explicit confirmation)
   │  bitter app deploy --dry-run --database          # review the plan
   │  →  ask: "Deploy these changes to production?"
   │  bitter app deploy --confirm --database
   │  bitter grid services wait weightags.com          # status == verified
   ▼
prove it  →  the site is live only after verification passes
```

### Deploy commands

```bash
cd /workspace/weightags-com

# preview (safe, repeatable, not production)
bitter app deploy --dry-run --database --host weightags.preview.bittergrid.com
bitter app deploy --confirm --database --host weightags.preview.bittergrid.com

# production (dry-run first, then one confirmation)
bitter app deploy --dry-run --database
bitter app deploy --confirm --database
bitter grid services wait weightags.com
```

`--database` is required — `ops/manifest.json` declares managed Postgres and the
migration command. Factory owns credential injection, the Rails master key,
database provisioning, migrations, and smoke; do not paste production secrets
anywhere.

If a deploy blocks on Factory-managed plumbing (master-key custody, DB
provisioning, runtime-env), that is a platform setup issue — run app-level
Factory deploy repair with the blocker code and retry; do not ask for
production secrets. Only an app-owned external credential (e.g. a third-party
API key) goes through app Credentials / Environment.

## Proof — what counts as "live"

A push, build, or HTTP 200 alone proves nothing. Claim → command → decisive field:

| Claim | Command | Proof |
|---|---|---|
| production verified | `bitter grid services wait weightags.com` | `status == verified` (not `settled_unverified`) |
| exact commit serving | `bitter grid services verify-external weightags.com` | release/header matches the commit |
| app healthy | `curl -fsS https://weightags.com/up` + app smoke | HTTP success + smoke pass |
| database migrated | `bitter app managed-box database --app weightags.com --action smoke` | migration + smoke pass |
| renders | `bitter browser screenshot` | screenshot artifact |

`--no-wait` means *accepted*, not *live*. `settled_unverified` is a failure.

## CI (recommended, deferred)

Not yet wired. When added, `.github/workflows/ci.yml` should run `bin/ci`
against a `postgres` service, on `pull_request` and `push` to `main`, and gate
merges. Until then, treat a green preview deploy as the test gate and keep the
workcell static checks (steps 2–5) green before every commit.
