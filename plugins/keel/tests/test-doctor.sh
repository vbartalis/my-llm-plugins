#!/usr/bin/env bash
# `keel doctor`: does this repo's keel setup hold, right now?
#
# Present tense by design. Keel records no version and keeps no history of what
# it changed between releases, so "is this repo behind" is unanswerable and
# unasked. Everything here is decided by looking at what exists today.
#
# The distinction the tests defend: BROKEN means something does not work and
# gets fixed; differs means this repo and this keel disagree, and only a human
# knows which is right.

. "$(dirname "$0")/helpers.sh"

printf 'doctor\n'

# A repo set up with keel some time ago, then lived in.
aged_repo() {
  local d; d="$(mktemp -d)"
  ( cd "$d" || exit 1
    git init -q -b trunk .
    git config user.email keel-tests@example.invalid
    git config user.name "keel tests"
    git config commit.gpgsign false
    mkdir -p .keel/checks scripts/checks docs/keel/features
    cp "${KEEL_PLUGIN_ROOT}/templates/keel-wrapper.sh" scripts/keel
    chmod +x scripts/keel
    cp "${KEEL_PLUGIN_ROOT}/templates/participants.json" .keel/participants.json
    printf '# Repo\n\nThis repo uses keel.\n' > CLAUDE.md
    printf '# Constitution\n' > docs/keel/constitution.md
    cp "${KEEL_PLUGIN_ROOT}/templates/checks/link-integrity.sh"   scripts/checks/
    cp "${KEEL_PLUGIN_ROOT}/templates/checks/link-integrity.json" .keel/checks/
    chmod +x scripts/checks/link-integrity.sh
    printf 'seed\n' > README.md
    git add -A && git commit -qm seed ) >/dev/null 2>&1
  printf '%s' "$d"
}

# --- a healthy repo ---------------------------------------------------------

REPO="$(aged_repo)"
out="$(KEEL_HOME="$KEEL_PLUGIN_ROOT" keel doctor 2>&1)"; rc=$?
assert_contains "a sound setup says so"        "$out" "keel holds here."
assert_not_contains "and reports nothing broken" "$out" "BROKEN"
assert_rc "and exits 0" 0 "$rc"
rm -rf "$REPO"

# --- broken: things that do not work today ----------------------------------

REPO="$(aged_repo)"
write_file .keel/checks/lint.json '{"id":"lint","description":"d","why":"w","command":"scripts/checks/lint.sh","scope":["**/*"],"severity":"blocking","layer":"repo"}'
out="$(KEEL_HOME="$KEEL_PLUGIN_ROOT" keel doctor 2>&1)"; rc=$?
assert_contains "a check whose command is gone is broken" "$out" "lint: 'scripts/checks/lint.sh' does not exist"
assert_rc "and doctor exits 1" 1 "$rc"

write_file scripts/checks/lint.sh '#!/usr/bin/env bash'
out="$(KEEL_HOME="$KEEL_PLUGIN_ROOT" keel doctor 2>&1)"
assert_contains "a check command that is not executable is broken" "$out" "is not executable"
( cd "$REPO" && chmod +x scripts/checks/lint.sh )
out="$(KEEL_HOME="$KEEL_PLUGIN_ROOT" keel doctor 2>&1)"
assert_contains "and fine once it can run" "$out" "lint can run"
rm -rf "$REPO"

# A registry that leaves a stage with nobody to dispatch.
REPO="$(aged_repo)"
cat > "${REPO}/.keel/participants.json" <<'JSON'
[ { "id": "only-build", "kind": "implementer", "agent": "keel:implementer", "at": "build" } ]
JSON
out="$(KEEL_HOME="$KEEL_PLUGIN_ROOT" keel doctor 2>&1)"
assert_contains "nothing at task-review is broken"   "$out" "nothing at 'task-review'"
assert_contains "and says what it costs"             "$out" "built and never reviewed"
assert_contains "nothing at branch-review is broken" "$out" "nothing at 'branch-review'"
assert_contains "a present implementer is fine"      "$out" "1 at build"

# A keel: target this version does not ship is a dangling reference.
cat > "${REPO}/.keel/participants.json" <<'JSON'
[ { "id": "gone", "kind": "reviewer", "prompt": "keel:skills/removed/old.md", "at": "verify" },
  { "id": "noagent", "kind": "reviewer", "agent": "keel:no-such-agent", "at": "verify" } ]
JSON
out="$(KEEL_HOME="$KEEL_PLUGIN_ROOT" keel doctor 2>&1)"
assert_contains "a dangling keel prompt is broken" "$out" "prompt 'keel:skills/removed/old.md' does not resolve"
assert_contains "a missing keel agent is broken"   "$out" "keel has no agent 'no-such-agent'"
rm -rf "$REPO"

# --- differs: this repo and this keel disagree ------------------------------
#
# Not defects. Keel cannot tell its own change from the repo's deliberate one,
# so it says what it sees and stops.

REPO="$(aged_repo)"
write_file scripts/checks/link-integrity.sh '#!/usr/bin/env bash'
write_file .keel/checks/link-integrity.json '{"id":"link-integrity","description":"d","why":"w","command":"scripts/checks/link-integrity.sh","scope":["**/*.md"],"severity":"advisory","layer":"repo"}'
( cd "$REPO" && chmod +x scripts/checks/link-integrity.sh )
out="$(KEEL_HOME="$KEEL_PLUGIN_ROOT" keel doctor 2>&1)"; rc=$?
assert_contains "a retuned shipped check reads as a difference" "$out" "differs"
assert_contains "and names both sides as candidates"            "$out" "yours or ours, you decide"
assert_not_contains "and is not called broken"                  "$out" "BROKEN"
assert_rc "differences alone do not fail" 0 "$rc"
assert_contains "and the summary explains why keel will not choose" "$out" "cannot tell"

