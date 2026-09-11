---
name: using-keel
description: Use when starting any conversation in a keel repository - establishes the stage map, which stage the work is in, and which skill to invoke next
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, ignore this
skill. Your task brief is your whole world. Do that, and nothing else.
</SUBAGENT-STOP>

# Using Keel

Keel is the process spine for this monorepo. It owns one thing completely:
**how work moves from an idea to a shipped change.** Six stages, each with an
artifact on disk, each ending by naming the next.

<EXTREMELY-IMPORTANT>
You do not improvise the process. If work is happening in this repo, it is
happening in a stage. Find the stage, invoke its skill, follow it.

You may not skip a gate because the change looks small. Stage *ceremony*
scales with the work. Stage *gates* never do.
</EXTREMELY-IMPORTANT>

## The Stage Map

```
  /keel:orient   →  keel:orienting                     →  surface.md
                    what are we touching?                 [GATE: human approves surface]
        ↓
  /keel:design   →  keel:brainstorming                 →  design.md
                    why, and what behaviour                [GATE: human approves design]
        ↓
  /keel:plan     →  keel:writing-plans                 →  plan.md
                    how, task by task                      [GATE: human approves plan]
        ↓
  /keel:build    →  keel:subagent-driven-development    →  ledger.md + commits
                    fresh subagent per task, review each   [no gate — runs to completion]
        ↓
  /keel:verify   →  keel:verification-before-completion →  verification record
                    prove it works                         [GATE: evidence, not claims]
        ↓
  /keel:ship     →  keel:finishing-a-development-branch →  merged / PR
                                                           [GATE: human chooses]
```

Available at any point, not part of the line:

| Command | Skill | Use for |
|---------|-------|---------|
| `/keel:init` | — | Set up keel in a repo, or reconcile a setup that has drifted. Re-runnable; there is no separate upgrade. |
| `/keel:status` | — | Where am I? Reads the feature workspace and reports. |
| `/keel:check` | `keel:checking-invariants` | Run the repo's registered invariant checks. |
| `/keel:review` | `keel:requesting-code-review` | Dispatch a reviewer at any point. |

## Finding Your Stage

Before your first substantive response, work out where you are:

1. Run `scripts/keel workspace current`, or read `docs/keel/features/` for the
   newest workspace. If `scripts/keel` does not exist, keel is not set up in
   this repo yet — run `/keel:init` first.
2. The highest-numbered artifact present is the last completed stage. Your
   stage is the next one.
3. No workspace at all → you are at `orienting`.

Say which stage you are in out loud, then invoke that stage's skill.

## Routing Shortcuts

Not everything is a feature. Route first:

- **A question** ("how does X work", "where is Y") → answer it. No stage, no
  workspace. Reading is not a change.
- **A bug with unknown cause** → find the cause before designing anything. A fix
  designed before the cause is known is a guess. Prefer any debugging skill this
  environment has; where there is none, this is the floor:
  1. **Reproduce it.** A bug you cannot produce on demand is a bug you cannot
     confirm you fixed.
  2. **Narrow it.** Shrink the failing case until removing anything more makes
     the failure go away. Bisect; do not reason from the first hypothesis.
  3. **Name the cause in one sentence, with the evidence that proves it.** "The
     webhook retries because the ack is written after the commit, see the log
     at X" — not "something in the retry logic".
  4. **Re-enter at `orienting`**, and put that sentence in `surface.md` under
     `## Request`. It is known now and expensive to recover later.
- **A spike** — a feasibility question whose output is an answer, not code you
  keep → `orienting` will classify it and route you out of the pipeline. Say
  so, timebox it, label anything built as throwaway.
- **Anything that changes code you intend to keep** → the pipeline. Enter at
  `orienting`.

## Stage Discipline

**Announce.** Every stage skill opens with an announcement. Say it. Your human
partner tracks the process by those lines.

**Chain.** Every stage skill ends by naming the next one. Follow the naming —
do not stop and ask "shall I continue to planning?" when the stage told you to
go. Gates are where you stop; the end of a stage is not automatically a gate.

**Write the artifact before the gate.** A gate is your human partner reading a
file, not a paragraph in chat. If there is no file, there is nothing to
approve.

**Never edit an approved artifact silently.** If reality contradicts an
approved `design.md` or `plan.md`, say so, amend the file, and re-gate that
one point. Drifting from an approved artifact without saying so is the single
most expensive thing you can do here.

**Returns are normal; unrecorded returns are not.** Work goes back as often as
it goes forward, and it goes to the stage that owns the defect rather than to
the start. Write every return to the ledger before acting on it. See
`references/return-paths.md`.

**Agents inform gates. Humans decide gates.** A repo can register outside
reviewers at any stage through `.keel/participants.json`, and keel's own are
entries in that same registry. None of them can pass a gate. See
`references/participants.md`.

## Red Flags

These thoughts mean stop — you are rationalising your way out of the process:

| Thought | Reality |
|---------|---------|
| "This is a one-line change" | One line crossing an app boundary is the expensive kind. Orient. |
| "I'll just look at the code first" | Orienting *is* how you look at the code. Invoke it. |
| "I know which apps this touches" | Then `surface.md` takes ninety seconds. Write it. |
| "The design is obvious" | Then say it in three sentences and get a nod. That is the bounded path. |
| "I'll write the plan while I code" | A plan written during coding is a log, not a plan. |
| "I'll fix the invariant failure later" | Later is where the last three rebuilds went. Fix it or ledger a ruling. |
| "The surface was fine when I wrote it" | Days ago. Look at what moved under the Watch block before you build on it. |
| "I went back a stage, no need to note it" | A workspace showing only forward motion lies about how the change happened. |
| "The user wants speed" | Speed is not skipping gates. Speed is small stages. |
| "This stage doesn't apply here" | Say that out loud with a reason and let your partner decide. |

## Precedence

Direct instructions from your human partner override keel. `CLAUDE.md` in this
repo overrides keel. Keel overrides your defaults. When your partner tells you
to skip a stage, skip it and say which one you skipped.

**When another process plugin is installed.** Keel shares several skill names
with `superpowers` — `brainstorming`, `writing-plans`,
`subagent-driven-development`, `executing-plans`,
`verification-before-completion`, `finishing-a-development-branch`,
`requesting-code-review` — because keel's stages are versions of the same ideas.
Skills are namespaced, so both exist: `keel:brainstorming` and
`superpowers:brainstorming` are different skills.

In this repo, **invoke the `keel:` one.** It is the stage, it writes the
artifact this repo's later stages read, and it names the successor that keeps
the chain intact. Invoking the other one produces good work with no artifact and
no successor, and the next stage then has nothing to read.

Everything that plugin covers and keel does not — debugging technique, TDD
mechanics, worktrees, receiving review — is yours to use freely and at any
point. Keel claims the shape of the work, not the tactics inside a task.

## What Keel Does Not Own

Keel owns process. It deliberately does not own:

- **Tactics** — debugging technique, test design, language idiom. Other
  plugins and skills cover these and keel does not compete with them.
- **Data contracts** — reserved. See `references/extension-points.md`.
- **Design system enforcement** — reserved. Same file.

Both attach as checks and participants. They are not built yet.

Anything outside keel that should take part in a stage — an outside design
system, an accessibility auditor, a language specialist — registers in
`.keel/participants.json` rather than being wired in here.
