---
description: Report which keel stage the current work is in and what comes next
allowed-tools: Bash(scripts/keel check:*), Bash(scripts/keel doctor:*), Read, Glob
---

## Workspace

!`scripts/keel workspace current 2>&1 || true`

## Artifacts

!`ws="$(scripts/keel workspace current 2>/dev/null)" && ls -1 "$ws" 2>/dev/null || echo "none"`

---

The two blocks above are resolution — they read keel's own files and run nothing
the repo supplied.

**Now run these yourself, as tool calls:**

```
scripts/keel check --changed
scripts/keel doctor
```

They are separate calls on purpose. A check's `command` is shell this repo
supplied, and running it through command injection would execute every in-scope
check at expansion time — no tool call, no permission decision, nothing in the
transcript — from a command that says it changes nothing. Keel does not execute
repo-supplied content outside the tool layer. `scripts/keel check --list` names
what would run without running it.

Then report the state of keel work in this repo. Change nothing.

If there is no workspace, say so; the next step is `/keel:orient`.

Otherwise report:

- the workspace path, the change name, and the surface class
- which artifacts exist, and which are missing
- from `ledger.md`: tasks complete of total, open rulings, parked findings, and
  whether verification has run
- the stage this puts the work in, and the command for the next stage
- check results by layer, pass and fail counts
- whether the setup holds; if anything is broken or differs, say so in one line
  and point at `/keel:init`, which reconciles it

Read `ledger.md` for the middle bullet; the rest is above. Keep it to a short
report. No narration.
