#!/usr/bin/env bash
# template-drift: this repo's copies of keel's templates match the templates.
#
# This repo runs keel on itself, so several files exist twice: once in
# plugins/keel/templates/ as what /keel:init installs, and once at the path
# init would install it to. Editing one and not the other means the plugin ships
# something nobody here is running, and the drift is invisible — both files are
# valid, both pass every other check, and nothing compares them.

set -uo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root" || exit 2

T="plugins/keel/templates"

# installed path <- template it came from
PAIRS="
scripts/keel|${T}/keel-wrapper.sh
scripts/checks/link-integrity.sh|${T}/checks/link-integrity.sh
.keel/checks/link-integrity.json|${T}/checks/link-integrity.json
"

fail=0
while IFS='|' read -r installed template; do
  [ -n "$installed" ] || continue
  if [ ! -f "$template" ]; then
    printf 'template-drift: %s: template is missing\n' "$template" >&2
    fail=1; continue
  fi
  if [ ! -f "$installed" ]; then
    printf 'template-drift: %s: not installed here — this repo should run what it ships\n' "$installed" >&2
    fail=1; continue
  fi
  if ! diff -q "$template" "$installed" >/dev/null 2>&1; then
    printf 'template-drift: %s differs from %s\n' "$installed" "$template" >&2
    diff -u "$template" "$installed" | sed 's/^/template-drift:   /' >&2
    fail=1
  fi
done <<< "$PAIRS"

exit "$fail"
