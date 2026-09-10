#!/usr/bin/env bash
# keel — repo wrapper. Locates the installed keel plugin and execs its runner.
#
# Installed by /keel:init. Committed to the repo so that plan steps, CI, and
# humans can all just run `scripts/keel` without knowing where the plugin lives.

set -euo pipefail

find_runner() {
  # 1. explicit override
  if [ -n "${KEEL_HOME:-}" ] && [ -x "${KEEL_HOME}/scripts/keel" ]; then
    printf '%s' "${KEEL_HOME}/scripts/keel"; return 0
  fi
  # 2. plugin root, when invoked from a context that sets it
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -x "${CLAUDE_PLUGIN_ROOT}/scripts/keel" ]; then
    printf '%s' "${CLAUDE_PLUGIN_ROOT}/scripts/keel"; return 0
  fi
  # 3. installed plugin cache — newest match wins
  local base="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins"
  local hit
  hit="$(find "$base" -type f -path '*/keel/scripts/keel' -perm -u+x 2>/dev/null \
         | sort -r | head -1)"
  [ -n "$hit" ] && { printf '%s' "$hit"; return 0; }
  # 4. development checkout next to this repo
  local here; here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  [ -x "${here}/plugins/keel/scripts/keel" ] && { printf '%s' "${here}/plugins/keel/scripts/keel"; return 0; }
  return 1
}

runner="$(find_runner)" || {
  cat >&2 <<'MSG'
keel: cannot find the keel plugin runner.

Install the plugin, or set KEEL_HOME to the plugin directory:

  export KEEL_HOME=/path/to/plugins/keel
MSG
  exit 2
}

exec "$runner" "$@"
