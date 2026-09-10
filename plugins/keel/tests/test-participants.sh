#!/usr/bin/env bash
# `keel participants`: registry validation, scoping, gates, and resolution.

. "$(dirname "$0")/helpers.sh"

printf 'keel participants\n'

surface() {
  local class="$1"; shift
  mkdir -p "${REPO}/docs/keel/features/2026-01-01-x"
  { printf '# Surface: x\n\n**Class:** %s\n\n## Watch\n\n```\n' "$class"
    printf '%s\n' "$@"
    printf '```\n'
  } > "${REPO}/docs/keel/features/2026-01-01-x/surface.md"
}

# --- usage ------------------------------------------------------------------

REPO="$(new_repo)"
out="$(keel participants --at nope 2>&1)"; rc=$?
assert_contains "an unknown point is named"      "$out" "unknown attachment point: nope"
assert_contains "and the valid ones are listed"  "$out" "branch-review"
assert_rc "and it exits 2" 2 "$rc"

out="$(keel participants --at build --class nope 2>&1)"; rc=$?
assert_contains "an unknown --class is rejected" "$out" "unknown class: nope"
assert_rc "and it exits 2" 2 "$rc"
rm -rf "$REPO"

# --- shipped defaults -------------------------------------------------------
#
# Every stage skill promises keel's own reviewers by name. A repo with no
# registry has to get them, or those promises are false.

REPO="$(new_repo)"
out="$(keel participants --at branch-review 2>&1)"
assert_contains "a repo with no registry gets the defaults" "$out" "keel-code-review"
assert_contains "and is told where they came from"          "$out" "using keel's shipped defaults"

printf '[]\n' > "${REPO}/.keel/participants.json"
out="$(keel participants --at branch-review 2>&1)"
assert_not_contains "an empty registry turns them off" "$out" "keel-code-review"
assert_not_contains "and is not called a default"      "$out" "shipped defaults"
rm -rf "$REPO"

# --- entry validation -------------------------------------------------------

REPO="$(new_repo)"
cat > "${REPO}/.keel/participants.json" <<'JSON'
[
  { "id": "no-target", "at": "build" },
  { "id": "bad-kind", "kind": "helper", "agent": "x:y", "at": "build" },
  { "id": "advisor-model", "kind": "advisor", "skill": "x:y", "at": "design", "model": "opus" },
  { "id": "odd-model", "kind": "reviewer", "agent": "x:y", "at": "verify", "model": "claude-something-new" },
  { "id": "fine", "kind": "reviewer", "agent": "x:y", "at": "verify" }
]
JSON
out="$(keel participants --at verify --all 2>&1)"
assert_contains "an entry with no target is rejected"  "$out" "no-target — needs id, at, and one of"
assert_contains "an unknown kind is rejected"          "$out" "bad-kind — kind must be"
assert_contains "an advisor with a model is rejected"  "$out" "advisor-model — advisors run in your context"
assert_contains "an unknown model warns"               "$out" "odd-model — model \"claude-something-new\""
assert_contains "and the unknown model still resolves" "$out" "claude-something-new"
assert_contains "a valid entry defaults to sonnet"     "$out" "fine"$'\t'"reviewer"$'\t'"agent"$'\t'"x:y"$'\t'"advisory"$'\t'"artifacts"$'\t'"sonnet"
rm -rf "$REPO"

# --- the class placeholder --------------------------------------------------
#
# The template ships all four options on one line. Reading only the first word
# turned that into `spike`, which silently skipped every class-scoped reviewer
# on the changes that need them most.

REPO="$(new_repo)"
cat > "${REPO}/.keel/participants.json" <<'JSON'
[ { "id": "heavy", "kind": "reviewer", "agent": "x:y", "at": "design-gate",
    "when": { "class": ["cross-app", "boundary"] } } ]
JSON
surface "spike | local | cross-app | boundary"
out="$(keel participants --at design-gate 2>&1)"; rc=$?
assert_contains "the unedited template line is an error" "$out" "surface.md Class is 'spike | local | cross-app | boundary'"
assert_contains "and says how to fix it"                 "$out" "pick one and delete the rest"
assert_rc "and exits 2 rather than resolving to spike" 2 "$rc"

surface "boundary"
out="$(keel participants --at design-gate 2>&1)"
assert_contains "a filled class resolves normally" "$out" "heavy"

surface "local"
out="$(keel participants --at design-gate 2>&1)"
assert_not_contains "and scopes the entry out when it does not apply" "$out" "heavy"
rm -rf "$REPO"

# --- gates are advisory -----------------------------------------------------

