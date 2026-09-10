# Constitution

Repo law for `my-llm-plugins`. Every keel stage reads this and treats it as
outranking its own output.

This repo is a Claude Code plugin marketplace. Its one substantial plugin is
`keel`, which means the repo runs the process it ships — every clause below is
something that was already true and is now checkable.

---

## Boundaries

A plugin owns everything under `plugins/<name>/`. Nothing outside that directory
is imported by it, and nothing inside it reaches out — a plugin is installed on
its own, without the rest of this repo.

Repo-level files (`.claude-plugin/marketplace.json`, `scripts/`, `.keel/`) exist
to run and test the plugins. They are never a dependency of one.

*Rubric*

## Shapes

`plugins/keel/templates/` is authoritative for every file `/keel:init` installs.
Where this repo runs an installed copy, the template is the source of truth and
the copy follows.

*Check:* `template-drift`

## Versions And Dependencies

Keel's runner depends on `bash`, plus `jq` or `python3` for JSON. Nothing else.
No package manager, no runtime, no vendored library — a process spine that
cannot run until you install something is a spine nobody starts with.

Keel targets Claude Code and nothing else. Compatibility shims, manifests, or
prose for other harnesses do not belong here.

The plugin manifest and the marketplace entry carry the same version. A release
bumps both or neither.

*Check:* `plugin-manifests` · *Rubric*

## The Harness Surface

Keel extends Claude Code through skills, agents, commands, one `SessionStart`
hook, and one script. It ships no MCP server, no `userConfig`, no plugin
dependencies, no workflows and no output styles — each of those would put
keel's behaviour somewhere a repo's own rules cannot reach.

The hook covers every session source and injects exactly one skill. A source it
does not cover is a session with no stage map, which is invisible until someone
notices the process was improvised.

*Check:* `plugin-manifests`, `keel-tests`

## Testing

Behaviour a command can decide has a test in `plugins/keel/tests/` before it
lands. That covers the runner: parsing, validation, scoping, resolution.

Skills are not unit-tested. They are tested by running the stage on a real
change and watching where the agent argues with the instructions — a skill that
gets rationalised past has a missing red-flag row. Record what you ran.

*Check:* `keel-tests` · *Rubric*

## Naming And Copy

Every `keel:` skill, agent, and `/keel:` command named in the documentation
resolves to something that exists. Vocabulary from a superseded version of the
model does not survive in prose.

Every relative link in a tracked markdown file resolves.

*Check:* `keel-refs`, `link-integrity`

## Documentation

Every rule states the failure it prevents. A red-flag row, a check's `why`, a
stage's reason for existing — each names what goes wrong without it. A rule with
no named failure gets deleted the first time it is inconvenient, so it may as
well not be written.

Instructions are positive. "App code uses design tokens" outperforms "don't use
raw colours"; write what should be true.

*Rubric*

## Migrations And Data

Keel writes only inside `docs/keel/` and `.keel/` in a target repo, and only
files it created. It never rewrites a repo's own files without saying so —
`/keel:init` merges into `CLAUDE.md` rather than replacing it.

*Rubric*

---

## Amendments

**2026-09-10** — First version. Derived from `plugins/keel/CLAUDE.md` and from
the checks already registered, rather than written fresh: every clause was
already being enforced by hand or by a check, and this records which.
