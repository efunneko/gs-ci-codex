---
name: tera-config
description: Author, plan, and apply Kottera (tera) vault-native configuration — recipes, deployment manifests, and input variables — using the tera config plan/apply/validate/diff workflow. Use when changing a tera daemon's work-order types, tools, roles, listeners, LLM tiers, MCP upstreams, or any .tera/ config, or when reading the machine-readable plan contract.
tags: [config, hcl, iac, vault, deployment]
metadata:
  tera-stamp: "tera@v0.8.0-rc.4/ce1e4656fdb20fd9b14bcf7b2ff176d96c22620b097bfcd8cbbb6813df5f45ea"
---

# tera-config

This skill teaches you to change a running **Kottera** daemon's configuration
the golden-path way: edit vault-tracked `.tera/` files, **plan** the change to
see its reviewed action set and blast radius, then **apply** it. The workflow
is Terraform-shaped and every step has a machine-readable contract.

The `references/` directory next to this file is **generated from the exact
`tera` binary** you are targeting — the recipe JSON Schemas, per-kind reference
tables, the plan contract schema, and the full schema-registry catalog. Trust
it over anything you remember: it cannot be stale or version-skewed relative to
the daemon that produced it.

## Mental model (ADR-064)

- The daemon's **system vault** (a git repo, default id `system`) is the *sole
  desired-state store*. Configuration lives as files under its `.tera/`
  directory. Additional **user vaults** contribute recipes namespaced
  `<vault-id>/<kind>/<name>`.
- `bootstrap.hcl` is a tiny **kernel** (broker / storage / system_vault /
  break_glass / token_vault / deployment_profile). Everything else — LLM tiers,
  listeners, workers, MCP upstreams/exposures, roles — is a vault config-kind
  composed onto the kernel at boot and on every hot-reload.
- **Git history is the apply audit log.** Applying writes and commits into the
  owned vaults; the `.tera/` file watcher then recomposes the running config.
  There is no separate "config API write" surface — edits flow through the
  vault.
- Editing a `.tera/` file on disk (or pushing to a synced remote) hot-reloads
  the daemon. `tera config apply` is the same thing done transactionally with
  validation, dependency ordering, and a drift guard.

## The two shapes of a desired-state push

Every `plan`/`apply`/`validate`/`diff` accepts the desired state in one of two
modes:

- **Directory mode** — a single vault's tree on disk:
  `--dir <path>` (the vault root containing `.tera/`) and `--vault <id>`
  (default `system`).
- **Manifest mode** — a multi-vault composition declared by a deployment
  manifest (ADR-066): `-m <file>` (defaults to `tera.hcl` in the working
  directory if present). The manifest pulls sources (local paths, git remotes)
  and composes them into a snapshot.

If a `tera.hcl` exists in the working directory, manifest mode is the default;
otherwise pass `--dir`.

## Golden-path workflow: plan then apply

1. **Edit** the recipe files under your vault's `.tera/` tree (see "Authoring
   recipes" below).

2. **Validate offline** (no daemon needed) — schema + reference checks:
   ```
   tera config validate --dir ./myvault
   tera config validate -m tera.hcl
   ```
   Exit code 0 = valid, 2 = problems found. Add `--format json` for a
   machine-readable problem list.

3. **Plan** — compute the reviewed, ordered action set against the running
   daemon:
   ```
   tera config plan --dir ./myvault
   tera config plan --dir ./myvault --format json -out plan.json
   ```
   `--format json` emits the **plan contract** (see below). `-out plan.json`
   saves it so you can apply *exactly that* reviewed transition later. Use
   `--diff` to see the raw current-vs-desired text instead of the action set.

4. **Apply**:
   ```
   tera config apply plan.json        # replay a saved plan EXACTLY
   tera config apply --dir ./myvault  # re-plan from the tree and apply in one step
   ```
   Applying a saved `plan.json` carries the plan's **baseline** (per-vault git
   HEAD at plan time). If a vault moved since (e.g. a file write committed), apply
   refuses with `409 plan_stale` before writing anything — the TOCTOU guard.
   Re-plan and retry.

`--server <url>` overrides the management API base URL (default `$TERA_SERVER`
or `http://127.0.0.1:8081`) for `plan`, `apply`, and `diff`. `validate` is
fully offline and takes no server.

## Ownership, pruning, and deletion

- An apply is **full desired-state within ownership scope**: objects absent
  from the pushed tree for an owned vault are **pruned** (deleted). Scope is the
  set of vaults in the desired push; deletion can never exceed it.
- Deleting an object that another vault depends on fails the apply and names the
  dependent (cross-vault delete protection).
