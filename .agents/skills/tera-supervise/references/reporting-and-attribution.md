# Reporting what happened, and what the event log already answers

A supervisor reports as often as it acts. This page is for the report rather
than for the action: how to reconstruct a decision that was already made, what
the answer verb does and does not know once it has re-dispatched, and what is
recorded about you on every transition you drive.

## Reconstructing a decision after the fact

The exchange is on the event log too, both halves — the parking event's
`pause_reason` and the resume event's `payload` — which is where to look when
reconstructing a decision after the fact rather than making one:

```json
{"kind": "transitioned", "to_state": "paused:awaiting-input",
 "reason": "human.ask: awaiting-input",
 "payload": {"pause_reason": {"context": {"question": "rebase or merge?"}}}}
```

## What the answer verb knows once it has re-dispatched

On the redispatch path the daemon knows the run was re-entered carrying
the answer, and no more than that: whether the session then reads it
happens past a seam this verb cannot see. If a run goes quiet after a
`redispatch`, that is a fresh question about the session, not evidence
that the answer verb failed.

If you report *what happened* rather than just whether it worked, read
`resumed_parked_run` beside it. `true` means the run resumed at the step
it parked on with its bounds intact (an ADR-086 parked run); `false` means
the recipe was re-entered from the top and the agent's own session memory
carries the continuity. Both are healthy — the field distinguishes two
normal outcomes, not a good one from a bad one. Say "resumed" only for the
first; a daemon older than kottera/kottera#1705 omits the field, so absent
reads as `false`.

## Every action you take is attributed

Each **transition** you drive is recorded on the Work Order's event log
with your identity — the acting class, the principal, the origin seam and
the MCP session (ADR-077 D6, PRD-016 SC2):

```json
{"kind": "transitioned", "from_state": "paused:awaiting-input",
 "to_state": "active", "reason": "work_order.answer",
 "actor": {"class": "operator", "principal": "wo-harness",
           "origin": "mcp_gateway", "session_id": "5c7fb9ea…"}}
```

Two things follow. **"Who answered this Work Order" is answerable from
the event log alone** — you never have to reconstruct it from
scrollback, and neither does anyone reviewing your work. And your
`reason` / `hint` / `note` text is durable and attributed: write it for
the person who reads it in three weeks.

> Note the asymmetry with **creation**: the `created` event carries no
> `actor` block, and records the filing principal as `created_by` in its
> payload instead. So "who filed this" and "who answered this" are both
> answerable, but only the second carries the MCP session id. Do not
> infer from a null `actor` on a `created` event that the Work Order
> arrived unattributed.

Your class is `operator`, which is what gives you **cross-owner reach** —
you can answer, retry, transition and cancel Work Orders you did not
file and did not watch pause. That reach is the entire reason this
surface exists, and it is also why the grant behind it is separate from
the tool grants. Use it deliberately.
