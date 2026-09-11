# my-llm-plugins

A Claude Code plugin marketplace. The substantial plugin here is `keel`. Two
things are true in this repo at once: it runs keel, and it is where keel is
built. The first half is below; the second half is under "Working on keel
itself".

<!-- The section below is templates/repo-CLAUDE.md, installed by /keel:init.
     Anything above it is this repo's own and outranks it. -->

## This repo uses keel

Work here moves through six stages. Each writes one file and names the next:

```
/keel:orient → /keel:design → /keel:plan → /keel:build → /keel:verify → /keel:ship
```

If you are about to change code you intend to keep, you are in a stage. Find
it before doing anything else:

```
scripts/keel workspace current      # which change am I in?
scripts/keel check                  # do the repo's invariants hold?
```

The `keel:using-keel` skill is the full stage map and is loaded automatically
at session start. Invoke the stage's skill and follow it rather than
improvising a process.

### What binds you here

- **`docs/keel/constitution.md`** is repo law. It outranks anything a stage
  produces, and anything you would otherwise prefer.
- **`.keel/checks/*.json`** are invariants. A failing check has three outcomes —
  fix the code, fix the check, or escalate the rule to a human. Never skip one.
- **Gates are human decisions.** You may not approve a surface, design, plan, or
  verification on your partner's behalf, and neither may any agent.
- **Artifacts are committed.** `docs/keel/features/<workspace>/` is part of the
  change, not scratch.

### Answering a question is not a stage

Reading code, explaining how something works, or investigating a bug's cause
needs no workspace. Only changes you intend to keep enter the pipeline.

### This repo ships keel as well as running it

`keel` is a stage skill's namespace *and* a directory here. When a keel stage
tells you to invoke `keel:orienting`, that is the installed plugin. When you are
editing `plugins/keel/skills/orienting/`, you are changing it. Both happen in
this repo, sometimes in the same session — say which one you are doing.

---

# Working on keel itself

Keel is a Claude Code plugin. It targets Claude Code and nothing else — do not
add compatibility shims, manifests, or prose for other harnesses.

## What goes where

- **`skills/<stage>/SKILL.md`** — the stage's instructions. Written to be
  followed by an agent under pressure to skip it.
- **`skills/<stage>/references/*.md`** — templates and technique, loaded on
  demand. Detail belongs here, not in SKILL.md, because SKILL.md is read every
  time the stage runs.
- **`agents/*.md`** — dispatched subagents. Self-contained; they inherit no
  conversation context, so anything they need must be in their file or in the
  brief constructed for them.
- **`commands/*.md`** — thin entry points. A command invokes a skill and adds
  the one or two guards specific to being invoked directly. Never put substance
  in a command; it duplicates and then drifts.
- **`scripts/keel`** — the only executable. Bash, `jq` or `python3` for JSON,
  no other dependency. It has **two roles**, and conflating them hid four bugs:

  **Resolver**, for anything the harness must start. `keel participants` says
  who should take part; the stage skill dispatches. Not a preference — bash
  cannot dispatch a subagent — but it means participants inherit the harness's
  guarantees free: per-call permission, a transcript entry, a timeout, process
  isolation.

  **Bounded executor**, for repo-supplied shell. `keel check` runs a check's
  `command` itself, because the verdict has to be an exit status the runner
  aggregates rather than an opinion an agent forms. Nothing else can price a
  check at milliseconds or work in CI with no agent present.

  The second role is the one that needs writing down, because keel took it on
  without stating what it owes. See `run_one_check`: stdin closed, output off
  any inherited descriptor, a fresh shell, a wall-clock bound. Every clause is a
  measured failure, and "it resolves; it never dispatches" is what kept them
  invisible — the doctrine said no execution site existed.
- **`templates/`** — what `/keel:init` copies into a repo. `participants.json`
  here is also the registry a repo falls back to before init has run, so it is
  live code, not a sample.
- **`tests/`** — the runner's test suite. Bash, no framework.

## Where documentation goes

- **`docs/`** — for people. Narrative, examples, vocabulary, failure modes. Not
  loaded by any agent at runtime.
- **`skills/*/SKILL.md`** — for the agent running that stage. Read every time
  the stage runs, so keep it to what is needed to act.
- **`skills/*/references/*.md`** — detail loaded on demand. Templates, schemas,
  technique.
- **`templates/repo-CLAUDE.md`** — what the target repo says about itself.

When you change behaviour, the docs that must follow are: the stage skill, the
relevant reference, `docs/walkthrough.md` if the example no longer matches, and
`docs/glossary.md` if you introduced a word.

## The harness surface

What keel plugs into Claude Code with, and what it deliberately does not.

