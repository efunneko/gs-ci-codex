#!/bin/sh
# The gate for a Node project: the one command that decides whether a change
# may merge. Copy it to scripts/gate.sh; the profile's `## Gate` runs it as
# `sh scripts/gate.sh`, and CI runs the same line.
#
# The project's own package.json scripts say how it lints, builds and tests.
# The gate runs them in that order, so the gate and `npm test` cannot drift
# apart. A missing `lint` or `build` script is skipped and named. `test` is
# required.
#
# It stops at the first red, and says which step it was.
set -eu
cd "$(dirname "$0")/.."

step() { printf '== %s\n' "$*"; }

# A repository with no package.json yet has nothing to check, and its gate is
# green: a new repository's first commit passes the gate it adopts. Once
# package.json exists every step below runs, and `test` is required.
if [ ! -f package.json ]; then
	step "no package.json: nothing to check yet, gate green"
	exit 0
fi

has_script() {
	node -e 'const s=(require("./package.json").scripts||{}); process.exit(s[process.argv[1]] ? 0 : 1)' "$1"
}

# A clean install from the lockfile, so the gate tests the dependencies the
# lockfile pins rather than whatever is already in node_modules.
step install
if [ -f package-lock.json ]; then
	npm ci
else
	echo "no package-lock.json: installing with npm install, which pins nothing (commit a lockfile)"
	npm install
fi

for s in lint build; do
	step "$s"
	if has_script "$s"; then
		npm run "$s"
	else
		echo "package.json has no \"$s\" script: $s was NOT run"
	fi
done

step test
npm test

step "gate green"
