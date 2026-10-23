# Every `work_order.create` argument, and the idempotent-retry result

The skill body carries the arguments an ordinary filing sets. This page carries
the complete table — read it when you need an argument that is not in that set
(`draft`, `needs_approval`, `tags`, `parent_id`, `relations`, …) — and what the
create result tells you when a call has to be retried.

Rows that say "see below" or "see Step 1" point at the skill body: `worker` is
Step 1, and the per-type `inputs` shape and the `idempotency_key` rule are both
in Step 5 beside the worked example.

## The complete argument table

| Argument | Required | Notes |
|---|---|---|
| `type` | **yes** | A registered Work Order Type. The one unconditionally required field. |
| `worker` | **yes, unless derivable** | The owning worker. Derivable only for an agent recipe exactly one worker claims; **required for workflow and capability recipes**, which name no agent to key on. Over MCP, nothing defaults it — see Step 1. |
| `title` | no | Short imperative summary — this is what `list` shows. Always set it. |
| `body` | no | The prose from Step 2. |
| `inputs` | no | Typed object, validated against the type's declared schema. **Read the type's schema rather than assuming a shape** — see below. |
| `depends_on` | no | Array of Work Order IDs. The gate from Step 4. |
| `cohort` | no | The undertaking to file into (Step 4). `{"of": "<work-order-id>"}` joins that Work Order's cohort and is the golden path; a bare `"<cohort-id>"` joins a cohort some Work Order you can read already bears; `{"new": true, "label": "…"}` opens a named unit. Omitted, the daemon places it — in the one cohort every `depends_on` target shares, else a new cohort of one. |
| `draft` | no | File it in `draft`: durable, visible, and **it does not run**. No gate is evaluated, no capacity consumed, no seat drawn. A draft **blocks** anything naming it in `depends_on`, which is what makes drafting a whole breakdown safe — a dependent reports the draft under `block_reason.detail.pending` rather than stepping over it. Leaves by exactly two doors, released or cancelled, and nothing puts it back. Omit it for the normal case; set it when a breakdown wants approving before any of it dispatches. |
| `needs_approval` | no | Committed work held at `blocked:waiting-on-approval` until a person runs `tera workorder approve`. Distinct from `draft`, which is a filing not yet committed to. **Cannot be set later** — state it here or discard and re-file. |
| `priority` | no | Integer. |
| `tags` | no | Array of strings, matched **whole** by `list --tag` (no prefix or wildcard). Pick a spelling like `repo:<owner>/<name>` and keep it. |
| `concurrency_key` | no | Overrides the type's default serialization key. |
| `deferred_until` | no | RFC3339 — do not dispatch before this instant. |
| `links` / `relations` | no | Typed references to vault *documents* (`links`) and non-causal edges to other Work Orders (`relations`: `supersedes`, `duplicate_of`, `about`, `related`). Neither gates anything. |
| `mirrors` | no | External-system mirrors. Leave unset unless the deployment has a mirror configured. |
| `parent_id` | no | Files this one beneath an existing Work Order, making it part of that train. It must be one you can read with `work_order.get`; one you cannot is refused exactly as that read would refuse it. A recipe decomposing *its own* work uses `work_order.create_child`, which is deliberately not on this surface. |
| `idempotency_key` | no, but **set it** | A token of your choosing that makes a retry safe. See below. |

## Reading `idempotent_replay`

Read `idempotent_replay` in the result to know which happened:

```json
{ "id": "019fc9ec-c5a7-7937-bb5b-982ef9e7558b", "state": "scheduled",
  "idempotent_replay": true }
```

`true` means the Work Order already existed — your earlier call did land, and
this one filed nothing. Report it to the user as the existing Work Order, not
as a new one. Absent or `false` means this call filed it. Two further
properties: the key is scoped to you, so it cannot collide with another
caller's; and it expires after ten minutes, so it is a retry token rather
than a name for the Work Order — past that window the same key files a new
one. If you get `idempotency_key_in_flight`, your earlier call is still
running: **nothing was created by this one**, so reissue the same request
with the same key rather than dropping it.
