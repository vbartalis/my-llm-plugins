# Constitution

Repo law. Every keel stage reads this and treats it as outranking its own
output. Keep it under two pages — a constitution nobody reads enforces nothing.

Each clause should be one of:

- **Checkable** — a command can decide it. Register it in `.keel/checks/` and
  reference the check id here. Prose alone will not hold.
- **Judgment** — no command can decide it. It becomes a rubric for the
  `invariant-reviewer` agent.

A clause that is neither is a preference, not law. Delete it.

---

## Boundaries

<Which app or package may depend on which. The direction dependencies are
allowed to flow. What may never import what.>

*Check:* `<id>` | *Rubric*

## Shapes

<Who owns a data shape that crosses an app boundary. Whether an app may
declare its own copy of a shape another app owns. Where shapes live.>

*Check:* `<id>` | *Rubric*

## Versions And Dependencies

<Language version floors. What may be added as a dependency and by whom. What
is banned and why.>

*Check:* `<id>`

## Testing

<What must have a test before it lands. What kind of test. What "verified"
means in this repo.>

*Check:* `<id>` | *Rubric*

## Naming And Copy

<Naming rules that cross app boundaries. User-facing wording rules.>

*Check:* `<id>` | *Rubric*

## Migrations And Data

<Rules for anything touching persisted data. Rollback requirements.>

*Check:* `<id>`

---

## Amendments

<Append-only. Date, what changed, why. A constitution that changes silently is
not law.>
