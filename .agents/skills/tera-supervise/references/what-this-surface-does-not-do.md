# What this surface does not do

The `work_order.*` surface is deliberately narrower than the daemon's own
lifecycle. This page carries the two absences a supervisor meets — the
bookkeeping you no longer do, and the five verbs that are not on the surface — with the
reasoning that makes each one a decision rather than a gap.

## The daemon dispatches; you advise

The difference from driving runs by hand is not cosmetic:

| Driving runs yourself | this skill |
|---|---|
| **You** launch each run, pick a host, and hold the concurrency cap. | The **daemon** dispatches. Concurrency, retries, backoff and scheduling are its state machine, not your bookkeeping. |
| You watch log files and reattach dropped followers. | You read a durable event log with a cursor. Nothing is dropped; a supervisor that was offline catches up. |
| A crashed follower can strand a work item. | Your session is not load-bearing. Disconnect and reconnect and the Work Orders are exactly where they were. |

## The five verbs you do not have

Five verbs are deliberately **not** on this surface, and their absence is
a decision rather than a gap (ADR-077 D3):

`work_order.complete` · `work_order.fail` · `work_order.create_child` ·
`work_order.pause` · `human.ask`

Note `work_order.fail` is absent and `work_order.force_fail` is present.
They are not the same verb wearing two names: `fail` is the worker
classifying its own outcome, which is the adjudication you do not get;
`force_fail` is you observing that a dispatch has stopped answering, which
is the judgement `cancel` already lets you make.

The rule is PRD-016's durability rule: **a harness advises; it does not
adjudicate outcomes it did not observe.** Terminal classification belongs
to the worker that watched the work happen. The daemon enforces that
independently of privilege: `work_order.complete` refuses with `not_root`
for every caller except the dispatched root — a principal holding a bare
`#` grant included — because the check is "are you the agent running this
Work Order", not "are you privileged".

So if you catch yourself wanting to mark something complete, what you
want is `transition(action = "approve")` — the sanctioned override path,
and the one that is exposed.
