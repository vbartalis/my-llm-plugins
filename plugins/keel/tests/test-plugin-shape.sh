#!/usr/bin/env bash
# The plugin's contract with the harness: frontmatter, hooks, and the guard.
#
# `claude plugin validate` covers the manifests. Nothing covers the component
# files, and everything here fails silently: an agent with no `model` inherits
# the coordinator's, a command with no `description` is invisible to the model,
# a hook that emits malformed JSON injects nothing at all.

. "$(dirname "$0")/helpers.sh"

printf 'plugin shape\n'

P="$KEEL_PLUGIN_ROOT"

# Value of a frontmatter key, from the first ten lines only — frontmatter is at
# the top, and a body line that looks like `key: value` is not frontmatter.
fm() { sed -n "1,10p" "$1" | sed -n "s/^$2: *//p" | head -1; }

# --- agents -----------------------------------------------------------------

for f in "$P"/agents/*.md; do
  a="$(basename "$f" .md)"
  [ -n "$(fm "$f" name)" ]        && _pass "agent ${a} declares a name"        || _fail "agent ${a} declares a name" "no name in frontmatter"
  [ -n "$(fm "$f" description)" ] && _pass "agent ${a} declares a description" || _fail "agent ${a} declares a description" "no description"
  [ -n "$(fm "$f" tools)" ]       && _pass "agent ${a} restricts its tools"    || _fail "agent ${a} restricts its tools" "no tools list — it would get everything"

  # The registry decides the model and the coordinator passes it. Frontmatter
  # is the floor under a dispatch that forgets: without it, a forgotten model
  # inherits the coordinator's, which is the expensive default the registry
  # exists to prevent.
  m="$(fm "$f" model)"
  [ -n "$m" ] && _pass "agent ${a} names a model floor" || _fail "agent ${a} names a model floor" "no model — a dispatch that forgets inherits the coordinator's"

  # frontmatter name must match the filename, or `keel:<file>` resolves to
  # nothing while the docs keep saying it does.
  [ "$(fm "$f" name)" = "$a" ] && _pass "agent ${a} name matches its filename" || _fail "agent ${a} name matches its filename" "frontmatter says '$(fm "$f" name)'"
done

# A reviewer that can write is not a reviewer. This is the one tool rule worth
# asserting: keel's whole review model rests on reviewers judging, not fixing.
for a in task-reviewer invariant-reviewer; do
  t="$(fm "$P/agents/${a}.md" tools)"
  case "$t" in
    *Write*|*Edit*) _fail "${a} cannot write" "tools include Write/Edit: ${t}" ;;
    *) _pass "${a} cannot write" ;;
  esac
done

t="$(fm "$P/agents/implementer.md" tools)"
case "$t" in
  *Write*) _pass "implementer can write" ;;
  *) _fail "implementer can write" "tools are ${t} — it has to produce code" ;;
esac

# --- commands ---------------------------------------------------------------

for f in "$P"/commands/*.md; do
  c="$(basename "$f" .md)"
  [ -n "$(fm "$f" description)" ] && _pass "/keel:${c} declares a description" || _fail "/keel:${c} declares a description" "no description — the model cannot route to it"
done

# Side effects stay user-initiated. The stage chain invokes skills, not
# commands, so this costs the pipeline nothing.
for c in init ship; do
  [ "$(fm "$P/commands/${c}.md" disable-model-invocation)" = "true" ] \
    && _pass "/keel:${c} is user-initiated" \
    || _fail "/keel:${c} is user-initiated" "disable-model-invocation is not true, and this command has side effects"
done

# Shell injection in a command body runs before anyone sees it, and a
# model-invocable command's arguments can be composed by the model. Keel injects
# only where the command takes no arguments.
for f in "$P"/commands/*.md; do
  c="$(basename "$f" .md)"
  if grep -q '^!`' "$f" && grep -q '\$ARGUMENTS' "$f"; then
    grep -q '^!`.*\$ARGUMENTS' "$f" \
      && _fail "/keel:${c} does not shell-inject its arguments" "an injected line interpolates \$ARGUMENTS" \
      || _pass "/keel:${c} does not shell-inject its arguments"
  else
    _pass "/keel:${c} does not shell-inject its arguments"
  fi
done

# --- skills -----------------------------------------------------------------

for d in "$P"/skills/*/; do
  s="$(basename "$d")"
  f="${d}SKILL.md"
  [ -f "$f" ] || { _fail "skill ${s} has a SKILL.md" "missing ${f}"; continue; }
  [ "$(fm "$f" name)" = "$s" ] && _pass "skill ${s} name matches its directory" || _fail "skill ${s} name matches its directory" "frontmatter says '$(fm "$f" name)'"

  # A description that summarises the workflow gives the model a shortcut it
  # takes instead of reading the skill.
  d_="$(fm "$f" description)"
  case "$d_" in
    "Use when"*) _pass "skill ${s} description states a trigger" ;;
    *) _fail "skill ${s} description states a trigger" "starts with: ${d_}" ;;
  esac
done

