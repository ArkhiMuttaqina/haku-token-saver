# Haku Token Saver

Token-saving toolkit for agentic coding workflows.

`hts` is a small orchestrator that wraps:

- `snip` for command-aware output filters
- `rtk` as fallback compression path
- `caveman`-style template workflows for structured summaries

Backend priority:

```text
snip > rtk > raw-limited
```

`raw-limited` is the safe fallback. If `snip`, `rtk`, or a command filter is unavailable, `hts` still runs the command but caps output by line and byte limits, then reports fallback metadata.

`hts` does not replace upstream tools. It routes to them, picks filters, and adds workflow commands useful for AI agents.

---

## What this repo is for

Use this when your AI agent keeps wasting tokens on verbose CLI output:

- `git status`, `git log`, `git diff`
- `pytest`, `vitest`, `jest`, `npm test`
- `docker ps`, `docker logs`, `kubectl logs`
- lint/build/install commands

Instead of sending raw output to the agent, `hts` can:

- select a matching filter
- compress file content
- generate commit/review packets
- keep output short but still useful

---

## Why `hts` exists

`snip`, `rtk`, and `caveman` are useful, but each solves a different slice of the agent-token problem.

| Tool | Strong at | Gap |
|------|-----------|-----|
| `snip` | command-aware filtering with many YAML filters | agent still needs filter selection and workflow policy |
| `rtk` | fallback brevity/compression path | less declarative/filter-rich than `snip` |
| `caveman` | structured template workflows | not a general command filter engine |
| `hts` | routing, filter selection, agent packets | intentionally thin; should not reimplement upstream tools |

`hts` is the missing UX layer:

```text
snip = filter engine
rtk = fallback compression
caveman = workflow templates
hts = router + agent workflow gateway
```

Healthy boundary:

- `hts` detects backend
- `hts` selects filter/workflow
- `hts` runs command safely
- `hts` emits compact agent packets
- `hts` falls back when a backend is missing

It should not become its own filter engine, parser DSL, or agent framework.

---

## Agent operating model

For Hermes, OpenClaw, and other shell-capable agents, treat `hts` as the default terminal interface for **observation**.

```text
observe / inspect / summarize -> hts
act / mutate / install / deploy -> normal terminal, then summarize with hts
```

Prefer `hts` for:

- `git status`, `git log`, `git diff`
- tests/lint output
- docker/kubectl logs
- commit preparation
- review packets

Use raw terminal only when:

1. exact unfiltered output is required
2. the command has no useful mapping yet
3. debugging `hts` or backend behavior

Recommended agent rule:

```markdown
Use `hts` as the default interface for verbose terminal inspection.
Before raw `git diff`, `git log`, tests, lint, docker logs, or kubectl logs, prefer `hts`.
Use raw terminal for actions/mutations or when exact output is required.
```

---

## Features

### Core routing

- auto backend detection: `snip > rtk > raw-limited`
- command-to-filter mapping via `config/filter-map.yaml`
- project pack detection: `git`, `node`, `python`, `docker`
- synced `snip` inventory support

### Workflow commands

- `hts --doctor`
- `hts --init`
- `hts --which`
- `hts --filters [pattern]`
- `hts --packs`
- `hts --sync-snip-filters`
- `hts --gain -- <cmd>`
- `hts --explain -- <cmd>`
- `hts --compress <file> [--limit N]`
- `hts --max-lines N --max-bytes N -- <cmd>`
- `hts --no-limit -- <cmd>`
- `hts --commit <summary|full-summary> [--staged-only]`
- `hts --review <diff|lint|test|all>`
- `hts --template <name>`

---

## Install HTS

The installer installs `hts` and automatically installs or verifies its backends:

```text
snip > rtk > raw-limited
```

It also handles `caveman` template support and creates a `caveman` shim when the npm package does not expose a binary.

### Shell install

```bash
git clone git@github.com:ArkhiMuttaqina/haku-token-saver.git
cd haku-token-saver
./install.sh --install-deps
hts --doctor
```

HTTPS clone:

```bash
git clone https://github.com/ArkhiMuttaqina/haku-token-saver.git
cd haku-token-saver
./install.sh --install-deps
hts --doctor
```

`--install-deps` is the expected default workflow. It attempts to install:

- `snip`
- `rtk`
- `caveman`

If a backend is unavailable, `hts` still works through `raw-limited` bounded output.

### Prompt install for AI agents

Paste this into Hermes, OpenClaw, Codex, Claude Code, Antigravity, Gemini CLI, Cursor, or another shell-capable coding agent:

```text
Install HTS for this environment. Clone https://github.com/ArkhiMuttaqina/haku-token-saver.git, run ./install.sh --install-deps, ensure ~/.local/bin is on PATH, then verify with hts --doctor and hts --which. After install, use hts as the default observation interface for verbose terminal output: git status/log/diff, tests, lint, build output, docker logs, and kubectl logs. Use raw terminal only for mutation, install, deploy, interactive, or exact-output tasks.
```

### Agent adaptation rule

Add this to project instructions for Hermes/OpenClaw/Codex/Claude Code/Antigravity/Gemini CLI/Cursor/general terminal agents:

```markdown
Use `hts` as the default interface for verbose terminal inspection. Prefer `hts -- <command>` or hts workflow commands before raw `git diff`, `git log`, tests, lint, build output, docker logs, or kubectl logs. Use raw terminal for mutation, install, deploy, interactive, or exact-output tasks. After mutation, summarize with `hts` when output is large.
```

### Verify

```bash
hts --which
hts --doctor
hts --packs
hts --filters '^git-'
```

### Initialize per project

```bash
cd your-project
hts --init
```

This creates `.hts.json` and detects relevant packs.

---

## How to use

Detailed guide: [`docs/USAGE.md`](docs/USAGE.md)

