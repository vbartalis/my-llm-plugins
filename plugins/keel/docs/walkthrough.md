# A change, end to end

One boundary-class change through all six stages, with the artifacts it
produces. Read this once and you have seen the whole system working.

The example is deliberately the hard case: a shape owned by a Go service and
consumed by a TypeScript app and a Python job. A single-app change would skip
most of the ceremony below — see *Ceremony scales* at the end.

**The request:** invoices need to carry the currency they were issued in.

---

## Stage 1 — orient

```
/keel:orient invoices need to carry their currency
```

Keel creates `docs/keel/features/2026-09-10-invoice-currency/`, reads the
constitution, then goes looking. Not for what calls what, but for **where this
information lives and who believes something about its shape** — origin, store,
transport, declaration, consumption.

The part that matters is the declaration count:

> Found three declarations of Invoice: `services/billing/invoice.go` (owner),
> `apps/web/src/invoice/types.ts`, `jobs/reporting/models.py`. Two of these are
> hand-maintained copies.

Three declarations of one shape is the finding. That is the mechanism the
change would drift through, and it goes in Risks.

### surface.md

```markdown
# Surface: invoice currency

**Class:** boundary
**Base:** 5787c98
**One line:** Invoice gains a currency, visible everywhere an amount is shown.

## Apps Touched

| App | Language | Change | Owner of what |
|-----|----------|--------|---------------|
| `services/billing` | Go | produces the field | authoritative for Invoice |
| `apps/web` | TypeScript | renders it | — |
| `jobs/reporting` | Python | aggregates by it | — |

## Contracts

**Invoice** — authoritative in `services/billing`. Consumed by `apps/web` and
`jobs/reporting`, both of which maintain their own declaration of it. Adding a
field means three edits that must agree, with nothing enforcing that they do.

## Watch

```
services/billing/invoice.go
apps/web/src/invoice/types.ts
jobs/reporting/models.py
```

## Risks

- Invoice is declared three times. Nothing detects divergence today.
- Historical invoices have no currency. Backfill or nullable — design decides.

## Out Of Scope

Multi-currency conversion. Display formatting per locale.
```

**Gate.** You confirm the surface is right. Nothing has been designed yet — if
an app is missing from that table, this is the cheap moment to catch it.

---

## Stage 2 — design

```
/keel:design
```

Advisors registered at `design` are invoked first. Then the questions that
matter: what happens to invoices written before the change, and does the
reporting job break if it sees a currency it does not know.

Because the class is `boundary`, the design writes the shape out rather than
describing it:

```markdown
## Data Shapes

**Invoice.currency** — ISO 4217 alpha-3, e.g. `USD`.
Owner: `services/billing`.

| Field | Type | Optional | Filled by |
|-------|------|----------|-----------|
| `currency` | string(3) | no, after backfill | billing at issue time |

**Compatibility.** Additive. Existing rows backfill to the account's default
currency in the same migration. A consumer that has not been updated ignores an
unknown field and keeps working — verified per consumer in stage 5.
```

Plus the behaviour at the edges — empty, unknown code, mixed-currency
aggregation — because those are what stage 5 tests against.

**Gate.** Reviewers registered at `design-gate` run and hand you findings.
Their verdicts are advisory; you approve, not them.

---

## Stage 3 — plan

```
/keel:plan
```

For a boundary change the task order is not negotiable: **the shape first,
alone.** A task that changes a shape and a consumer together cannot be
reviewed, because a reviewer cannot tell whether the consumer was updated
correctly or the shape was bent to fit it.

```markdown
### Task 1: Invoice carries a currency

**App:** `services/billing`

**Files:**
- Modify: `services/billing/invoice.go`
- Test:   `services/billing/invoice_test.go`

**Interfaces:**
- Consumes: none
- Produces: `Invoice.Currency string` — ISO 4217 alpha-3, always populated
  after migration 0042.

**Checks:** `go-lint`, `surface-stale`

- [ ] **Step 1: Write the failing test**
- [ ] **Step 2: Run it and confirm it fails** — `go test ./services/billing/ -run TestInvoiceCurrency`
      Expect: FAIL, `unknown field Currency`
- [ ] **Step 3: Implement the minimum**
- [ ] **Step 4: Run it and confirm it passes**
- [ ] **Step 5: Run the task's checks**
- [ ] **Step 6: Commit**

**Done when:** Invoice round-trips a currency through the store.
```

