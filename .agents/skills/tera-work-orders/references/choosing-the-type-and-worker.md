# Why the owner is load-bearing, and what will not default it

The `worker` argument is the one filing-time decision whose consequence lands
somewhere other than the filing. Read this when a `worker is required` refusal
surprises you, when a dispatch fails mid-workflow with `not_found`, or when you
are tempted to let something else supply the owner.

## The owner is a filing-time decision

The owner is a filing-time
decision — stated by the `worker` param, or by the `worker` attribute
of the trigger that files it — and it is load-bearing rather than
bookkeeping: a capability step runs worker-class and reaches only that
worker's own Work Orders, so a wrong owner surfaces as a mid-workflow
`not_found` rather than as a filing error.

**The client-context default worker does not reach you here.** `tera
context set --default-worker` (kottera/kottera#1334) is a *caller-side* default that
`tera workorder create` fills in from `~/.tera/config`. An MCP session
has no such file, and an operator-class `work_order.create` arrives
carrying no worker of its own, so there is nothing to fall back on —
omitting `worker` on a non-agent-recipe type is refused, every time.