# A participant keel ships that this registry does not carry is an offer.
cat > "${REPO}/.keel/participants.json" <<'JSON'
[ { "id": "keel-implementer",  "kind": "implementer", "agent": "keel:implementer",  "at": "build" },
  { "id": "keel-task-review",  "kind": "reviewer",    "agent": "keel:task-reviewer", "at": "task-review" },
  { "id": "keel-code-review",  "kind": "reviewer",    "prompt": "keel:skills/requesting-code-review/code-reviewer.md", "at": "branch-review" } ]
JSON
out="$(KEEL_HOME="$KEEL_PLUGIN_ROOT" keel doctor 2>&1)"
assert_contains "a participant keel ships but the repo lacks is a difference" "$out" "keel ships a participant"
assert_contains "phrased as a choice, not an omission"                        "$out" "or decide you do not want it"

# A plugin someone else's entry needs, absent from this machine.
cat > "${REPO}/.keel/participants.json" <<'JSON'
[ { "id": "keel-implementer", "kind": "implementer", "agent": "keel:implementer", "at": "build" },
  { "id": "keel-task-review", "kind": "reviewer", "agent": "keel:task-reviewer", "at": "task-review" },
  { "id": "keel-code-review", "kind": "reviewer", "agent": "keel:invariant-reviewer", "at": "branch-review" },
  { "id": "ux", "kind": "reviewer", "agent": "no-such-plugin:ux", "at": "branch-review" } ]
JSON
out="$(KEEL_HOME="$KEEL_PLUGIN_ROOT" keel doctor 2>&1)"
assert_contains "an uninstalled plugin is a difference, not a break" "$out" "plugin 'no-such-plugin' is not installed here"
assert_contains "and the entry is left standing"                     "$out" "the entry stays"
rm -rf "$REPO"

# --- feature workspaces are reported, never corrected -----------------------
#
# Every artifact under docs/keel/features/ passed a gate. An artifact a human
# approved is not keel's to rewrite because the plugin moved on.

REPO="$(aged_repo)"
mkdir -p "${REPO}/docs/keel/features/2026-01-01-old"
printf '# Surface\n\n**Class:** boundary\n' > "${REPO}/docs/keel/features/2026-01-01-old/surface.md"
before="$(cat "${REPO}/docs/keel/features/2026-01-01-old/surface.md")"
out="$(KEEL_HOME="$KEEL_PLUGIN_ROOT" keel doctor 2>&1)"
assert_contains "a workspace with no Base is reported"      "$out" "no Base recorded"
assert_contains "in terms of what it costs now"             "$out" "uncommitted work only"
assert_contains "and a valid class is reported as fine"     "$out" "class boundary"
after="$(cat "${REPO}/docs/keel/features/2026-01-01-old/surface.md")"
[ "$before" = "$after" ] && _pass "doctor did not touch the artifact" || _fail "doctor did not touch the artifact" "surface.md was modified"

printf '# Surface\n\n**Class:** spike | local | cross-app | boundary\n' > "${REPO}/docs/keel/features/2026-01-01-old/surface.md"
out="$(KEEL_HOME="$KEEL_PLUGIN_ROOT" keel doctor 2>&1)"; rc=$?
assert_contains "an unreadable class is broken, not a difference" "$out" "which is not a class"
assert_rc "and fails" 1 "$rc"
rm -rf "$REPO"

# --- doctor never writes ----------------------------------------------------

REPO="$(aged_repo)"
before="$( cd "$REPO" && git status --porcelain; find . -path ./.git -prune -o -type f -print | sort )"
KEEL_HOME="$KEEL_PLUGIN_ROOT" keel doctor >/dev/null 2>&1
after="$( cd "$REPO" && git status --porcelain; find . -path ./.git -prune -o -type f -print | sort )"
[ "$before" = "$after" ] && _pass "doctor changes nothing at all" || _fail "doctor changes nothing at all" "the tree differs after running it"
rm -rf "$REPO"

# --- it records no version --------------------------------------------------
#
# The constraint this whole design is built around. If a version marker ever
# appears, the upgrade story has quietly become a migration.

grep -rqiE '\.keel/(version|installed)|keel\.version|INSTALLED_VERSION' "$KEEL_PLUGIN_ROOT/scripts/keel" \
  && _fail "the runner records no version" "found a version marker" \
  || _pass "the runner records no version"

grep -q "records no version" "$KEEL_PLUGIN_ROOT/commands/init.md" \
  && _pass "init states that keel records no version" \
  || _fail "init states that keel records no version" "the constraint is not written down where the agent reads it"

# The word appears only to deny the concept. Any instruction to look one up,
# compare two, or act on the gap between them is the migration model returning.
grep -qiE "(which|previous|installed|last|target) version|version (file|marker|number|history)|upgrade from" \
  "$KEEL_PLUGIN_ROOT/commands/init.md" \
  && _fail "init never looks a version up" "init.md reasons about a specific version" \
  || _pass "init never looks a version up"

report
