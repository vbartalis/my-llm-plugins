# Writing A Check

## Shape

A check is a script. It reads the repo and exits.

```bash
#!/usr/bin/env bash
# no-raw-colour: app code uses design tokens, never raw colour literals.
set -euo pipefail

fail=0
while IFS= read -r line; do
  printf 'no-raw-colour: %s\n' "$line" >&2
  fail=1
done < <(grep -rnE '#[0-9a-fA-F]{3,8}\b' apps --include='*.tsx' --include='*.css' \
         | grep -v 'tokens\.' || true)

exit "$fail"
```

Rules the runner relies on:

- **Exit 0 means the invariant holds.** Nothing else means that.
- **Diagnostics to stderr**, one line per violation, starting with the check
  id and containing `file:line`. The runner surfaces these verbatim into the
  ledger.
- **No writes.** A check never fixes. Fixing is a task.
- **No network.** Checks run constantly; they must be offline and fast.
- **Deterministic.** Same tree, same result, every time.

## Choosing what to check

The checks that pay for themselves detect **divergence between two things
that must agree**:

| Pattern | Example |
|---------|---------|
| Generated artifact vs its source | regenerate, diff, fail if different |
| Two declarations of one shape | the same entity declared in two apps |
| A literal that should be a reference | raw hex, raw pixel, hardcoded URL, magic number |
| A dependency crossing a forbidden direction | a domain package importing a UI package |
| A file that must exist alongside another | every migration has a rollback |

The best of these is the first. Where an artifact is generated, the check is
"regenerate and diff" and it cannot produce a false positive. Prefer that
shape whenever you can arrange for it — it is the reason the contracts layer
is being built around codegen rather than around documentation.

## Anti-patterns

- **The unbounded lint.** A check that reimplements a linter. Use the linter;
  register the linter as the check.
- **The advisory that is never read.** If nobody acts on `advisory`, make it
  blocking or delete it.
- **The slow check.** Anything over a few seconds gets moved to CI only, and a
  check that only runs in CI does not stop an agent mid-build.
- **The check with no `why`.** It will be deleted the first time it is
  inconvenient, and nobody will remember what it protected.

## A worked example

`templates/checks/link-integrity.sh` is a real check you can read: it walks
tracked markdown, resolves every relative link against the file that contains
it, and prints `file:line` for each one that misses. It shows the shape —
accumulate into a temp file rather than a pipeline subshell, report to stderr,
exit non-zero, touch nothing.

## Registering

Write the JSON into `.keel/checks/<id>.json`, put the script wherever the repo
keeps scripts, and run `scripts/keel check --id <id>` to confirm it passes on
a clean tree and fails on a deliberately broken one. **Both.** A check never
verified against a known violation is not a check.
