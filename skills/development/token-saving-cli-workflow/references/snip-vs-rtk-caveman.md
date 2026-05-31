# snip vs RTK/Caveman

Condensed research notes from evaluating:
- `edouard-claude/openclaw-snip`
- `edouard-claude/snip`
- local fork `Haku-token-saver`

## openclaw-snip

OpenClaw plugin that registers a `snip` tool.

### Architecture

Files:
```text
index.ts
src/tool.ts
openclaw.plugin.json
SKILL.md
```

Flow:
```text
agent -> snip tool -> snip binary -> shell command -> filtered output -> agent
```

`index.ts`:
- reads config `{ enabled?: boolean, snipPath?: string }`
- auto-detects `snip` via `which snip`
- if missing, registers degraded helper tool with install instructions
- if present, registers tool created by `createSnipTool(snipBin)`
- registers `/snip` status CLI command

`src/tool.ts`:
- exposes `snip(command, workdir?)`
- spawns `snip -- <command>`
- timeout: 120s
- max captured output: 10 MB
- combines stdout/stderr
- returns `isError` when exit code non-zero

### Adaptation lesson

Do not copy OpenClaw plugin code directly into Haku-token-saver. Hermes does not use the OpenClaw plugin API. Extract the concept:
- detect `snip`
- expose/encourage `snip <command>` usage
- provide install instructions if missing
- avoid silent no-op

## snip

CLI proxy written in Go for token-saving shell output filtering.

### Core traits

- 127 built-in YAML filters
- Declarative filter DSL, no compiled-code filter authoring
- Custom filters in `~/.config/snip/filters/` and optional project `.snip/`
- Graceful passthrough when no filter matches or filter errors
- Preserves exit codes
- Tracks savings via `snip gain`
- `snip discover` scans history for missed savings

### Common usage

```bash
snip git log -10
snip go test ./...
snip npm install
snip gain
snip discover
```

### Filter DSL shape

```yaml
name: "git-log"
version: 1
description: "Condense git log to hash + message"
match:
  command: "git"
  subcommand: "log"
  exclude_flags: ["--format", "--pretty", "--oneline"]
inject:
  args: ["--pretty=format:%h %s (%ar) <%an>", "--no-merges"]
  defaults:
    "-n": "10"
pipeline:
  - action: "keep_lines"
    pattern: "\\S"
  - action: "truncate_lines"
    max: 80
  - action: "format_template"
    template: "{{.count}} commits:\n{{.lines}}"
on_error: "passthrough"
```

### Pipeline actions to remember

- `keep_lines`, `remove_lines`
- `head`, `tail`, `dedup`
- `truncate_lines`, `strip_ansi`, `compact_path`
- `regex_extract`, `group_by`, `aggregate`
- `json_extract`, `json_schema`, `ndjson_stream`
- `state_machine`
- `format_template`
- `match_output`, `on_empty`

## Comparison

| Feature | snip | RTK + Caveman |
|---|---|---|
| Best role | General CLI filtering | Custom template/manual fallback |
| Coverage | 127+ built-in filters | Per-wrapper/template only |
| Extensibility | YAML filter files | JS templates + shell glue |
| Tracking | `snip gain` | `rtk gain` if RTK installed |
| Passthrough | Built in | Depends on wrapper |
| Install risk | `snip init` can be invasive | installer/scripts can be invasive |
| Project fit | Primary backend | fallback/demo backend |

## Integration guidance for Haku-token-saver

Recommended positioning:
```text
snip first, RTK/Caveman fallback.
```

Do:
- Add snip as optional backend in README/docs
- Detect `snip` in install script
- Print install instructions if missing
- Keep custom `.snip/` filters only when they add project-specific value
- Document when to bypass filtering

Do not:
- Auto-run `snip init`
- Chain `snip -> rtk -> caveman` by default
- Copy OpenClaw plugin TypeScript directly
- Overwrite user hook/config files

## Main risks

1. Double filtering can over-compress and hide debugging context.
2. Auto hooks (`snip init`) modify tool configs; require explicit user consent.
3. Shell quoting/wrapping must preserve exit codes and avoid command mangling.
4. Raw output recovery depends on snip tee config; do not assume always available.
5. Installing from source requires Go 1.25+; prefer binary/brew when possible.