### Basic command routing

```bash
hts -- git status
hts -- git log -20
hts -- pytest
hts -- npm test
hts -- docker ps
```

### Force backend

```bash
hts --backend snip -- git status
hts --backend rtk -- npm test
hts --backend raw -- git diff
```

### Inspect filters and packs

```bash
hts --filters
hts --filters '^git-'
hts --packs
hts --sync-snip-filters
```

### Measure savings

```bash
hts --gain -- git log -30
```

Gain reports two modes:

- `semantic-filter` when `snip` or `rtk` produced the final output
- `raw-limited` when `hts` had to fall back to bounded passthrough

Example fallback metrics:

```text
backend=raw
mode=raw-limited
filter=python3
fallback_reason=snip_and_rtk_missing_fallback_to_raw
raw_bytes=98432
output_bytes=20000
bytes_saved=78432
percent_saved=79.68
```

### Explain routing

```bash
hts --explain -- python3 -m pytest
```

```text
[hts-route]
command=python3
filter=python3
original_backend=snip
selected_backend=raw
fallback_reason=snip_and_rtk_missing_fallback_to_raw
no_limit=false
raw_max_lines=200
raw_max_bytes=20000
```

### Safe raw fallback

If no backend/filter is available, `hts` runs the command in bounded raw mode instead of failing.

```bash
hts --max-lines 100 --max-bytes 10000 -- some-verbose-command
```

For exact output:

```bash
hts --no-limit --backend raw -- some-verbose-command
```

Default env:

```bash
export HTS_RAW_MAX_LINES=200
export HTS_RAW_MAX_BYTES=20000
```

### Compress a file

```bash
hts --compress README.md
hts --compress README.md --limit 120
```

### Generate packets for agents

```bash
hts --commit summary
hts --commit full-summary --staged-only
hts --review diff
hts --review all
```

### Template workflows

```bash
hts --template status
hts --template log
hts --template lint
hts --template test
```

---

## Filter language

Filter mapping docs: [`docs/FILTER_LANGUAGE.md`](docs/FILTER_LANGUAGE.md)

`hts` uses a simple mapping layer, not a heavy DSL.

Main file:

```text
config/filter-map.yaml
```

It contains two core parts:

- `aliases:` human-friendly workflow names
- `command_families:` command-to-alias resolution

Example:

```yaml
aliases:
  status:
    snip: [git-status]
    template: git-status

command_families:
  git: status
```

Meaning:

- command family `git` resolves to alias `status`
- alias `status` can point to `snip` filter `git-status`
- alias may also define a template workflow

---

## Add or customize filters

Guide: [`docs/ADDING_FILTERS.md`](docs/ADDING_FILTERS.md)

Common tasks:

- add a new alias
- map a new command family
- sync new upstream `snip` filters
- add pack presets for project types

Files involved:

- `config/filter-map.yaml`
- `config/snip-filters.txt`
- `packs/*.yaml`

---

## Agentic support

Guide: [`docs/AGENTIC_SUPPORT.md`](docs/AGENTIC_SUPPORT.md)

### Current target

This repo is designed first for shell-capable coding agents that can call CLI tools.

Working/targeted usage:

- Hermes
- OpenClaw-style / generic terminal agents

### Soon support

Planned CLI integration docs/snippets for:

- Codex CLI
- OpenCode
- Claude Code
- Cursor workflows

Planned IDE integration docs:

- VS Code
- Antigravity-style IDE workflows

These are documentation/integration targets. `hts` itself is just a CLI, so anything that can run shell commands can usually use it.

---

## Config

### `.hts.json`

Example:

```json
{
  "packs": ["git", "node"],
  "backend": "auto",
  "created": "2026-05-31T12:00:00+07:00"
}
```

### Environment variables

- `HAKU_TOKEN_SAVER_BACKEND` → force backend: `snip|rtk|raw`
- `HAKU_TOKEN_SAVER_STRICT` → fail if chosen backend is unavailable
- `HTS_SNIP_REF` → override local reference path for synced snip filters

---

## Repository layout

```text
scripts/hts                  main orchestrator
scripts/caveman_wrapper.sh   template workflow adapter
config/filter-map.yaml       alias + command family mapping
config/snip-filters.txt      synced upstream filter inventory
packs/*.yaml                 project pack presets
docs/                        documentation
```

---

## Documentation map

- [`docs/USAGE.md`](docs/USAGE.md)
- [`docs/FILTER_LANGUAGE.md`](docs/FILTER_LANGUAGE.md)
- [`docs/ADDING_FILTERS.md`](docs/ADDING_FILTERS.md)
- [`docs/AGENTIC_SUPPORT.md`](docs/AGENTIC_SUPPORT.md)
- [`docs/README.md`](docs/README.md)

Phase notes:

- [`docs/phase-4c-p1.md`](docs/phase-4c-p1.md)
- [`docs/phase-4c-p2.md`](docs/phase-4c-p2.md)
- [`docs/phase-4c-p3.md`](docs/phase-4c-p3.md)
- [`docs/phase-4c-p4.md`](docs/phase-4c-p4.md)

---

## Troubleshooting

### Backend detection

```bash
hts --which
hts --doctor
```

### See chosen filter without executing fully

```bash
hts --dry-run -- git log -20
```

### Refresh upstream filter inventory

```bash
hts --sync-snip-filters
```

### Check available filters

```bash
hts --filters
hts --filters '^docker-'
```

---

## Status

Implemented now:

- auto backend routing
- pack detection/init
- synced filter inventory
- filter search
- file compression
- gain measurement
- commit packet generation
- review packet generation
- caveman-style template workflows

Planned next:

- richer `.hts.json` overrides
- command-specific help
- more agent/IDE integration recipes
- more pack/install workflows