| Extension point | Keel uses it for |
|---|---|
| `skills/` | the ten stage and support skills |
| `agents/` | implementer, task-reviewer, invariant-reviewer |
| `commands/` | thin `/keel:*` entry points |
| `hooks/hooks.json` | one `SessionStart` hook, injecting one skill |
| `scripts/keel` | the resolver |

**Deliberately unused**, and each for the same reason — it would put keel's
behaviour somewhere a repo's own rules cannot reach:

- **`mcpServers` / `.mcp.json`** — keel resolves with bash and reads files. A
  server is a second place state could live.
- **`userConfig`** — per-user, per-machine settings. Everything keel decides is
  a property of the repo, so it belongs in the repo: `.keel/`, the constitution,
  the participants registry. A user-level knob would let two people run
  different processes over the same code and never find out.
- **`dependencies`** — keel requires no other plugin. It coexists with them.
- **`workflows/`, `outputStyles/`, `experimental.*`** — no need, and each is a
  second way to do something keel already does one way.

`tests/test-plugin-shape.sh` asserts those absences, so dropping one is a
decision someone makes rather than a thing that drifts in.

**Rules that hold here:**

- **One `SessionStart` hook, one skill, every source.** The matcher covers
  `startup|resume|clear|compact|fork`. Omitting a source does not degrade
  gracefully: that session simply has no stage map and improvises the process
  keel exists to stop it improvising. The hook is synchronous, or the first turn
  can start before the map lands.
- **The hook is guarded.** It injects only in a repo that has been through
  `/keel:init`. The plugin installs per machine, and a router that announces
  "this repository is built with keel" everywhere is wrong in most repos.
- **No `CLAUDE.md` inside the plugin.** It is not loaded for anyone who installs
  keel, so contributor rules live here at the repo root instead. `claude plugin
  validate --strict` warns about this, and `plugin-manifests` runs it.
- **Commands carry `description` and `argument-hint`; side-effecting ones carry
  `disable-model-invocation`.** The stage chain invokes *skills*, so making
  `/keel:init` and `/keel:ship` user-initiated costs the pipeline nothing.
- **No command sets `model` or `effort`.** The main conversation runs on the
  model your partner chose. The registry governs what keel *dispatches*, and
  nothing else.

## Rules for editing skills

**One resident skill.** Only `using-keel` is injected at session start. Adding
a second resident skill is a design change, not an edit.

**Every stage names its successor.** The chain is the hand-holding. A stage
that ends without saying what comes next is broken.

**Every rule states its failure.** A red-flag row, a check's `why`, a stage's
reason for existing — all of them name the thing that goes wrong without it.
Rules without a named failure get deleted the first time they are inconvenient.

**Positive instructions.** "App code uses design tokens" outperforms "don't use
raw colours". Write what should be true.

**Ceremony scales, gates do not.** If you add ceremony, key it to the surface
class. Never key a gate to anything.

## Testing a change

**Runner and plugin-shape changes have tests, and the tests come first.**

```
bash plugins/keel/tests/run-tests.sh          # every suite, ~3s
bash plugins/keel/tests/test-check.sh         # one suite
claude plugin validate ./plugins/keel --strict
```

`plugins/keel/tests/helpers.sh` gives you a throwaway git repo per test, so the runner sees a
real `REPO_ROOT`, a real branch and a real diff. Write the failing assertion
before the fix: the three defects in 0.5.0 were all mechanically testable and
none was caught by reading, which is the diligence keel exists to stop relying
on. `keel-tests` in `.keel/checks/` runs the suite, so a regression fails the
repo's own check set.

For skill changes there is no unit test. Run the stage on a real change and
watch where the agent argues with it. A skill that gets rationalised past is a
skill with a missing red-flag row. Say in the ledger which stage you ran.

## Rules for editing agents

**An agent's frontmatter names its model.** `.keel/participants.json` decides
what a dispatch actually runs on, and the coordinator passes it explicitly — but
the frontmatter is the floor under a dispatch that forgets. Without it, a
forgotten model inherits the coordinator's, which is the expensive default the
registry exists to stop. Keep the two in step: an agent's frontmatter model
matches what the shipped registry gives it.

## Field separators

Rows passed between the runner's functions are separated by `\x1f`, not tabs.
Tab is IFS whitespace, so consecutive tabs collapse on `read` and an empty field
silently shifts every later field left. Do not "simplify" this back to ``.

## Adding a layer

Read `skills/using-keel/references/extension-points.md` first. There are exactly
two mechanisms — checks and participants — and a layer uses them. A layer does
not add a stage, a gate, a way to pass a gate, a new attachment point, or a
session-start injection.
