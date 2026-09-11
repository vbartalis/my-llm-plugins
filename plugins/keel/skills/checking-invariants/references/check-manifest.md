# Check Manifest Schema

`.keel/checks/<id>.json`

```json
{
  "id": "string, required, kebab-case, stable, matches filename",
  "description": "string, required, present tense, states what must be TRUE",
  "why": "string, required, the failure this prevents",
  "command": "string, required, shell command run from repo root",
  "scope": ["array of globs, required, relative to repo root"],
  "severity": "blocking | advisory, required",
  "layer": "string, required, provenance — see below",
  "fixHint": "string, optional, what a fix usually looks like"
}
```

## Field notes

**`id`** — plans reference it by this string in their `**Checks:**` lines.
Renaming an id breaks existing plans; treat it as a public name.

**`description`** — positive and present tense. "App code uses design tokens"
rather than "don't use raw colours". Positive statements are what the agent
tries to satisfy; negative ones only tell it what to avoid.

**`why`** — the single most important field for longevity. Every check will
one day be inconvenient. This is the sentence that stops it being deleted.

**`scope`** — the runner uses this for `--changed`, so it must be accurate. A
scope wider than the check's real reach makes `--changed` useless; a scope
narrower than its reach makes it silently skip.

**`severity`** — `blocking` fails a task in the build loop. `advisory` is
reported and appended to the ledger, and is reviewed at verification. Use
`advisory` only while a check is being introduced against existing violations;
promote it to `blocking` once the tree is clean, or delete it.

The two values are the whole set: a manifest with any other severity is reported
and skipped, because a check whose severity nobody can read is a check nobody
can act on.

**`layer`** — provenance, and the unit `keel check --layer` selects. Keel's four
conventional values are `constitution` (repo law), `contracts` and
`design-system` (reserved for the planned layers), and `repo` (everything else).

A repo may name its own — `infra`, `security`, `data` — and the runner will
group and filter by it. `--layer` naming a layer no check carries reports the
layers that do exist rather than running nothing and calling it a pass.

**`fixHint`** — surfaced to implementers when the check fails, so a fix round
starts from the right place. Optional, cheap, worth writing.

## What the runner guarantees your command

Keel runs a check's `command` itself rather than handing it to the harness, so
it owes you a stated envelope. You can rely on all of this:

| | |
|---|---|
| cwd | the repo root |
| stdin | `/dev/null` — never keel's own data |
| stdout + stderr | captured, not streamed; surfaced on failure |
| shell | a fresh one; keel's `set -uo pipefail` does not reach you |
| time | bounded (`--timeout`, default 120s); over it is `TIMEOUT`, not `FAIL` |
| result | your exit status, and nothing else |

The one thing keel cannot bound is what your command *spawns*. A backgrounded
child outlives the check and nothing in the conversation knows it exists, so a
check owns its children: do not background work from one.
