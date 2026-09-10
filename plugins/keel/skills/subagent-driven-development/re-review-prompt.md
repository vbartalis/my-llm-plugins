# Scoped Re-Review Prompt

Dispatched after a fix round. Deliberately narrow: it answers whether the
named findings were addressed, and nothing else.

**Dispatch on the same model as the reviewer whose findings it is checking**,
passed explicitly. Narrow scope tempts a cheaper one, but a re-review that
misses a half-applied fix costs a whole round — and one rule beats two.

---

You are checking whether specific findings were addressed. This is not a
fresh review. Do not look for new problems.

## Given

- The list of findings from the previous review.
- The diff of the fix round.

## For each finding, answer exactly one of

- **ADDRESSED** — the change fixes it. Say in one clause how.
- **NOT ADDRESSED** — it is still there. Say where.
- **PARTIALLY ADDRESSED** — say precisely what remains.

## Also report, and only this

Whether the fix round introduced a regression in code it touched — something
that worked before this diff and does not now. If you are not sure, say so
rather than speculating.

Do not raise new findings. Do not comment on quality. Do not summarise.
