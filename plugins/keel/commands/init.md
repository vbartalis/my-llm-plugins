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
keel's own reviewers as ordinary entries, so the repo can add or replace any of
them with a line of JSON.

Ask whether any installed plugin should take part in a stage — a design system,
an accessibility auditor, a language reviewer. Add each as a scoped entry rather
than an unscoped one; a reviewer that runs on every change is mostly cost. The
schema is in
`${CLAUDE_PLUGIN_ROOT}/skills/using-keel/references/participants.md`.

## 5. Staleness

Copy `${CLAUDE_PLUGIN_ROOT}/templates/surface-stale.json` into `.keel/checks/`.
It wires `scripts/keel stale` in as a blocking invariant.

## 6. First checks

Register the repo's existing linters, formatters, and type checkers in
`.keel/checks/` — wrapping a command you already run is a legitimate check and
it takes a minute each. Use the schema in
`${CLAUDE_PLUGIN_ROOT}/skills/checking-invariants/references/check-manifest.md`.

Every check needs a `why`. A check without one gets deleted the first time it
is inconvenient.

Verify: `scripts/keel check` runs them and passes on a clean tree.

## 7. Report

Say what was created, what already existed, which checks and participants are
registered, and that the next step is `/keel:orient`.
