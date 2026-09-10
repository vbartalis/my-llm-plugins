# Extension Points

Keel is a spine. Everything that is not the six stages attaches through one of
the mechanisms below. If you are adding a layer, honour these rather than
inventing new ones.

There are only two, and both are repo-level JSON:

| Mechanism | File | For |
|-----------|------|-----|
| **Checks** | `.keel/checks/*.json` | Anything a command can decide |
| **Participants** | `.keel/participants.json` | Anything an agent or skill decides |

Everything else is reserved *content* inside artifacts, not a new mechanism.

## Checks

A rule with a command behind it, exiting non-zero when it does not hold. This
is how a rule stops being prose an agent can rationalise past. See
`../../checking-invariants/SKILL.md`.

Prefer this. It costs milliseconds, it is deterministic, and it runs after
every task without anyone remembering to ask for it.

## Participants

An advisor (a skill invoked *during* a stage), a reviewer (an agent dispatched
*after* work exists), or an implementer (the agent that executes one task),
attached at one of ten points, scoped by path and surface class, and dispatched
on the model its entry names. Keel's own reviewers and implementer are entries in
this registry — that uniformity is what makes an outside reviewer a one-line
addition and a keel reviewer a one-line deletion. See `participants.md`.

Use this when no command can decide the rule.

## Reserved artifact content

`orienting` writes a `## Contracts` section and an `## Interface Surfaces`
section into `surface.md`. They are filled in prose today, so the habit of
naming crossed boundaries starts now and the contracts layer has somewhere to
write generated blast-radius output without changing the artifact schema.

`plan.md` tasks may carry a `**Checks:**` line naming which invariants gate that
task. Optional today; mandatory for boundary-class tasks once contracts land.

## Planned layers

**Contracts.** One language-agnostic source of truth for data shapes crossing
app boundaries, codegen into TS/Go/Python, and a drift check that fails when an
app hand-rolls its own copy of a shared shape. Lands as checks plus the reserved
`surface.md` sections. Not designed — the problem needs to be understood against
the real monorepo first.

**Design system.** Tokens as source of truth, a closed primitive inventory, and
a check rejecting raw literals and shadow components in app code. Lands as
checks plus an advisor at `design` and a reviewer at `branch-review`. Being an
advisor is the important half: a design system that only reviews catches drift
after it exists.

## Rules for adding a layer

A layer may add: checks, participants, reserved artifact sections, and reference
files.

A layer may not add: **a stage**, **a gate**, **a way to pass a gate**, **a new
attachment point**, or **a second session-start injection**.

If a layer seems to need any of those, that is a defect in keel to be fixed in
the spine rather than worked around in the layer.
