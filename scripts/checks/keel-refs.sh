#!/usr/bin/env bash
# keel-refs: every keel: skill, agent, and /keel: command named in the docs exists.
#
# The plugin's own documentation refers to its skills, agents, and commands by
# name. An agent is nameable wherever a participant entry is shown, so the three
# namespaces resolve together.
# Renaming or removing one leaves those references pointing at nothing, and
# nothing else in the repo notices.

set -uo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root" || exit 2

PLUGIN="plugins/keel"
[ -d "$PLUGIN" ] || { printf 'keel-refs: %s not found\n' "$PLUGIN" >&2; exit 2; }

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# Command basenames are legitimate after "keel:" too, because "/keel:orient"
# contains "keel:orient". Treat any name with a command file as resolved.
commands="$(find "$PLUGIN/commands" -name '*.md' -exec basename {} .md \; 2>/dev/null | tr '\n' ' ')"

# Agent basenames resolve too: a participant entry names one as "keel:<agent>",
# and the docs show those entries verbatim.
agents="$(find "$PLUGIN/agents" -name '*.md' -exec basename {} .md \; 2>/dev/null | tr '\n' ' ')"

while IFS= read -r hit; do
  file="${hit%%:*}"; rest="${hit#*:}"
  line="${rest%%:*}"; name="${rest#*:}"
  name="${name#keel:}"
  # "keel:skills/..." is a plugin-relative prompt path, not a skill name
  case "$name" in */*) continue ;; esac
  [ -n "$name" ] || continue
  [ -d "$PLUGIN/skills/$name" ] && continue
  case " $commands " in *" $name "*) continue ;; esac
  case " $agents "   in *" $name "*) continue ;; esac
  printf '%s:%s: keel:%s names no skill, agent, or command\n' "$file" "$line" "$name" >> "$tmp"
done < <(git ls-files '*.md' | xargs -r grep -noE 'keel:[a-z][a-z0-9-]*(/[a-z0-9./-]*)?' 2>/dev/null)

while IFS= read -r hit; do
  file="${hit%%:*}"; rest="${hit#*:}"
  line="${rest%%:*}"; name="${rest#*:}"
  name="${name#/keel:}"
  [ -f "$PLUGIN/commands/$name.md" ] && continue
  printf '%s:%s: /keel:%s names no command\n' "$file" "$line" "$name" >> "$tmp"
done < <(git ls-files '*.md' | xargs -r grep -noE '/keel:[a-z][a-z0-9-]*' 2>/dev/null)

# Vocabulary from superseded models. Keeping the old words alive teaches the
# old model to whoever reads next.
while IFS= read -r hit; do
  file="${hit%%:*}"; rest="${hit#*:}"; line="${rest%%:*}"
  case "$file" in */extension-points.md) continue ;; esac
  printf '%s:%s: "socket" is 0.1.0 vocabulary — the model is checks and participants\n' "$file" "$line" >> "$tmp"
done < <(git ls-files '*.md' | xargs -r grep -nioE 'socket' 2>/dev/null)

if [ -s "$tmp" ]; then
  sed 's/^/keel-refs: /' "$tmp" >&2
  exit 1
fi
exit 0
