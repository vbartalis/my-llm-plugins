#!/usr/bin/env bash
# `keel workspace`, and the runner's own shape.

. "$(dirname "$0")/helpers.sh"

printf 'keel workspace\n'

REPO="$(new_repo)"

out="$(keel workspace current 2>&1)"; rc=$?
assert_contains "an empty repo says where to start" "$out" "/keel:orient"
assert_rc "and exits non-zero" 1 "$rc"

out="$(keel workspace new 'Not Kebab' 2>&1)"; rc=$?
assert_contains "a non-kebab slug is rejected" "$out" "slug must be kebab-case"
assert_rc "and exits 2" 2 "$rc"

out="$(keel workspace new invoice-currency 2>&1)"
assert_contains "a workspace is dated and slugged" "$out" "$(date +%Y-%m-%d)-invoice-currency"

out="$(keel workspace current 2>&1)"
assert_contains "and becomes the current one" "$out" "invoice-currency"

# Two on the same day must still resolve to the one most recently worked in.
keel workspace new second-change >/dev/null 2>&1
touch "${REPO}/docs/keel/features/$(date +%Y-%m-%d)-second-change"
out="$(keel workspace current 2>&1)"
assert_contains "the newest workspace wins" "$out" "second-change"

out="$(keel workspace list 2>&1)"
assert_contains "list shows the first"  "$out" "invoice-currency"
assert_contains "list shows the second" "$out" "second-change"
rm -rf "$REPO"

printf 'runner shape\n'

out="$(bash -n "$KEEL" 2>&1)"; rc=$?
assert_rc "the runner parses" 0 "$rc"

out="$("$KEEL" help 2>&1)"
assert_contains "help documents workspace"    "$out" "keel workspace new"
assert_contains "help documents check"        "$out" "keel check"
assert_contains "help documents participants" "$out" "keel participants"
assert_contains "help documents --base"       "$out" "--base <ref>"
assert_not_contains "help stops at the marker" "$out" "END-HELP"

out="$("$KEEL" nonsense 2>&1)"; rc=$?
assert_contains "an unknown command is named" "$out" "unknown command: nonsense"
assert_rc "and exits 2" 2 "$rc"

# Only one executable ships, and it depends on bash plus jq or python3.
found="$(find "${KEEL_PLUGIN_ROOT}/scripts" -type f -perm -u+x | wc -l)"
assert_rc "scripts/ holds exactly one executable" 1 "$found"
rm -rf "$REPO"

report
