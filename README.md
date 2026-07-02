# weightags

Weigh tag reconciliation between commodity growers and buyers. A neutral, multiplayer
system of record that auto-pairs tags, surfaces discrepancies in a shared diff view,
and resolves disputes on a deterministic clock.

The Rails 8 app in [`app/`](app/) implements the full roadmap (Foundation + Waves
A–D), gated with tests and deployable to `weightags.com`. See
[`app/README.md`](app/README.md) for the per-feature map.

## Repository layout

```
docs/
  charter.md        Project charter — vision, market, data model, architecture, milestones
  dev-to-prod.md    How a change ships: environments, the bin/ci gate, deploy flow, proof
  design/           Design language, status palette, and canonical-screen mockups
app/                The Rails 8 + Hotwire + Postgres application
ops/
  manifest.json     Deploy contract: build, start command, health path, database, migrations
```

- New here? Start with [docs/charter.md](docs/charter.md) (what we're building).
- Shipping a change? Read [docs/dev-to-prod.md](docs/dev-to-prod.md) (how it goes live).
