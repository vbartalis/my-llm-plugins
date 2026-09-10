#!/usr/bin/env bash
# Base-ref resolution: what "the change" is measured against.
#
# The failure this guards is quiet in both directions. Without a base, committed
# work stops counting and scoped checks and reviewers stop matching. And warning
# about a missing base in a repo where nothing is path-scoped is an alarm about
# a setting that is not being used — which teaches people to ignore it.

. "$(dirname "$0")/helpers.sh"

printf 'base ref\n'

# A git repo with no remote and no upstream.
bare_repo() {
  local d; d="$(mktemp -d)"
  ( cd "$d" || exit 1
    git init -q -b trunk .
    git config user.email keel-tests@example.invalid
    git config user.name "keel tests"
    git config commit.gpgsign false
    mkdir -p .keel/checks apps/web
    printf 'seed\n' > README.md
    git add -A && git commit -qm seed
  ) >/dev/null 2>&1
  printf '%s' "$d"
}

# --- resolution order -------------------------------------------------------

REPO="$(bare_repo)"

out="$(keel base 2>&1)"; rc=$?
assert_contains "with nothing to go on, base is none" "$out" "base:   none"
assert_contains "and the effect is spelled out"       "$out" "looks like nothing changed"
assert_contains "and it suggests git config"          "$out" "git config keel.base"
assert_rc "and reports failure" 1 "$rc"

( cd "$REPO" && git remote add origin https://example.invalid/x.git ) >/dev/null 2>&1
out="$(keel base 2>&1)"
assert_contains "with a remote, it suggests set-head" "$out" "git remote set-head origin -a"

( cd "$REPO" && git config keel.base trunk ) >/dev/null 2>&1
out="$(keel base 2>&1)"; rc=$?
assert_contains "git config keel.base resolves"  "$out" "base:   trunk"
assert_contains "and says where it came from"    "$out" "from:   git config keel.base"
assert_rc "and reports success" 0 "$rc"

out="$(keel base --base HEAD 2>&1)"
assert_contains "--base outranks the config" "$out" "from:   --base"

# A configured base naming nothing is a repo defect, not a fallback. It must
# stop every entry point — `resolve_base` runs inside command substitution,
# where an exit would end only the subshell.
( cd "$REPO" && git config keel.base no-such-ref ) >/dev/null 2>&1
for cmd in "base" "check --changed" "participants --at build"; do
  out="$(keel $cmd 2>&1)"; rc=$?
  assert_contains "a bogus keel.base is named (${cmd})" "$out" "resolves to nothing in this repo"
  assert_rc "and exits 2 (${cmd})" 2 "$rc"
done
( cd "$REPO" && git config --unset keel.base ) >/dev/null 2>&1
rm -rf "$REPO"

# --- upstream and remote HEAD ----------------------------------------------

REPO="$(bare_repo)"
( cd "$REPO"
  git branch -q other
  git checkout -qb feature
  git config branch.feature.remote .
  git config branch.feature.merge refs/heads/trunk ) >/dev/null 2>&1
out="$(keel base 2>&1)"
assert_contains "an upstream is used when set" "$out" "from:   this branch's upstream"
rm -rf "$REPO"

# A repo whose only remote is not called "origin" still resolves.
REPO="$(bare_repo)"
( cd "$REPO"
  git update-ref refs/remotes/upstream/trunk refs/heads/trunk
  git symbolic-ref refs/remotes/upstream/HEAD refs/remotes/upstream/trunk ) >/dev/null 2>&1
out="$(keel base 2>&1)"
assert_contains "a non-origin remote HEAD resolves" "$out" "upstream/trunk"
rm -rf "$REPO"

# --- the change spans commits ----------------------------------------------

REPO="$(bare_repo)"
( cd "$REPO" && git branch -q base-ref && git checkout -qb feature ) >/dev/null 2>&1
write_file apps/web/page.tsx 'x'
commit_all "the task commits"

out="$(keel base --base base-ref 2>&1)"
assert_contains "committed work counts as the change" "$out" "the change: 1 path(s)"

out="$(keel base --base feature 2>&1)"
assert_contains "measuring against yourself finds nothing" "$out" "the change: 0 path(s)"
assert_contains "and says why that might be"               "$out" "on the base branch itself"
rm -rf "$REPO"

# --- the warning fires only when it matters ---------------------------------
#
# Keel's shipped participants are scoped by class, never by path, so a default
# install never needs a base at all.

REPO="$(bare_repo)"
out="$(keel participants --at branch-review 2>&1)"
assert_not_contains "no base warning when nothing is path-scoped" "$out" "no base ref"
assert_contains     "and the participants still resolve"          "$out" "keel-code-review"

cat > "${REPO}/.keel/participants.json" <<'JSON'
[ { "id": "web", "kind": "reviewer", "agent": "x:y", "at": "branch-review",
    "when": { "paths": ["apps/web/**"] } } ]
JSON
out="$(keel participants --at branch-review 2>&1)"
assert_contains "the warning does fire once something is path-scoped" "$out" "no base ref"

# check --changed always depends on the base, so it always warns.
write_file .keel/checks/web.json '{"id":"web","description":"d","why":"w","command":"true","scope":["apps/web/**"],"severity":"blocking","layer":"repo"}'
out="$(keel check --changed 2>&1)"
assert_contains "check --changed warns without a base" "$out" "no base ref"
rm -rf "$REPO"

report
