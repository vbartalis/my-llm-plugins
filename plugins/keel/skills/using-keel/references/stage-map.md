# The Stage Map In Full

One page. If you can hold this, you can use keel.

## Why six stages and not four, or eighty-two

Each stage exists because skipping it has a distinct, observable failure mode.
A stage that cannot name its failure mode should be deleted.

| Stage | Exists to prevent |
|-------|-------------------|
| **orienting** | Designing against one app's worldview and silently breaking another. The monorepo failure. |
| **brainstorming** | Building the wrong thing correctly. |
| **writing-plans** | Context rot: a long change where the agent forgets its own earlier decisions. |
| **subagent-driven-development** | The same, plus unreviewed code accumulating faster than anyone can read it. |
| **verification-before-completion** | "Done" meaning "I wrote code", not "it works". |
| **finishing-a-development-branch** | Work that is complete but never lands, or lands unreviewed. |

## Stage inputs and outputs

```
orienting          in: a request                       out: surface.md
brainstorming      in: surface.md                      out: design.md
writing-plans      in: design.md + surface.md          out: plan.md
subagent-driven-   in: plan.md + design.md             out: commits + ledger.md
  development
verification       in: everything above                out: verification section in ledger.md
finishing          in: a verified branch               out: merge / PR
```

Every stage reads `docs/keel/constitution.md` if it exists. That file is repo
law and outranks anything a stage produces.

## Ceremony scaling

The gates never move. What moves is how much you write to pass them.

| Surface class (from orienting) | brainstorming | writing-plans |
|--------------------------------|---------------|---------------|
| **spike** | 2–3 sentences in chat | skipped — exits the pipeline |
| **local** (one app, existing flow) | short design in chat, recorded in design.md | plan in chat if under ~3 tasks, else plan.md |
| **cross-app** (two or more apps) | full design.md, always | full plan.md, always |
| **boundary** (changes a shape or protocol between apps) | full design.md + explicit blast radius | full plan.md + invariant checks named per task |

`boundary` is the class that will grow the most when the contracts layer
lands. Today it means "write the shape down and say who consumes it."

## Non-linear entries

Work returns as often as it advances. The full table of returns, what each one
means, and how to record it is in `return-paths.md`. The short version:

- A failed verification goes to the stage that **owns the defect**, not to the
  start. Wrong behaviour is a `brainstorming` defect; missing work is a
  `writing-plans` defect; a broken implementation stays in the build loop.
- A gate that says no returns to the same stage. Revise and re-present.
- Amending an approved artifact → edit it, state the delta out loud, re-gate
  only the delta. If what was wrong is load-bearing it is a return, not an
  amendment.
- A stale surface (`keel stale` fails) returns to `orienting`.
- Resuming a workspace after context loss → `/keel:status`, then read
  `ledger.md` in full before touching anything. The ledger is the memory.

Every return is written to the ledger before you act on it.
