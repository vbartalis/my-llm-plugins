# Test helpers for the keel runner.
#
# Each test runs against a throwaway git repo so the runner sees a real
# REPO_ROOT, a real branch, and a real diff. Nothing here touches the repo the
# tests are run from.

set -uo pipefail

KEEL_TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEEL_PLUGIN_ROOT="$(cd "${KEEL_TESTS_DIR}/.." && pwd)"
KEEL="${KEEL_PLUGIN_ROOT}/scripts/keel"

PASSED=0
FAILED=0
FAILURES=""

# A git repo with keel's directories, on a branch with a base to diff against.
new_repo() {
  local dir
  dir="$(mktemp -d)"
  (
    cd "$dir" || exit 1
    git init -q -b main .
    git config user.email keel-tests@example.invalid
    git config user.name  "keel tests"
    git config commit.gpgsign false
    mkdir -p .keel/checks docs/keel/features scripts
    printf 'seed\n' > README.md
    git add -A && git commit -qm "seed"
    git branch -q base-ref
    git checkout -qb work
  ) >/dev/null 2>&1
  printf '%s' "$dir"
}

keel() { ( cd "$REPO" && "$KEEL" "$@" ); }

commit_all() { ( cd "$REPO" && git add -A && git commit -qm "${1:-work}" ) >/dev/null 2>&1; }

write_file() {
  local path="$1"; shift
  mkdir -p "$(dirname "${REPO}/${path}")"
  printf '%s\n' "$*" > "${REPO}/${path}"
}

# --- assertions -------------------------------------------------------------
#
# Every assertion prints the actual value on failure. An assertion that reports
# only "expected X" makes you re-run the test by hand to find out what happened.

_pass() { PASSED=$((PASSED + 1)); printf '  ok   %s\n' "$1"; }
_fail() {
  FAILED=$((FAILED + 1))
  FAILURES="${FAILURES}
  ${1}
       ${2}"
  printf '  FAIL %s\n       %s\n' "$1" "$2"
}

assert_contains() {
  local name="$1" haystack="$2" needle="$3"
  case "$haystack" in
    *"$needle"*) _pass "$name" ;;
    *) _fail "$name" "expected to contain: ${needle} — got: $(printf '%s' "$haystack" | tr '\n' '|')" ;;
  esac
}

assert_not_contains() {
  local name="$1" haystack="$2" needle="$3"
  case "$haystack" in
    *"$needle"*) _fail "$name" "expected NOT to contain: ${needle} — got: $(printf '%s' "$haystack" | tr '\n' '|')" ;;
    *) _pass "$name" ;;
  esac
}

assert_rc() {
  local name="$1" want="$2" got="$3"
  if [ "$want" = "$got" ]; then _pass "$name"; else _fail "$name" "expected exit ${want}, got ${got}"; fi
}

report() {
  printf '\n%d passed, %d failed\n' "$PASSED" "$FAILED"
  [ "$FAILED" -eq 0 ] || { printf 'failures:%s\n' "$FAILURES"; return 1; }
  return 0
}
