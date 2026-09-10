<!-- Installed by /keel:init. Merge into this repo's existing CLAUDE.md rather
     than replacing it — repo-specific instructions outrank everything below. -->

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
