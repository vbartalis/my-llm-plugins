---
description: Set up keel in this repository — wrapper, directories, constitution
---

Set up keel in this repository. Report what you created and what already
existed; do not overwrite anything that is already there.

## 1. The wrapper

Copy `${CLAUDE_PLUGIN_ROOT}/templates/keel-wrapper.sh` to `scripts/keel` in
the repo root and make it executable.

It locates the installed plugin at runtime, so plan steps, CI, and humans can
all run `scripts/keel` without knowing where the plugin lives. Commit it.

Verify: `scripts/keel help` prints usage.

## 2. Directories

```
docs/keel/features/
.keel/checks/
```

## 3. The constitution

If `docs/keel/constitution.md` does not exist, copy
`${CLAUDE_PLUGIN_ROOT}/templates/constitution.md` to it.

Then help fill it in. Do not invent clauses — ask what this repo's actual
non-negotiables are, and look at what the code already enforces: existing
linter configs, CI checks, dependency rules, directory conventions. A
constitution derived from what is already true is one people will follow.

Keep it under two pages. For each clause say whether it is checkable by a
command or a matter of judgment.

## 4. Participants

If `.keel/participants.json` does not exist, copy
`${CLAUDE_PLUGIN_ROOT}/templates/participants.json` to it. That registers
keel's own reviewers and its implementer as ordinary entries, so the repo can
add or replace any of them with a line of JSON.

Until that copy exists keel uses the same file from inside the plugin, so review
is never silently off — but the copy is what makes the registry the repo's, and
editable.

Ask whether any installed plugin should take part in a stage — a design system,
an accessibility auditor, a language reviewer. Add each as a scoped entry rather
than an unscoped one; a reviewer that runs on every change is mostly cost. The
schema is in
`${CLAUDE_PLUGIN_ROOT}/skills/using-keel/references/participants.md`.

Say that every entry names the `model` it runs on — the shipped defaults put the
implementer and task review on `sonnet` and the gate and branch reviews on
`opus` — and that the repo can retune them without touching a skill. Do not
change them during init; the defaults are the recommendation.

## 5. First checks

Keel ships one general-purpose check. Copy both files:

```
${CLAUDE_PLUGIN_ROOT}/templates/checks/link-integrity.sh   → scripts/checks/
${CLAUDE_PLUGIN_ROOT}/templates/checks/link-integrity.json → .keel/checks/
```

Make the script executable. It fails when a relative link in any tracked
markdown file points at something that no longer exists.

Then register the repo's existing linters, formatters, and type checkers —
wrapping a command you already run is a legitimate check and it takes a minute
each. Use the schema in
`${CLAUDE_PLUGIN_ROOT}/skills/checking-invariants/references/check-manifest.md`.

Every check needs a `why`. A check without one gets deleted the first time it
is inconvenient.

Verify: `scripts/keel check` runs them and passes on a clean tree.

## 6. Confirm the base ref resolves

```
scripts/keel participants --at branch-review
```

If that prints `no base ref resolved`, the repo has no upstream and no
`origin/HEAD`, so keel can only see uncommitted work — which goes empty as soon
as a task commits, taking every path-scoped check and reviewer with it.

Say so, and tell your partner that stages will need `--base <ref>` until the
repo has a remote. Do not invent a branch name to paper over it.

## 7. Declare keel in the repo

Merge `${CLAUDE_PLUGIN_ROOT}/templates/repo-CLAUDE.md` into the repo's own
`CLAUDE.md`, creating it if absent. Merge — never replace; existing repo
instructions outrank everything in the template.

This matters twice over. The SessionStart hook only fires when the plugin is
installed, so the repo should state its own process to survive a checkout by
someone who has not installed keel. And the hook only injects the router in a
repo that has been through this command — creating `.keel/` and `scripts/keel`
above is what turns it on here, and what keeps it quiet in every repo that does
not use keel.

## 8. Report

Say what was created, what already existed, which checks and participants are
registered, and that the next step is `/keel:orient`.
