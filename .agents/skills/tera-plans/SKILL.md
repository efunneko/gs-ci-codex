---
name: tera-plans
description: Take a feature from a design session to its requirements, decisions and a plan; have the plan ratified; start its train as a plan orchestrator Work Order with `work_order.create` on the `tera` MCP server or `tera workorder create`; and check a running train with `work_order.tree`. Follows the repository's process profile, `.tera/process.md`.
metadata:
  tera-stamp: "plugin.dev-pipeline@2.0.0/18e2bfe027e716cd41dcf698cb1761ad0ca15028c5a4f84faddbe4cac101af18"
---

# tera-plans

Use this skill when the person wants to design a feature and have the dev
pipeline build it, start a plan that is already written, or check on one
that is running ("start a plan", "check a train", "how is the search
train doing?").

A **plan** is a document: the order the work for a feature lands in, as
waves of items. A **train** is that plan running: one plan orchestrator Work
Order drives it wave by wave, filing a wave orchestrator for each wave, which
derives the wave's items, has them implemented and verified, and reports
back. People decide and ratify. The train does the rest, and parks to ask
when it needs someone.

## Read the profile first

Read `.tera/process.md` before anything else. It says:

- where requirements, decisions, plans and briefs live (`## Documents`);
- who decides, who ratifies and who performs out-of-band acts (`## People`);
- how Work Orders, pull requests and cohorts are named (`## Naming`);
- how a document change is reviewed and merged (`## Review and merge`).

Everything below defers to it. If the repository has no profile, stop and
use the `tera-dev-process` skill to write one first. A plan needs to know
where its documents go and who ratifies it.

## How this skill names a tool

A tool is named here as "`work_order.<verb>` on the `tera` MCP server". Your
harness spells an MCP tool its own way, so call whatever it maps that name
to. **The `tera workorder` command is the fallback** when no `tera` MCP
server is connected to your session. It reaches the same Work Orders through
the daemon's management API with your own credentials, and
`tera workorder -h` is the authority on its flags. The `tera-work-orders`
skill covers filing in full, and `tera-supervise` covers answering what a
train parks on.

## 1. The design session: requirements, decisions, a plan

A design session is a conversation with the person who decides (the
profile's `## People`). It produces three kinds of document, in this order,
in the directories `## Documents` names.

**Requirements: what must be true, and why.** Ask what problem the feature
solves and for whom. Ask what "done" looks like from the outside. Write the
answers as numbered requirements (R1, R2, …), each one testable, with how
success is measured. Say nothing about how they will be met.

**Decisions: how the requirements will be met.** Ask one design question at
a time. For each one, lay out the options with what each costs, and give a
recommendation. When the person chooses, record the decision with its
context, the options rejected and why, and its consequences. A question the
person wants to leave open stays open, and the decision says so. Do not
decide it for them.

**The plan: the order the work lands in.** Write the waves in order. A wave
is a stretch of work the train finishes, verifies and learns from before it
commits to the next. Its items run in parallel where nothing orders them,
and may depend on one another, so a wave need not be one layer of the
dependency graph. Start a new wave where what comes next depends on what
this one will teach, or where a person must act in between. A typical
feature is two to four waves. For each wave, state:

- its objective, and which requirements and decisions it carries;
- its scope, as an outline of what the wave must cover, and acceptance
  criteria a verifier can check. Do not list its items: the wave
  orchestrator derives them from the code when the wave starts, sizing each
  to about an hour of a session's work, so several bullets of an outline may
  become one item;
- what must not break while it runs;
- the out-of-band acts it needs: what a person must do that no session can,
  such as a release, a credential or a deployment, and who does it.

Give the plan a **feature slug**, a short lowercase name such as `search`.
It names the plan's file, its cohort, its Work Orders and its pull requests,
as `## Naming` sets out.

Show each document in full before writing it. Write it on the person's
approval, and land it as `## Review and merge` says, usually as a pull
request of documents. Each document opens with `**Status:** Proposed`.

## 2. Ratification

A train runs only on a ratified plan. Ratification is a person's act, by
whoever `## People` names, never yours and never the train's:

1. The ratifier reads the plan with the requirements and decisions it cites,
   and either asks for changes or accepts it.
2. On acceptance, change the plan's status to `Ratified` and its
   requirements' and decisions' statuses to `Accepted`, and land that change
   as a pull request. The plan must be on the branch the train will run
   from before the train starts, because the orchestrator reads it from its
   own checkout.

When the train ends, the ratifier does the same for the outcome. The plan
becomes `Done`, and any decision the train changed is superseded by a new
one.

## 3. Starting a train

File one **plan orchestrator** Work Order for the plan. Check the
deployment's registered types first, with `tera workorder types`, and pick
the plan orchestrator for the harness the person runs: `plan-orchestrator-claude`
on Claude Code, or the Codex add-on's `plan-orchestrator` on Codex. Read the
type's inputs with `tera workorder types <type>`. The dev pipeline's
orchestrators take:

| Input | Value |
|---|---|
| `plan_path` | the plan's repository-relative path, already committed on `branch` |
| `repo` | the repository, as `owner/repo` |
| `branch` | the branch the train runs from, usually the default branch |

Open a new cohort for the train, labelled as `## Naming` says (by default
`<feature> - <short description>`). Everything the orchestrator files then
lands in it.

Call `work_order.create` on the `tera` MCP server:

```json
{
  "type": "plan-orchestrator-claude",
  "worker": "<the worker the deployment runs the pipeline as>",
  "title": "<feature>: drive the plan",
  "inputs": {
    "plan_path": "<path to the plan>",
    "repo": "<owner/repo>",
    "branch": "<branch>"
  },
  "cohort": { "new": true, "label": "<feature> - <short description>" },
  "idempotency_key": "<feature>-train-<date>"
}
```

Or, as the fallback:

```sh
tera workorder create --type plan-orchestrator-claude --worker <worker> \
  --title "<feature>: drive the plan" \
  --inputs '{"plan_path":"<path>","repo":"<owner/repo>","branch":"<branch>"}' \
  --new-cohort --cohort-label "<feature> - <short description>" \
  --idempotency-key "<feature>-train-<date>"
```

Show the person the call before you make it, and tell them what it starts.
Keep the Work Order's id: it is how the train is checked.

## 4. Checking a train

The plan orchestrator is the root of the train. Everything the train files
is beneath it.

- **`work_order.tree`** with the orchestrator's id
  (`tera workorder tree <id>`) gives the whole train in one call: each wave
  orchestrator and its items, their states, counts by state, what is blocked
  on what, and the question of anything parked awaiting an answer.
- **`work_order.get`** on one Work Order (`tera workorder show <id>`) gives
  its full state, including a failure's reason.
- **`work_order.events`** (`tera workorder events <id>`) gives what happened
  to it, in order.
- **The plan itself** records each finished wave's verdict, and each wave's
  brief records what it learned. Read them from the repository.

Report to the person, in this order:

1. what is parked waiting on a person, with each question as asked;
2. what failed, and whether the train has already handled it;
3. which wave is running, and how many of its items are done;
4. the out-of-band acts that are due, and who performs them.

A parked question is the person's to answer, or the person's to delegate to
you. Answer it only when they tell you to, with `tera-supervise`. Never
cancel, retry or approve anything in a train unless the person asks.

## Rules

- **Never start a train on a plan that is not ratified**, and never ratify
  one yourself.
- **Never write a document the person has not seen and approved.**
- **File the plan orchestrator only.** It files the waves and they file the
  items. A Work Order you file by hand inside a running train is invisible to
  the orchestrator that should have filed it.
- **Never invent a type, a worker or an input.** Read them from the
  deployment, and ask the person when you cannot.
