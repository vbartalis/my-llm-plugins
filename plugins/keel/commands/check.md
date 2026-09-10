---
description: Run the repo's registered invariant checks
---

Run the invariant checks:

```
scripts/keel check $ARGUMENTS
```

Report failures grouped by layer, with the file and line from each check's
output.

For each failure there are exactly three outcomes — fix the code, fix the
check, or change the invariant. The third is the human's decision. There is no
"skip". If a failure cannot be resolved now, record it in the feature
workspace ledger as a parked finding with the reason.

If the request was to *add* a check rather than run one, invoke the
`keel:checking-invariants` skill instead.
