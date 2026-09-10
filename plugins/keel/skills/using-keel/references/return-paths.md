# Return Paths

Work returns as often as it advances. The forward chain is documented in every
stage skill; this file is where it goes when it comes back.

The rule that makes returns cheap: **go to the stage that owns the defect, not
to the start.**

## The returns

| Trigger | Goes to | Because |
|---------|---------|---------|
| A gate says no | the same stage | The artifact is wrong, not the framing. Revise and re-present. |
| Design reveals a missed app or boundary | `orienting` | The surface was incomplete, so the design is being argued against the wrong map. |
| Planning reveals a hole in the design | `brainstorming` | A plan cannot decide behaviour the design never settled. |
| Build hits reality contradicting an approved artifact | amend it in place | Edit the artifact, state the delta, re-gate **only the delta**, continue. |
| A watched file changed on the base branch in a way the design rests on | `orienting` | The surface is stale: the design was argued against a shape that no longer exists. |
| Verification: wrong behaviour | `brainstorming` | A design defect. The code does what the plan said; the plan said the wrong thing. |
| Verification: missing work | `writing-plans` | A plan defect. The design covered it, no task implemented it. |
| Verification: broken implementation | the build loop | A build defect. Handled by the fix loop, not by a stage return. |
| A bug whose cause is unknown | find the cause first | A fix designed before the cause is known is a guess. Re-enter at `orienting` once you know. |

Stage 6 is the one place a return is not a loop. Not every branch lands, and
discarding is a legitimate outcome.

## Recording a return

<EXTREMELY-IMPORTANT>
Every return is written to `ledger.md` before you act on it.

A workspace that shows only forward motion is lying about how the change
happened. "We re-entered design on day three because verification found the
behaviour was wrong" is the single most useful thing a later reader can learn
from a feature workspace, and it is invisible unless you write it down.
</EXTREMELY-IMPORTANT>

```markdown
## Return YYYY-MM-DD — to <stage>

**From:** <the stage you were in>
**Trigger:** <what forced it, quoted where possible>
**Owns the defect:** <why this stage and not another>
**Invalidates:** <which artifacts or completed tasks are now in doubt>
**Re-gated:** <what your human partner had to approve again, or "the delta only">
```

## Amending versus returning

They are different and the difference matters.

**Amend** — the artifact was right about the shape of the problem and wrong in
a detail. Edit it, note the delta at the top of the amended section, re-gate
that one point, keep going. The plan survives.

**Return** — the artifact was wrong about something load-bearing. Go back to
the stage, redo the part that was wrong, re-gate it properly. Tasks built on
the wrong part are in doubt and must be named as such.

When you cannot tell which one applies, it is a return. An amendment that
should have been a return is how a plan quietly stops matching the code.

## What does not loop

Do not go back to the start. "Re-run the whole pipeline" throws away every gate
your human partner already passed and asks them to approve the same things
again, which teaches them that gates are noise.
