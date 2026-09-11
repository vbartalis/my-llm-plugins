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

Plus three that are not part of the line: `/keel:status` (where am I),
`/keel:check` (run invariant checks), `/keel:review` (dispatch a reviewer).
And `/keel:init`, once per repo.

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

That last one is the load-bearing idea. Keel's position is that documentation
does not enforce anything, and a rule worth having is worth a check.

## Install

```
/plugin marketplace add <this repo>
/plugin install keel
```

A `SessionStart` hook injects exactly one skill — `using-keel`, the stage map.
Everything else loads on demand. One resident skill is the whole context cost,
and it costs nothing at all in a repo that does not use keel: the hook stays
quiet until `/keel:init` has run, so installing the plugin does not announce
itself in every project on the machine.

## Set up a repo

```
/keel:init
```

Run it again whenever you like. There is no separate upgrade: on a fresh repo it
sets keel up, on one that has had keel for a year it reconciles what drifted.
`scripts/keel doctor` reports the state first, and `/keel:init` walks the
differences with you.

Keel records no version and keeps no history of its own changes. It cannot tell
your deliberate edit from its own drift, so it never guesses — it reports what
is broken today, reports where you differ from what it currently ships, and
leaves the judgment to you. Feature workspaces it will not touch at all: those
artifacts passed a gate.

That installs `scripts/keel` (a wrapper that finds the plugin at runtime),
creates `docs/keel/` and `.keel/checks/`, and walks you through a constitution.

The constitution is your repo's non-negotiables — version floors, dependency
policy, boundary rules. Every stage reads it and treats it as outranking its
own output. Keep it under two pages; longer and nobody reads it, and it stops
working. A template lives in `templates/constitution.md`.

`/keel:init` also installs `link-integrity`, the one check keel ships: it fails
when a relative link in any tracked markdown file points at something that no
longer exists. Add your own next — start with the linters and formatters you
already run, since wrapping an existing command is a legitimate check and takes
a minute. See `skills/checking-invariants/`.

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

Three kinds. An **advisor** is a skill invoked *during* a stage — it shapes the
work. A **reviewer** is an agent dispatched *after* work exists — it produces
findings. You want both: a design system that only reviews catches drift after
it already exists. An **implementer** is the agent that executes one task.

Ten attachment points, scoped by path and surface class so a Go-only change
never pays for a UI reviewer. Keel's own reviewers and its implementer are
entries in the same registry, so adding one is a line and replacing one of
keel's is deleting a line. A repo with no file yet gets that same registry from
inside the plugin — review is never silently off — and `[]` is how you turn
everything off deliberately.

Path scoping spans commits, not just the working tree. A task ends by
committing, so comparing against uncommitted work alone would skip every scoped
reviewer at exactly the moment review runs.

Every entry names the **model** it runs on — `opus`, `sonnet`, `haiku`,
`fable`, or `inherit` — so what keel spends is decided in one file rather than
per dispatch. Your own session is untouched: it runs on the model you picked,
and the registry governs only what keel dispatches.

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
| [../../CLAUDE.md](../../CLAUDE.md) | agents | You are changing keel itself. Lives at the repo root, because a `CLAUDE.md` inside a plugin is not loaded for anyone who installs it. |
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
scripts/keel     workspace, check and participant runner
templates/       what /keel:init copies into a repo, including checks/
tests/           the runner's test suite — bash, no framework
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
of the work, not how you write a for-loop. Plugins covering those compose with
keel cleanly, because keel claims exactly one layer and says so.

A plugin that claims the **same** layer is a different matter, and `superpowers`
is one: keel's stages are versions of its ideas, and seven skill names overlap.
Both can be installed — skills are namespaced, so `keel:brainstorming` and
`superpowers:brainstorming` coexist — and inside a keel repo the `keel:` one
wins, because it is the stage that writes the artifact and names the successor.
`using-keel` states that rule where an agent will actually read it. Superpowers'
non-overlapping skills stay useful throughout; keel does not replace them.