- The plan's per-action **blast radius** tells you the runtime consequence
  before you apply: e.g. "bounces MQTT listener", "re-describes 3 bindings",
  "destroys vault subtree" on a delete. Read it.

## Objects the binary contributes (`origin: engine`)

Not everything the daemon runs comes from a `.tera/` file. The binary
**contributes** the objects whose meaning its own code defines (ADR-161 D13),
and registers each one on every boot and reload, with or without a system
vault. Each changes only when the binary does:

| Object | Key |
|---|---|
| the work-order type the MCP gateway files durable upstream calls under | `system/work-order-types/mcp-upstream-task` |
| the `tera-config` and `off-tera-work` skills | `system/skills/<name>` |
| the standard roles `admin`, `operator`, `developer`, `auditor`, `reader` | their names |
| the `repository` role, which a repository vault's binding names | `repository` |
| the `workbench-inbox` correspondence transport | `system/correspondence-transports/workbench-inbox` |
| the `default` worker, which owns a person's filing that names no worker | `default` |

- **You will not find their files.** No vault file defines them, and a file a
  vault holds at one of their paths (`.tera/roles/operator.hcl`,
  `.tera/skills/tera-config/`, `.tera/workers/default.hcl`, …) is never read.
  A `.tera/` tree is therefore not the whole set. The listings mark them
  `origin: engine`, and `configuration` for one a vault declares:
  `tera workorder types` (or `GET /api/v1/work-order-types`), the worker
  listing (`GET /api/v1/workers`), the skill tool's listing, and
  `tera config plan`.
- **Name them by key.** A `role_binding` names `operator` or `repository`
  exactly as before, and a type's `based_on` names
  `system/work-order-types/mcp-upstream-task`.
- **Do not write, edit or delete a copy.** A copy an older seed left in a
  vault is ignored with a boot warning when it is unedited and **refused** when
  it is edited, and `tera config apply` refuses a tree that adds or alters
  one, even byte-identical to a seed's. `tera vault seed-diff` lists such
  copies as `engine-owned` and `engine-owned-edited`; an operator deletes
  them, following `docs/ops/upgrade-to-engine-contributed-configuration.md`.
- **To get something different, add your own object beside it**, under your
  own name, in your own file:
  - **a role of your own, bound beside the standard one.** List both in the
    binding's `roles`. Deny-overrides holds across roles (ADR-010), so a
    `deny` in your role narrows `operator` exactly as editing `operator` would
    have, and a `grant` widens it;
  - **a skill of your own**, in `.tera/skills/<your-name>/`;
  - **a work-order type of your own**, written whole, or derived from the
    binary's with `based_on = "system/work-order-types/mcp-upstream-task"`,
    which resolves at `tera config validate`, `config plan` and the mount
    although no tree holds the base's file. Do not reuse its leaf: a second
    `mcp-upstream-task` makes the bare leaf ambiguous, and `tera config plan`
    warns (`type_leaf_ambiguous`) naming the binary's type `origin: engine`
    and yours as the one to rename;
  - **a worker of your own**, under any name but `default`, holding the
    connections and credentials `default` never holds. A file
    `.tera/workers/default.hcl` is refused.

## Authoring recipes

Recipe kinds are the `.tera/<kind>/<name>` files. The kinds with generated JSON
Schemas (validated by `tera config validate`) are:

`work-order-type`, `skill`, `subject-kind`, `tool`, `toolchain`, `trigger`,
`role`, `role-binding`.

One kind is missing from that list on purpose. `agent` is **deprecated**: the
daemon runs no model (ADR-136 D4), so do not author one. The kind itself still
loads, but new work that needs judgment is a capability or `select` work-order
type dispatching at a harness. A workflow `agent` step is **refused at load**
(ADR-136 D5 row 1): write a capability step instead — a workflow with no agent
step still loads. The migration pointer is the
section *Migrating off the agent shape* in
`examples/code-lifecycle-types/README.md`; ADR-136 D5 carries the per-door
dispositions.

For any kind, read `references/recipes/<kind>.md` for the full block/attribute
reference (every field, type, required flag, constraint, description) and
`references/recipes/<kind>.schema.json` for the JSON Schema you can validate
against. A running daemon serves the identical content at
`GET /api/v1/schemas/recipe/<kind>/reference` and
`GET /api/v1/schemas/recipe/<kind>/<version>`.

