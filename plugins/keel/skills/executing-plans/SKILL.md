---
name: executing-plans
description: Use to execute an approved plan when subagents are unavailable - the solo fallback for subagent-driven-development
---

# Executing Plans

**Announce:** "I'm using the executing-plans skill to implement this plan."

The fallback for `keel:subagent-driven-development`, used when subagent
dispatch is unavailable in this environment.

**Prefer subagent-driven-development wherever it is available.** Executing a
plan yourself means every task's context accumulates in one window, which is
the exact failure this pipeline exists to prevent. On a plan of more than a
few tasks the difference is large. If subagents are available, stop and use
that skill instead.

## The Process

### 1. Set up

1. Isolated workspace: worktree or branch, never main.
2. Read `plan.md`, `design.md`, `surface.md`.
3. Read `ledger.md` if resuming.
4. Review the plan critically. Raise concerns with your partner before
   starting, not during.
5. Create a todo per task.

### 2. Execute

Per task:

1. Mark in progress.
2. Follow the steps exactly and in order. Run the steps that only run a
   command and check output — they are the proof.
3. Run the task's checks.
4. Self-review the diff as though someone else wrote it.
5. Commit.
6. Append the task completion to `ledger.md`, including the interfaces it
   produced.
7. Mark complete.

Because there is no independent reviewer here, the self-review step is not
optional and the ledger entry is not optional. They are the only record.

### 3. Finish

1. `keel:requesting-code-review` for a whole-branch review — dispatch a
   reviewer even if you executed alone. If no dispatch at all is possible,
   say so plainly in the ledger; an unreviewed branch should be visible.
2. **Next stage:** `keel:verification-before-completion`.

## When To Stop

Same four things as `subagent-driven-development`: irreversible or destructive
operations, security-sensitive actions, side effects outside the workspace,
and a plan so broken every path forward is a guess.

Everything else you rule on and ledger. See the Rulings section of
`keel:subagent-driven-development` — the same authority order applies:
constitution, surface, design, plan, judgment.
