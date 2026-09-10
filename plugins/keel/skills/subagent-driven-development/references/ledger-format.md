# Ledger Format

`ledger.md` is the append-only record of the build. It is the only thing that
survives a compaction, a crash, or a new session, so it is written for a
reader who remembers nothing.

Append. Never rewrite. Never delete an entry, including entries about things
that later turned out to be wrong — a reversed decision is more useful than a
missing one.

## Format

```markdown
# Ledger: <change name>

**Plan:** ./plan.md
**Branch / worktree:** <name>
**Started:** YYYY-MM-DD

---

## Task 1: <name> — COMPLETE YYYY-MM-DD

**Commits:** `a1b2c3d`
**Implementer rounds:** 1
**Review:** approved
**Checks:** `contract-drift` pass, `lint` pass

**Produced:** <the exact interface names and signatures this task exported, so
later tasks and later sessions can find them without reading the diff>

**Notes:** <anything a future reader needs. Empty is fine.>

---

## Ruling YYYY-MM-DD — <one-line subject>

**Decision:** <what you decided>
**Why:** <the reason, referencing the authority: constitution, surface,
design, plan, or judgment>
**Cost if wrong:** <what has to be redone>
**Amended:** <which artifact you amended, or "none">

---

## Task 2: <name> — IN PROGRESS
...

---

## Return YYYY-MM-DD — to <stage>

**From:** <the stage you were in>
**Trigger:** <what forced it>
**Owns the defect:** <why this stage>
**Invalidates:** <artifacts or completed tasks now in doubt>
**Re-gated:** <what was approved again, or "the delta only">

---

## Parked findings

<Findings adjudicated open at round 5, with the reason they were parked and
what would have to be true to close them.>

---

## Verification YYYY-MM-DD

<Filled by keel:verification-before-completion. Evidence, not claims.>
```

## What goes in

- Every task completion, with the commit and the interfaces it produced.
- Every ruling.
- Every return — see `../../using-keel/references/return-paths.md`. A workspace
  that shows only forward motion is lying about how the change happened.
- Every check failure and what happened to it.
- Every parked finding, with the `id` of the participant that raised it.
- Amendments to `design.md` or `plan.md`, with the reason.

## What stays out

- Narration. "Now starting task 3" is not a ledger entry.
- Tool output. Reference the commit; do not paste the diff.
- Anything already in the plan. The ledger records deviation and outcome, not
  intent.
