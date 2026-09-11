---
name: finishing-a-development-branch
description: Use when verification has passed and the work needs to land
---

# Finishing A Development Branch

**Announce:** "I'm using the finishing-a-development-branch skill to land this work."

Sixth stage. The work is verified. Now it lands, or it does not, and either
way the workspace is left in a state someone else can pick up.

<HARD-GATE>
Merging, pushing to a shared branch, and opening a PR are side effects outside
this workspace. Your human partner chooses. You do not choose for them, and
you do not do any of them because it seemed like the obvious next step.
</HARD-GATE>

## Prerequisites

`keel:verification-before-completion` ran and its record is in the ledger. If
it did not, go back — this stage does not verify anything, it only lands what
was verified.

## The Process

### 1. Confirm the tree is clean

- Everything committed. No stray files, no debug output, no commented-out
  code left from the build.
- The keel artifacts are committed too. `surface.md`, `design.md`, `plan.md`,
  and `ledger.md` are part of the change, not scratch.
- Branch is up to date with its base — the one `surface.md` recorded — and
  still passes. A verification run against a stale base proves less than it
  looks like. **How** you bring it up to date is the repo's business: rebase,
  merge, whatever this repo does. Keel does not read on it.

### 2. Summarise the change

Write a summary a reviewer can read without opening the artifacts:

- What changed and why, in a paragraph.
- Which apps are affected.
- Any behaviour change a consumer will notice.
- Anything carried forward: parked findings, advisories, things a human must
  verify by hand.

That last bullet is not optional. Every open item from the ledger appears
here or it disappears.

### 3. Present the options

Give your partner the real choices:

| Option | When |
|--------|------|
| Open a PR | The default for anything shared. |
| Merge directly | Only if your partner says so and the repo works that way. |
| Leave the branch | Work is done but landing waits on something else. |
| Discard | It was a spike, or the answer was no. |

Say which you recommend and why. Then wait.

### 4. Execute the choice

For a PR: title naming the apps affected, body from the summary, link to the
feature workspace. For a merge: onto the base `surface.md` recorded, only after
explicit agreement, and never onto a protected branch without it.

Squash, merge commit, fast-forward, rebase-and-merge — the repo's convention,
not keel's. Follow what this repo already does; ask if it is not obvious.

### 5. Close the workspace

- If a worktree was used, remove it — after the work has landed, not before.
- Append a closing line to the ledger: what happened, and where the work
  landed.

The feature workspace stays in the repo. It is the record of why the code
looks the way it does, and it is the thing you will read when this area is
changed again in six months.

## Red Flags

| Thought | Reality |
|---------|---------|
| "I'll just push, it's what they wanted" | Pushing is a side effect outside the workspace. Ask. |
| "The artifacts are process noise, don't commit them" | They are the only record of why. Commit them. |
| "The parked findings can go in a follow-up ticket" | Fine — but they go in the summary too, or they vanish. |
| "Verification passed, no need to rebase" | It passed against the old base. Rebase and re-run. |
| "I'll clean the worktree up first" | After it lands. Not before. |
