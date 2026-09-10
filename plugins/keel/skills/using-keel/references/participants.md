# Participants

How something keel does not own takes part in a keel stage.

Keel's own reviewers and its implementer are entries in this registry like
anything else. That is the point: adding an outside reviewer is one line, and
replacing one of keel's is deleting a line. There is no separate mechanism for
"built in", and no dispatch keel makes is invisible to this file.

## The registry

`.keel/participants.json` — a JSON array.

```json
[
  {
    "id": "ux-review",
    "kind": "reviewer",
    "agent": "design-system:ux-reviewer",
    "at": "branch-review",
    "when": { "paths": ["apps/web/**"] },
    "blocking": true,
    "brief": "artifacts"
  },
  {
    "id": "component-guidance",
    "kind": "advisor",
    "skill": "design-system:designing-a-component",
    "at": "design",
    "when": { "paths": ["apps/web/**"] }
  },
  {
    "id": "keel-implementer",
    "kind": "implementer",
    "agent": "keel:implementer",
    "at": "build",
    "model": "sonnet"
  }
]
```

| Field | Meaning |
|-------|---------|
| `id` | Stable. Referenced in the ledger when its findings are recorded. |
| `kind` | `advisor`, `reviewer`, or `implementer`. See below. |
| `agent` / `skill` / `prompt` | Exactly one. What to dispatch or invoke. |
| `at` | The attachment point. |
| `when.paths` | Globs. Absent means always. |
| `when.class` | Surface classes this applies to. Absent means all. |
| `blocking` | `true` means findings must be resolved. Ignored at gates. |
| `brief` | `artifacts`, `diff`, or `both`. What the participant is given. |
| `model` | What to dispatch on. Absent means `sonnet`. See below. |

## The registry keel ships

A repo with no `.keel/participants.json` gets the one bundled with the plugin —
keel's own implementer and reviewers, the defaults every stage skill names. That
is what makes those promises true before `/keel:init` has run.

`/keel:init` copies it into the repo, and from then on the repo's file is the
whole registry: keel adds nothing behind it. Turn a participant off by deleting
its entry, and turn every one off with an empty array `[]`. Both are things the
file says, which is the point — no dispatch keel makes is invisible to it.

## Naming a target

`agent` names a subagent the harness can dispatch. Plugin agents are scoped:
`keel:implementer`, `design-system:ux-reviewer`.

`skill` names a skill to invoke, scoped the same way:
`design-system:designing-a-component`.

`prompt` names a file to read and send. The runner resolves it to a path you can
open and prints that path in the row:

| Written as | Resolves to |
|---|---|
| `keel:skills/…/code-reviewer.md` | that file inside the installed keel plugin |
| `other-plugin:prompts/x.md` | that file inside that installed plugin |
| `.keel/prompts/mine.md` | that file in this repo |
| `/abs/path.md` | itself |

A prompt the runner cannot locate is printed as written, with a line on stderr
naming it — usually the plugin that provides it is not installed.

## When a participant is not installed

Say so and carry on. A registry entry is a repo's statement of intent, and an
entry naming an agent or skill this machine does not have is a setup gap, not a
reason to stop the stage. Note it in the ledger with the participant `id` so the
gap is visible, and continue — a stage that halts because someone else's plugin
is missing punishes the wrong person.

## Three kinds

**Advisor** — a skill invoked *during* a stage, while the artifact is being
written. It shapes the work. It has no veto. Use this when an outside plugin
should influence how something is designed rather than judge it afterwards.

**Reviewer** — an agent or prompt dispatched *after* work exists. It produces
findings. At `task-review`, `branch-review` and `verify` a blocking reviewer's
findings go through the fix loop like any other finding.

**Implementer** — the agent dispatched at `build` to execute one task. Exactly
one may match a given task; the runner exits 2 rather than choose between two,
because picking either silently would build the task on a model the repo did
not choose. Scope alternatives by `when.class`, not by path — `build` resolves
before the task has written anything.

Review-only extension catches drift late. If a design-system plugin has an
opinion about how a component should be built, it belongs at `design` as an
advisor, not only at `branch-review` as a reviewer.

## Attachment points

| Point | When | Paths scoped against |
|-------|------|----------------------|
| `orient` | while mapping the surface | nothing yet |
| `surface-gate` | before the human approves the surface | nothing yet |
| `design` | while writing design.md | the `## Watch` block |
| `design-gate` | before the human approves the design | the `## Watch` block |
| `plan` | while writing plan.md | the `## Watch` block |
| `plan-gate` | before the human approves the plan | the `## Watch` block |
| `build` | dispatching the implementer for one task | nothing — class only |
| `task-review` | after each task's implementer reports | the working diff |
| `branch-review` | the whole-branch review | the working diff |
| `verify` | during verification | the working diff |

