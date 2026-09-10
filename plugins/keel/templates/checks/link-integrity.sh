#!/usr/bin/env bash
# link-integrity: every relative link in a tracked markdown file resolves.
#
# Skips absolute URLs, mailto:, and bare anchors. Strips any #fragment before
# testing, so a link to a real file with a stale anchor still passes — anchors
# are not verifiable without parsing headings.

set -uo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root" || exit 2

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

while IFS= read -r md; do
  [ -f "$md" ] || continue
  dir="$(dirname "$md")"
  while IFS= read -r hit; do
    n="${hit%%:*}"
    raw="${hit#*:}"
    raw="${raw#](}"
    case "$raw" in
      http://*|https://*|mailto:*|'#'*|'') continue ;;
    esac
    target="${raw%%#*}"
    [ -n "$target" ] || continue
    case "$target" in
      /*) path=".$target" ;;
      *)  path="$dir/$target" ;;
    esac
    [ -e "$path" ] || printf '%s:%s: broken link -> %s\n' "$md" "$n" "$raw" >> "$tmp"
  done < <(grep -noE '\]\([^) ]+' "$md" 2>/dev/null || true)
done < <(git ls-files '*.md' 2>/dev/null)

if [ -s "$tmp" ]; then
  sed 's/^/link-integrity: /' "$tmp" >&2
  exit 1
fi
exit 0
