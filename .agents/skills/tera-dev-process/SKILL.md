---
name: tera-dev-process
description: Write a repository's process profile, `.tera/process.md`, which the dev pipeline's sessions read before anything else. In a new repository, interview the person one opinion at a time. In an existing one, draft it from the evidence. Offer the starter gate script, CI workflow and documents layout. Show every draft, and write files only when the person approves them.
metadata:
  tera-stamp: "plugin.dev-pipeline@2.0.0/d1294f891fe98f2c0d111981109d6826cf06d21be1de5e5acc0573cdf6e377b1"
---

# tera-dev-process

Use this skill when the person wants their repository's process written
down for the dev pipeline. That happens when `tera get-started`'s `process`
stage sends you here, or when they ask to write or change
`.tera/process.md`.

**You write the files, not tera, and only once the person has approved
them.** tera serves this skill and checks the result. It never writes the
profile or the starter files. They belong to the repository from the moment
they exist: they carry no stamp, and nothing refreshes them.

## What the profile is

One Markdown file at `<repository>/.tera/process.md`, committed and pushed
like code. Every session the dev pipeline dispatches into the repository
reads it first. Where it speaks to a matter of the repository, it outranks
the session's own defaults. Where it is silent, the defaults apply. It is
repository content, not configuration: a change merged mid-train reaches
the train's later items.

It carries these sections, each heading spelled exactly so. Other sections
are allowed:

| Heading | What it says |
|---|---|
| `## Gate` | the one command that verifies a change before it merges, in exactly one fenced block, and when to run it |
| `## Build and test` | how to build and test while working |
| `## Branches and pull requests` | branch naming, one pull request per item, title and body |
| `## Review and merge` | who or what reviews, the required checks, the merge method, who merges |
| `## CI` | what runs where, and what a session must not do |
| `## Naming` | Work Orders, pull requests, cohorts |
| `## Documents` | where requirements, decisions, plans, briefs and notes live |
| `## People` | who decides, ratifies and performs out-of-band acts, by role |
| `## Rules` | the repository's own musts and must-nots |

A section may point at the repository's own documents instead of repeating
them, for example "see `CONTRIBUTING.md` § Releases". `tera config validate
--dir <repository>` checks that every heading is present and that `## Gate`
holds exactly one fenced block. Whether the gate command works is shown
later, when the first Work Order runs it.

## The references

| Reference | What it is | Written to, on approval |
|---|---|---|
| [`references/process-template.md`](references/process-template.md) | the profile, every choice stated with its reason | `.tera/process.md` |
| [`references/gate/go.sh`](references/gate/go.sh), [`rust.sh`](references/gate/rust.sh), [`python.sh`](references/gate/python.sh), [`node.sh`](references/gate/node.sh) | the gate script for each language | `scripts/gate.sh` |
| [`references/ci/gate.yml`](references/ci/gate.yml) | a GitHub Actions workflow that runs the gate | `.github/workflows/gate.yml` |
| [`references/documents-layout.md`](references/documents-layout.md) | the documents layout, with a `README.md` for each directory | `docs/<kind>/README.md` |

The template is the use case's opinions, and every choice in it states its
reason. A repository that accepts every recommendation keeps the template
almost as it is. A repository that differs changes the choice and gives its
own reason. Keep the `*Why:*` lines: they tell the next reader what changing
a choice gives up.

If you were not given the references as files, `tera skills show
tera-dev-process <reference>` prints each one.

## First, which repository is this?

`tera get-started` tells you. Its `process` stage prints either an interview
or a discovery brief. Without it, judge by history:

- **A new repository** has no history worth reading: no merged pull
  requests, no CI, no build scripts. **Interview** the person.
- **An existing repository** has a process already, written down or not.
  **Discover** it from the evidence, then confirm it with the person.

When you cannot tell, ask which it is.

## A new repository: the interview

Offer the use case's opinions **one at a time**, in the template's order,
starting with `## Gate`. For each one:

