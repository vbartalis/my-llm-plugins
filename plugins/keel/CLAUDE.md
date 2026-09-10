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
  no other dependency. It **resolves**; it never dispatches. `keel participants`
  says who should take part; the stage skill does the dispatching. That split is
  why adding a participant never means touching the runner.
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

**Runner changes have tests, and the tests come first.**

```
bash tests/run-tests.sh     # every suite, ~2s
bash tests/test-check.sh    # one suite
```

`tests/helpers.sh` gives you a throwaway git repo per test, so the runner sees a
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
