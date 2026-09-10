# plan.md Template

````markdown
# Plan: <change name>

> **For agentic workers:** execute this with `keel:subagent-driven-development`
> (preferred) or `keel:executing-plans`. Steps use `- [ ]` for tracking.

**Design:** ./design.md
**Surface:** ./surface.md
**Class:** <copied from surface.md>

**Goal:** <one sentence — what this builds>

**Architecture:** <two or three sentences on the approach>

## Global Constraints

<Project-wide requirements copied VERBATIM from docs/keel/constitution.md and
from surface.md's Constitution Constraints section. Version floors, dependency
policy, boundary rules, naming and copy rules. One per line, exact values.
Every task implicitly carries all of these.>

## File Map

| File | Created / Modified | Responsibility |
|------|--------------------|----------------|
| `services/billing/invoice.go` | Modified | Authoritative Invoice shape |
| `apps/web/src/invoice/types.ts` | Modified | Consumer view of Invoice |

## Task Order

<Two or three sentences on why the tasks are in this order. For boundary
changes state the shape-first rule explicitly.>

---

### Task 1: <component name>

**App:** `services/billing`

**Files:**
- Create: `exact/path/to/file.go`
- Modify: `exact/path/to/existing.go:123-145`
- Test: `exact/path/to/file_test.go`

**Interfaces:**
- Consumes: <exact signatures this task relies on from earlier tasks. "None"
  for the first task.>
- Produces: <exact names, parameter and return types that later tasks will
  use. This task's implementer sees only this task; later implementers learn
  these names only from here.>

**Checks:** <invariant check ids that gate this task, or "none">

- [ ] **Step 1: Write the failing test**

```go
func TestInvoiceCarriesMetadata(t *testing.T) {
    // exact test body
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `go test ./services/billing/ -run TestInvoiceCarriesMetadata -v`
Expect: FAIL, `undefined: Invoice.Metadata`

- [ ] **Step 3: Implement the minimum that passes**

<code or precise instruction>

- [ ] **Step 4: Run the test and confirm it passes**

Run: `go test ./services/billing/ -run TestInvoiceCarriesMetadata -v`
Expect: PASS

- [ ] **Step 5: Run the task's checks**

Run: `scripts/keel check --task 1`
Expect: exit 0

- [ ] **Step 6: Commit**

`git commit -m "billing: add Metadata to Invoice"`

**Done when:** <the independently testable deliverable, in one line>

---

### Task 2: ...
````
