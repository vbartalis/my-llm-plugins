# Glossary

Keel invents some vocabulary. This is all of it, in one place.

Terms are grouped by what they are, because that is the thing most often
confused — a *check* and a *rubric* both enforce rules but are different
mechanisms, and a *ruling* and a *return* both record a decision but mean very
different things happened.

---

## The work

**Stage** — one of the six steps work moves through: orient, design, plan,
build, verify, ship. Each writes one artifact and names its successor.

**Feature workspace** — the directory holding one change's artifacts:
`docs/keel/features/YYYY-MM-DD-<slug>/`. Committed, not scratch.

**Class** — how much ceremony this change needs, assigned by orienting and read
by every later stage. One of:

| | Meaning |
|---|---|
| **spike** | A feasibility question whose output is an answer, not code you keep. Exits the pipeline at orient. |
| **local** | One app, and the flow being changed already exists there to read. |
| **cross-app** | Two or more apps change, but no shape between them changes. |
| **boundary** | A shape, schema, protocol or public interface between apps changes. |

**Ceremony** — how much you write at each stage. Scales with class. Distinct
from gates, which never scale.

**Task** — the smallest unit that carries its own test cycle and is worth a
fresh reviewer's judgment. If you cannot say how it is verified, it is not a
task.

---

## The artifacts

**Constitution** — `docs/keel/constitution.md`. Repo law. Outranks anything a
stage produces. Under two pages or nobody reads it.

**Surface** — `surface.md`. The blast radius: which apps, languages and
boundaries a change touches, and its class. The one artifact that exists
because this is a monorepo.

**Design** — `design.md`. Why, and the resulting behaviour. Not code. If you
would reject the finished feature, you should be able to reject this file.

**Plan** — `plan.md`. The tasks. Written for an implementer with zero
conversation context, because that is literally who executes them.

**Ledger** — `ledger.md`. Append-only record of the build: task completions,
rulings, returns, check results, parked findings, verification evidence. The
only thing that survives a compaction.

**Watch block** — the fenced list in `surface.md` of every file the change will
touch. The mechanical projection of the Contracts section: Contracts names
shapes in prose, Watch names the files that define them. Before a build exists
it is also the path set the pre-build participant points scope against.

**Interfaces block** — a task's `Consumes` and `Produces`. Load-bearing: the
only way task 5 learns what task 3 named things. Preconditions and
postconditions at task granularity.

---

## Enforcement

**Invariant** — a rule that must hold. Enforced either as a check or a rubric.

**Check** — an invariant a command can decide. `.keel/checks/<id>.json`, whose
`command` exits 0 when the invariant holds. Milliseconds, deterministic. Prefer
this.

**Rubric** — an invariant that needs judgment, so a reviewer agent decides it.
Not a separate mechanism: a rubric is a reviewer registered in
`.keel/participants.json`.

**Severity** — `blocking` stops a task; `advisory` is reported and ledgered.

**Staleness** — whether a shape the surface rests on has moved on the base
branch since the surface was written. A judgment, not a check: read what changed
under the Watch block and decide whether the design still holds.

---

## Participation

**Participant** — anything that takes part in a stage, registered in
`.keel/participants.json`. Keel's own reviewers and implementer are ordinary
entries.

**Advisor** — a skill invoked *during* a stage, while the artifact is being
written. Shapes the work. No veto.

**Reviewer** — an agent or prompt dispatched *after* work exists. Produces
findings. Blocking outside a gate, advisory at one.

**Implementer** — the agent dispatched at `build` to execute one task. Exactly
one applies to a given task.

**Attachment point** — where a participant runs. Ten of them: `orient`,
`surface-gate`, `design`, `design-gate`, `plan`, `plan-gate`, `build`,
`task-review`, `branch-review`, `verify`.

**Brief** — what a participant is given: `artifacts`, `diff`, or `both`. Never
the conversation — a reviewer that shares your context has already accepted
every decision you made.

**Model** — what a participant is dispatched on: `opus`, `sonnet`, `haiku`,
`fable`, or `inherit`. Absent means `sonnet`. Anything else passes through to
the harness as written, with a line on stderr, so a repo can name a model keel
has not heard of. Advisors have none — they run in your context. Neither does
the main conversation: it runs on the model you chose, and no entry changes that.

**Base ref** — what a branch's change is measured against: `--base`, else the
branch's upstream, else the remote's default branch. No branch name is
hardwired. It defines "the change" for `--changed` and for path-scoped
participants, and it spans commits — a task ends by committing, so comparing
against the working tree alone would stop matching exactly when review runs.

---

## Decisions and movement

**Gate** — a point where a stage stops and a **human** approves the artifact.
Five of them. Ceremony scales; gates never do. Agents inform gates; humans
decide gates.

**Ruling** — a decision the coordinator made during a build rather than
stopping to ask, recorded as *what you decided — why — what it costs if wrong*.
A running plan does not wait on a human.

**Return** — going back to an earlier stage. Goes to **the stage that owns the
defect**, not to the start. Recorded in the ledger before it is acted on.

**Amendment** — editing an approved artifact over a detail, then re-gating only
the delta. Distinct from a return, which is for something load-bearing. When
you cannot tell which applies, it is a return.

**Parked finding** — a real finding, out of scope for now, recorded with the
reason and surfaced again at verification. The legitimate alternative to
silently dropping something.

**The four stops** — the only things that halt a running build: an irreversible
or destructive operation, a security-sensitive action, a side effect outside the
workspace, and a plan so broken every path forward is a guess. Everything else
is ruled on.
