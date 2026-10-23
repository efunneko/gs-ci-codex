---
name: tera-work-orders
description: File, find and watch work as tera Work Orders, through `work_order.*` on the `tera` MCP server or the `tera workorder` command. Composes the human-prose body, optionally files a plain GitHub anchor issue (prose only, no protocol labels), then calls `work_order.create` with typed inputs, a cohort and `depends_on` references. Dependency semantics ride Work Order deps, not issue labels.
metadata:
  tera-stamp: "tera@v0.8.0-rc.4/cf674a660e45a9945403bbdd6e47ce59f68b48a0ecce1d7608fd113a7befd992"
---

# tera-work-orders

Use this skill when the user asks you to file a unit of work into the
tera Work Order queue. A Work Order is durable state inside the daemon —
not a GitHub issue with labels on it — and you file it by calling
`work_order.create` on the `tera` MCP server.

This is the **filing** skill, and it is the only way work is filed. Its
partner, [`tera-supervise`](../tera-supervise/SKILL.md), is how filed work is
watched and unstuck.

Consumer-specific values — the repo slug, which Work Order **type** and
**worker** to use, any cohort-labelling convention, where product context
lives — are the consuming repository's own instructions to state, not this
body's: the instructions file your harness loads when a session starts. Those
instructions are the source of truth even where a step below names a value
for illustration. (The examples below are kottera's own, which keeps them
under "Kottera work-order consumer config" in its instructions.)

## How this skill names a tool

A tool is named here as "`work_order.<verb>` on the `tera` MCP server" — the
server the daemon's `work_order.*` verbs arrive on (Step 0). Your harness
spells an MCP tool its own way; call whatever it maps that name to. Nothing
in this skill depends on a particular harness, its tool names or its files.

**The `tera workorder` command is the fallback** when no `tera` MCP server is
connected to your session. It reaches the same Work Orders through the
daemon's management API with your own CLI credentials, against the
deployment `tera context` points at: `tera workorder create --type <type>`
files, `show <id>` reads one, `list` and `tree <id>` find work, and `watch
<id>` follows one to its end. Its flags spell the arguments below
(`--worker`, `--depends-on`, `--cohort-of`, `--idempotency-key`,
`--inputs @file`); `--worker` defaults to the one `tera context set
--default-worker` stored, but pass it as Step 1 says.
`tera workorder -h` is the authority on all of it.

## Work Orders are the queue

A Work Order filed here is the work: the daemon dispatches it, a runner
executes it, and the lifecycle is durable daemon state. There is no second
queue to also file into.

GitHub keeps exactly one role, ratified by PRD-016 §12: **archival anchor
and discussion home, never a state machine** (Step 3).
→ [`references/github-anchors.md`](references/github-anchors.md) for why an
anchor is never the work item, and the two routes for filing one.

## Step 0 — connect to the exposure

