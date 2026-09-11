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

Keel keeps no version and no record of what changed between its releases, so
there is no migration mechanism either — and a layer must not add one. When the
plugin moves on, `keel doctor` reports what is broken today and where a repo
differs from what keel currently ships, and a human decides. See
`../../../docs/troubleshooting.md`.

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

## Considered and not built

Keel's own brainstorming skill says the most valuable line in a design is often
"we considered X and did not do it because Y". These are keel's.

**A `debug` attachment point.** Proposed so a polyglot repo could register a
debugging skill per app. It cannot be scoped: an unknown-cause bug arrives
*before* orienting, so there is no workspace, no surface class, and — the tree
being clean and the fault being in committed code — no diff either. Every
path-scoped entry would therefore fail to match, which means `when.paths` on a
debug entry is a field that can never be true. It would also be the eleventh
point, against the contract two files above.

**`fallback: true` on a participant** — an entry resolving only when no other
entry matched. Wanted for the same case: keel's own debugging skill for the apps
a repo has not covered. Two reasons it is wrong. It *infers* "nobody covered
this" from a scoping result, and per the point above that result under-matches,
so the fallback would over-fire and displace the repo's real skill in exactly
the apps that had one — silently. And the registry is a single file the repo
owns outright, so precedence between entries in it is already expressible by
editing it; a fallback field only pays off where entries arrive from two sources
that cannot see each other, which is a composition model keel does not have.

Both remain purely additive. Neither needs anything reserved for it now, and the
honest trigger for reconsidering either is a real caller that is not prose.

**A debugging skill of keel's own.** Held, not refused. The bug-routing bullet in
`using-keel` now carries the minimum itself, which is strictly more reliable: a
separate skill must be *invoked*, and the thing that would invoke it is the same
prose that was failing. Promote it to a skill if the resident lines prove too
thin — that is extraction, not rework.

**A TDD skill.** Not needed, and the reason generalises: **keel ships a tactic
only where no artifact records the decision and no participant or check can
catch its absence.** TDD has both — the plan template's task steps are the
red-green cycle, and the task-reviewer treats a missing verification step as
blocking. Debugging had neither, which is why its minimum is written down. Test
*design* stays out: it is language-specific, and the reviewer already asks
whether a test would fail if the implementation were wrong.

## Rules for adding a layer

A layer may add: checks, participants, reserved artifact sections, and reference
files.

A layer may not add: **a stage**, **a gate**, **a way to pass a gate**, **a new
attachment point**, or **a second session-start injection**.

If a layer seems to need any of those, that is a defect in keel to be fixed in
the spine rather than worked around in the layer.
