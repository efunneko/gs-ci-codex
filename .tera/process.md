# tally development process

This profile records the repository's existing process from CONTRIBUTING.md,
AGENTS.md, CLAUDE.md and .github/. Those documents remain the detailed references.

## Gate

```sh
make check
```

Run before opening a pull request and after changes before merging.
*Why:* the same command runs locally and in CI.

## Build and test

The Makefile runs `go vet ./...` and `go test ./...`. Build the command with
`go build ./cmd/tally`. Exported functions have table-driven tests beside them,
as required by CLAUDE.md.
*Why:* the standard Go tools verify this small module without dependencies.

## Branches and pull requests

Follow CONTRIBUTING.md: branch from `main` as `<type>/<short-description>` and
open one pull request per change. Use the existing PR template to explain what
changed, why, and how it was verified.
*Why:* each change has a focused review and verification record.

## Review and merge

A maintainer named in .github/CODEOWNERS approves every pull request. The
required `check` job must pass against an up-to-date branch. GitHub requires
one approving review and code-owner review, including for administrators.
Squash-merge, using the pull request title as the commit subject, per
CONTRIBUTING.md. Do not bypass review or branch protection.
*Why:* the existing review and CI requirements protect every change.

## CI

.github/workflows/ci.yml runs `make check` on pull requests and pushes to main,
using the Go version in go.mod. Preserve this gate and workflow.
*Why:* CI and local verification must agree.

## Naming

Pull request titles follow `<type>(<scope>): <change>` (Conventional Commits),
as specified in CONTRIBUTING.md. Give Work Orders descriptive action titles;
include a plan item identifier when work belongs to a plan.
*Why:* titles identify the change and connect planned work to its review.

## Documents

README.md describes usage; CONTRIBUTING.md describes contributions. Development
plans live in `docs/plans/`, with their purpose described in its README.md.
Change documents through pull requests like code.
*Why:* plans have a predictable location without duplicating existing guides.

## People

The code owner is @efunneko, as recorded in .github/CODEOWNERS. Maintainers
approve changes and decide process or design questions. Credential setup and
other actions requiring a person's account are performed by that person.
*Why:* decisions and account access have an identifiable owner.

## Rules

Follow AGENTS.md and CLAUDE.md: add no dependencies, prefer the standard library,
keep commits small, and provide table-driven tests for exported functions.
Keep credentials out of repository files and commits. Land changes through
reviewed pull requests rather than pushing directly to main.
*Why:* these preserve the module's simplicity and existing review process.
