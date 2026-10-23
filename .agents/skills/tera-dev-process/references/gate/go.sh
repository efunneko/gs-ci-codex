#!/bin/sh
# The gate for a Go module: the one command that decides whether a change may
# merge. Copy it to scripts/gate.sh; the profile's `## Gate` runs it as
# `sh scripts/gate.sh`, and CI runs the same line.
#
# It stops at the first red, and says which step it was.
set -eu
cd "$(dirname "$0")/.."

step() { printf '== %s\n' "$*"; }

# A repository with no Go code yet has nothing to check, and its gate is
# green: a new repository's first commit passes the gate it adopts. Once
# go.mod exists every step below runs. A .go file without a go.mod is red,
# because `go build` cannot build it.
if [ ! -f go.mod ]; then
	if [ -n "$(find . -path ./.git -prune -o -name '*.go' -print | head -n 1)" ]; then
		echo "there are .go files but no go.mod: run \`go mod init\` to make this a module"
		exit 1
	fi
	step "no go.mod and no .go file: nothing to check yet, gate green"
	exit 0
fi

# Formatting first: it is the cheapest check, and an unformatted tree makes
# every later diff noisier to review.
step gofmt
unformatted=$(gofmt -l .)
if [ -n "$unformatted" ]; then
	printf 'these files are not gofmt-formatted; run `gofmt -w` on them:\n%s\n' "$unformatted"
	exit 1
fi

step build
go build ./...

# vet compiles the test files too, so a change that breaks only a test file
# is caught here and not halfway through the test run.
step vet
go vet ./...

# -race costs time and finds the bugs no other check finds.
step test
go test -race -count=1 ./...

step "gate green"
