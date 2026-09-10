# surface.md Template

Copy this into the feature workspace and fill it. Never delete a section —
write "None." Empty sections are information.

```markdown
# Surface: <change name>

**Class:** spike | local | cross-app | boundary
**Date:** YYYY-MM-DD
**Base:** <output of `git rev-parse HEAD` at the time you traced this>
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

<Every file whose change would invalidate this surface. One repo-relative path
per line inside the fence. Lines starting with # are ignored.

This is the mechanical projection of the Contracts section above: Contracts
names shapes, Watch names the files that define them. `scripts/keel stale`
reads this block and fails when any of these has moved on the base branch since
**Base:**.>

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
