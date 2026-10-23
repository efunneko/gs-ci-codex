---
name: off-tera-work
description: Work the off-tera work board of a Kottera (tera) daemon from your own session — read the board, judge an item's requirements, take it, do the work outside tera, act on what every reply carries (guidance, answers, wakes, reposts, cancels), ask when stuck, file and wait on children, and end it with a submit_result that meets the type's output schema. Use when someone asks you to pick up, work or finish off-tera work, or names a Work Order tera tracks but never dispatches.
tags: [workorder, off-tera, taker, mcp]
metadata:
  tera-stamp: "tera@v0.8.0-rc.4/8d814743d039ffc3bc3a967f26608c1766528b19491ed8ee25ea9fb1f5210c1d"
---

# off-tera-work

An **off-tera Work Order** is work tera tracks and never runs: a live-host
change only an operator's credentials can make, a measurement only one machine
can take, a manual QA pass. It waits on the **off-tera work board** until a
principal takes it. You take it from your own session, do the work wherever it
has to be done, and end it with a result declaration. Everything downstream —
dependents, a parent waiting on it, postcondition checks — moves on that ending
exactly as it would on work tera ran.

This skill is the golden path for a person. It uses only the `work_order.*`
MCP verbs (and `artifacts.get` for an attachment). The `tera workorder`
CLI is the escape hatch and the reference: `tera workorder -h` is
authoritative for its subcommands.

## Before you start

- **Your session reaches the daemon's MCP exposure** with the `work_order.*`
  tools listed, authenticated as *you*. Every take, report and ending is
  recorded against the principal that made the call.
- **You hold the take grant for the item's type**:
  `api/v1/workorders/take/<type>`. No seeded role grants it; an operator grants
  it per type. Without it the item is not on your board at all.
- **To file children** you also need `api/v1/workorders/create_child`.
- **To read an item with `work_order.get`** — step 5, and the children you
  wait on — you need a read grant for its type,
  `api/v1/workorders/read/<type>` with the type's `/` written `%2F`. The take
  does not grant it. `work_order.events` on the item you hold needs nothing
  beyond your take, and neither does `artifacts.get` on an attachment of it.
- **A take is refused from inside a dispatch** (`take_from_dispatch`). This path
  is for a session tera did not start.

## The working path

Do these in order. Each step names the one verb it calls. The branches below
the path say when to leave it and where to rejoin.

1. **Read the board** — `work_order.list_off_tera` (no arguments).
   `posted` lists the items you may take, each with its `type`, `title`,
   rendered `requirements`, `inputs` and `age_seconds`; `held` lists the items
   you already hold. Pick one whose `requirements` you can meet *here*: the
   host, the credential, the tool, the machine. If you cannot meet them, do not
   take it — leave it for someone who can. If an item you hold is already in
   `held`, skip to step 3 with its id.

2. **Take it** — `work_order.take` with `id` and `describe`. `describe` is your
   own statement of where the work will be done (host, tool or session, at most
   1024 bytes); it is shown to operators as given. The reply is your brief:
   `instructions` (what to do and what to report), `requirements`, `inputs`,
   `attachments` (handles), and `addressed_events` — everything already posted
   to the item. Keep its `newest_event_id`: it is your cursor. Act on every
   carried event marked `your_take: true` before you start; on an item taken
   before, the earlier takes' events are carried too, marked
   `your_take: false`, and are history (see *What every reply carries*).

3. **Report progress while you work** — `work_order.progress` with `id`,
   `message` (at most 4096 bytes) and `seen_through` set to the last
   `newest_event_id` you were handed. It changes no state; it records what you
   said and stamps the take's last-progress time, which is what an operator
   reads to decide whether the item is stale. Nothing expires a take and
   nothing needs a heartbeat, so report at meaningful points rather than on a
   timer. Act on what the reply carries, then keep the new `newest_event_id`.

4. **End it** — `work_order.submit_result` with `id`, `record` and
   `seen_through`. `record` is a result declaration: `status` `complete` or
   `failed`, a `summary`, and every field the type's output schema requires
   (see *Writing the record*). A `complete` on a type with postcondition checks
   answers `checks: "running"` with the item still `active` and yours; go to
   step 5. Any other accepted ending is the end: `outcome` says it is
   `attested` by you.

