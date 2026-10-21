# `make check` is the gate: CI runs it on every pull request, and it must pass
# before a change merges.
check:
	go vet ./...
	go test ./...

.PHONY: check
