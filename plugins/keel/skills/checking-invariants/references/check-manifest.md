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
  "layer": "constitution | contracts | design-system | repo, required",
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

**`layer`** — provenance. `constitution` checks come from repo law.
`contracts` and `design-system` are reserved for the planned layers. `repo`
is everything else. The runner groups output by layer.

**`fixHint`** — surfaced to implementers when the check fails, so a fix round
starts from the right place. Optional, cheap, worth writing.
