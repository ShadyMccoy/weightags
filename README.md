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
  charter.md            Project charter — vision, market, data model, architecture, milestones
  dev-to-prod.md        How a change ships: environments, the bin/ci gate, deploy flow, proof
  correctness-gaps.md   Known gaps with fix designs and gates
  design/               Design language, status palette, and canonical-screen mockups
app/                    The Rails 8 + Hotwire + Postgres application
  Dockerfile            Production image (built by Railway)
  railway.json          Railway service config: builder, health check, replicas
ops/
  manifest.json         OBSOLETE — deploy contract for a platform we no longer use;
                        also points at a db/schema.rb this repo does not have. Safe to delete.
```

Production runs on **Railway** with one managed Postgres, serving `weightags.com`.
See [docs/dev-to-prod.md](docs/dev-to-prod.md).

- New here? Start with [docs/charter.md](docs/charter.md) (what we're building).
- Shipping a change? Read [docs/dev-to-prod.md](docs/dev-to-prod.md) (how it goes live).
