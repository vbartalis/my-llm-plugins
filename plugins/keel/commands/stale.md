---
description: Check whether anything this change's surface depends on has moved
---

Run the staleness check for the current feature workspace:

```
scripts/keel stale $ARGUMENTS
```

It compares `surface.md`'s `**Base:**` commit against the base branch and fails
if any file in the `## Watch` block has moved since.

If it fails, the design was argued against a shape that no longer exists.
Do not build on it. Re-run `keel:orienting` against the current base, reconcile
`surface.md`, and re-gate whatever the move invalidated — then record the return
in the ledger — see the `keel:using-keel` skill, `return-paths` reference.

If `surface.md` has no `**Base:**` line or an empty `## Watch` block, that
surface predates staleness checking. Say so and offer to fill both in.
