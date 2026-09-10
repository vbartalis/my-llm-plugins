---
description: Report which keel stage the current work is in and what comes next
---

Report the state of keel work in this repo. Do not change anything.

1. Run `scripts/keel workspace current`.
2. If there is no workspace, say so — the next step is `/keel:orient`.
3. Otherwise report:
   - the workspace path, the change name, and the surface class
   - which artifacts exist (`surface.md`, `design.md`, `plan.md`, `ledger.md`)
   - from the ledger: tasks complete of total, open rulings, parked findings,
     and whether verification has run
   - the stage this puts the work in, and the command for the next stage
4. Run `scripts/keel check --changed` and report pass or fail counts by layer.

Keep it to a short report. No narration.
