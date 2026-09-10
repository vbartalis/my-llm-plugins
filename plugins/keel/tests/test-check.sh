#!/usr/bin/env bash
# `keel check`: manifest validation, filtering, and scoping.

. "$(dirname "$0")/helpers.sh"

printf 'keel check\n'

# --- manifest validation ----------------------------------------------------

REPO="$(new_repo)"
write_file .keel/checks/ok.json '{"id":"ok","description":"d","why":"w","command":"true","scope":["**/*"],"severity":"blocking","layer":"repo"}'
write_file .keel/checks/nofields.json '{"id":"nofields"}'
write_file .keel/checks/badsev.json '{"id":"badsev","description":"d","why":"w","command":"true","scope":["**/*"],"severity":"blocked","layer":"repo"}'
write_file .keel/checks/notjson.json 'this is not json'
out="$(keel check 2>&1)"; rc=$?

assert_contains "runs a valid manifest"          "$out" "PASS      [repo] ok"
assert_contains "names missing fields"           "$out" "missing fields:"
assert_contains "rejects an unknown severity"    "$out" "severity must be blocking or advisory, not \"blocked\""
assert_contains "reports the real parse error"   "$out" "notjson.json"
assert_not_contains "does not run a rejected manifest" "$out" "[repo] badsev"
assert_rc "clean tree exits 0" 0 "$rc"
rm -rf "$REPO"

# --- pass / fail / advisory -------------------------------------------------

REPO="$(new_repo)"
write_file .keel/checks/fails.json '{"id":"fails","description":"must hold","why":"w","command":"echo nope >&2; exit 1","scope":["**/*"],"severity":"blocking","layer":"repo"}'
out="$(keel check 2>&1)"; rc=$?
assert_contains "a blocking failure is reported" "$out" "FAIL      [repo] fails"
assert_contains "the check's output is surfaced" "$out" "nope"
assert_rc "a blocking failure exits 1" 1 "$rc"

write_file .keel/checks/fails.json '{"id":"fails","description":"must hold","why":"w","command":"exit 1","scope":["**/*"],"severity":"advisory","layer":"repo"}'
out="$(keel check 2>&1)"; rc=$?
assert_contains "an advisory failure is reported" "$out" "ADVISORY  [repo] fails"
assert_rc "an advisory failure exits 0" 0 "$rc"
rm -rf "$REPO"

# --- --layer ----------------------------------------------------------------

REPO="$(new_repo)"
write_file .keel/checks/a.json '{"id":"a","description":"d","why":"w","command":"true","scope":["**/*"],"severity":"blocking","layer":"repo"}'
write_file .keel/checks/b.json '{"id":"b","description":"d","why":"w","command":"true","scope":["**/*"],"severity":"blocking","layer":"infra"}'
out="$(keel check --layer repo 2>&1)"
assert_contains     "--layer selects its layer"      "$out" "[repo] a"
assert_not_contains "--layer excludes other layers"  "$out" "[infra] b"

out="$(keel check --layer infra 2>&1)"
assert_contains "a repo may name its own layer" "$out" "[infra] b"

out="$(keel check --layer typo 2>&1)"
assert_contains "an unregistered layer says which exist" "$out" "no checks registered in layer 'typo'"
assert_contains "and lists them"                         "$out" "infra"
rm -rf "$REPO"

# --- --changed, before and after a commit -----------------------------------
#
# The regression this file exists for: a task's last step is a commit, so
# scoping against the working tree alone stops matching exactly when review
# and checks are supposed to run.

REPO="$(new_repo)"
write_file .keel/checks/web.json '{"id":"web","description":"d","why":"w","command":"true","scope":["apps/web/**"],"severity":"blocking","layer":"repo"}'
write_file .keel/checks/api.json '{"id":"api","description":"d","why":"w","command":"true","scope":["services/api/**"],"severity":"blocking","layer":"repo"}'
commit_all "register checks"

write_file apps/web/page.tsx 'x'
out="$(keel check --changed --base base-ref 2>&1)"
assert_contains     "--changed runs an in-scope check (uncommitted)"  "$out" "[repo] web"
assert_not_contains "--changed skips an out-of-scope check"           "$out" "[repo] api"

commit_all "the task commits"
out="$(keel check --changed --base base-ref 2>&1)"
assert_contains     "--changed still runs it after the commit"        "$out" "[repo] web"
assert_not_contains "--changed still skips the other one"             "$out" "[repo] api"
assert_contains     "and reports what it skipped"                     "$out" "1 out of scope"
rm -rf "$REPO"

# --- --task -----------------------------------------------------------------

REPO="$(new_repo)"
write_file .keel/checks/a.json '{"id":"a","description":"d","why":"w","command":"true","scope":["**/*"],"severity":"blocking","layer":"repo"}'
write_file .keel/checks/b.json '{"id":"b","description":"d","why":"w","command":"true","scope":["**/*"],"severity":"blocking","layer":"repo"}'
mkdir -p "${REPO}/docs/keel/features/2026-01-01-x"
cat > "${REPO}/docs/keel/features/2026-01-01-x/plan.md" <<'PLAN'
### Task 1: first

**Checks:** `a`

### Task 2: second

no checks line here
PLAN
out="$(keel check --task 1 2>&1)"
assert_contains     "--task runs the checks its task names" "$out" "[repo] a"
assert_not_contains "--task skips the ones it does not"     "$out" "[repo] b"

out="$(keel check --task 2 2>&1)"
assert_contains "a task naming no checks says so" "$out" "task 2 names no checks"

out="$(keel check --task 9 2>&1)"; rc=$?
assert_contains "a missing task number is an error" "$out" 'no "### Task 9:" heading'
assert_rc "and exits 2" 2 "$rc"
rm -rf "$REPO"

report