Config-kinds that are *not* recipe schemas — `llm`, `listeners`, `workers`,
`workflows`, MCP upstreams/exposures and the rest — are HCL blocks composed
onto the kernel; they decode to the daemon's HCL config types. They participate
in plan/apply the same way (as objects with their own kinds and blast radius).
They have no JSON Schema, because their authority is the runtime struct the
loader decodes into — but they *do* have a generated reference: read
`references/config/<kind>.md` (every attribute, type, required flag,
constraint), served live at `GET /api/v1/schemas/config/<kind>/reference`.
`references/README.md` lists all of them.

## What names an object, and how variants are written (ADR-087)

Two rules decide the shape of every file you write, and both are stated on
each kind's reference page rather than left to inference:

- **Identity** — the `Identity regime` row in the reference's metadata table
  says which name identifies an object of that kind: `recipe` (the filename
  stem, and a block label if written must equal it), `inventory` (the block
  label, with the file as a container), or `singleton` (the kind itself; no
  label). Read that row before naming a file. A recipe-kind file whose label
  disagrees with its stem is a hard error at load *and* at plan — never a
  silent rewrite.
- **Variants** — where a kind has variants with different fields, exactly one
  **variant-named nested block** is written, and the reference page's
  **"Exactly one of …"** line names the legal set. Where the variants differ
  only in behaviour, it is one enum attribute, spelled `type` unless the page
  shows `transport`, `mode` or `runtime`. `kind =` and `provider =` are
  retired as variant spellings; do not write either as a discriminator.

A union violation always reports in one sentence —
`exactly one of a | b required; found: …` — so a repair you have made once
transfers to every kind. In-repo readers: the full normative rules, including
the checklist for adding a new kind, are in
`docs/hcl-authoring-conventions.md`.

RBAC note: the standard roles are the binary's (`admin`/`operator`/
`developer`/`auditor`/`reader` for people, and `repository` for vaults; see
"Objects the binary contributes" above), and a `role` recipe you write is a
role of your own beside them; `role_binding` recipes (mapping your IdP
principals to roles) are deployment-specific and authored per-install. Adopting a repository vault is one system-vault binding,
`principals = ["vault:<alias>"]`, `roles = ["repository"]`: it may then
contribute work-order types, workflows, skills, inline skills, triggers and
toolchains, and nothing else. Exec, provision, `file as` and sharing
toolchains are separate grants you add to that binding.

## Onboarding a repository — `tera init`

You are very likely reading this *inside* a coding assistant, standing in a
repository somebody wants to run work in. That is the case `tera init` is built
for, and this skill is its substrate.

`tera init` reads a repository and proposes the configuration it needs:
`toolchain` definitions for the ecosystems the deployment does not already
declare, **their detection rules**, and a `work-order-type` to carry the
requirement. Detection rules cannot be the front door — real repositories
permute without bound — so a model proposes them and `tera init` evaluates
them. That is the split, and it is worth holding on to: **you author rules; you
do not decide what the repository needs.** Whether a rule fires is decided
locally, against the checkout, by the same evaluator `tera toolchain detect`
uses. A definition whose own rules do not match is written down anyway (the
next repository of that shape is then recognised offline and for no tokens) and
required by nothing.

You are the only agent in this: the daemon runs no model, and a plain
`tera init` resolves the repository against the deployment's existing rules
alone, pointing the operator at `--brief` for everything else. When you are
asked to author what nothing declares, it is these two invocations:

```
tera init <repo> --brief -                     # the question: read this
tera init <repo> --proposal ./proposal.json    # the answer: hand it back
```

The brief is self-contained — the instructions, the deployment's existing
toolchain declarations, and a bounded listing plus excerpts of the repository.
Read `references/recipes/toolchain.md` beside it for the full attribute
reference; the brief tells you the rules the decoder enforces, and that page
tells you everything else.

Three things about your answer:

- **It is JSON, one object, and its `hcl` fields are whole files.** The brief
  states the shape. Every definition is decoded by the loader the daemon uses
  before an operator ever sees it, so a file that would be refused at apply is
  refused at your desk instead.
- **You author data and install nothing.** A `provision` block runs on the
  operator's host and puts binaries in front of every dispatch, so it is shown
  to them by step count and destination, and `--allow-exec` still stands
  between it and any byte. Prefer a detection-only definition over inventing a
  download you are not sure of: rules with no provisioning still make the
  ecosystem visible, and a fabricated URL is a failed install somebody has to
  debug.
- **Propose nothing rather than guessing.** An empty `toolchains` list with a
  note saying the deployment already declares what this repository needs is a
  good answer.