The `work_order.*` verbs reach you through an MCP server the
daemon exposes. It is a **documented example, not a default** (ADR-077
D3, PRD-016 §13): if nobody has installed it, there is nothing to call.
See the operator guide,
[`docs/ops/workorder-mcp-exposure.md`](https://github.com/kottera/kottera/blob/main/docs/ops/workorder-mcp-exposure.md),
and the copy-ready config in
[`examples/workorder-mcp-exposure/`](https://github.com/kottera/kottera/tree/main/examples/workorder-mcp-exposure).

Registering it with your harness under the name `tera` — what every harness's
MCP configuration needs, the loopback rule, and the raw JSON-RPC escape hatch
for a client that cannot hold an HTTP MCP server →
[`references/connecting-to-the-exposure.md`](references/connecting-to-the-exposure.md).
A session that can already list the verbs needs none of that.

**Verify before composing anything.** List the server's tools. You should
see a set of names every one of which is `work_order.*` — `create`, `get`,
`list` and `tree` to file and read, and the lifecycle verbs (`answer`,
`transition`, `retry`, `guide`, `edit`, `release`, `cancel`, `events`,
`force_fail`) that [`tera-supervise`](../tera-supervise/SKILL.md)
drives. The set grows; do not pin a count. No exposure to connect to is not a
dead end: the `tera workorder` command reaches the same verbs (see "How this
skill names a tool").

Three separate gates stand behind that listing, and which one is missing is
legible from *how* it fails:

- **The listing itself is refused** → missing `mcp/work-orders`, the
  exposure gate. The session opens and every method is refused.
- **A name you expect is absent** → missing that `tools/work_order.…`
  grant. Visibility and invokability are the same check, so a name you
  cannot see is also a name you cannot call.
- **Every name visible, every call refused** → missing
  `api/v1/workorders/#`. This is the one people forget, and it is
  separate on purpose (see Failure modes).

## Step 1 — read project conventions

Read the repository's instructions — the file your harness loads when a
session starts — before composing. You need:

- **The Work Order type.** `type` is the only unconditionally required
  argument to `work_order.create`, and an unregistered name is refused —
  so read the deployment's own registered set rather than a list written
  down here. Lifecycle types are **not seeded** (ADR-082 D3 Amendment 1):
  a `code-*` family is a deployment's own configuration, and what tera
  ships is a teaching set at
  [`examples/code-lifecycle-types/`](https://github.com/kottera/kottera/tree/main/examples/code-lifecycle-types). The
  harness built-ins ship the generic direct types — one `<harness>-task`
  per harness built-in (ADR-082 D4), installed with
  `tera plugin add builtin:<name>` — and such a type is the ad-hoc escape
  hatch for work with no registered kind, taking a free-prose `task` input. Prefer a typed kind whenever one fits: what
  ad-hoc costs is schema strength and queue legibility.

  **List the deployment's own set rather than trusting any of the above.**
  A vault registers each recipe under `<vault>/work-order-types/<stem>` and
  a bare leaf resolves when no other registered type shares it. When one
  does, the refusal lists every candidate: name the one the work is meant
  for in full, which is the candidate naming another in `previous_names`,
  and never `system/` by default
  ([refusals](references/refusals-and-what-they-mean.md)). `ls` the
  vault's `.tera/work-order-types/` on the daemon host, or read back a
  recent Work Order's `type`. Where a deployment installs a lifecycle
  family, its instructions should name the ordinary home for each kind of
  work — kottera's, for example, files a self-contained code change as
  `code-implementation-direct`.
- **The worker.** Pass it. Derivation is the exception, not the rule: it
  exists **only** for an agent recipe, and only when exactly one worker
  claims that recipe's agent — the lookup is keyed on an agent name, and
  a **workflow** or **capability** recipe names none, so for those two
  kinds `worker` is required and always will be (kottera/kottera#1305). The generic
  direct types are all capability recipes, so `worker` is required for
  every one of them — and ADR-082 D3 recommends the same shape for a
  deployment's own lifecycle types.

  Why the owner is load-bearing rather than bookkeeping, and why nothing —
  including `tera context set --default-worker` — will fill it in for you over
  MCP → [`references/choosing-the-type-and-worker.md`](references/choosing-the-type-and-worker.md).
- **The repo slug**, if you are also filing a GitHub anchor.
- **Where product context lives** (PRDs, ADRs, `docs/`), so the body
  cites the right documents.

If those instructions are silent on something the user did not specify, ask once
rather than guessing. A Work Order filed against the wrong type dispatches
to the wrong recipe.

## Step 2 — compose the prose body

The body is for a human and for the harness session that will execute it.
Write it to a file in the session's temp directory
(`${TMPDIR:-/tmp}` — under a tera dispatch `/tmp` is denied) if it is long, or
inline it into the `body` argument if short. Shape:

```
<one-paragraph summary>

## Goal
<what success looks like — concrete, testable when possible>

## Notes
<design hints, references to ADRs/PRDs, edge cases>

## Acceptance criteria
<for implementation work>
```

Two rules:

- **Every repo-rooted markdown path you cite must exist.** There is no
  server-side pre-flight on `work_order.create` — the daemon does not read
  your prose. So the check is yours:
  confirm each referenced doc is committed and reachable before you file.
  An item filed against a document that does not exist invites the worker
  to invent the spec, which is the failure mode this check exists to
  prevent.
- **Do not write a dependency section into the prose.** Dependencies are
  a typed field (`depends_on`), enforced by the state machine. A prose
  list of blockers is decorative and will drift from the real gate.

## Step 3 — optionally file a plain GitHub anchor issue

**Skip this whole step when the user did not ask for an issue.** A Work Order
is complete without one, and much work is filed with no anchor at all.

When one is wanted, the rule that binds both routes is that **an anchor is
prose**: no labels that encode queue state, no `### Dependencies` section. The deployment's `github` anchor connector is the
route to prefer — it has no label operation at all — and `gh issue create` is
the escape hatch when the connector is not installed.
→ [`references/github-anchors.md`](references/github-anchors.md)
for both routes in full, and for carrying the issue number into the Work Order
only when the type declares a field for it.

## Step 4 — resolve dependencies

If this work must wait on other Work Orders, collect their **Work Order
IDs** — UUIDv7 strings, not GitHub issue numbers — and pass them as
`depends_on`. If the user named blocking work by issue number, resolve it
first — and note that there is no issue-number filter: `work_order.list`
narrows by `worker`, `state`, `states`, `type` and `parent_id` only, so
the resolution is a `list` followed by `get` on the candidates, matching
on `inputs.issue_number`.

You do not have to defend against a typo here: `create` validates every
`depends_on` entry and refuses the whole call rather than filing a Work
Order with a gate that can never open —

```
depends_on: work_order "019fc000-0000-7000-8000-000000000000" not found
```

— so passing an issue number where an ID belongs fails loudly at filing
time, which is the good outcome.

The daemon enforces the gate. A Work Order with unsatisfied deps is
created in state `blocked:waiting-on-deps` and carries a `block_reason`
naming exactly which prerequisites are outstanding:

```json
"block_reason": { "kind": "deps", "detail": { "pending": ["019fc9ec-…"] } }
```

What the gate reports while it holds, and which detail clears on its own versus
which one means somebody has to repair the upstream →
[`references/dependency-gates.md`](references/dependency-gates.md).

If the user did not name deps but the work logically waits on something,
say so and propose the list before filing — that is a judgment call worth
surfacing, not one to make silently.

### Which undertaking it joins — `cohort`

Every Work Order is in exactly one **cohort**: the undertaking it belongs to,
read back as `cohort_id` on `create`, `get`, `list` and `tree` ([ADR-102](https://github.com/kottera/kottera/blob/main/docs/adr/ADR-102-work-order-cohorts.md)).
`create` places it in a fixed order — what you state; else, when the filing
comes from inside a dispatch, that dispatch's own Work Order's cohort; else the
one cohort every `depends_on` target already shares; else a new cohort of one.
"From inside a dispatch" means the daemon knows which Work Order you are
running: a session dispatched by a Work Order filing over the gateway with the
per-dispatch token its dispatch handed it, or a workflow step. A person's
gateway session — yours, if you are filing on someone's behalf from an MCP
client — is not inside a dispatch, so for it the second line never fires.

**Filing into an undertaking that already exists: pass
`cohort: {of: <work-order-id>}`, naming any Work Order already in it.** This
is the golden path. Name a sibling rather than carry a cohort id: the sibling's
id is one you already hold for the work itself, while a `cohort_id` echoed from
a create hours ago is a UUID to restate across sessions, and restating is where
it drifts. An `{of:}` naming a Work Order you cannot read is refused exactly as
`work_order.get` of it would be.

**Stating nothing is enough when every `depends_on` target is already in one
cohort** — the new Work Order lands in it. That line is a heuristic and it
fails quietly: with no targets, or targets in two cohorts, it mints a fresh
cohort and says nothing. So if any dependency sits outside the undertaking, or
there are none, pass `{of:}`. Genuinely separate work states nothing and gets
a cohort of its own.

`cohort: <id>` also exists, for when an id is what you hold; it must name a
cohort a Work Order you can read already bears — it joins, it never mints.
A **draft** resolves its cohort at `release`, against its `depends_on` as they
are then, so the `cohort_id` its `create` returns is provisional.

**Opening a new unit — a feature, a wave — and naming it: pass
`cohort: {new: true, label: "…"}` on the one call that files the unit's first
Work Order, and nothing on anything filed beneath it.** Everything that Work
Order files inherits the cohort. Each `{new: true}` mints a cohort, so a label
on every item makes one cohort per item, all named alike. Filed from inside a
dispatch, the new cohort nests under that dispatch's; `detach: true` beside it
is for unrelated work that must not. With a `parent_id`, two forms are
accepted: `{new: true, label?}`, a sub-unit under the parent's cohort, and
`{of: <work-order-id>}`, joining a cohort in the parent's tree — so several
children share one sub-unit by opening it with the first and naming the first
with `of` on the rest. Anything outside the parent's tree, a bare cohort id and
`detach` are refused. The operator page is
[`docs/ops/workorder-cohorts.md`](https://github.com/kottera/kottera/blob/main/docs/ops/workorder-cohorts.md).

**The deployment's own cohort-label convention.** Which types open a cohort
and how its label reads is a deployment's convention, not tera's — a plan
orchestrator that always opens a feature cohort, a wave orchestrator that
opens a child cohort beneath it, implementation items that join rather than
open. When the consumer's instructions state one, follow it by the type's leaf
name, including every suffix variant; when it states none, the rules above are
the whole of it.

Such labels are **cohort labels**, separate from the Work Order's `title`.

## Step 5 — file it

Call `work_order.create`:

| Argument | Required | Notes |
|---|---|---|
| `type` | **yes** | A registered Work Order Type. The one unconditionally required field. |
| `worker` | **yes, unless derivable** | The owning worker. Derivable only for an agent recipe exactly one worker claims; **required for workflow and capability recipes**, which name no agent to key on. Over MCP, nothing defaults it — see Step 1. |
| `title` | no | Short imperative summary — this is what `list` shows. Always set it. |
| `body` | no | The prose from Step 2. |
| `inputs` | no | Typed object, validated against the type's declared schema. **Read the type's schema rather than assuming a shape** — see below. |
| `depends_on` | no | Array of Work Order IDs. The gate from Step 4. |
| `cohort` | when joining or naming an undertaking | `{"of": "<work-order-id>"}` joins existing work; `{"new": true, "label": "…"}` opens a named unit. Follow any cohort-label convention the consumer's instructions state (Step 4). |
| `idempotency_key` | no, but **set it** | A token of your choosing that makes a retry safe. See below. |

Those are the arguments an ordinary filing sets. The complete table — `draft`,
`needs_approval`, `priority`, `tags`, `concurrency_key`, `deferred_until`,
`links` / `relations`, `mirrors`, `parent_id` — is in
[`references/create-arguments-and-idempotent-retries.md`](references/create-arguments-and-idempotent-retries.md).
Read it when you need one of them, and before filing a whole breakdown at
once: `draft` is what makes that safe, and `needs_approval` cannot be set later.

**`inputs` is per-type and the shape is not universal.** There is no field
every type takes: `issue_number` belongs to types that declare it. Inputs
are validated against the type's whole `input_schema` at create, so a type
whose schema sets `additionalProperties: false` refuses an undeclared key
(`schema_violation`, naming it), and any other type ignores it silently.
Kottera's `code-*` direct family, for example, takes `repo`, `branch` and
**`task`**, where `task` carries the whole prose specification and is the
field the dispatched agent actually reads. Read a recent Work Order of the
same type (`work_order.get`, then look at `inputs`) before composing a new
one. Filed into kottera's own deployment, it looks like this:

```json
{
  "type": "code-implementation-direct",
  "worker": "code-orchestrator",
  "title": "remove the D2 echo check from live dispatches",
  "inputs": {
    "repo": "kottera/kottera",
    "branch": "main",
    "task": "# Remove the echo check\n\n…the whole specification from Step 2…"
  },
  "depends_on": ["019fc9ec-c571-7d1c-ac8f-665eb2686267"],
  "tags": ["repo:kottera/kottera"],
  "idempotency_key": "remove-d2-echo-check-2026-09-07"
}
```

**Set `idempotency_key`, and never retry a `create` without one.** If the
call fails in a way that does not tell you whether it landed — a timeout, a
dropped connection, a transport error with no body — you cannot distinguish
"the request never arrived" from "it arrived and the response was lost", and
retrying without a key files the work **twice**. That is not a theoretical
concern on this surface: it has happened, leaving two Work Orders dispatched
and wedged `active`, each holding a seat lease, cleared by hand. A Work Order
provisions a workspace volume, draws a seat and spends real tokens; it is the
most expensive thing you can accidentally do twice.

Choose any stable string that identifies *this filing* — the issue number
plus a date works well — and **reuse it verbatim on every retry of the same
create**. Do not regenerate it per attempt; a fresh key on the retry is the
same as having no key at all.

What the result tells you about whether a retried `create` filed anything, and
what `idempotency_key_in_flight` means →
[`references/create-arguments-and-idempotent-retries.md`](references/create-arguments-and-idempotent-retries.md).

The result is the Work Order's identity and its opening state:

```json
{ "id": "019fc9ec-c5a7-7937-bb5b-982ef9e7558b",
  "worker": "wo-mcp-worker",
  "state": "scheduled" }
```

`scheduled` means it is queued for dispatch. `blocked:waiting-on-deps`
means Step 4's gate is holding it. Both are success.

**Your identity is on it.** The daemon records the authenticated
principal as `created_by` on the Work Order and in the `created` event —
so "who filed this" is answerable from the event log alone. Write the
body as something you are willing to have attributed to you, because it
is.

## Step 6 — verify and report

Read it back with `work_order.get`, then tell the user:

1. The Work Order **ID** and its state.
2. The type, worker, and deps.
3. The GitHub anchor issue URL, if you filed one.
4. That the anchor issue is **not** itself the work item — the Work Order
   is, and the issue only points at it.

Reading it back is not ceremony: `create` returns before the dependency
gate and the dispatcher have run, so the state in the create result is
the opening one, not the settled one.
## Failure modes

Every refusal and surprising symptom this surface produces, with what each one
means → [`references/refusals-and-what-they-mean.md`](references/refusals-and-what-they-mean.md).
The three gates behind the exposure fail in three distinguishable ways, which
is the distinction worth carrying into a diagnosis.

## Rules

- **Never put a label that encodes queue state on an anchor issue.** The
  queue is the daemon's; a label read as state drives nothing, so one
  applied is a state claim with no state machine behind it. The `github`
  anchor connector cannot apply one; `gh --label` can, so the rule bites
  on the escape hatch (Step 3).
- **Never reach for a general GitHub surface to do an anchor's job.**
  If the anchor connector lacks an operation you want, that absence is
  PRD-016 §12, not a gap — label writes, issue editing, listing and PR
  merges are excluded by decision. Adding one is a ratification.
- **Never hand-roll a dependency gate in prose.** `depends_on` is the
  contract; prose is not.
- **Never use `work_order.create_child`** — it is not on this surface,
  by decision. It expresses an executing recipe's own decomposition,
  scoped to its dispatch. A harness filing a standalone Work Order uses
  `create` with `depends_on`.
- **Never invent argument names.** Each verb's arguments are fixed;
  a field the handler does not know is ignored, so a typo fails silently
  rather than loudly. Check against the table above.
- **Never describe the surface as unauthenticated or open.** Every call
  carries an authenticated principal and is attributed. If a call
  succeeds without one, that is a bug to report, not a convenience.
