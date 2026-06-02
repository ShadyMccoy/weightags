# Design

Visual design language and canonical screens for WeighTags. The source of truth for
intent is the [project charter](../charter.md) — see *Site aesthetic*, *Canonical
screens*, and *Data model*. This folder holds the artifacts those sections reference.

## Prototype

The live React + Vite + Tailwind v4 prototype that implements this design language lives in
[`prototype/`](prototype/) (formerly shipped as `WeighTagsFigma-v3.zip`). It is the **design source
of truth** — exact hex, spacing, and component structure — and the input to the roadmap's UI
engineering track. Design-only and throwaway; the production app is a modern Rails app (Hotwire). See
[`prototype/README.md`](prototype/README.md).

## Mockups

The PNGs below are screenshots of the prototype — the four screens in implementation today.

| Screen | State shown | File |
|---|---|---|
| Weigh tags list | Receiver home; full status spectrum across 7 tags | [`mockups/01-list.png`](mockups/01-list.png) |
| Weigh tag detail — matched | Both posted, deltas within tolerance, auto-matched | [`mockups/02-detail-matched.png`](mockups/02-detail-matched.png) |
| Weigh tag detail — review | Both posted, net delta −0.74% exceeds 0.5% tolerance | [`mockups/03-detail-review.png`](mockups/03-detail-review.png) |
| Weigh tag detail — disputed | Formal dispute filed, −2.11% net | [`mockups/04-detail-disputed.png`](mockups/04-detail-disputed.png) |

## Status palette

Color is the primary signal for workflow state (charter → *Status palette*):

| State | Hex | Meaning |
|---|---|---|
| Draft | `#8b7d6b` | Your own incomplete work, not yet shared |
| Pending | `#d97706` | Waiting on the partner; no action from you |
| Review | `#b45309` | Deltas above tolerance; your action required |
| Disputed | `#dc2626` | Active dispute filed |
| Matched | `#059669` | Both posted; deltas within tolerance |
| Resolved | `#0891b2` | Was disputed, now closed |
| Invoiced | `#4f46e5` | Closed tag linked to an external invoice batch |

Two rules: **amber** = "this needs attention" (a fact about the numbers); **red** =
active conflict (a fact about the workflow state). A load can carry both at once.

## Screens still to design

Tracked in the charter under *Canonical screens → Still to design* (landing page,
empty states, CSV upload preview, invite email, invoice batch, settings, members,
audit log, compromise flow, edit-own-tag flow).
