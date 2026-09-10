---
name: writing-plans
description: Use when a design is approved and before any implementation begins
---

# Writing Plans

**Announce:** "I'm using the writing-plans skill to break this design into tasks."

Third stage. The design said what and why. The plan says **how, task by task**,
in enough detail that an implementer with zero conversation context can
execute one task and get it right.

That is not a figure of speech. In the next stage each task is handed to a
fresh subagent that has never seen this conversation, this design discussion,
or the other tasks. The plan is the entire world it gets. Write for that
reader.

<HARD-GATE>
Do not begin implementation until your human partner has approved the plan.
</HARD-GATE>

## Prerequisites

`design.md` exists and was approved. Read it and `surface.md` in full.

## Ceremony By Class

| Class | Plan form |
|-------|-----------|
| **local**, under ~3 tasks | Present the tasks in chat, get a nod. Record them in `plan.md` afterwards so the build stage has a file to read. |
| **local**, larger | Full `plan.md`. |
| **cross-app** | Full `plan.md`. Tasks tagged with the app they touch. |
| **boundary** | Full `plan.md`. Shape-defining task comes first and is its own task. Consumers updated in later tasks. Checks named per task. |

## The Process

### Step 1: Map the files

Before writing tasks, list every file that will be created or modified and
what each becomes responsible for. Decomposition is decided here; tasks just
carry it out.

- One clear responsibility per file. Files that change together live together.
- Split by responsibility, not by technical layer.
- In existing code, follow the established pattern. If a file you must touch
  has grown unwieldy, splitting it can be a task — but say so rather than
  doing it silently.

### Step 2: Order by dependency, shapes first

For **boundary** changes the order is not negotiable:

1. Define or change the shape. Alone, in its own task.
2. Update the authoritative producer.
3. Update each consumer.
4. Remove the old shape, if removal is in scope.

A task that changes a shape and a consumer together cannot be reviewed,
because a reviewer cannot tell whether the consumer was updated correctly or
the shape was bent to fit it.

### Step 3: Right-size the tasks

A task is the smallest unit that **carries its own test cycle and is worth a
fresh reviewer's judgment.**

- Fold setup, configuration, scaffolding, and docs into the task whose
  deliverable needs them. They are not tasks.
- Split where a reviewer could sensibly approve one task and reject its
  neighbour.
- Each task ends with something independently testable. If you cannot say how
  a task is verified, it is not a task.

Inside a task, steps are one action each and take a couple of minutes: write
the failing test, run it and watch it fail, implement, run it and watch it
pass, commit.

### Step 4: Write the interfaces

This is the part that makes isolated implementers work, and the part most
often skipped.

Every task states what it **consumes** from earlier tasks and what it
**produces** for later ones, with exact names and types. The implementer of
task 5 has never seen task 3. The only way it learns what task 3 named things
is this block.

### Step 5: Name the checks

Each task may carry a `**Checks:**` line listing invariant checks that must
pass before the task counts as done. See `keel:checking-invariants`.

Optional for `local`. Required for `boundary` tasks that touch a shape.

### Step 5b: Advisors

```
scripts/keel participants --at plan
```

Invoke any advisor listed before writing the tasks.

### Step 6: Write plan.md

Use `references/plan-template.md`. Copy global constraints verbatim from the
constitution and from `surface.md` — do not paraphrase. Every task implicitly
carries them, and an implementer reading a paraphrase will follow the
paraphrase.

### Step 7: Gate

Dispatch gate reviewers:

```
scripts/keel participants --at plan-gate
```

Verdicts are advisory — present them, your human partner decides.

Summarise: number of tasks, the ordering logic, reviewer findings, and anything
you are unsure about. Give the path. Ask for approval.

Then:

**Next stage:** invoke `keel:subagent-driven-development`. If subagents are
unavailable in this environment, invoke `keel:executing-plans` instead.

## Plan Quality

**Assume competence, not context.** The implementer is a good engineer who
knows nothing about this repo, this domain, or your toolchain, and has
questionable taste in tests. Give paths, commands, and exact expectations.

**Give the verification, not just the goal.** "Run `go test ./billing/...`,
expect `TestInvoiceMetadata` to fail with 'unknown field'" is usable. "Test
it" is not.

**Keep tasks independently commitable.** Each task ends in a commit that
leaves the repo working.

**DRY, YAGNI, TDD, frequent commits.** Plan for those; they are not the
implementer's judgment call.

## Red Flags

| Thought | Reality |
|---------|---------|
| "The implementer can figure out the naming" | It cannot. It has not seen the other tasks. Write the interfaces. |
| "This task is small, I'll fold it in" | Fold in setup. Never fold in a second reviewable deliverable. |
| "Shape and consumer in one task is faster" | It is unreviewable. Split it. |
| "I'll paraphrase the constraint" | Implementers follow what you wrote, not what it meant. |
| "Tests can come at the end" | A task without its own test cycle is not a task. |
| "The plan can stay loose, we'll adapt" | Adaptation during build happens in isolated contexts with no memory. The plan is the memory. |
