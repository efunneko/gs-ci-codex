# Refusals, and what each one means

Each row is a symptom this surface actually produces — a refusal message, or a
state that surprises. Read what you were told before re-reading the Work Order:
most of these are the state machine or the grant model declining something, not
a Work Order that is wrong.

## Failure modes

| Symptom | Cause and fix |
|---|---|
| Every call refused, full catalog visible | Missing `api/v1/workorders/#`. Holding the ten tools is not enough — the operator gate is separate and carries the cross-owner reach. |
| `work_order <id> not found` on an ID that exists | An ownership-gate refusal is reported as not-found so a caller cannot probe for IDs. Check grants before doubting the ID. |
| `cannot retry from state "…"` | `work_order.retry` acts on `active` and `failed` only. The message names both; anything else (cancelled, complete, a `paused:*`) has no retry edge. |
| `reason is required` on retry | `reason` is mandatory. Only `hint` and `backoff` are optional — `id` is schema-optional but required *for you*, since it defaults to the caller's own dispatch and a supervisor has none (`id is required (no caller WorkitemID to default from)`). |
| `retry_cap_exceeded` | The type's `max_retries` cap, on an `active` Work Order — that is the orchestrator's ladder, and you have reached the top of it. Let the attempt fail and retry from `failed`, which the cap does not bound. |
| `backoff is not supported when retrying from state "failed"` | Nothing enforces a delay on that path yet. Drop the `backoff` and retry when you are ready. |
| `cannot approve from state "…"` | Review actions need `paused:awaiting-review`. |
| `not_root` on complete/fail | Working as designed — those verbs are not yours, at any privilege level. Use `transition(action = "approve")`. |
| `delivery: "none"` on answer | No orchestrator runs that worker. Operational fault; surface it. Do not re-answer. |
| `unknown parameter "…"` | The surface rejects arguments it does not recognise rather than dropping them. Check the spelling, or the message's pointer at the verb that does take it. |
