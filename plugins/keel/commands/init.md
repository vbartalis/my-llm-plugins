---
description: Set up keel in this repository, or reconcile a setup that has drifted
argument-hint: "[nothing — it works out which it is]"
disable-model-invocation: true
---

Bring this repository's keel setup to a working state.

**Run it as often as you like.** There is no separate upgrade: on a repo with
no keel this creates one, and on a repo that has had keel for a year it
reconciles what is there. Same command, because it does the same thing — look
at what exists now and fix what does not hold.

## First: what is actually here

```
scripts/keel doctor
```

If `scripts/keel` does not exist yet, this is a fresh setup — skip to step 1 and
work through in order.

Otherwise `doctor` has just told you the state of every piece, and **its output
is your worklist.** Work only the lines it printed. Do not re-do the steps it
reported `ok`; re-copying a file someone has deliberately edited is how a repo
loses its own decisions.

<EXTREMELY-IMPORTANT>
Keel records no version and keeps no history of what it changed between
releases. It cannot tell a difference it introduced from one the repo made on
purpose, and it must not guess.

So a `differs` line is **not** a defect and **not** a thing to fix. It is a
question for your human partner: keel currently ships X, this repo has Y, which
do you want? Ask, one at a time, with both versions visible.

`BROKEN` lines are different — those are things that do not work today, and
they get fixed.
</EXTREMELY-IMPORTANT>

## Reconciling, by who owns what

**Keel's plumbing — replace it.** `scripts/keel` is the wrapper that locates
the runner. It is lookup code with nothing in it worth customising, and it has
to track the plugin. If `doctor` says it differs or is broken, copy the current
template over it and say that you did.

**Shared files — propose, never overwrite.** `.keel/participants.json`, the
shipped checks, the `CLAUDE.md` section. The repo has been editing these on
purpose. For each difference, show what keel ships and what is here, and let
your partner choose. A participant keel ships that this repo lacks is an
offer, not an omission.

**The repo's own — report only.** `docs/keel/constitution.md`, checks this repo
wrote, its own participants. Keel never edits these. Mention anything that looks
stale and move on.

**Feature workspaces — never touch.** Every artifact in
`docs/keel/features/*/` passed a gate. If one lacks something the current keel
reads — a `**Base:**` line, a valid `**Class:**` — say what it costs, in
present tense: *"scoping here falls back to uncommitted work."* Then leave it
alone unless your partner asks. Retro-fitting an approved artifact is the
silent-edit this whole process exists to prevent.

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

## 6. Say how this repo branches

Nothing to configure — just tell your partner what to expect, once:

Each change records the branch it forks from, as `**Base:**` in its
`surface.md`. Orienting writes it, because that is the moment it is known: you
are standing on the branch you are about to fork from. It is the only thing keel
needs to know about branching — what to diff against, so that a task which has
committed still counts as part of the change.

Everything else about branching stays the repo's. Squash or merge or rebase,
long-lived branches or none — keel does not read on it, does not configure it,
and has no opinion. A repo that does not branch records `**Base:** none` and
keel scopes against uncommitted work.

`scripts/keel base` reports what applies inside a workspace. There is none yet
at init time, so there is nothing to check here.

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

Say what you created, what you replaced, what you left alone, and what is still
an open question for your partner. End with `scripts/keel doctor` again, so the
report is the tool's output rather than your account of it.

On a fresh setup, the next step is `/keel:orient`. On a reconcile, there may be
no next step at all — that is a fine outcome and worth saying.
