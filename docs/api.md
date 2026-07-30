# WeighTags API (v1)

The headless ingest channel. WeighTags is usable without the web app: upload weighs and sync
statuses over a small JSON API. This is the charter's *"production public API (v2)"* deliverable for
**Ingest excellence** — layered on the same domain services the UI uses (`Weighs::Poster`,
`Tags::Query`), so the API and the screen can never drift.

## Design principle — one simple object

The API exposes a **single outward resource, the `weigh_tag`**. Internally a shipment is a `Tag`
projected over per-party `Weigh` records (see [`charter.md` → *Data model*](charter.md)); the API hides
that split entirely. From a caller's perspective a weigh tag is *one shipment seen from your org*: your
weigh, your partner's weigh, and the reconciliation status. There are no `weigh` or `tag` endpoints to
reason about — just weigh tags.

## Spec & reference (OpenAPI)

The API is described by an **OpenAPI 3.1** document — the broadly-accepted standard, importable into
Postman, Insomnia, Stoplight, or any client generator. Both URLs are public (no key required):

| URL | What |
|---|---|
| `GET /openapi.yaml` | The machine-readable OpenAPI 3.1 spec (source: [`app/config/openapi.yaml`](../app/config/openapi.yaml)). |
| `GET /api/docs` | A rendered, human-readable reference (Redoc). |

This Markdown page is the narrative overview; the OpenAPI spec is the precise, versioned contract.

## Authentication

Bearer token, no cookies. Mint a key under **API** in the app nav (admin only) — the plaintext is
shown once. Send it on every request:

```
Authorization: Bearer wt_live_xxxxxxxxxxxxxxxxxxxxxxxx
```

Header only — never a query parameter, which would end up in access logs, browser history, and
referrers. The `wt_live_` prefix makes a leaked token recognisable in code search (and registrable
with a secret-scanning partner program); only its SHA-256 digest is stored, so nothing can hand you
an existing token back. **Rotation** is therefore a workflow, not a feature: mint a new key, move the
consumer over, revoke the old one.

A key is scoped to one org and tied to the user who minted it, so every weigh posted over the API
attributes to a real person in the append-only audit log — identical to the UI. Revoking a key is
immediate. Missing/invalid/revoked tokens return `401`.

Each key has:

- A non-secret **Key ID** (`wtk_…`) shown in the dashboard, so a credential is identifiable without
  exposing its secret.
- A **scope** (least privilege):
  - **read-only** — sync statuses (`GET`); good for an accountant's pull or a dashboard.
  - **read-write** — also upload weighs (`POST`); for a scale system or your own scripts.

  A `POST` with a read-only key returns `403`. A request that names no recognisable scope mints the
  read-only key — the weaker credential is the failure mode.

Revoked keys are never deleted: the row is the record of what existed, who minted it, and when it was
last used. `Last used` is stamped to the nearest minute, so polling doesn't turn every read into a
write.

## Rate limits

**600 requests per minute, per key** — per key rather than per IP, because integrations routinely
share egress addresses and one tenant's traffic should never throttle another's. Over the limit
returns `429` with a `Retry-After` header (seconds). Requests presenting an invalid token are capped
separately, per IP; a valid key is never collateral damage.

