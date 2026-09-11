# surface.md Template

Copy this into the feature workspace and fill it. Never delete a section —
write "None." Empty sections are information.

**`Class` holds one word.** Every later stage reads it, and `keel participants`
scopes reviewers by it. A `Class` line the runner cannot read stops the stage
with an error naming what it found, rather than resolving to something plausible
and quietly skipping the reviewers a heavier change needs.

**`Base` is the branch this work forks from** — the one you are standing on as
you write this. It is what "the change" is measured against from here on: the
working tree plus every commit since it. Keel never guesses it, because the
guesses are wrong in ordinary cases and wrong quietly. Write "none" for a repo
that does not branch; scoping then covers uncommitted work only, which is the
right answer for that workflow.

```markdown
# Surface: <change name>

**Class:** <exactly one of: spike, local, cross-app, boundary>
**Base:** <the branch this work forks from — the one you are on right now>
**Date:** YYYY-MM-DD
**One line:** <what changes, from the outside>

## Request

<What was asked for, in your partner's terms. Two or three sentences. This is
the thing the design will be judged against.>

## Apps Touched

| App / package | Language | Change | Owner of what |
|---------------|----------|--------|---------------|
| `apps/web` | TypeScript | consumes new field | — |
| `services/billing` | Go | produces it | authoritative for Invoice |

## Interface Surfaces

<Every place this change is visible from outside the code that implements it:
HTTP endpoints, RPC methods, events published or consumed, CLI flags,
database columns, public exports of a shared package, UI routes.

For each: what it is today, what it becomes, and whether the change is
backward compatible.

Reserved: the contracts layer will write generated blast-radius output here.>

## Contracts

<The data shapes that cross an app boundary in this change.

For each shape: its name, which app is authoritative for it, every app that
consumes it, and whether any consumer maintains its own second declaration of
it. A second declaration is a finding — record it under Risks.

Today this is prose. Reserved: the contracts layer will write generated
blast-radius output here.>

## Watch

<Every file this change will touch. One repo-relative path per line inside the
fence. Lines starting with # are ignored.

This is the mechanical projection of the Contracts section above: Contracts
names shapes, Watch names the files that define them. Before a build there is
no diff, so this block is what the design, design-gate, plan and plan-gate
points scope participants against — a reviewer registered for paths you did not
list here is never dispatched.>

```
services/billing/invoice.go
apps/web/src/invoice/types.ts
```

## Existing Flow

<For local and cross-app changes: where the flow you are changing lives today,
with file paths. If you cannot point at it, the change is not local.>

## Constitution Constraints

<Quote verbatim any clause from docs/keel/constitution.md that bears on this
change. Quote, don't paraphrase — later stages read this instead of re-reading
the constitution.>

## Risks

<Things that could make this change go wrong, that are true before any design
exists. Two apps claiming ownership of one shape. A consumer nobody
maintains. A migration with no rollback. A boundary with no test.>

## Out Of Scope

<What this change explicitly does not do. Prevents the plan growing during
build.>
```
