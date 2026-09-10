# my-llm-plugins

Claude Code plugin marketplace.

| Plugin | What it is |
|--------|------------|
| [keel](plugins/keel/) | Process spine for a polyglot monorepo: orient → design → plan → build → verify → ship, with invariants that are checked rather than merely written down. |

## Use

```
/plugin marketplace add vbartalis/my-llm-plugins
/plugin install keel
```

Then, in the target repo, `/keel:init`.
