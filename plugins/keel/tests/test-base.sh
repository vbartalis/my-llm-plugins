#!/usr/bin/env bash
# The base ref: what "the change" is measured against.
#
# Recorded, not inferred. Every git signal keel could derive this from is wrong
# in an ordinary case — most sharply a branch pushed with `git push -u`, which
# is its own upstream — and wrong silently, which is the failure mode this whole
# area exists to eliminate.

. "$(dirname "$0")/helpers.sh"

printf 'base ref\n'

# A repo with a trunk, a feature branch off it, and a workspace.
feature_repo() {
  local d; d="$(mktemp -d)"
  ( cd "$d" || exit 1
    git init -q -b trunk .
    git config user.email keel-tests@example.invalid
    git config user.name "keel tests"
    git config commit.gpgsign false
    mkdir -p .keel/checks apps/web docs/keel/features/2026-01-01-x
    printf 'seed\n' > README.md
    git add -A && git commit -qm seed
    git checkout -qb feature ) >/dev/null 2>&1
  printf '%s' "$d"
}

surface() {
  { printf '# Surface: x\n\n**Class:** boundary\n'
    [ -z "${1:-}" ] || printf '**Base:** %s\n' "$1"
    printf '\n## Watch\n\n```\napps/web/p.tsx\n```\n'
  } > "${REPO}/docs/keel/features/2026-01-01-x/surface.md"
  # Commit it, or the artifact itself counts as part of the change.
  ( cd "$REPO" && git add -A && git commit -qm surface ) >/dev/null 2>&1 || true
}

# --- recorded, and only recorded ---------------------------------------------

REPO="$(feature_repo)"
surface ""                       # a surface with no Base line

out="$(keel base 2>&1)"; rc=$?
assert_contains "with nothing recorded, there is no base" "$out" "base:   none"
assert_contains "and it says what to record"              "$out" '**Base:** <branch>'
assert_contains "and where"                               "$out" "in surface.md"
assert_rc "and reports failure" 1 "$rc"

surface trunk
out="$(keel base 2>&1)"; rc=$?
assert_contains "a recorded base resolves"    "$out" "base:   trunk"
assert_contains "and names surface.md as why" "$out" "from:   surface.md"
assert_rc "and reports success" 0 "$rc"

out="$(keel base --base HEAD 2>&1)"
assert_contains "--base overrides for one run" "$out" "from:   --base"

# A recorded base naming nothing is a defect in the artifact, not a fallback.
# It must stop every entry point: resolve_base runs inside command substitution,
# where an exit would end only the subshell.
surface no-such-branch
for cmd in "base" "check --changed" "participants --at build"; do
  out="$(keel $cmd 2>&1)"; rc=$?
  assert_contains "a bogus recorded base is named (${cmd})" "$out" "resolves to nothing in this repo"
  assert_rc "and exits 2 (${cmd})" 2 "$rc"
done
rm -rf "$REPO"

# --- keel infers nothing -----------------------------------------------------
#
# The regression that forced this design. Pushing a feature branch with -u makes
# it its own upstream; a resolver preferring the upstream computed a merge-base
# of the branch tip, so the entire change read as empty — the exact silent skip
# the base ref was added to prevent.

REPO="$(feature_repo)"
UP="$(mktemp -d)"; git init -q --bare -b trunk "$UP" >/dev/null 2>&1
( cd "$REPO"
  git remote add origin "$UP"
  git push -q -u origin trunk
  git remote set-head origin -a
  git checkout -q feature ) >/dev/null 2>&1
write_file apps/web/p.tsx 'x'
commit_all "the task commits"
( cd "$REPO" && git push -q -u origin feature ) >/dev/null 2>&1

surface ""
out="$(keel base 2>&1)"
assert_contains "an upstream is not treated as a base"  "$out" "base:   none"
assert_not_contains "nor is origin/HEAD"                "$out" "trunk"

surface trunk
out="$(keel base 2>&1)"
# Two: the app file and surface.md itself. Keel artifacts are committed and are
# part of the change by design, so they count.
assert_contains "with it recorded, a pushed branch still sees its change" "$out" "the change: 2 path(s)"
rm -rf "$REPO" "$UP"

# --- the change spans commits ------------------------------------------------

REPO="$(feature_repo)"
surface trunk
write_file apps/web/p.tsx 'x'
commit_all "the task commits"
out="$(keel base 2>&1)"
assert_contains "committed work counts as the change" "$out" "the change: 2 path(s)"

# A repo that does not branch is a supported workflow, not a misconfiguration.
surface none
out="$(keel base 2>&1)"; rc=$?
assert_contains "'none' is not treated as a ref" "$out" "base:   none"
assert_rc "and needs no fixing" 1 "$rc"
rm -rf "$REPO"

# --- warn only where it changes something ------------------------------------

REPO="$(feature_repo)"
surface ""
out="$(keel participants --at branch-review 2>&1)"
assert_not_contains "no base warning when nothing is path-scoped" "$out" "no base ref"
assert_contains     "and the participants still resolve"          "$out" "keel-code-review"

cat > "${REPO}/.keel/participants.json" <<'JSON'
[ { "id": "web", "kind": "reviewer", "agent": "x:y", "at": "branch-review",
    "when": { "paths": ["apps/web/**"] } } ]
JSON
out="$(keel participants --at branch-review 2>&1)"
assert_contains "the warning fires once something is path-scoped" "$out" "no base ref"

write_file .keel/checks/web.json '{"id":"web","description":"d","why":"w","command":"true","scope":["apps/web/**"],"severity":"blocking","layer":"repo"}'
out="$(keel check --changed 2>&1)"
assert_contains "check --changed always depends on it" "$out" "no base ref"
rm -rf "$REPO"

# --- the runner offers it at the one moment it is free -----------------------

REPO="$(feature_repo)"
out="$(keel workspace new some-change 2>&1)"
assert_contains "workspace new names the branch to record" "$out" '**Base:** feature'
assert_contains "and still prints the path on stdout"      "$(keel workspace new some-change 2>/dev/null)" "some-change"
rm -rf "$REPO"

report