Tasks 2–4 update the migration and the two consumers, each naming
`Invoice.Currency` in its **Consumes** block — because the agent implementing
task 3 will never see task 1.

**Gate.** You approve the plan.

---

## Stage 4 — build

```
/keel:build
```

Setup runs `scripts/keel stale` first. If a watched file moved on `main` while
you were designing, stop — the design was argued against a shape that no longer
exists.

Then, per task:

1. The coordinator constructs a brief: the task verbatim, the global
   constraints verbatim, the files it may touch, the interfaces. **Not** the
   design, not other tasks, not this conversation.
2. `keel participants --at build` names the implementer and the model it runs
   on. A fresh implementer executes the task and commits.
3. Reviewers registered at `task-review` judge spec compliance and quality,
   each on the model its own entry names.
4. The task's checks run.
5. Findings go through the fix loop — up to five rounds, resuming the same
   implementer for the first three and dispatching a fresh, more capable one
   after that.
6. The outcome is appended to the ledger.

No pause between tasks. The ledger is the progress report.

Nothing here changes the model *you* are running on. The registry governs what
keel dispatches; your own session stays on whatever you chose.

### ledger.md

```markdown
## Task 1: Invoice carries a currency — COMPLETE 2026-09-10

**Commits:** `a1b2c3d`
**Review:** approved · **Checks:** go-lint pass, surface-stale pass
**Produced:** `Invoice.Currency string`

---

## Ruling 2026-09-10 — backfill default for accounts with no currency

**Decision:** default to `USD` rather than failing the migration.
**Why:** design says additive and non-breaking; a failing migration is breaking.
**Cost if wrong:** a data fix on a small number of legacy accounts.
**Amended:** design.md § Data Shapes.
```

A ruling, not a question. A wrong ruling costs rework you can see and undo; a
session parked on a question costs your whole day.

---

## Stage 5 — verify

```
/keel:verify
```

Every claim needs an observation made in this session. Memory of a test that
passed twenty tool calls ago is not an observation.

- Full suite, not just the code you touched.
- Full check set, and `keel stale` again — the branch may have been open days.
- Every statement in the design's Behaviour section, matched to the test that
  demonstrates it.
- Every consumer named in `surface.md`, confirmed still working. For a boundary
  change **"it still compiles" is not enough** — a consumer that compiles
  against a changed shape and behaves wrongly is the exact failure this
  pipeline exists to catch.

**Gate.** You read the evidence, including what could not be verified here.

---

## Stage 6 — ship

```
/keel:ship
```

The tree is clean, the artifacts are committed alongside the code, and the
branch is rebased and still passing. You get a summary and the real options —
PR, merge, leave, discard — and you choose. Every open item from the ledger
appears in that summary or it disappears.

---

## What the change left behind

```
docs/keel/features/2026-09-10-invoice-currency/
  surface.md    why these three apps, and that Invoice had three declarations
  design.md     why additive with a backfill, and what was rejected
  plan.md       why the shape moved before its consumers
  ledger.md     the USD default, and that it was a ruling rather than a decision you made
```

In six months, when someone asks why invoices default to USD, the answer is in
the repo instead of gone.

---

## Ceremony scales

That was `boundary`, the heaviest path. The same change confined to one app
would have been `local`:

| | local | boundary |
|---|---|---|
| Design | a few sentences in chat, recorded | full design.md with the shape written out |
| Plan | in chat if under ~3 tasks | full plan.md, shape task first |
| Checks per task | optional | required on shape tasks |
| Verify | suite + checks | plus every consumer confirmed by behaviour |

**The gates never scale.** Five approvals either way. A one-line change that
crosses a boundary is the expensive kind, which is exactly why orienting runs
first and classification is its own step.

---

## When it goes backwards

Work returns as often as it advances, and it returns to **the stage that owns
the defect**, not to the start.

If verification finds the reporting job silently drops mixed-currency rows,
that is not a build defect — the code does what the plan said. The plan said
the wrong thing because the design never settled it. So: return to
`brainstorming`, settle it, re-gate the delta, add the tasks it needs, and
record the return in the ledger. Tasks built on the wrong part are named as in
doubt.

The full table is in the `keel:using-keel` skill's `return-paths` reference.
