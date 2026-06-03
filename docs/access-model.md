# Access model — shared records, tenant boundaries & identity governance

*The single source of truth for "who can see and touch what." The charter
([`charter.md`](charter.md) → *Positioning principle*, *Data model*) is canonical;
this expands its multiplayer rule into the concrete access + governance policy
the enforcement layers implement.*

> **Vocabulary (v12).** **Tag** = the shipment (the BOL identity; was *Load*).
> **Weigh** = one weighing, owned by the party that recorded it (was *Tag*). A Tag
> is a thin projection over its Weighs and is garbage-collected when it has none.

## The policy, in one paragraph

A **user** accesses an **org**'s data **iff they hold an active membership** in
that org. The set of such orgs is the user's **tenant wall** — they can never see
data of an org they're not a member of. A **Tag** and an **InvoiceBatch** are
*shared records*: each is accessible to **both** its sender org and its receiver
org (an explicit participation join, never a default-scope leak). A **Weigh** is
owned by the org that recorded it and readable by the counterparty through the
shared Tag. Within the wall, the **active org** (`Current.org`) narrows what the
UI shows to one relationship at a time; it is a *focus*, not a security boundary.

## Two notions of "my org" — don't conflate them

| Term | Meaning | Where it lives |
|---|---|---|
| **Active org** | the one org the user is currently working in | `Current.org` (session) |
| **Accessible orgs** (the wall) | every org the user is an active member of | `User#accessible_org_ids` |

The active org is always within the accessible set. The UI scopes to the active
org; the tenant wall is the accessible set.

## The one predicate

Participation is defined once, in `Tag.for_org` (and `InvoiceBatch.for_org`):

```ruby
scope :for_org, ->(org) { where(sender_org_id: org.id).or(where(receiver_org_id: org.id)) }
```

Everything else derives from it.

## Three layers, one policy

1. **App-level scoping (the precise view).** Controllers read only
   `current_org.tags` etc. — `Tag.for_org(active_org)`. This is what a user sees
   and acts on: their **active** org's shared records.
2. **Action guard (write path).** Identity/state services re-check participation
   (`side_of(actor_org)`) so a write is refused unless the acting org participates.
3. **Postgres row-level security (the hard wall).** `weighs`, `tags`, and
   `invoice_batches` carry forced RLS policies exposing a row only when one of its
   orgs is in `app.accessible_org_ids`, which the app pins each request
   (`Tenancy#apply_rls_scope`) to **`User#accessible_org_ids`** — the whole wall,
   not just the active org. RLS is therefore *looser* than layer 1 by design
   (`active org ⊆ accessible orgs`): it guarantees a tenant can never reach another
   tenant's data even if an app-level scope is forgotten, while active-org
   narrowing stays a UI concern in layer 1.

## Governance of shipment identity

Identity operations — weigh-in, relabel, link/merge, split/move — follow an
**optimistic, symmetric** policy. The platform records and notifies; it does not
gatekeep.

- **Who:** either **participant** (both sides, equal agency; no "owner" of a
  shared Tag). Never an outsider. You may touch only your **own** Weigh; merges
  combine *identities*, not the other party's measurements.
- **Why it's safe without permission walls:** three invariants —
  1. **Reversibility** — every op has an inverse (merge ↔ split, move a weigh back).
  2. **Attribution + notice** — every op is an audited event *and* notifies the
     counterparty; unilateral never means invisible.
  3. **You move your own data** — append/move/relabel your weigh; never edit theirs.
- **Graduated by settledness, not by role:**

  | Operation | Governance |
  |---|---|
  | Weigh-in / append your own Weigh | Unilateral, always |
  | Correct the canonical reference (BOL) | Unilateral, audited; each Weigh keeps its `recorded_ref` |
  | Link / merge two **open** Tags (accept fuzzy, or manual) | Either side, one click, notified, reversible |
  | Move your weigh / split an **open** Tag | Unilateral (your data), notified, reversible |
  | Merge/split touching a **resolved/invoiced** Tag | Gated: needs the other side's confirm, or un-invoice first |

- **Mutual confirmation survives only for the settled case** — rewriting a record
  someone may have billed against. Open-tag fuzzy matches need a **single confirm
  + notice**, not mutual confirmation, so the cooperative wedge stays low-friction.

This is the same posture as the dispute clock: record and notify, don't
adjudicate. Merge/split are just more events in the neutral log; a bad actor is
named by the log and undone by the counterparty.

## Garbage collection & the audit log

A Tag is **GC'd when its last Weigh leaves** (merge/split/retract). Because
`audit_events` are DB-immutable (no `UPDATE`/`DELETE`), the Tag→events association
must **not** cascade-destroy or nullify — it would collide with the immutability
trigger. `subject` is polymorphic (no FK), so deleting the husk is clean; events
keep their denormalized BOL and remain as permanent facts. GC fires on weigh
*removal*, checks `weighs.count == 0` transactionally (to avoid racing a concurrent
weigh-in), and can only ever hit a non-settled empty (settled Tags are gated and
have weighs by definition).

## Edge cases

- **Ghost orgs** (`claimed: false`, no members): outside everyone's wall, so no one
  logs in as them; their weighs are visible only to the inviting counterparty via
  the shared Tag until claimed (A5), which puts the Tag in the claimer's wall.
- **Departed users**: ending a `Membership` drops the org from that user's wall
  (access revoked going forward); past audit entries stay attributed (events
  reference the user, not the membership).
- **Production role**: RLS binds only when the app connects as the non-superuser
  `weightags_app` role (superusers bypass RLS). Dev/test connect as a superuser,
  so layer 3 is proven by a test that assumes the app role
  (`test/models/row_level_security_test.rb`).
