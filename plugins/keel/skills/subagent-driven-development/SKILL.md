---
name: subagent-driven-development
description: Use to execute an approved plan in this session - dispatches a fresh implementer subagent per task with review after each, recording everything in the ledger
---

# Subagent-Driven Development

**Announce:** "I'm using the subagent-driven-development skill to execute this plan."

Fourth stage. You are the coordinator. You do not write the code.

For each task in the plan you dispatch a fresh implementer subagent, dispatch
a reviewer against what it produced, run the task's invariant checks, and
append the outcome to the ledger. Then the next task.

**Why fresh subagents.** Each implementer gets exactly the context you
construct for it and nothing else — no conversation history, no memory of
earlier tasks, no accumulated confusion. This is what stops context rot on a
long change. It also preserves your own context for coordination, which is
the only thing you are doing.

**Core loop:** fresh implementer → task review → checks → ledger → next task.

## Setup

1. Ensure an isolated workspace. Use a git worktree if the repo convention is
   worktrees; otherwise a branch. Never execute a plan on the main branch.
2. Read `plan.md`, `design.md`, and `surface.md` in full. You are the only
   participant who sees all three.
3. Read `ledger.md` if it exists — you may be resuming. The ledger is the
   memory; if it says task 4 completed, task 4 completed.
4. **Check the surface is still current:**

   ```
   scripts/keel stale
   ```

   A surface written days ago can be wrong by now. If a watched file has moved
   on the base branch, stop — the design was argued against a shape that no
   longer exists. Re-run `keel:orienting` against the current base and re-gate
   whatever the move invalidates. Building on a stale surface is how a change
   passes every local test and breaks at integration.
5. Pre-flight the plan: read it critically once. If a task is unimplementable
   in isolation, fix the plan now and say so. Fixing it later costs a wasted
   dispatch.
6. Create a todo per task.

## Per-Task Loop

### 1. Dispatch the implementer

Use `implementer-prompt.md`. Construct the brief yourself — the implementer
sees only what you put in it:

- The task, verbatim from the plan.
- The Global Constraints section, verbatim.
- The File Map rows for files this task touches.
- The Interfaces block: what it consumes, what it must produce.
- Nothing else. Not the design, not other tasks, not this conversation.

If the implementer asks a question, answer it from the design and surface.

### 2. Review the task

```
scripts/keel participants --at task-review
```

Dispatch every reviewer it lists, each with the same review package: the task
text, the diff, and the test output. Never this conversation — a reviewer that
shares your context has already accepted every decision you made.

By default this is keel's own `task-reviewer`, which judges two things — **spec
compliance** (does it do what the task said) and **code quality**. A repo may
register others; an external reviewer scoped to `apps/web/**` runs only on tasks
that touch it. See `../using-keel/references/participants.md`.

Findings from all reviewers merge into one list for the fix loop. Record which
participant raised each one.

### 3. Run the checks

Run the task's `**Checks:**` line, or the full check set if the plan names
none. See `keel:checking-invariants`. A failing check is a finding like any
other and enters the fix loop.

### 4. Fix loop

Findings go back for a fix round. Up to five rounds:

- Rounds 1–3: resume the same implementer with the findings.
- Rounds 4–5: dispatch a fresh implementer on a more capable model. Three
  failed rounds means the context is the problem.

After each fix round dispatch a **scoped re-review** with
`re-review-prompt.md` — it looks only at whether the named findings were
addressed, not for new ones.

At round 5, adjudicate every open finding yourself: fix it, rule on it, or
park it in the ledger with a reason.

### 5. Ledger and advance

Append the task completion to `ledger.md`. Mark the todo done. Next task.

## Continuous Execution

Do not pause between tasks to check in. Your partner asked you to execute the
plan; execute it. Progress summaries and "shall I continue?" prompts cost
their attention and buy nothing — the ledger is the progress report.

## Rulings, Not Stalls

A running plan does not wait on a human. Conflicts between the plan and
reality, ambiguities, plan defects, a limit you would have asked to exceed —
**decide them.**

Authority order: the constitution, then `surface.md`, then `design.md`, then
`plan.md`, then your judgment. The design is the binding intent; the plan is
its argument. Where the plan contradicts the design, the design wins and the
plan gets amended.

Record every decision in the ledger:

```
Ruling: <what you decided> — <why> — <what it costs if wrong>
```

A wrong ruling costs rework your partner can see and undo. A session parked on
a question costs their whole day and buys nothing.

## Four Things Stop You

Stop and ask only for:

1. An irreversible or destructive operation.
2. A security-sensitive action.
3. A side effect outside this workspace that norms say you ask about first — a
   merge, a push to a shared branch, a publish, a migration against real data.
4. A plan so broken that every path forward is a guess.

Nothing else. Not an ambiguity. Not a conflict. Not a failing check you know
how to fix.

## Boundary-Class Rules

When the surface class is `boundary`, two extra rules bind:

- **The shape task's review is not optional and not scoped down.** It is the
  task everything else is built on.
- **After the last consumer task, run the full check set**, not the scoped
  one. A shape change is only correct once every consumer agrees.

## On Finishing

When all tasks are complete:

1. Dispatch a broad whole-branch review with `keel:requesting-code-review`. It
   resolves `--at branch-review`, so any reviewer the repo registered there —
   a design system, an accessibility audit, a language specialist — runs
   alongside keel's own.
2. Findings from it get **one** fix dispatch and one scoped re-review.
   Adjudicate residuals into the ledger.
3. **Next stage:** invoke `keel:verification-before-completion`.

## Narration

Between tool calls, at most one short line. The ledger and the tool results
carry the record. Your partner is reading the ledger, not your commentary.

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll just write this task myself, it's small" | Then you carry its context into every later task. Dispatch. |
| "I'll give the implementer the design for background" | Background is how a focused agent becomes an unfocused one. Send the task. |
| "Let me check in on progress" | The ledger is the check-in. Keep going. |
| "This finding is minor, skip the re-review" | Scoped re-review is two minutes. Skipping it is how findings come back. |
| "The plan says X but Y is obviously right" | Then rule for Y, ledger it, and amend the plan. Do not do it silently. |
| "I'll ask about this ambiguity" | Rule on it. Only the four things stop you. |
| "The check fails but the code is fine" | Then the check is wrong and fixing the check is the task. Either way, ledger it. |