1. State the recommendation and its reason, in a sentence or two, taken from
   the template.
2. Ask whether to keep it or change it. Accept a short answer: "yes", "squash
   is fine", "we merge with a merge commit".
3. If they change it, ask for the reason in their words, and record both.

Do not batch questions, and do not ask about something the person has
already settled. One opinion at a time keeps each decision a real choice
rather than a form to sign.

The gate comes first, because everything else refers to it. Ask which
language the repository is in and offer that language's gate script as
`scripts/gate.sh`. If it is more than one language, offer a script that calls
each language's gate in turn. If the repository already has a single command
that builds, lints and tests, offer that command instead.

Each language's gate script passes on a repository with no code in that
language yet, and says so, so a new repository's first commit passes the gate
it adopts. Once the language's manifest or code exists, every check runs.

Then, for the starter files, ask once each whether they want:

- **the gate script** at `scripts/gate.sh`;
- **the CI workflow** at `.github/workflows/gate.yml`, which runs the same
  command, if the repository is hosted on GitHub. Elsewhere, offer to
  translate it to the host's CI, keeping the rule that CI runs exactly the
  gate;
- **the documents layout**: the directories they keep, each with its
  `README.md`.

## An existing repository: discovery

Read the evidence before you draft anything, and note where each answer came
from:

- **CI configuration**: `.github/workflows/`, `.gitlab-ci.yml`, and any other
  CI files. Find the command a pull request must pass.
- **Branch protection**, for the required checks, required reviews and
  whether history must be linear:
  `gh api repos/<owner>/<repo>/branches/<default-branch>/protection`.
- **Build and test scripts**: `Makefile`, `package.json` scripts,
  `Cargo.toml`, `pyproject.toml`, `justfile`, and `scripts/`.
- **Contribution guides**: `CONTRIBUTING.md`, `README.md`, and `docs/`.
- **Pull request templates** and **code owners**: `.github/` and
  `CODEOWNERS`.
- **Recent merged pull requests** and their titles, which show the naming
  and the merge method in practice:
  `gh pr list --state merged --limit 30 --json title,mergeCommit,author`.
- **The repository's own agent instructions**: `CLAUDE.md`, `AGENTS.md`, and
  whatever other files its harnesses read.

Then draft each section from that evidence, in the template's shape.

- **Where the repository already decides something, the profile says what it
  decides**, and points at the document that says it where one exists. Do
  not replace a working process with the template's.
- **A gap is a decision, not a default.** If there is no single gate
  command, no plans directory, or no review rule, do not fill the gap
  silently. Ask the person, offering the template's choice and its reason as
  the recommendation.
- **When the evidence disagrees with itself**, for example a contribution
  guide saying "rebase" while the history shows merge commits, show the
  person both and ask which one is the rule.

## Show, correct, then write

1. **Show every draft in full** before writing anything: the profile and each
   starter file the person wanted. Say where each will be written.
2. **Correct it with the person** until they approve it. Approval of the
   profile is not approval of the CI workflow. Ask for each file.
3. **Write only what was approved**, at the paths you showed.
4. **Check it**: `tera config validate --dir .` must report no finding for
   `.tera/process.md`. Fix any finding and show the fix.
5. **Commit and push it as the repository's own rules say**, which is now the
   profile you just wrote: the profile and every starter file you wrote, in
   one commit, so the default branch carries the gate script the profile
   runs. Ask before you push. `tera get-started` counts the
   `process` stage done only once the profile is on the default branch.

## Rules

- **Never write a file the person has not seen and approved.**
- **Never put a secret in the profile or a starter file.** A gate that needs
  a credential reads it from the environment, and the profile names the
  variable, never its value.
- **Never edit a file tera manages**, such as `.tera/instructions.md` or the
  block between `<!-- tera:begin` and `<!-- tera:end -->`, to record the
  process. The process belongs in `.tera/process.md`.
- **Do not repeat a document the repository already has.** Point at it.