Before a build there is no diff, so pre-build points scope against what the
change *will* touch — the `## Watch` block of `surface.md`. After a build they
scope against what it *did*.

"What it did" is the working tree **plus every commit since the base ref**. That
matters because a task's last step is a commit: scoping against the working tree
alone would go empty the moment a task finished, and skip every path-scoped
participant on exactly the work it was registered for. The base is `--base`, or
the branch's upstream, or the remote's default branch — no branch name is
hardwired, and when none resolves the runner says so and uses the working tree.

`build` scopes against neither. It resolves once per task, before that task has
written anything, and the runner does not know which files the task names — so
path globs on an implementer entry would silently never match. Use
`when.class`.

## Model

`model` is what to dispatch the participant on: `opus`, `sonnet`, `haiku`,
`fable`, or `inherit` for the session's own. Omitted means `sonnet`.

Those five pass silently. Anything else passes too — a specific model id, or one
released after this version of keel — and the runner says so on stderr as it
resolves. So a typo still surfaces in the same place a rejection would have, and
naming a model keel has not heard of does not mean waiting for a keel release.

`sonnet` is the floor, not `haiku`. Cost tracks turns, not tokens per turn, and
the cheapest model routinely takes two to three times the turns on multi-step
work — a saving on paper that is a loss on the clock. Drop to `haiku` when the
work is transcription: the task's plan text already contains the code.

**Pass it explicitly when dispatching.** An omitted model inherits the
coordinator's, which is usually the most capable and most expensive one in the
session — and every entry in this file becomes decoration.

The main conversation is not covered by any of this. It runs on the model your
human partner chose, and no entry here changes that.

<HARD-RULE>
Agents inform gates. Humans decide gates.

At any `*-gate` point, `blocking` is ignored and the verdict is presented to
your human partner as part of what they read before approving. Nothing but a
human passes a keel gate.

This is enforced by the runner, not by convention: `keel participants` reports
every gate participant as advisory regardless of what its entry says.
</HARD-RULE>

The reason is authority. The constitution is repo law and your human partner is
the decider. Anything with a veto over a gate sits above them in practice,
because they have to argue past it to proceed — and a false positive from a
plugin nobody here wrote would stall the pipeline with no clean recovery.

## Resolving

```
scripts/keel participants --at design-gate
scripts/keel participants --at branch-review
scripts/keel participants --at build --class boundary
scripts/keel participants --at plan --class boundary
scripts/keel participants --at branch-review --all   # ignore path scoping
```

Output is one row per participant: `id`, `kind`, target type, target,
`blocking`, `brief`, `model`. The runner decides *who* takes part and *on what*.
The stage skill does the dispatching — that split is why adding a participant
never requires changing the runner.

An entry the runner cannot make sense of is reported to stderr and skipped, not
guessed at: an unknown `kind` or `model`, or a `model` on an advisor. An advisor
is a skill invoked in your own context — there is no subagent to give a model
to, so an entry that sets one has misunderstood what an advisor is, and its row
carries `-` in that column.

## Briefing a participant

<EXTREMELY-IMPORTANT>
An external reviewer gets the same package discipline as an internal one: the
artifacts, the diff, and nothing from this conversation.

A reviewer that inherits your context has already accepted every decision you
made, and reviews the code instead of the decision. That inversion is the
entire reason review works here. It does not stop applying because the agent
came from another plugin.
</EXTREMELY-IMPORTANT>

By `brief`:

- `artifacts` — `design.md`, `surface.md`, the constitution.
- `diff` — the diff against the base branch, plus test and check output.
- `both` — all of it.

## What a participant may not do

- **Replace a stage.** Add advisors to `writing-plans` freely; a plugin that
  wants to *be* the planner should not be used with keel. Registering an
  implementer replaces the *worker* inside `build`, not the stage: the brief,
  the review that follows, and the ledger entry are unchanged.
- **Pass a gate.** See the hard rule.
- **Add an attachment point.** The ten above are the contract. If a layer
  seems to need an eleventh, that is a defect in keel to fix in the spine.
- **Receive the conversation.** See above.

## Handling findings

Findings from an external reviewer are handled exactly like internal ones —
fix, rule against with a written reason, or park in the ledger. Never silently
dropped. Record the participant `id` alongside the finding so a later reader
knows which reviewer raised it.
