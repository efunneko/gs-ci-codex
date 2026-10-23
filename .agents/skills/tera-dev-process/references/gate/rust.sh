#!/bin/sh
# The gate for a Rust crate or workspace: the one command that decides whether
# a change may merge. Copy it to scripts/gate.sh; the profile's `## Gate` runs
# it as `sh scripts/gate.sh`, and CI runs the same line.
#
# It stops at the first red, and says which step it was.
set -eu
cd "$(dirname "$0")/.."

step() { printf '== %s\n' "$*"; }

# A repository with no Rust code yet has nothing to check, and its gate is
# green: a new repository's first commit passes the gate it adopts. Once
# Cargo.toml exists every step below runs. A .rs file without a Cargo.toml is
# red, because cargo cannot build it.
if [ ! -f Cargo.toml ]; then
	if [ -n "$(find . -path ./.git -prune -o -name '*.rs' -print | head -n 1)" ]; then
		echo "there are .rs files but no Cargo.toml: run \`cargo init\` to make this a crate"
		exit 1
	fi
	step "no Cargo.toml and no .rs file: nothing to check yet, gate green"
	exit 0
fi

# rustfmt and clippy are rustup components a bare toolchain may not carry.
# Where one is missing the step says so on its own line rather than passing
# in silence; install the component to make the step count.
step rustfmt
if cargo fmt --version >/dev/null 2>&1; then
	cargo fmt --all -- --check
else
	echo "rustfmt is not installed: formatting was NOT checked (rustup component add rustfmt)"
fi

step build
cargo build --workspace --all-targets

step clippy
if cargo clippy --version >/dev/null 2>&1; then
	cargo clippy --workspace --all-targets -- -D warnings
else
	echo "clippy is not installed: lints were NOT checked (rustup component add clippy)"
fi

step test
cargo test --workspace

step "gate green"