# Exactly one skill is resident. A second is a design change, not an edit.
resident="$(grep -c 'skills/using-keel/SKILL.md' "$P/hooks/session-start")"
[ "$resident" -ge 1 ] && _pass "the hook injects using-keel" || _fail "the hook injects using-keel" "found no reference"
others="$(grep -oE 'skills/[a-z-]+/SKILL\.md' "$P/hooks/session-start" | sort -u | grep -cv using-keel)"
assert_rc "the hook injects nothing else" 0 "$others"

# --- the resident skill carries its own minimum ------------------------------
#
# Every other instruction in keel resolves to a file, a command, or a shipped
# default. The bug-routing bullet once delegated its entire payload to "whatever
# debugging skill this environment has", which in a repo with none resolved to
# nothing — the only no-op instruction in the plugin.

router="$P/skills/using-keel/SKILL.md"
while IFS= read -r beat; do
  [ -n "$beat" ] || continue
  grep -qF "$beat" "$router" \
    && _pass "bug routing carries: ${beat}" \
    || _fail "bug routing carries: ${beat}" "the resident skill does not say it"
done <<'BEATS'
Reproduce it.
Narrow it.
Name the cause in one sentence
Re-enter at `orienting`
BEATS
grep -qF "Prefer any debugging skill this" "$router" \
  && _pass "and still prefers an installed debugging skill" \
  || _fail "and still prefers an installed debugging skill" "keel would be claiming the tactic outright"

# --- the hook ---------------------------------------------------------------

# A bare directory, not new_repo — new_repo creates .keel/, which is precisely
# the marker the guard looks for.
REPO="$(mktemp -d)"

# Guarded: a repo that has not run /keel:init gets nothing. Without this the
# router claims "this repository is built with keel" in every repo on the machine.
out="$(CLAUDE_PROJECT_DIR="$REPO" bash "$P/hooks/session-start" 2>&1)"; rc=$?
assert_rc "the hook stays quiet in a non-keel repo" 0 "$rc"
[ -z "$out" ] && _pass "and emits nothing" || _fail "and emits nothing" "got: $(printf '%s' "$out" | head -c 120)"

# Each of the three markers /keel:init leaves behind turns it on by itself.
for marker in .keel scripts/keel docs/keel; do
  probe="$(mktemp -d)"; mkdir -p "$(dirname "${probe}/${marker}")"; touch "${probe}/${marker}"
  out="$(CLAUDE_PROJECT_DIR="$probe" bash "$P/hooks/session-start" 2>&1)"
  assert_contains "the hook fires on ${marker}" "$out" "hookSpecificOutput"
  rm -rf "$probe"
done

mkdir -p "${REPO}/.keel"
out="$(CLAUDE_PROJECT_DIR="$REPO" bash "$P/hooks/session-start" 2>&1)"
assert_contains "the hook fires once .keel/ exists" "$out" "hookSpecificOutput"

if command -v jq >/dev/null 2>&1; then
  ev="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.hookEventName' 2>&1)"
  assert_contains "and emits parseable JSON with the right event" "$ev" "SessionStart"
  ctx="$(printf '%s' "$out" | jq -r '.hookSpecificOutput.additionalContext' 2>/dev/null)"
  assert_contains "carrying the router's own text" "$ctx" "The Stage Map"
  assert_contains "and the subagent stop-clause"   "$ctx" "SUBAGENT-STOP"
fi

# Every source a session can start from. Missing one does not degrade
# gracefully — that session simply has no stage map.
matcher="$(jq -r '.hooks.SessionStart[0].matcher' "$P/hooks/hooks.json" 2>/dev/null)"
for src in startup resume clear compact fork; do
  case "|${matcher}|" in
    *"|${src}|"*) _pass "SessionStart covers ${src}" ;;
    *) _fail "SessionStart covers ${src}" "matcher is '${matcher}'" ;;
  esac
done

# The hook must block, or the first turn happens before the map arrives.
[ "$(jq -r '.hooks.SessionStart[0].hooks[0].async' "$P/hooks/hooks.json")" = "false" ] \
  && _pass "the hook is synchronous" \
  || _fail "the hook is synchronous" "async is not false — the first turn could start without the map"

rm -rf "$REPO"

# --- deliberate non-use -----------------------------------------------------
#
# Keel ships no MCP server, no user config, no workflows and no output styles,
# and depends on no other plugin. Each of those is a real extension point that
# would put keel's behaviour somewhere other than the repo, where a repo's own
# rules could not reach it. Asserting their absence keeps that a decision.

for absent in .mcp.json .lsp.json workflows output-styles; do
  [ ! -e "$P/$absent" ] && _pass "ships no ${absent}" || _fail "ships no ${absent}" "it exists — was that deliberate?"
done

for field in mcpServers userConfig dependencies workflows outputStyles; do
  v="$(jq -r --arg f "$field" 'has($f)' "$P/.claude-plugin/plugin.json")"
  [ "$v" = "false" ] && _pass "the manifest declares no ${field}" || _fail "the manifest declares no ${field}" "it is present — was that deliberate?"
done

report
