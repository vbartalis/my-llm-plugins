---
description: Run the repo's registered invariant checks
argument-hint: "[--id <id> | --task <n> | --changed | --layer <layer>]"
allowed-tools: Bash(scripts/keel check:*), Read, Glob, Grep
---

Run the invariant checks:

```
scripts/keel check $ARGUMENTS
```

Run it with the Bash tool rather than expecting the output to be here already.
This command takes arguments and the model can invoke it, so keel does not
interpolate those arguments into a shell string it runs unseen — the tool call
is visible, permission-gated, and the pre-approval above covers it.

Report failures grouped by layer, with the file and line from each check's
output.

For each failure there are exactly three outcomes — fix the code, fix the
check, or change the invariant. The third is the human's decision. There is no
"skip". If a failure cannot be resolved now, record it in the feature
workspace ledger as a parked finding with the reason.

If the request was to *add* a check rather than run one, invoke the
`keel:checking-invariants` skill instead.
