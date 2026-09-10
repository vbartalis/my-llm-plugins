# Artifacts On Disk

Keel state lives in the repo, in files a human can read without an agent.
Nothing important lives only in a context window.

## Layout

```
docs/keel/
  constitution.md                   # repo law. optional but recommended.
  features/
    2026-09-09-billing-webhooks/    # one workspace per unit of work
      surface.md                    # orienting
      design.md                     # brainstorming
      plan.md                       # writing-plans
      ledger.md                     # build + verification
.keel/
  checks/                           # registered invariant checks
    *.json
```

## Workspace naming

`YYYY-MM-DD-<kebab-slug>`. Date first so the directory sorts chronologically,
slug from the change not the ticket, so it reads without a tracker open.

Created by `scripts/keel workspace new <slug>`.

## What each file is for

**`constitution.md`** — the non-negotiables for this repo. Version floors,
dependency policy, boundary rules, naming rules. Short. Every stage reads it
and treats it as outranking its own output. If it is longer than two pages
nobody reads it and it stops working.

**`surface.md`** — the blast radius. Which apps, which languages, which
boundaries are crossed, what class of change this is. The one artifact that
exists because this is a monorepo. Reserved sections here are where the
contracts layer will attach.

**`design.md`** — why, and the behaviour that results. Not code. A reader who
disagrees with the change should be able to disagree with *this file*.

**`plan.md`** — the tasks. Each task names files, interfaces it consumes and
produces, and how it is verified. Written so an implementer with zero
conversation context can execute one task in isolation, because that is
exactly what happens.

**`ledger.md`** — the running record during build. Task completions, rulings,
invariant results, verification evidence. Append-only. This is what survives
a compaction, so it is written for a reader who has forgotten everything.

## Rules

- Artifacts are committed. They are part of the change, not scratch.
- Artifacts are amended, never silently rewritten. An amendment says what
  changed and why, at the top of the amended section.
- A stage never writes another stage's artifact.
