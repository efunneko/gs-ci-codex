# The documents layout

Five directories, one for each kind of document the dev pipeline reads and
writes. The profile's `## Documents` section names them, and a session reads
that section to find them. Offer each one as a directory holding a
`README.md` that says what belongs there, using the text below. Write only
the directories the person accepts. If they keep a kind of document
somewhere else, the profile names that place instead.

| Directory | Holds | One file is |
|---|---|---|
| `docs/requirements/` | what must be true, and why | one product area or feature |
| `docs/decisions/` | how it will be made true, and what was rejected | one decision |
| `docs/plans/` | the order the work lands in | one train of work |
| `docs/briefs/` | what one wave of a plan must know before it starts, and what it learned | one wave |
| `docs/notes/` | anything worth keeping that is none of the above | one topic |

**Why five, and why these:** each kind answers a different question and
changes at a different rate. Requirements change least, and a plan changes
every wave. Keeping them apart means a session that needs one does not have to
dig it out of the others.

## Naming

Number requirements and decisions, and date plans:

- `docs/requirements/REQ-001-<slug>.md`
- `docs/decisions/DEC-001-<slug>.md`
- `docs/plans/PLAN-<yyyy>-<mm>-<feature>.md`
- `docs/briefs/brief-<feature>-wave<N>.md`
- `docs/notes/<slug>.md`

**Why:** a number never changes when a title does, so a citation such as
"DEC-004" stays true. A plan is named for its feature slug, which is also how
its Work Orders and pull requests are named.

## Status

Every requirement, decision and plan opens with a status line:

```
**Status:** Proposed
```

Requirements and decisions move from `Proposed` to `Accepted`, and later to
`Superseded by <id>` if they are replaced. A plan moves from `Proposed` to
`Ratified` before its train starts, and to `Done` when the train ends.
**Why:** the status is what a session checks before it acts on a document. It
must never build to a decision nobody accepted.

## The `README.md` for each directory

Write each directory's `README.md` as below, adjusted to whatever the person
changed.

### `docs/requirements/README.md`

```markdown
# Requirements

What must be true, and why: one file per product area or feature, named
`REQ-<nnn>-<slug>.md`. Each states the problem, who has it, numbered
requirements (R1, R2, …) and how success is measured. It says nothing about
how the requirements will be met: that is a decision.

A requirement opens `**Status:** Proposed` and becomes `Accepted` when a
maintainer accepts it.
```

### `docs/decisions/README.md`

```markdown
# Decisions

How a requirement will be met: one file per decision, named
`DEC-<nnn>-<slug>.md`, each with its context, the decision, the alternatives
rejected and why, and its consequences. A decision is never edited after it
is accepted. A later decision supersedes it, and both say so.
```

### `docs/plans/README.md`

```markdown
# Plans

The order work lands in: one file per train, named
`PLAN-<yyyy>-<mm>-<feature>.md`. A plan names the requirements and decisions
it carries out, then its waves in order. For each wave it gives the items,
each with acceptance criteria, what must not break, and the out-of-band acts a
person must perform. The train's orchestrator records each wave's verdict
here.

A plan is `Proposed` until a maintainer ratifies it. No train starts on a
plan that is not `Ratified`.
```

### `docs/briefs/README.md`

```markdown
# Briefs

What one wave of a plan must know before it starts: one file per wave, named
`brief-<feature>-wave<N>.md`. It holds the state of the code, the rulings for
the wave, and what earlier waves learned. The wave's closeout is appended to
its brief when the wave ends.
```

### `docs/notes/README.md`

```markdown
# Notes

Anything worth keeping that is not a requirement, a decision, a plan or a
brief, such as an investigation, a measurement or a runbook. One file per
topic.
```