REPO="$(new_repo)"
cat > "${REPO}/.keel/participants.json" <<'JSON'
[ { "id": "g", "kind": "reviewer", "agent": "x:y", "at": "plan-gate",  "blocking": true },
  { "id": "t", "kind": "reviewer", "agent": "x:y", "at": "task-review", "blocking": true } ]
JSON
out="$(keel participants --at plan-gate --all 2>&1)"
assert_contains "a blocking gate entry is reported advisory" "$out" "g"$'\t'"reviewer"$'\t'"agent"$'\t'"x:y"$'\t'"advisory"
assert_contains "and the human is told they decide"          "$out" "the human decides"

out="$(keel participants --at task-review --all 2>&1)"
assert_contains "outside a gate blocking survives" "$out" "t"$'\t'"reviewer"$'\t'"agent"$'\t'"x:y"$'\t'"blocking"
rm -rf "$REPO"

# --- one implementer --------------------------------------------------------

REPO="$(new_repo)"
cat > "${REPO}/.keel/participants.json" <<'JSON'
[ { "id": "i1", "kind": "implementer", "agent": "a:b", "at": "build" },
  { "id": "i2", "kind": "implementer", "agent": "c:d", "at": "build" } ]
JSON
out="$(keel participants --at build 2>&1)"; rc=$?
assert_contains "two implementers is a config defect" "$out" "more than one implementer matches build"
assert_contains "and both are named"                  "$out" "i1, i2"
assert_rc "and it exits 2 rather than choosing" 2 "$rc"
rm -rf "$REPO"

# --- path scoping before a build (the Watch block) --------------------------

REPO="$(new_repo)"
cat > "${REPO}/.keel/participants.json" <<'JSON'
[ { "id": "web", "kind": "reviewer", "agent": "x:y", "at": "design-gate",
    "when": { "paths": ["apps/web/**"] } } ]
JSON
surface boundary "services/api/main.go"
out="$(keel participants --at design-gate 2>&1)"
assert_not_contains "a Watch block that misses the paths scopes it out" "$out" "web"

surface boundary "apps/web/page.tsx" "services/api/main.go"
out="$(keel participants --at design-gate 2>&1)"
assert_contains "a Watch block that names them scopes it in" "$out" "web"

surface boundary "# a comment, not a path"
out="$(keel participants --at design-gate 2>&1)"
assert_not_contains "a commented Watch line is not a path" "$out" "web"
rm -rf "$REPO"

# --- path scoping after a build (the same regression as check --changed) ----

REPO="$(new_repo)"
cat > "${REPO}/.keel/participants.json" <<'JSON'
[ { "id": "web", "kind": "reviewer", "agent": "x:y", "at": "branch-review",
    "when": { "paths": ["apps/web/**"] } },
  { "id": "api", "kind": "reviewer", "agent": "x:y", "at": "branch-review",
    "when": { "paths": ["services/api/**"] } } ]
JSON
commit_all "register participants"

write_file apps/web/page.tsx 'x'
out="$(keel participants --at branch-review --base base-ref 2>&1)"
assert_contains     "an in-scope reviewer resolves (uncommitted)" "$out" "web"
assert_not_contains "an out-of-scope one does not"                "$out" "api"

commit_all "the task commits"
out="$(keel participants --at branch-review --base base-ref 2>&1)"
assert_contains     "it still resolves after the commit" "$out" "web"
assert_not_contains "and the other still does not"       "$out" "api"

out="$(keel participants --at branch-review --base work 2>&1)"
assert_not_contains "working-tree-only scoping is what used to skip it" "$out" "web"
rm -rf "$REPO"

# --- prompt target resolution -----------------------------------------------

REPO="$(new_repo)"
cat > "${REPO}/.keel/participants.json" <<'JSON'
[ { "id": "keel-prompt", "kind": "reviewer", "prompt": "keel:skills/requesting-code-review/code-reviewer.md", "at": "verify" },
  { "id": "repo-prompt", "kind": "reviewer", "prompt": ".keel/prompts/mine.md", "at": "verify" },
  { "id": "missing",     "kind": "reviewer", "prompt": "nosuchplugin:prompts/x.md", "at": "verify" } ]
JSON
write_file .keel/prompts/mine.md 'review it'
out="$(keel participants --at verify --all 2>&1)"
assert_contains "a keel: prompt resolves to a real path" "$out" "${KEEL_PLUGIN_ROOT}/skills/requesting-code-review/code-reviewer.md"
assert_contains "a repo-relative prompt resolves too"    "$out" "${REPO}/.keel/prompts/mine.md"
assert_contains "an unresolvable prompt says so"         "$out" "cannot locate prompt 'nosuchplugin:prompts/x.md'"
assert_contains "and is still listed, as written"        "$out" "nosuchplugin:prompts/x.md"
rm -rf "$REPO"

report