**Native builds take `cc` beside the ecosystem toolchain.** A type whose work
compiles native code — cgo, `go test -race`, a Rust build script, a node-gyp
addon — lists `cc` beside the toolchain it builds for, each named as the
deployment declares it: `toolchains = ["plugin.go/toolchains/go",
"plugin.cc/toolchains/cc"]` where the deployment installed `builtin:go` and
`builtin:cc` (the repository then declares `.tera/builds-on/go.hcl` and
`.tera/builds-on/cc.hcl`), or the bare name where its system vault holds its
own definition. No language toolchain is seeded: a bare name resolves only to
the writing vault's or the system vault's own definition, never to a
plugin's. Do not author a `cc` definition, and propose it only for a
repository that compiles native code, and only by the name the brief's
existing declarations show, because the operator installs and provisions it
(`docs/ops/hermetic-c-toolchain.md`). It
is a compiler, not the build drivers: `make`, `cmake`, `pkg-config` and
`python3` for node-gyp stay the host's.

`tera init` then shows the operator a diff, plans it, applies it through the
same `config apply` above, and leaves the provisioning act separate. It never
writes on your say-so.

## Deployment manifests (ADR-066)

A manifest (`tera.hcl`) declares vault sources and how they compose into the
desired snapshot. Manifest-mode planning/applying resolves those sources first.
Pin remote sources to immutable revisions with a lockfile:

```
tera config lock -m tera.hcl              # resolve sources, write tera.hcl.lock
tera config lock -m tera.hcl --refresh    # re-fetch past the cache
tera config lock -m tera.hcl --from old.lock   # promote pins from an existing lock
```

On plan/apply/validate/diff in manifest mode, `--update-locks` re-resolves and
rewrites the lockfile first, and `--refresh` re-fetches remote sources past the
cache. The manifest + lockfile shapes are catalog entries in
`references/schema-registry.json` (`manifest/deployment`, `lockfile/deployment`)
with pointers to their Go source and ADR-066.

## Input variables (var.<name>)

Vaults may declare input variables (`variables.hcl`) resolved at load. This lets
one tree parameterize per-deployment values. The declaration shape is the
`variables/hcl` catalog entry in `references/schema-registry.json` (see
ADR-064 §6).

## Reading the plan JSON contract

`tera config plan --format json` emits a **machine-output plan contract**
(schema: `references/machine-output/plan.schema.json`, served at
`GET /api/v1/schemas/machine-output/plan/v1`). The human render and the JSON are
derived from the same value — a harness and a human see the same facts. Key
fields:

- `version` — plan contract version (currently `v1`).
- `scope` — vault IDs this plan owns; pruning/deletion are confined to these.
- `actions[]` — ordered transitions, dependency-first for create/update and
  dependents-first for delete. Each has:
  - `op` — `create` | `update` | `delete` | `build` | `upload`.
  - `vault`, `kind`, `name` — object identity (`<vault>/<kind>/<name>`).
  - `blast_radius[]` — human-readable runtime consequences of the action.
  - `depends_on[]` — canonical names this action must be ordered after.
- `summary` — per-op counts (`create`/`update`/`delete`/…) for the header line.
- `baseline[]` — per-vault git HEAD at plan time; apply refuses on drift.
- `source` — the embedded desired `.tera` trees, so a saved plan re-applies the
  exact reviewed tree without re-reading local files.
- `secrets` / `builds` — reserved slots (J5/J8), usually empty.

To drive apply programmatically: `plan --format json -out plan.json`, inspect
`summary`/`actions`, then `apply plan.json`. Never hand-edit a saved plan —
its `baseline` and embedded `source` must stay consistent; re-plan instead.

## Quick command reference

```
tera config plan     [--dir <path> --vault <id> | -m <file>] [--format text|json] [-out plan.json] [--diff] [--server <url>]
tera config apply    [plan.json | --dir <path> --vault <id> | -m <file>] [--json] [--server <url>]
tera config validate [--dir <path> --vault <id> | -m <file>] [--format text|json]     # offline
tera config diff     [--dir <path> --vault <id> | -m <file>] [--server <url>]
tera config lock     [-m <file>] [--refresh] [--from <lock>]
```

In manifest mode, `plan`/`apply`/`validate`/`diff` also accept `--update-locks`
and `--refresh`.

## Verifying an end-to-end change

A minimal loop to confirm a config change lands:

1. `tera config validate --dir ./myvault` → expect `composed tree valid`.
2. `tera config plan --dir ./myvault` → review the action set + blast radius.
3. `tera config apply --dir ./myvault` → review the applied/skipped/failed
   summary.
4. Re-run `tera config plan --dir ./myvault` → expect **no changes** (the tree
   now matches the daemon).
