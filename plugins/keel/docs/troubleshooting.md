# Troubleshooting

---

### `keel: cannot find the keel plugin runner`

`scripts/keel` is a wrapper that locates the installed plugin at runtime. It
looks at `KEEL_HOME`, then `CLAUDE_PLUGIN_ROOT`, then the plugin cache under
`~/.claude/plugins`, then a development checkout beside the repo.

Install the plugin, or point it explicitly:

```
export KEEL_HOME=/path/to/plugins/keel
```

### `keel: no feature workspace yet — start with /keel:orient`

There is no `docs/keel/features/*` directory. Either this is a fresh repo, or
you are being asked a question rather than making a change — questions need no
workspace.

### `keel: no invariant checks registered in .keel/checks/`

Expected on day one, and worth fixing early. Start by wrapping the linters,
formatters and type checkers you already run — each is a legitimate check and
takes a minute. Every check needs a `why`, or it gets deleted the first time it
is inconvenient.

### The surface no longer matches the repo

A shape the design rests on moved on the base branch while the branch was open.
The design was argued against something that no longer exists.

Look at what actually changed under the `## Watch` block before reacting — a
formatting pass is nothing. If a signature or contract moved, do not build on
it: re-run `/keel:orient` against the current base, reconcile `surface.md`,
re-gate whatever the move invalidated, and record the return in the ledger.

### A check fails but the code looks right

Three outcomes, and only three:

1. **Fix the code** — the invariant is right. The default.
2. **Fix the check** — the invariant is right, the command has a false
   positive. Fixing the command is now the task.
3. **Change the invariant** — the rule itself is wrong. That is repo law, so it
   is a human decision, not something to rule on mid-build.

"Skip it for now" is not one of them. If it cannot be resolved inside the task,
park it in the ledger with a reason.

### A participant I registered never runs

Check, in order:

```
scripts/keel participants --at <point> --all     # ignore path scoping
scripts/keel participants --at <point>           # with scoping
```

- If `--all` shows it and the scoped call does not, `when.paths` is not matching.
  Remember what each point scopes against: pre-build points use the `## Watch`
  block of `surface.md`, post-build points use the change.
- If the scoped call is empty and the runner said `no base ref resolved`, it had
  only the working tree to go on — which is empty once a task has committed.
  Pass `--base <ref>` naming what this branch came from.
- If neither shows it, check `when.class` against the surface's actual class,
  and watch for `keel: ignoring participant <id>` — an entry needs `id`, `at`,
  and exactly one of `agent` / `skill` / `prompt`.
- If it is listed but nothing happens, the agent or skill it names is not
  installed. Note it in the ledger with the participant `id` and continue; a
  missing plugin of someone else's is a setup gap, not a reason to stop.

### `keel: no base ref`

```
scripts/keel base
```

That says what keel is measuring the change against and where it got it.

**What it is.** The branch this work forked from. "The change" is the working
tree plus every commit since it — a task's last step is a commit, so without a
base, finished tasks stop counting and path-scoped checks and reviewers stop
matching.

**Where it comes from.** `surface.md` records it as `**Base:**` when orienting
runs, because that is the moment it is known: you are standing on the branch
you are about to fork from. `--base <ref>` overrides it for one run. There is
no third source.

**Keel does not infer it**, and that is deliberate. Every available signal is
wrong in an ordinary case — most sharply, a branch pushed with `git push -u`
has *itself* as its upstream, so a merge-base against it is the branch tip and
the entire change reads as empty. Silently. Guessing a repo's trunk is also not
keel's business: some squash, some merge, some rebase, some never branch. Keel
needs one fact — what to diff against — and asks for it rather than deriving a
policy it has no standing to hold.

**To fix it**, add the line to `surface.md` next to `**Class:**`:

```
**Base:** trunk
```

For a repo that does not branch, write `none`. Scoping then covers uncommitted
work only, which is the right answer for that workflow.

A `**Base:**` naming a ref that does not exist is an error rather than a
fallback, because a silent fallback here means scoping quietly degrades.

**If you only see this sometimes**, that is correct. Keel resolves a base only
when something needs one: `check --changed` always does, and `participants`
only when an entry at that point has `when.paths`. Keel's own participants are
scoped by class, so a default install never needs a base at all.

### `keel: surface.md Class is '...', which is not a class`

The `**Class:**` line holds one word: `spike`, `local`, `cross-app`, or
`boundary`. Most often this is the template line with all four still on it.

This is an error rather than a guess on purpose. Reading the first word off that
line resolves to `spike`, which looks like it worked and silently skips every
class-scoped reviewer — on precisely the changes heavy enough to have registered
some.

### `keel: no .keel/participants.json in this repo`

Not an error. The repo has no registry, so keel's shipped defaults are in use —
its own implementer and reviewers, which is what every stage skill promises.

`/keel:init` writes a copy into the repo, and from then on that file is the
whole registry. Delete an entry to turn a participant off; use `[]` to turn
every one off.

### `keel: no checks registered in layer '<x>'`

