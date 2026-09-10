#!/usr/bin/env bash
# plugin-manifests: the plugin and marketplace manifests are valid and agree.
#
# Three things rot silently here. A manifest field can be misspelled and the
# plugin still loads, minus whatever the field configured. The plugin version
# and the marketplace entry's version can drift, and users then install a
# version that says it is something else. And a hook can stop matching a
# session source, which costs nothing visible until the session it was supposed
# to cover starts without it.

set -uo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root" || exit 2

PLUGIN="plugins/keel"
MARKET=".claude-plugin/marketplace.json"
fail=0

say() { printf 'plugin-manifests: %s\n' "$*" >&2; fail=1; }

# 1. Both manifests pass the harness's own validator, warnings included.
if ! command -v claude >/dev/null 2>&1; then
  say "the claude CLI is not on PATH — it is what validates these manifests"
  exit 1
fi

for target in "$PLUGIN" .; do
  if ! out="$(claude plugin validate "$target" --strict 2>&1)"; then
    say "claude plugin validate ${target} --strict failed:"
    printf '%s\n' "$out" | sed 's/^/plugin-manifests:   /' >&2
  fi
done

# 2. The two version strings agree. `claude plugin tag` enforces this at release
#    time; enforcing it here means a bump cannot be half-done on main.
pv="$(jq -r '.version // ""' "${PLUGIN}/.claude-plugin/plugin.json" 2>/dev/null)"
mv="$(jq -r --arg n keel '.plugins[] | select(.name == $n) | .version // ""' "$MARKET" 2>/dev/null)"
if [ -z "$pv" ]; then
  say "plugin.json has no version"
elif [ -n "$mv" ] && [ "$pv" != "$mv" ]; then
  say "version drift: plugin.json says ${pv}, the marketplace entry says ${mv}"
fi

# 3. The SessionStart hook covers every source a session can start from.
#    Omitting one does not degrade gracefully — that session simply has no
#    stage map, and improvises the process keel exists to stop it improvising.
matcher="$(jq -r '.hooks.SessionStart[0].matcher // ""' "${PLUGIN}/hooks/hooks.json" 2>/dev/null)"
for src in startup resume clear compact fork; do
  case "|${matcher}|" in
    *"|${src}|"*) ;;
    *) say "the SessionStart matcher does not cover '${src}' — a ${src} session would start with no stage map" ;;
  esac
done

exit "$fail"
