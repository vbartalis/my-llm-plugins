---
name: checking-invariants
description: Use when running the repo's invariant checks, or when a rule needs enforcing rather than documenting
---

# Checking Invariants

**Announce:** "I'm using the checking-invariants skill to <run|add> invariant checks."

The enforcement layer. Keel's central claim is that **a rule that lives only
in prose gets ignored the moment context fills**. An invariant is a rule with
a command behind it.

The contracts and design-system layers will land mostly as checks. The runner
and the registry ship with keel; the rules themselves belong to the repo.

## The Registry

`.keel/checks/*.json` — one file per check.

```json
{
  "id": "no-raw-colour",
  "description": "App code uses design tokens, never raw colour literals.",
  "why": "Ad-hoc colours are how the design system drifted last time.",
  "command": "scripts/checks/no-raw-colour.sh",
  "scope": ["apps/**/*.tsx", "apps/**/*.css"],
  "severity": "blocking",
  "layer": "design-system"
}
```

| Field | Meaning |
|-------|---------|
| `id` | Stable. Plans reference it in `**Checks:**` lines. |
| `description` | What must be true. Present tense, positive. |
| `why` | The failure it prevents. Without this the check gets deleted the first time it is inconvenient. |
| `command` | Exits 0 if the invariant holds, non-zero otherwise. Prints what failed and where. |
| `scope` | Globs. A check outside its scope is skipped, and skipping is reported. |
| `severity` | `blocking` stops a task; `advisory` is reported and ledgered. |
| `layer` | Which layer owns it: `constitution`, `contracts`, `design-system`, or `repo`. |

## Running Checks

```
scripts/keel check                 # everything
scripts/keel check --id <id>       # one check
scripts/keel check --task <n>      # the checks the current plan's task names
scripts/keel check --changed       # only checks whose scope matches the change
scripts/keel check --base <ref>    # what "the change" is measured against
scripts/keel base                  # what it resolves to here, and why
```

`--changed` means the working tree **plus every commit since the base**. A task
ends by committing, so a working-tree-only comparison would go empty at the
moment the checks are supposed to run. The base is `--base`, else the branch's
upstream, else the remote's default branch.

<EXTREMELY-IMPORTANT>
A check's `command` is shell, and `scripts/keel check` runs it. Read the
manifests in `.keel/checks/` before running the set on a branch you did not
write — running keel's checks on someone else's branch executes their code.
On your own branches this is the whole point: a check is a command, which is
what makes it enforceable where a document is not.
</EXTREMELY-IMPORTANT>

Called by `keel:subagent-driven-development` after each task, by
`keel:verification-before-completion` in full, and by a human via
`/keel:check`.

## Reading a Failure

A failing check is a finding, and findings go through the fix loop like any
other. Three outcomes and only three:

1. **Fix the code.** The default. The invariant is right.
2. **Fix the check.** The invariant is right but the command is wrong — it has
   a false positive. Fixing the command is now the task.
3. **Change the invariant.** The rule itself is wrong. This is a decision for
   your human partner, not a ruling you make mid-build, because an invariant
   is repo law. Park it in the ledger and raise it.

There is no fourth outcome. "Skip it for now" is how the previous rebuilds
happened. If you genuinely cannot resolve it inside the task, ledger it as a
parked finding with the reason, and it becomes visible at verification.

## Adding a Check

Add one when a rule has been broken twice, or when a rule is important enough
that you would reject a PR for it.

### The test for whether it should be a check

- Can a command decide it? If judgment is required, it is a **rubric** for the
  invariant-reviewer agent, not a check. Both are legitimate; they are
  different mechanisms.
- Does it have a failure you can name? A check whose `why` is vague gets
  deleted.
- Is it fast? Checks run after every task. Seconds, not minutes.

### Writing the command

- Exit 0 when the invariant holds. Any non-zero when it does not.
- Print the offending file and line. A check that says only "failed" costs
  more than it saves.
- No side effects. Checks read; they never write or fix.
- Deterministic. A flaky check gets ignored, and an ignored check is worse
  than no check because it looks like coverage.

See `references/writing-a-check.md`.

## Checks Versus Rubrics

| | Check | Rubric |
|---|-------|--------|
| Decided by | a command | a reviewer agent |
| Lives in | `.keel/checks/*.json` | `.keel/participants.json` |
| Good for | literals, structure, generated-file drift, naming, dependency direction | cohesion, naming quality, whether an abstraction earns itself |
| Cost | milliseconds | a subagent dispatch |
| Failure mode | false positives | inconsistency between runs |

Prefer a check. Reach for a rubric only when no command can decide it.

A rubric is not a separate mechanism: it is a reviewer registered in
`.keel/participants.json`, the same registry an outside plugin uses. Keel's own
`invariant-reviewer` is one entry among them. See
`../using-keel/references/participants.md`.

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll add the check after the feature lands" | The feature is what would have violated it. Add it first. |
| "This check is annoying" | Then it is wrong, or the code is. Both are fixable. Neither is 'skip'. |
| "I'll disable it just for this task" | A check disabled once is disabled forever. Park it in the ledger instead. |
| "Documenting the rule is enough" | That is what was done last time, and the design drifted anyway. |
| "This needs judgment, so no check" | Then write a rubric. Do not write nothing. |