`--layer` selects on a check's `layer` field. Keel's conventional values are
`constitution`, `contracts`, `design-system` and `repo`, but a repo may name its
own — the message lists the layers that actually exist here, which is usually
enough to spot the typo.

### A gate participant is not blocking, and I wanted it to

Working as designed. At any `*-gate` point `blocking` is ignored and the verdict
is presented to you instead. The runner enforces this, not convention.

Agents inform gates; humans decide gates. Anything with a veto over a gate sits
above you in practice, and a false positive from a plugin you did not write
would stall the pipeline with no clean recovery.

If you want something to actually block, attach it at `task-review`,
`branch-review` or `verify` — or make it a check.

### The plugin moved on and this repo did not

```
scripts/keel doctor
```

Then `/keel:init`. There is no separate upgrade command, and no version to
compare against.

**Why there is no version.** Keel records nothing about which release set a repo
up, and keeps no history of what changed between releases. That is deliberate.
Tracking versions and per-version changes is a database migration, and the
problem here is not shaped like one: the repo has been editing these files on
purpose, and no ledger of keel's changes can tell a deliberate divergence from a
stale one. Only the person who made it knows.

**What keel can answer** is present tense: does each piece still work today, and
where does this repo differ from what keel currently ships. `doctor` reports
both, and the distinction is the whole point:

- **`BROKEN`** — something does not work now. A check whose script is gone, a
  registry with nobody at `task-review`, a participant naming an agent keel does
  not have. These get fixed.
- **`differs`** — this repo and this keel disagree. A retuned check, a
  participant keel ships that you do not carry. **Not a defect.** Keel has no
  way to know whether that is your decision or its own drift, so it says what it
  sees and stops. You decide, one at a time.

**What `/keel:init` will and will not do**, by who owns the file:

| | |
|---|---|
| `scripts/keel` | replaced — lookup plumbing, nothing in it worth keeping |
| `.keel/participants.json`, shipped checks, the `CLAUDE.md` section | proposed, one difference at a time |
| your constitution, your checks, your participants | reported, never edited |
| anything under `docs/keel/features/` | never touched at all |

That last row matters most. Those artifacts passed a gate. A `surface.md`
written before `**Base:**` existed keeps working — scoping there falls back to
uncommitted work, `doctor` says so, and nothing rewrites it. Retro-fitting an
approved artifact because the plugin moved on is exactly the silent edit keel
exists to prevent.

**What this costs.** Keel can never tell you "release X changed Y, go do Z". If
a difference does not show up today as something not working or not matching
what keel currently ships, keel has nothing to say about it. Release notes are
for humans to read; the tooling stays present tense.

### Keel does not seem to be active in this repo

The `SessionStart` hook injects the stage map only where keel is set up — it
looks for `.keel/`, `scripts/keel`, or `docs/keel/` in the project. The plugin
installs per machine, so without that guard every repo on your machine would be
told it is built with keel.

Run `/keel:init`. The commands work either way, so `/keel:init` is available
even in a repo the hook stays quiet in.

If the repo *has* been through init and the map is still missing, check the hook
is running at all — `/keel:status` works regardless, and is the fastest way to
tell whether the runner is reachable.

### It was active, then I resumed the session and it was not

That was a real defect before 0.7.0: the hook matched `startup`, `clear` and
`compact`, but not `resume` or `fork`. A resumed session started with no stage
map and improvised. Update the plugin.

### The agent skipped a stage

Say so. Stage skills are written to be followed under pressure to skip them, but
the red-flag tables only work if someone notices. The common causes:

- The change genuinely was a question, not a change.
- It classified as `spike` and correctly exited at orient.
- `using-keel` was not loaded — check the SessionStart hook is running.

If it skipped a **gate**, that is a defect worth reporting.

### Resuming after a compaction or a new session

```
/keel:status
```

Then read `ledger.md` in full before touching anything. The ledger is the
memory: if it says task 4 completed, task 4 completed.

### Keel feels heavy in context

Only `using-keel` is resident — about 7 KB. Everything else loads when a stage
starts and reference files load only when that stage needs them. If the router
itself has grown, move detail into `skills/using-keel/references/` and leave
only the pointer.

### I want a different planner / designer

Then keel is not the right plugin for you. Add advisors to a stage freely, but
replacing a stage is out of scope by design — that boundary is what stops keel
becoming a kitchen sink.

### Superpowers is installed too, and the agent used its skill instead

Keel shares seven skill names with `superpowers`, because keel's stages are
versions of the same ideas. Both exist — skills are namespaced — so
`keel:brainstorming` and `superpowers:brainstorming` are different skills.

In a keel repo the `keel:` one is the stage: it writes the artifact the next
stage reads and names the successor. The other produces good work with no
artifact and no successor, and the chain stops. `using-keel` states this, and
the stage commands (`/keel:design` and the rest) name the skill explicitly, so
running the command rather than describing the task avoids the question.

Superpowers' non-overlapping skills — debugging, TDD, worktrees, receiving
review — stay useful at any point. Keel does not compete with them.