The limit is an abuse backstop, not a metered quota.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/api/v1/weigh_tags` | List your weigh tags (sync statuses) |
| `GET` | `/api/v1/weigh_tags/:id` | One weigh tag |
| `POST` | `/api/v1/weigh_tags` | Upload your weigh (creates a shipment or pairs into one) |

> The primary headless functions are **upload** and **sync**. Interactive resolution
> (accept / dispute / compromise) stays a human-in-the-loop UI moment for now; if signal calls for it,
> those actions extend naturally through the same `Tags::Actions` funnel.

### `GET /api/v1/weigh_tags`

Same filters as the web index: `q` (BOL/truck/driver), `status`, `partner_id`, `from`, `to`,
`invoice_number`. Pagination: `page` (1-based), `per_page` (default 50, max 200).

```json
{
  "weigh_tags": [ { "...": "see weigh tag object" } ],
  "page": 1,
  "per_page": 50
}
```

### `POST /api/v1/weigh_tags`

Upload one weigh. Two ways to say which shipment it belongs to:

- **By partner + BOL** (default). Name your partner and your role; the system mints or auto-pairs a
  shipment on exact BOL.
- **By `weigh_tag_id`** (preferred when the partner posted first). Append your weigh to their existing
  shipment — no re-keyed BOL, no typo, no pairing.

```jsonc
// minimal — your side of a new shipment
{
  "bol": "10849",
  "partner": "Pacific Hulling Co",   // or "partner_id": 42
  "role": "sender",                  // "sender" (default) or "receiver"
  "ship_date": "2026-05-27",
  "commodity": "Soybeans",
  "truck": "TX-4471", "driver": "J. Smith",
  "gross": 50000, "tare": 10000,     // net derived if omitted
  "moisture": 13.2, "grade": "US 2",
  "weighed_at": "2026-05-27T14:03:00Z", "weighed_by": "R. Green", "scale_id": "SC-1",
  "notes": "spillage observed during unload"
}
```

```jsonc
// weigh in against the partner's open shipment
{ "weigh_tag_id": 1234, "gross": 50010, "tare": 10000 }
```

Naming a `partner` that doesn't exist creates a placeholder org; add `partner_email` to send them a
claim invite (the records-gravity wedge). Returns `201` with the resulting weigh tag.

### The weigh tag object

```jsonc
{
  "id": 1234,
  "bol": "10849",
  "status": "review",                // see statuses below
  "role": "sender",                  // your side of this shipment
  "partner": { "id": 42, "name": "Pacific Hulling Co" },
  "ship_date": "2026-05-27",
  "commodity": "Soybeans",
  "truck": "TX-4471",
  "driver": "J. Smith",
  "mine":  { "gross": "50000.0", "tare": "10000.0", "net": "40000.0",
             "moisture": "13.2", "grade": "US 2",
             "weighed_at": "2026-05-27T14:03:00Z", "weighed_by": "R. Green",
             "scale_id": "SC-1", "notes": "...", "recorded_ref": "10849" },
  "partner_weigh": { "...": "same shape, or null if they haven't posted" },
  "net_delta": "-30.0",              // sender→receiver convention (receiver − sender)
  "net_delta_percent": "-0.06",
  "within_tolerance": true,          // null until both sides have posted
  "canonical_net": "40000.0",        // agreed value once closed, else null
  "invoice_number": null,
  "created_at": "2026-05-27T14:03:00Z",
  "updated_at": "2026-05-27T14:05:11Z"
}
```

Weights are **decimal strings**, not floats — this is a money-adjacent system of record and precision
is preserved deliberately (*vault, not toy*).

### Statuses

| Status | Meaning |
|---|---|
| `awaiting_partner` | You've posted; waiting on your partner. |
| `awaiting_you` | Your partner posted; your weigh is missing. |
| `review` | Both posted; net delta exceeds tolerance — needs a human. |
| `matched` | Both posted; within tolerance. |
| `disputed` | A dispute is open. |
| `compromise_proposed` | A negotiated value is awaiting acceptance. |
| `resolved` | Closed by acceptance, compromise, or auto-accept. |
| `invoiced` | Closed and linked to an external invoice batch. |

## Errors

JSON with an `error` string; validation failures add a `details` array.

| Status | When |
|---|---|
| `401` | Missing, invalid, or revoked token. |
| `403` | A read-only key attempted a write (`POST`). |
| `404` | Weigh tag not visible to your org (row-level security). |
| `422` | No partner named, or a weigh failed validation (e.g. missing BOL, duplicate for partner). |
| `429` | Rate limit exceeded. Honour `Retry-After`. |

## Isolation

Every request binds to the key's org under Postgres **row-level security** — the same defense-in-depth
the web app uses. You can only ever read or write your own org's weigh tags.
