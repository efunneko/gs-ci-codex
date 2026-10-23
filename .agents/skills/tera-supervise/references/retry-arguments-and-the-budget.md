# Retry arguments beyond `reason` and `hint`, and the budget

`work_order.retry` takes one more argument, behaves differently depending on
which state it fires from, and reports a budget that does not bound you. None
of that changes the call you make on the ordinary path — read it when a retry
is refused, when you are tempted to keep retrying, or when you are reporting
how far past a type's expectation you have pushed.

## The argument you will not pass

- `backoff` — a Go duration (`"30s"`, `"5m"`), **`active` only**, so in
  practice never yours to pass. From `failed` it is refused rather than
  accepted-and-ignored, because nothing enforces a delay on that path
  yet. Omit it and retry when you are ready.

## The two states, and who may fire each

The two states differ in what happens next, not in what you call:

| From | Who may fire it | Goes to | Bounded by the retry budget? |
|---|---|---|---|
| `active` | the dispatched agent only — **not you** | stays `active` — the agent re-invokes itself | **yes** |
| `failed` | you | back to `scheduled` — the daemon re-dispatches | **no** |

Either way the attempt is counted and your identity is on the event.

**The budget bounds the orchestrator, not you.** A type's
`max_retries` caps the ladder the orchestrator climbs on its own, while
the Work Order is still `active`; push past it there and you get
`retry_cap_exceeded`. Once the Work Order has `failed`, that ladder is
already spent — usually *because* of the cap — and your requeue is not
gated by it. So a Work Order that died with its budget exhausted is
still retryable with guidance, and a type that sets `max_retries = 0`
(`code-process-work-item` does) has declined to re-run itself
unattended, not declined you.

The result still reports the budget, so you can see how far past the
type's expectation you are pushing:

```json
{"id": "…", "state": "scheduled", "attempt": 2, "max": 1,
 "hint": "re-run only the touched packages; do not rebase"}
```

That is not licence to loop. An unbounded door is not a reason to keep
opening it: if two retries with guidance have not moved the Work Order,
the next thing to change is the work, not the hint — file a follow-up
Work Order or escalate.

`transition(action = "retry")` still exists and still re-queues a
`failed` Work Order, but it carries no guidance and there is no reason to
reach for it. If you put a `hint` on it you get an error naming the right
call — arguments this surface does not recognise are **rejected, not
ignored**.
