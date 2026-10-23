# Clearing a wedge

A dispatch that stops answering leaves its Work Order `active` forever,
holding its LLM seat and its concurrency slot, with everything that
depends on it waiting behind it. The state looks healthy; only the event
log shows nothing has happened.

**Do not retry it in place.** You will be refused, and the refusal is
protecting you: the `active` edge of `retry` is the dispatched agent's own
"give me another turn", and firing it from outside re-runs nothing while
opening a *second* seat lease. That is not hypothetical — it once drove a
six-seat pool to 6/6 held with zero work running.

Two calls, in this order:

```json
{"name": "work_order.force_fail",
 "arguments": {"id": "<id>",
               "reason": "no events for 25m; session died without a tool result"}}
```

```json
{"name": "work_order.retry",
 "arguments": {"id": "<id>", "reason": "operator requeue",
               "hint": "the last attempt never dispatched — check the ACL grants first"}}
```

`force_fail` moves it to `failed`, which releases its seat, its volumes
and its environments. `retry` then puts it back on the queue **under the
same id**, so everything that depends on it stays pointed at it and the
ordinary deps gate releases those when it completes. Nothing has to be
re-filed.

Four things to know:

- **It works on a `cancelled` Work Order too.** That is the reason the
  verb accepts a terminal state at all: `cancelled` has no retry edge, so
  before this existed, cancelling a zombie stranded every dependent
  permanently and the only recourse was re-filing the whole train. If you
  or someone else already reached for `cancel`, you are not stuck.
- **Prefer `force_fail` to `cancel`** for anything you might want back.
  Both end the dispatch and free the seat; only one has a way back.
- **It does not cascade.** Children of a force-failed parent keep
  running; a dependent stays `blocked:waiting-on-deps` naming the dead dep
  rather than failing with it. `cancel` is the verb that cascades.
- **`reason` is required, and it matters.** It is what someone reading
  the event log later has to tell your judgement from the agent's own
  failure report — the two land in the same column.

Before you reach for this, be sure it is actually wedged. Read
`work_order.events` and check that nothing has happened for a while.
A long-running `active` Work Order that is still emitting events is
working, and force-failing it throws away that work.