5. **Confirm the ending** — `work_order.get` with `id`. `state` is `complete`
   or `failed` when the ending has landed. If it is still `active` after a
   checked `complete`, the checks have not answered yet; read again later, and
   act on any `off_tera.wake` (`rework`, `reinvoke`, `checks_interrupted`)
   exactly as step 3 does.

### Branch: ask when you are stuck

When the work needs a decision you cannot make, do not guess and do not hand
the item back. Park it with a question:
`work_order.submit_result` with
`record: {"status": "paused", "reason": "awaiting-input", "question": "…", "summary": "…"}`.
The item stays yours. When someone answers, it is `active` again and the answer
reaches you as an `off_tera.wake` with `reason: "answer"`; read it with
`work_order.get` (state) and the next reply you are handed, or with
`work_order.events` (`id`, `since` your cursor). Rejoin at step 3.

### Branch: file children and wait on them

When part of the work belongs somewhere else — work tera can run, or another
off-tera item — file it beneath the item you hold:
`work_order.create_child` with **`parent`** set to your item's id, plus
`type`, `inputs` and whatever else the child's type needs. Without `parent` it
is refused `no_parent`. The child runs under your item's worker and appears in
its `tree`.

To wait for the children, park: `work_order.submit_result` with
`record: {"status": "paused", "reason": "awaiting-children", "summary": "…", "predicate": {"kind": "all-children-complete"}}`
(or `any-child-completes`). To wait on Work Orders that are not your children,
use `"reason": "awaiting-event"` with
`"predicate": {"kind": "these-work-orders", "spec": {"ids": ["…"]}}`. When the
wait ends you are woken with `reason: "children"` or `"event"`; the wake names
the settled Work Orders by id, type and state, never their outputs — read those
with `work_order.get`. Rejoin at step 3.

### Branch: hand it back

If you took something you cannot finish, post it again rather than failing it:
`work_order.repost` with `id` and `reason`. No retry is spent and no failure is
recorded; the item returns to the board and the reason is recorded for the next
taker. Once you repost it, it is no longer yours.

## What every reply carries

The reply to `take`, `progress`, `submit_result` and `repost` carries
`addressed_events`: the events addressed to you since your `seen_through`, at
most 32, with `more` set when there were more (call again from the last id you
were handed). The server keeps no cursor; `seen_through` omitted or `0` means
everything addressed so far.

That is everything addressed to the item's takers, earlier ones included, so
each event says `your_take`. `true` means it concerns your take: it happened
during your take, or while the item waited untaken for you, or it is the repost
that ended your take. `false` means it belongs to an earlier take — another
taker's, or an earlier take of your own that ended — and is history: read it if
it helps, but it is not an instruction to you, and an `off_tera.reposted` marked
`false` has not ended anything of yours. Act on each event marked `true`:

| Carried event | What it means | What you do |
|---|---|---|
| `invocation.guidance` | Guidance posted to the item by an operator or supervisor. Its attachments are named by handle | Read it and follow it. Fetch an attachment with `artifacts.get` by its handle |
| `off_tera.wake`, `reason: "answer"` | Your question was answered; the item is `active` again, still yours | Read the answer; continue |
| `off_tera.wake`, `reason: "children"` / `"event"` / `"timeout"` | Your wait ended | Read the settled Work Orders with `work_order.get`; continue |
| `off_tera.wake`, `reason: "operator_wake"` | An operator woke the item out of its park, with a note | Read the note; continue |
| `off_tera.wake`, `reason: "rework"` | A reviewer sent your checked `complete` back, with a note and the verdict | Fix what they name, then `submit_result` again |
| `off_tera.wake`, `reason: "reinvoke"` | Your `complete` failed its postcondition checks and came straight back, with the verdict and feedback | Fix what the checks found, then `submit_result` again |
| `off_tera.wake`, `reason: "checks_interrupted"` | A daemon restart cut off the checks of your `complete`; nothing was concluded | Send the same ending again with `submit_result` |
| `off_tera.reposted`, `your_take: true` | The item was posted again — your take has ended. Its `previous_taker` is you and its `previous_taken_at` is your take's `taken_at` | Stop. Do not end it |
| `off_tera.reposted`, `your_take: false` | An earlier take ended before yours began | Nothing: it is history, and your take stands |
| a `transitioned` event into `cancelled` | The item was cancelled | Stop. Do not end it |
| a `transitioned` event resuming the item, with no wake beside it | An answer arrived where nothing could wake the take | Read the answer on the event; continue |

