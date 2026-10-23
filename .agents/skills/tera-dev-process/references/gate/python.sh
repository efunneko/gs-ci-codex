#!/bin/sh
# The gate for a Python project: the one command that decides whether a change
# may merge. Copy it to scripts/gate.sh; the profile's `## Gate` runs it as
# `sh scripts/gate.sh`, and CI runs the same line.
#
# It needs only the interpreter. It runs ruff and pytest when the project
# has them installed, and says so when it falls back.
#
# It stops at the first red, and says which step it was.
set -eu
cd "$(dirname "$0")/.."

step() { printf '== %s\n' "$*"; }
PY=${PYTHON:-python3}

# A repository with no Python code yet has nothing to check, and its gate is
# green: a new repository's first commit passes the gate it adopts. Once a
# .py file exists every step below runs.
if [ -z "$(find . \( -path ./.git -o -path ./.venv -o -path ./venv -o -path ./node_modules \) -prune -o -name '*.py' -print | head -n 1)" ]; then
	step "no .py file: nothing to check yet, gate green"
	exit 0
fi

# Every file must at least compile: the one check a bare interpreter can make.
step compile
"$PY" -m compileall -q -x '(^|/)(\.venv|venv|\.git|node_modules)/' .

step lint
if "$PY" -m ruff --version >/dev/null 2>&1; then
	"$PY" -m ruff check .
	"$PY" -m ruff format --check .
else
	echo "ruff is not installed: lint and formatting were NOT checked (add ruff to the project's dev dependencies)"
fi

step test
if "$PY" -c 'import pytest' >/dev/null 2>&1; then
	"$PY" -m pytest -q
else
	"$PY" -m unittest discover -s tests -t .
fi

step "gate green"
