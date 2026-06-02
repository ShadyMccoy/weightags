# app

Placeholder for the WeighTags application. The production stack is **Rails 8 + Hotwire
(Turbo + Stimulus) + Postgres + Solid Queue** (charter → *Architecture*). Nothing is
scaffolded yet — the project is in charter phase — so this is only a sketch of where
things will land.

## Planned layout (once `rails new` runs)

```
app/
  Gemfile                  # deps: rails, pg, solid_queue, solid_cable, grover, view_component
  config/                  # application.rb, database.yml, environments, deploy.yml (Kamal)
  app/
    models/                # domain — users, orgs, memberships, tags, loads, audit
                           #   plus the auto-pair + smart-pairing logic (service objects)
    controllers/           # request handling, org-scoped before_actions
    views/                 # ERB templates — weigh-tag list + detail diff
    components/            # ViewComponents — status pills, comparison table, activity log
    jobs/                  # Solid Queue jobs — the dispute clock, reminders, auto-accept
    mailers/               # Action Mailer — invite + notification emails
  db/migrate/              # DB schema; audit-log invariants enforced via triggers
  test/ (or spec/)         # money-adjacent paths covered (charter → The app is the business)
```

Tables (charter → *Architecture*): `users`, `orgs`, `memberships`, `tags`, `loads`,
`invoice_batches`, `audit_events`, plus supporting tables.

## Hello world

`hello.rb` stands in until the real app exists. Run with `ruby app/hello.rb`
(requires Ruby, not yet installed in this environment).
