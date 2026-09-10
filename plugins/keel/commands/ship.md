---
description: Land verified work and close the feature workspace — stage 6
argument-hint: "[pr | merge | leave | discard, if already decided]"
allowed-tools: Bash(scripts/keel:*), Read, Glob, Grep
disable-model-invocation: true
---

Invoke the `keel:finishing-a-development-branch` skill and follow it.

If `ledger.md` has no verification record, stop and invoke
`keel:verification-before-completion` first.

Merging, pushing to a shared branch, and opening a PR are the human's choice.
Present the options and wait.

$ARGUMENTS
