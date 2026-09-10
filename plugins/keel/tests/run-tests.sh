#!/usr/bin/env bash
# Run every keel runner test. Exits non-zero if any of them fails.
#
# These cover the half of keel a command can decide: the runner's parsing,
# validation, scoping and resolution. The skills are tested by running a stage
# on a real change and watching where the agent argues with it — see CLAUDE.md.

set -uo pipefail
cd "$(dirname "$0")" || exit 2

failed=0
for t in test-*.sh; do
  bash "$t" || failed=1
  printf '\n'
done

if [ "$failed" -ne 0 ]; then
  printf 'keel tests: FAILED\n'
  exit 1
fi
printf 'keel tests: all suites passed\n'
