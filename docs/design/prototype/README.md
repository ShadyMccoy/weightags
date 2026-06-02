# WeighTags — design prototype

A working **React + Vite + Tailwind v4** prototype of the WeighTags design language. This is the
artifact the charter references (formerly shipped as `WeighTagsFigma-v3.zip`); the four PNGs in
[`../mockups/`](../mockups/) are screenshots of these screens.

## Role: design source of truth, not production code

- **This is design-only and deliberately throwaway.** The production app is a **modern Rails app
  (Hotwire)** (see [`../../charter.md`](../../charter.md) → *Architecture*, and
  [`../../roadmap.md`](../../roadmap.md)). Nothing here is deployed.
- Its job is to **pin down** typography, spacing, color palette, table density, status-pill
  treatment, and the core component patterns (Variance Status callout, Activity Log, Weigh Tag
  Comparison table) *before* they are translated into Rails ViewComponents + ERB. The React stack is
  fast to change and cheap to discard; the Rails implementation is the thing that lasts.
- When a design question arises during the Rails build, **this prototype is the answer** — exact
  hex, exact spacing, exact component structure — not a re-derivation from the charter prose.

## What's implemented today

| Screen | File | Charter canonical screen |
|---|---|---|
| Weigh tags list (receiver home) | `src/app/pages/LoadsListPage.tsx` | List — `mockups/01-list.png` |
| Weigh tag detail (matched / review / disputed) | `src/app/pages/LoadDetailPage.tsx` | Details 02–04 |

The status palette lives in [`src/styles/theme.css`](src/styles/theme.css) and
[`src/app/components/StatusBadge.tsx`](src/app/components/StatusBadge.tsx) — hex values match the
charter *Status palette* exactly. The data-model types in
[`src/app/types.ts`](src/app/types.ts) (`Load`, `WeighTag`, `ActivityEvent`, `Party`) mirror the
charter *Data model*; treat them as a reference shape for the Active Record models, not a binding contract.

Screens still to design are tracked in the charter (*Canonical screens → Still to design*) and
sequenced into the [roadmap](../../roadmap.md) UI deliverables per phase. New screens are prototyped
**here first**, then translated to Rails (Hotwire).

## Running it

```
npm i      # installs deps (node_modules is gitignored)
npm run dev # Vite dev server
```
