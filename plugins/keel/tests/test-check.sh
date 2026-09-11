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

# --- the envelope keel owes anything it runs --------------------------------
#
# Keel executes repo-supplied shell. That makes it an execution host, and a host
# owes its guests a stated contract. Every assertion below was a measured
# failure before it was a test.

REPO="$(new_repo)"

# stdin is closed. The manifest loop reads from a herestring, so a check that
# reads stdin used to eat the remaining checks: three registered, one ran,
# "0 failed", exit 0. A silently shrunk check set reporting green is the worst
# failure this runner can have.
write_file .keel/checks/a.json '{"id":"a-eats-stdin","description":"d","why":"w","command":"cat >/dev/null; true","scope":["**/*"],"severity":"blocking","layer":"repo"}'
write_file .keel/checks/b.json '{"id":"b-second","description":"d","why":"w","command":"true","scope":["**/*"],"severity":"blocking","layer":"repo"}'
write_file .keel/checks/c.json '{"id":"c-third","description":"d","why":"w","command":"true","scope":["**/*"],"severity":"blocking","layer":"repo"}'
out="$(keel check 2>&1)"
assert_contains "a check reading stdin does not eat the set" "$out" "3 ran"
assert_contains "the check after it still runs"              "$out" "b-second"
assert_contains "and the one after that"                     "$out" "c-third"
rm -rf "$REPO"

# The runner's own shell options do not reach the check. `set -u` used to leak
# through eval, so a check that passes when a human runs it FAILed under keel —
# with a diagnostic naming keel's own file, which sends the agent to fix the
# wrong thing.
REPO="$(new_repo)"
write_file .keel/checks/u.json '{"id":"unset-var","description":"d","why":"w","command":"echo $NOT_SET_ANYWHERE; true","scope":["**/*"],"severity":"blocking","layer":"repo"}'
out="$(keel check 2>&1)"; rc=$?
assert_contains "an unset variable is the check's business, not keel's" "$out" "PASS"
assert_not_contains "and keel does not blame the repo for its own shell"  "$out" "unbound variable"
assert_rc "so the run passes" 0 "$rc"
rm -rf "$REPO"

# Output is captured off any inherited descriptor. A check that backgrounds a
# child which inherits stdout used to block the runner for the child's whole
# lifetime — 25 seconds of dead air, and past the Bash tool's timeout an
# unrecognisable tool failure.
REPO="$(new_repo)"
write_file scripts/checks/bg.sh '#!/usr/bin/env bash
sleep 12 &
echo done
exit 0'
( cd "$REPO" && chmod +x scripts/checks/bg.sh )
write_file .keel/checks/bg.json '{"id":"backgrounds","description":"d","why":"w","command":"scripts/checks/bg.sh","scope":["**/*"],"severity":"blocking","layer":"repo"}'
start=$(date +%s); out="$(keel check 2>&1)"; elapsed=$(( $(date +%s) - start ))
assert_contains "a check with a backgrounded child still passes" "$out" "PASS"
[ "$elapsed" -lt 6 ] \
  && _pass "and does not block on it (${elapsed}s)" \
  || _fail "and does not block on it" "took ${elapsed}s — the runner is waiting on an inherited descriptor"
rm -rf "$REPO"

# Time is bounded, and exceeding the budget is its own outcome. "Seconds, not
# minutes" is a rule in checking-invariants with nothing enforcing it.
REPO="$(new_repo)"
write_file .keel/checks/slow.json '{"id":"slow","description":"d","why":"w","command":"sleep 30","scope":["**/*"],"severity":"blocking","layer":"repo"}'
start=$(date +%s); out="$(keel check --timeout 2 2>&1)"; rc=$?; elapsed=$(( $(date +%s) - start ))
assert_contains "an over-budget check times out"        "$out" "TIMEOUT"
assert_contains "and says what the budget was"          "$out" "2s"
assert_not_contains "and is not reported as a failed invariant" "$out" "FAIL "
assert_rc "the run still fails" 1 "$rc"
[ "$elapsed" -lt 8 ] \
  && _pass "and the runner returns promptly (${elapsed}s)" \
  || _fail "and the runner returns promptly" "took ${elapsed}s"
rm -rf "$REPO"

# --- the transcript records what ran ----------------------------------------
#
# `PASS [repo] keel-tests` hid `bash plugins/keel/tests/run-tests.sh`. One Bash
# call fans out to N commands, and the conversation recorded none of them.

REPO="$(new_repo)"
write_file scripts/checks/real.sh '#!/usr/bin/env bash
exit 0'
( cd "$REPO" && chmod +x scripts/checks/real.sh )
write_file .keel/checks/r.json '{"id":"named","description":"must hold","why":"w","command":"scripts/checks/real.sh --strict","scope":["**/*"],"severity":"blocking","layer":"repo"}'
out="$(keel check 2>&1)"
assert_contains "the result line names the command that ran" "$out" "scripts/checks/real.sh --strict"

out="$(keel check --list 2>&1)"
assert_contains "--list names the command"      "$out" "scripts/checks/real.sh --strict"
assert_contains "--list names the severity"     "$out" "blocking"
assert_not_contains "and runs nothing"          "$out" "PASS"
rm -rf "$REPO"

report
