---
name: requesting-code-review
description: Use to dispatch a fresh reviewer against a branch or a diff at any point - independent of the stage pipeline
---

# Requesting Code Review

**Announce:** "I'm using the requesting-code-review skill to get this reviewed."

Available at any point. Called automatically at the end of
`keel:subagent-driven-development` for the whole-branch review, and by a human
via `/keel:review`.

## Why A Fresh Agent

A reviewer that shares your context shares your blind spots. It has already
accepted every decision you made and will not question them. The value comes
entirely from the reviewer not having been there.

So: construct the package, dispatch a subagent, and send it nothing from this
conversation.

## The Review Package

Assemble and hand over:

- **The diff.** Full, against the base branch.
- **The intent.** `design.md` — what this was supposed to do. Without it a
  reviewer can only judge whether the code is nice, not whether it is right.
- **The surface.** `surface.md` — which apps and consumers are in play.
- **The constitution**, if the repo has one.
- **Test and check output** from verification, if it has run.

Not: the plan's step-by-step, the ledger's narration, or this conversation.
Those describe how it was built; the reviewer judges what was built.

## Dispatch

```
scripts/keel participants --at branch-review
```

Dispatch everything it lists, each with the same package and each on the model
in its row — the last column. By default that is keel's `code-reviewer` prompt
on `opus`, plus `invariant-reviewer` on `cross-app` and `boundary` changes
for the rubrics no command can decide. Pass the model explicitly; an omitted
one inherits yours and the entries stop meaning anything.

A repo can register more — a design-system reviewer, an accessibility auditor,
a language specialist — scoped so they run only when the change touches what
they care about. They are entries in the same registry as keel's own, which is
why adding one is a line of JSON and replacing one of keel's is deleting a
line. See `../using-keel/references/participants.md`.

Whatever their origin, every reviewer gets the artifacts and never the
conversation.

## Handling Findings

Findings are input, not verdicts. For each:

- **Fix it** — the default when it is right.
- **Rule against it** — the reviewer lacked context that the design or surface
  supplies. Record the ruling in the ledger with the reason. A reviewer being
  wrong is normal and does not mean the review was worthless.
- **Park it** — real, out of scope, recorded in the ledger and surfaced in the
  branch summary.

Never silently drop a finding. Every one gets one of these three, in writing.

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll review it myself, I know what to look for" | You accepted these decisions already. That is the problem. |
| "Give the reviewer the conversation for context" | That transfers your blind spots. Send the artifacts. |
| "The reviewer is wrong, ignore it" | Rule against it in writing. 'Ignore' is not one of the three. |
| "Findings can wait until after merge" | After merge nobody reads them. |
