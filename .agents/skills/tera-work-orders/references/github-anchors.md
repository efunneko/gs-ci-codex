# GitHub's one role, and how to file an anchor issue

Much work is filed with no anchor issue at all, so this page is for the filing
that wants a public discussion surface — and for understanding why the issue
is never the work item.

## The issue is never the work item

A Work Order filed here is the work: the daemon dispatches it, a runner
executes it, and the lifecycle is durable daemon state. GitHub keeps exactly
one role, ratified by PRD-016 §12: **archival anchor and discussion home,
never a state machine.**

A queue that reads labels off an issue as state — a `<queue>-work:*` or
`skill:*` family and their like — is a second queue, and nothing dispatches
from it. If the repository you are filing for once ran one, its instructions
say so; either way, do not apply those labels to anything.

## Step 3 — optionally file a plain GitHub anchor issue

If the work wants a public discussion surface, file one — plain.

**No labels that encode queue state. No `### Dependencies` section.** A
protocol-shaped section on an anchor is a **second statement of dependency
that drives nothing**, so it cannot be wrong loudly — it just drifts from the
`depends_on` that is actually authoritative and misleads the next reader. An
anchor is prose. That rule binds identically on both routes below.

### The golden path — the `github` anchor connector

The deployment's GitHub **anchor connector** is the route to prefer. It
exposes exactly four operations — `issue_create`, `issue_comment`,
`issue_close`, `pr_state` — and **has no label operation at all**, so the
"no protocol labels" rule above is enforced by the surface rather than by
your care. Call it the way you call any other connector-backed capability
on the MCP surface:

```json
{
  "operation": "issue_create",
  "params": { "title": "<title>", "body": "<the prose from Step 2>" }
}
```

`owner`/`repo` come from the connector's config; pass them as params to
override. The result carries `number`, `state` and `html_url` — `number`
is what Step 3's link-up below wants.

Like the `work_order.*` exposure in Step 0, the connector is a
**documented example, never a default**: if nobody has installed it,
there is nothing to call. Config and operator notes:
[`examples/github-anchor-connector/`](https://github.com/kottera/kottera/tree/main/examples/github-anchor-connector)
and [`docs/subsystems/connector-runtime.md`](https://github.com/kottera/kottera/blob/main/docs/subsystems/connector-runtime.md)
§ "The GitHub anchor connector".

### The escape hatch — `gh` directly

When the connector is not installed in this deployment, file the anchor
with `gh` instead. This is a real fallback, not a deprecated path — but
it is the route where the no-labels rule rests on you rather than on the
tool:

```bash
gh issue create --repo <owner/name> --title "<title>" --body-file "${TMPDIR:-/tmp}/wo-<slug>.md"
```

Never add `--label` to that command. There is no anchor-issue label worth
applying, and a label some other process reads as queue state files
duplicate work.

### Link the anchor to the Work Order

Whichever route you used, carry the issue number into the Work Order **if
the type declares a field for it**:

```json
"inputs": { "issue_number": 1052, "repo": "<owner/name>" }
```

**Check the type first.** Not every lifecycle type declares
`issue_number` — kottera's `code-implementation-direct`, for example, takes
`repo`, `branch` and `task` and nothing else. An undeclared key is refused at
create only when the type's schema sets `additionalProperties: false`;
otherwise it is **silently ignored**, so a mis-set link fails without telling
you. Where the type has no field for it, name the issue in the `task` prose
instead and let the PR close it with `Fixes #N`. Live state stays in tera
either way.
