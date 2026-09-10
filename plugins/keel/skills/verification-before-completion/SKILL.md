---
name: verification-before-completion
description: Use after a build completes and before shipping - proves the change works with evidence rather than claims
---

# Verification Before Completion

**Announce:** "I'm using the verification-before-completion skill to prove this works."

Fifth stage. "Done" means "it works", not "I wrote the code". This stage
produces evidence.

<HARD-GATE>
Do not report the work complete, and do not invoke
`keel:finishing-a-development-branch`, until every item below has an
observation attached. An unobserved item is a failure, not a pass.
</HARD-GATE>

## The Rule

**You may not claim anything you have not observed in this session.**

Not "tests pass" — the command you ran and its output. Not "the endpoint
works" — the request and the response. Not "nothing else broke" — the full
suite result. Memory of a passing test from twenty tool calls ago is not
observation; code has changed since.

## The Process

### 1. Full test suite

Run everything, not the tests for the code you touched. Cross-app changes
break things nobody expected — that is what makes them cross-app.

Record the exact command and the result. If the suite was already failing
before your change, say which failures pre-existed and prove it by naming the
commit you checked against.

### 2. Full check set

```
scripts/keel check
```

Full set, not `--changed`. For a `boundary` change this is the step that
confirms every consumer agrees with the new shape.

Any advisory findings accumulated during the build get reviewed here: fixed,
or carried forward with a reason.

### 2b. Surface freshness

The branch may have been open for days. Bring it up to date with its base, then
look at what moved under the `## Watch` block while it was open. If a shape the
design rests on changed, the verification you just ran proved something about a
world that no longer exists — reconcile before continuing.

### 2c. Registered reviewers

```
scripts/keel participants --at verify
```

Dispatch any listed. Their findings join the record below.

### 3. Design coverage

Walk `design.md`'s **Behaviour** section and its **Impact By App**
subsections. For each statement, name the test or the observation that
demonstrates it. Statements with nothing behind them are findings.

This is the step that catches the thing the plan quietly dropped.

### 4. Surface coverage

Walk `surface.md`'s **Interface Surfaces** and **Contracts** sections. For
each consumer named there, confirm it still works. For a boundary change,
"still compiles" is not enough — a consumer that compiles against a changed
shape and behaves wrongly is the exact failure this repo keeps hitting.

### 5. Parked findings

Read the ledger's parked findings. For each: is it still acceptable to ship
with this open? Anything that is not gets fixed now.

### 6. Manual observation

Some behaviour has no automated test. Run it. A request, a command, a page.
Record what you did and what happened.

If you genuinely cannot exercise something in this environment, say so
explicitly and name what a human needs to check. Do not let it pass silently.

### 7. Write the verification record

Append to `ledger.md` under `## Verification`. Use the template in this skill.
Every claim carries its observation.

### 8. Gate

Present: what you verified, what you could not, and anything open. Then:

**Next stage:** invoke `keel:finishing-a-development-branch`.

## Verification Record Template

```markdown
## Verification YYYY-MM-DD

**Test suite:** `<exact command>` → <result, with counts>
**Pre-existing failures:** <list, with the commit checked against, or "none">

**Checks:** `scripts/keel check` → <result>
**Advisories carried forward:** <list with reasons, or "none">

**Design coverage:**
| design.md statement | Evidence |
|---------------------|----------|
| <quoted statement> | <test name or observation> |

**Surface coverage:**
| Consumer from surface.md | Status | Evidence |
|--------------------------|--------|----------|
| `apps/web` invoice view | works | <what you ran and saw> |

**Manual observation:**
- <what you did> → <what happened>

**Could not verify:**
- <what, and what a human must check>

**Parked findings at ship:** <list, or "none">
```

## Red Flags

| Thought | Reality |
|---------|---------|
| "Tests passed earlier" | Code changed since. Run them again. |
| "I only changed one app, no need for the full suite" | The suite is how you learn that was untrue. |
| "It compiles, so the consumer is fine" | Compiling against a changed shape and behaving correctly are different things. |
| "This behaviour is obviously right" | Then observing it costs nothing. Observe it. |
| "I'll note the untested bit in the PR" | Note it here, in the record, where the gate can see it. |
| "The advisory findings are minor" | Then say why, in writing, and carry them forward deliberately. |
