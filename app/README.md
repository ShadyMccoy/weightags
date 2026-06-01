# app

Placeholder for the WeighTags application. The production stack is **Phoenix LiveView
+ Ecto + Postgres + Oban** (charter → *Architecture*). Nothing is scaffolded yet — the
project is in charter phase — so this is only a sketch of where things will land.

## Planned layout (once `mix phx.new` runs)

```
app/
  mix.exs                  # deps: phoenix, ecto_sql, postgrex, oban, chromic_pdf
  config/                  # config.exs, dev/test/runtime
  lib/
    weightags/             # domain — contexts, schemas, the matching engine
      accounts/            #   users, orgs, memberships
      tags/                #   tags, loads, the auto-pair + smart-pairing logic
      invoicing/           #   invoice batches
      audit/               #   append-only audit events
    weightags_web/         # web — LiveViews, components, layouts
      live/                #   weigh-tag list + detail diff views
      components/          #   status pills, comparison table, activity log
  priv/repo/migrations/    # DB schema; audit-log invariants enforced via triggers
  test/                    # money-adjacent paths covered (charter → The app is the business)
```

Tables (charter → *Architecture*): `users`, `orgs`, `memberships`, `tags`, `loads`,
`invoice_batches`, `audit_events`, plus supporting tables.

## Hello world

`hello.exs` stands in until the real app exists. Run with `elixir app/hello.exs`
(requires Elixir, not yet installed in this environment).