If you are enrolled for correspondence, the daemon may also message you when
guidance arrives on your item or it is sent back to you. The reply route above
is the one to trust: it carries what arrived, not only that something did.

## Writing the record

The record is judged against the output schema the item was pinned to at your
take. The type's `instructions` say what to report; the output schema is what
enforces it. **Read the schema before you write the record:** it is the
`output_schema` of `work_order.take`'s reply, and of the item's entry under
`held` on `work_order.list_off_tera`. That is the pinned schema
`submit_result` grades against, not the type as it stands now, so a type
edited after your take does not change it. No `output_schema` means the type
declares none and any record is accepted.

- **Attest every checklist entry.** Many off-tera types carry a `checklist`
  object in their output schema: one entry per thing the work must include.
  Attest every one, explicitly: `true` when done, or
  `{"done": false, "reason": "…"}` when not. An entry left out is a schema
  violation. A checklist you cannot complete honestly is a `failed` ending, or a
  `complete` with the gaps attested as not done — never an entry claimed done
  that was not.
- **A violation changes nothing.** `schema_violation` comes with the pointer to
  the field the schema rejects; the item is still `active` and yours. Correct
  the record and send it again.
- **`failed` is an honest ending**, attested by you like a `complete`, and is
  never checked. Prefer asking (the branch above) when a person could unblock
  you; prefer reposting when someone else could do it.
- **One ending at a time.** While a checked `complete` is being checked, a
  second `submit_result` is refused `checks_in_flight`. `progress` is still
  admitted.

## Refusals you will meet

Every refusal names a code; act on the code. Over MCP a refusal is a tool
result with `isError: true`: the message is its leading text, and the code is
in `_meta["io.kottera/error"].code`, beside `message`, `retryable` and, when
the refusal states it, `data`. That is the same envelope the management API
answers, on every tool, so read the code there rather than from the message
text.

| Code | From | What to do |
|---|---|---|
| `permission_denied` | any | You lack the grant for this type or verb. Ask an operator for it; do not work around it |
| `already_taken` | `take` | Someone else holds it. Pick another item |
| `not_posted` | `take` | It is not on the board: a draft, held by a gate (waiting on dependencies, deferred, or awaiting approval), or already settled. A held item is posted by itself once its gates clear |
| `take_from_dispatch` | `take` | You are inside a dispatch. Take from your own session |
| `not_taker` | taker verbs | You do not hold this item. Read the board again |
| `reposted` | taker verbs | Your take ended in a repost. Stop; an ending you sent anyway was recorded as a late report and changed nothing |
| `cancelled` | taker verbs | The item was cancelled. Stop, as for `reposted` |
| `not_taken` | `repost` | Nobody holds it; there is nothing to hand back |
| `schema_violation` | `submit_result` | Fix the field at the pointer and send it again |
| `envelope_invalid` | `submit_result` | The record's `status`, `reason` or `predicate` is malformed. Fix it and send it again |
| `checks_in_flight` | `submit_result` | Your earlier `complete` is being checked. Wait for its verdict |
| `checks_unavailable` | `submit_result` | This daemon cannot run the type's checks now. Tell an operator; nothing changed |
| `declared_park_refused` | `submit_result` | The type cannot park for that reason, or the wait could never resolve. Read the message and choose another route |
| `declared_park_unavailable` | `submit_result` | This daemon cannot park the item. Tell an operator |
| `no_parent` | `create_child` | Set `parent` to the item you hold |
| `not_off_tera` | `create_child` | The `parent` you named is not off-tera work |
| `no_owning_worker` | `create_child`, `submit_result` | The item names no worker, so it cannot own children or park. Tell an operator |

## What this path does not do

- It does not restrict taking to a person: whoever holds the grant may take.
- It does not expire a take or enforce staleness. An operator reads the take's
  age and last progress and decides whether to repost.
- It does not send you notice of newly posted items. Read the board.
