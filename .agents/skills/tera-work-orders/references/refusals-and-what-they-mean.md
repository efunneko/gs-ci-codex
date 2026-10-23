# Refusals, and what each one means

Each row is a symptom this surface actually produces — a refusal message, or a
state that surprises. Three of them are the
three separate gates behind the exposure, which is the distinction worth
carrying: a refused listing, an absent name and a refused call mean three
different missing grants.

## Failure modes

| Symptom | Cause and fix |
|---|---|
| `tools/list` is missing a verb you expect | Your principal lacks that `tools/work_order.…` grant. The catalog filter and the invoke check are the same gate, so a missing name would also be refused on call. |
| Session opens, every call refused | Missing `api/v1/workorders/#`. Holding the tools is **not** enough — that third gate is what carries cross-owner reach, and it is separate on purpose (ADR-077 D2). |
| `tools/list` refused outright | Missing `mcp/work-orders`, the exposure gate. |
| `work_order <id> not found` on an ID you know exists | An ownership-gate refusal reports not-found so an unauthorized caller cannot learn the ID exists. Check your grants before you doubt the ID. |
| `unknown work_order_type "…"` | No registered type has that name. A full name carries the vault the type is registered in, which is not always `system`: a tracked vault's types are `kottera/work-order-types/<stem>`, and a plugin installation's are `plugin.<installation>.v1/work-order-types/<stem>`. `tera workorder types` lists every name the daemon registers. |
| `ambiguous_type` | The bare leaf names more than one registered type, and the refusal lists every candidate. Pass the one the work is meant for by its full name, `<vault>/work-order-types/<stem>`, copied from that list. The current type is the candidate whose recipe names another in `previous_names`: during a move the other is usually the type being retired, and new work filed there runs the old recipe. When no candidate names another, the consumer's instructions say which is the ordinary home; ask rather than pick. |
| `type is required` | `type` is the one unconditionally mandatory argument. |
| `worker is required: …` | No recipe names its owner, so none can be derived — a workflow or capability recipe, which after ADR-082 D3 is every lifecycle type. Pass `worker` (Step 1). The refusal names the recipe kind, so it tells you which case you are in. The worker you name is also who the work runs as: its steps are authorized as `worker:<name>`, so the grants they need belong to that worker. |
| `depends_on: work_order "…" not found` | A dep ID that does not exist — most often a GitHub issue number passed where a Work Order ID belongs. Nothing was filed; fix the list and re-file. |
| Created immediately `blocked:waiting-on-deps` | Working as designed. Read `block_reason.detail.pending`. |
| Connection refused on 127.0.0.1:8099 | The exposure is not installed, or the daemon is not running. It is an example, not a default. |
| No GitHub anchor connector on the surface | It is an example, not a default (Step 3). Use the `gh` escape hatch, or install [`examples/github-anchor-connector/`](https://github.com/kottera/kottera/tree/main/examples/github-anchor-connector). |
| Anchor connector has no operation for what you want | Almost certainly PRD-016 §12 excluding it by decision — label writes, listing, issue editing, PR merges. Not a gap to route around. |
