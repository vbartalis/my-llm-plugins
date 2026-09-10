# keel

The process spine for a polyglot monorepo. Claude Code only — no other harness
is supported and none is planned.

## The whole system, on one page

Six stages. Each produces a file. Each ends by naming the next.

```
/keel:orient   →  surface.md   what are we touching?      [gate]
/keel:design   →  design.md    why, and what behaviour     [gate]
/keel:plan     →  plan.md      how, task by task           [gate]
/keel:build    →  ledger.md    fresh subagent per task     — runs to completion
/keel:verify   →  evidence     prove it works              [gate]
/keel:ship     →  PR / merge   land it                     [gate]
```

Plus four that are not part of the line: `/keel:status` (where am I),
`/keel:check` (run invariant checks), `/keel:stale` (has the ground moved),
`/keel:review` (dispatch a reviewer). And `/keel:init`, once per repo.

Work returns as often as it advances. A gate that says no sends you back into
the same stage; a failed verification sends you to whichever stage **owns the
defect** — design for wrong behaviour, plan for missing work, the build loop for
a broken implementation. Every return is recorded. See
`skills/using-keel/references/return-paths.md`.

That is the entire surface. If you have read this far you can use it.

## What it is for

This exists because a monorepo with several apps in several languages fails in
ways a single app does not:

- A change designed inside one app's worldview silently breaks a shape another
  app depends on. → **`orient` runs first**, and its whole job is to name every
  app and boundary the change touches before anyone designs anything.
- A long change loses coherence as the context window fills. → **`build`
  dispatches a fresh subagent per task**, each seeing only its own task brief.
  Nothing accumulates.
- A rule written in a document gets ignored the moment it is inconvenient. →
  **invariants are commands that exit non-zero**, not prose.

- A surface written days ago can be wrong by the time you build on it. →
  **`keel stale`** fails when a file the surface depends on has moved on the
  base branch, so a design is never built against a shape that no longer exists.

That last but one is the load-bearing idea. Keel's position is that
documentation does not enforce anything, and a rule worth having is worth a
check.

## Install

```
/plugin marketplace add <this repo>
/plugin install keel
```

A `SessionStart` hook injects exactly one skill — `using-keel`, the stage map.
Everything else loads on demand. One resident skill is the whole context cost.

## Set up a repo

```
/keel:init
```

That installs `scripts/keel` (a wrapper that finds the plugin at runtime),
creates `docs/keel/` and `.keel/checks/`, and walks you through a constitution.

The constitution is your repo's non-negotiables — version floors, dependency
policy, boundary rules. Every stage reads it and treats it as outranking its
own output. Keep it under two pages; longer and nobody reads it, and it stops
working. A template lives in `templates/constitution.md`.

Then register checks in `.keel/checks/`. Start with the linters and formatters
you already run — wrapping an existing command is a legitimate check and it
takes a minute. See `skills/checking-invariants/`.

## Bringing in things keel does not own

A repo declares who else takes part, in `.keel/participants.json`:

```jsonc
[
  { "id": "ux-review", "kind": "reviewer", "agent": "design-system:ux-reviewer",
    "at": "branch-review", "when": { "paths": ["apps/web/**"] }, "blocking": true },

  { "id": "component-guidance", "kind": "advisor", "skill": "design-system:designing-a-component",
    "at": "design", "when": { "paths": ["apps/web/**"] } }
]
```

Two kinds. An **advisor** is a skill invoked *during* a stage — it shapes the
work. A **reviewer** is an agent dispatched *after* work exists — it produces
findings. You want both: a design system that only reviews catches drift after
it already exists.

Nine attachment points, scoped by path and surface class so a Go-only change
never pays for a UI reviewer. Keel's own reviewers are entries in the same
registry, so adding one is a line and replacing one of keel's is deleting a
line.

One rule holds it together: **agents inform gates, humans decide gates.** At any
gate, `blocking` is ignored and the verdict is presented to you instead — the
runner enforces this, not convention. Nothing but a human passes a keel gate,
because anything with a veto sits above you in practice.

Full schema: `skills/using-keel/references/participants.md`.

## Documentation

| | For | Read when |
|---|---|---|
| [docs/walkthrough.md](docs/walkthrough.md) | humans | First. One boundary change through all six stages, with the artifacts it produces. |
| [docs/glossary.md](docs/glossary.md) | humans + agents | You hit a word keel invented — surface, class, ruling, return, advisor. |
| [docs/troubleshooting.md](docs/troubleshooting.md) | humans | Something errored, or a stage behaved unexpectedly. |
| [CLAUDE.md](CLAUDE.md) | agents | You are changing keel itself. |
| `skills/using-keel/references/` | agents | The stage map, artifacts, participants, return paths, extension points. Loaded on demand. |

The skills are the agent-facing documentation and are read at runtime; the
`docs/` directory is for people. `/keel:init` also installs a keel section into
the target repo's own `CLAUDE.md`, so the repo declares its process rather than
relying on the plugin being installed.

## Layout

```
skills/          one per stage, plus using-keel and checking-invariants
agents/          implementer, task-reviewer, invariant-reviewer
commands/        thin entry points; the substance is in the skills
scripts/keel     workspace, check, stale and participant runner
templates/       what /keel:init copies into a repo
docs/            human-facing: walkthrough, glossary, troubleshooting
```

Artifacts land in your repo, not here:

```
docs/keel/constitution.md
docs/keel/features/YYYY-MM-DD-<slug>/{surface,design,plan,ledger}.md
.keel/checks/*.json          invariants a command can decide
.keel/participants.json      advisors and reviewers, keel's own included
scripts/keel                 wrapper, installed by /keel:init
```

They are committed. They are the record of why the code looks the way it does.

## Ceremony scales, gates do not

`orient` classifies every change as `spike`, `local`, `cross-app`, or
`boundary`, and that class decides how much you write at each later stage. A
one-file fix gets three sentences and a nod. A change to a shape two apps share
gets the full treatment.

What never scales down is the gates. You do not skip approval because the
change looks small — small changes crossing boundaries are the expensive kind.

## Reserved

Two layers are designed for and deliberately not built. Both land as checks and
participants rather than as new stages:

- **contracts** — one source of truth for data shapes crossing app boundaries,
  codegen into TS/Go/Python, drift detection.
- **design system** — tokens, a closed primitive inventory, and a check that
  rejects raw literals and shadow components.

See `skills/using-keel/references/extension-points.md`. No layer may add a
stage, a gate, a way to pass a gate, or a new attachment point. If one seems to
need any of those, that is a defect in keel to be fixed in the spine.

## What keel does not own

Tactics — debugging technique, test design, language idiom. Keel owns the shape
of the work, not how you write a for-loop. Other plugins covering those are
compatible by construction, because keel claims exactly one layer and says so.
