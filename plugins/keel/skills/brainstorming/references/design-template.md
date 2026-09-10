# design.md Template

```markdown
# Design: <change name>

**Surface:** ./surface.md
**Class:** <copied from surface.md>
**Status:** draft | approved YYYY-MM-DD

## Problem

<The problem, in terms of who has it and what they do today. Not the
solution. A reader should be able to disagree that this problem is worth
solving.>

## Goals

<What success looks like from outside the system. Observable. Three to five
bullets.>

## Non-Goals

<What this explicitly does not solve, including things a reader would
reasonably assume it does.>

## Approach

<The chosen approach, argued. Every significant decision gets a because.>

## Alternatives Considered

| Option | Why not |
|--------|---------|
| <the other real option> | <the actual reason, not 'more complex'> |

## Data Shapes

<Required for boundary class, recommended for cross-app.

Write the actual shape — fields, types, optionality, ownership. For each
shape say which app is authoritative and what every consumer named in
surface.md sees after this change.

If a shape changes, state the compatibility story: is this additive, is there
a migration, what happens to data written before the change, what happens to
a consumer that has not been updated yet.>

## Behaviour

<What the system does, including at the edges: empty, duplicate, failure,
concurrent, very large. This section is what the plan's tests will be written
against.>

## Impact By App

<One subsection per app listed in surface.md. What changes there, and what a
developer working only in that app would notice.>

## Open Questions

<Anything unresolved at approval time, with who decides and by when. An open
question at approval is fine. An unrecorded one is not.>

## Amendments

<Append-only. Each entry: date, what changed, why, and whether it was
re-approved.>
```
