# What a dependency gate does once the Work Order is filed

The filing side of `depends_on` is in the skill body. This is the supervising
side: what the gate reports while it holds, which detail clears on its own and
which one means somebody has to repair the upstream.

It releases itself when they **complete** — nothing polls it forward and
nobody needs to unblock it by hand. Terminating is not the same as
completing, though: a dep that ends `failed` or `cancelled` does not
release its dependent, which stays in `blocked:waiting-on-deps` with the
same `kind: "deps"` reason and a different detail —

```json
"block_reason": { "kind": "deps",
                  "detail": { "failed_deps": [ { "id": "019fc9ec-…", "state": "failed" } ] } }
```

— so when supervising a train, read the detail rather than the state.
`pending` is every dep still outstanding and narrows as they complete, so
it clears on its own; `failed_deps` (or `unknown_deps`, a dep that no
longer exists) does not, and means this one is parked until someone
repairs the upstream. Note that `pending` is not by itself evidence of
progress — a dep sitting in `paused:awaiting-input` is pending too.
