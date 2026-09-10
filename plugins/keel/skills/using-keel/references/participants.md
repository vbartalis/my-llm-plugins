# Participants

How something keel does not own takes part in a keel stage.

Keel's own reviewers are entries in this registry like anything else. That is
the point: adding an outside reviewer is one line, and replacing one of keel's
is deleting a line. There is no separate mechanism for "built in".

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
  }
]
```

| Field | Meaning |
|-------|---------|
| `id` | Stable. Referenced in the ledger when its findings are recorded. |
| `kind` | `advisor` or `reviewer`. See below. |
| `agent` / `skill` / `prompt` | Exactly one. What to dispatch or invoke. |
| `at` | The attachment point. |
| `when.paths` | Globs. Absent means always. |
| `when.class` | Surface classes this applies to. Absent means all. |
| `blocking` | `true` means findings must be resolved. Ignored at gates. |
| `brief` | `artifacts`, `diff`, or `both`. What the participant is given. |

`prompt` values starting `keel:` are relative to the plugin root.

## Two kinds

**Advisor** — a skill invoked *during* a stage, while the artifact is being
written. It shapes the work. It has no veto. Use this when an outside plugin
should influence how something is designed rather than judge it afterwards.

**Reviewer** — an agent or prompt dispatched *after* work exists. It produces
findings. At `task-review`, `branch-review` and `verify` a blocking reviewer's
findings go through the fix loop like any other finding.

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
| `task-review` | after each task's implementer reports | the working diff |
| `branch-review` | the whole-branch review | the working diff |
| `verify` | during verification | the working diff |

Before a build there is no diff, so pre-build points scope against what the
change *will* touch — the `## Watch` block of `surface.md`. After a build they
scope against what it *did*.

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
scripts/keel participants --at plan --class boundary
scripts/keel participants --at branch-review --all   # ignore path scoping
```

Output is one row per participant: `id`, `kind`, target type, target,
`blocking`, `brief`. The runner decides *who* takes part. The stage skill does
the dispatching — that split is why adding a participant never requires
changing the runner.

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
  wants to *be* the planner should not be used with keel.
- **Pass a gate.** See the hard rule.
- **Add an attachment point.** The nine above are the contract. If a layer
  seems to need a tenth, that is a defect in keel to fix in the spine.
- **Receive the conversation.** See above.

## Handling findings

Findings from an external reviewer are handled exactly like internal ones —
fix, rule against with a written reason, or park in the ledger. Never silently
dropped. Record the participant `id` alongside the finding so a later reader
knows which reviewer raised it.
