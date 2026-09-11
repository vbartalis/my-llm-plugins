---
description: Report which keel stage the current work is in and what comes next
allowed-tools: Read, Glob
---

## Workspace

!`scripts/keel workspace current 2>&1 || true`

## Artifacts

!`ws="$(scripts/keel workspace current 2>/dev/null)" && ls -1 "$ws" 2>/dev/null || echo "none"`

## Checks against the change

!`scripts/keel check --changed 2>&1 || true`

## Setup

!`scripts/keel doctor 2>&1 | tail -6 || true`

---

Report the state of keel work in this repo from the above. Do not change
anything, and do not re-run those commands — their output is already here.

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
