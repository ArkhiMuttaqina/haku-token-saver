# Agentic support

`hts` is designed for AI coding agents that can run shell commands.

It is not tied to one model or one editor.

If an agent can execute:

```bash
hts -- git status
```

then it can use `hts`.

---

## Current support target

Primary practical targets today:

- Hermes
- OpenClaw-style agents
- other shell-capable coding agents

## Main-hand policy

Treat `hts` as the default terminal interface for observation-heavy work.

```text
observe / inspect / summarize -> hts
act / mutate / install / deploy -> normal terminal
then summarize again -> hts
```

Use `hts` first for:

- repo inspection
- diff review
- commit preparation
- test/lint summaries
- large logs
- docker/kubectl inspection

Use raw terminal only when:

1. exact unfiltered output is required
2. performing mutations/actions such as installs, deploys, migrations, writes
3. debugging backend/filter behavior

If a command has no useful mapping yet, keep `hts` in front. It falls back to bounded raw output (`raw-limited`) and reports fallback metadata. Use `--no-limit` only when exact output is required.

### Hermes

Primary target.

Recommended instruction snippet for Hermes project context:

```markdown
## Terminal output policy

Use `hts` as the default interface for verbose shell inspection.

Prefer:
- `hts -- git status`
- `hts -- git log -20`
- `hts --review diff`
- `hts --review test`
- `hts --review lint`
- `hts --commit full-summary --staged-only`
- `hts -- docker ps`
- `hts -- docker logs <container>`

Use raw terminal mainly for actions/mutations:
- installs
- builds
- migrations
- deploys
- exact stack traces or exact raw output

Before raw `git diff`, `git log`, tests, lint, or logs, prefer `hts`.
```

### OpenClaw / generic terminal agents

Supported as generic shell workflow.

Use this instruction:

```markdown
Use `hts` as the primary wrapper for verbose terminal inspection.

For repository understanding, prefer:
- `hts -- git status`
- `hts --review diff`
- `hts --review all`
- `hts --commit summary`

Use raw commands for execution-heavy steps or when exact output is required.
```

Works if the agent has:

- shell access
- repository working directory
- `hts` installed in `PATH`
- permission to call `hts` before large raw commands

---

## Current practical integrations

| Agent/tool | Status | Notes |
|------------|--------|-------|
| Hermes | supported target | main workflow target |
| OpenClaw-style agents | supported pattern | use CLI instructions |
| Generic terminal agents | supported pattern | anything shell-capable |

---

## Soon: Code CLI support

Planned docs/snippets for:

- Codex CLI
- OpenCode
- Claude Code
- Cursor terminal workflows

Goal:

- add ready-to-copy instructions
- add command recipes
- add safe defaults for verbose commands
- add review/commit packet workflows

Example future pattern:

```markdown
Before running `git diff`, use `hts --review diff`.
Before asking for a commit message, use `hts --commit full-summary --staged-only`.
For tests, use `hts --review test` or `hts -- npm test`.
```

---

## Soon: IDE support

Planned documentation for:

- VS Code
- Antigravity-style IDE workflows

Target use cases:

- terminal profile integration
- task runner integration
- agent rules / workspace instructions
- commit/review command shortcuts

Example future VS Code task idea:

```json
{
  "label": "hts review all",
  "type": "shell",
  "command": "hts --review all",
  "problemMatcher": []
}
```

---

## Recommended agent rules

Add this to project instructions, `CLAUDE.md`, `.cursorrules`, or equivalent:

```markdown
## CLI output compression

Use `hts` before exposing verbose command output to the assistant context.

Recommended commands:

- Git status: `hts -- git status`
- Git log: `hts -- git log -20`
- Git diff summary: `hts --review diff`
- Tests: `hts --review test` or `hts -- npm test`
- Lint: `hts --review lint`
- Commit packet: `hts --commit full-summary --staged-only`
- Filter search: `hts --filters '<pattern>'`

Use `hts --no-limit --backend raw -- <command>` only when exact raw output is required. For unknown filters, keep `hts` in front and let `raw-limited` guard token usage.
```

---

## Best practices for agents

### Prefer packet commands first

Instead of:

```bash
git diff
```

Use:

```bash
hts --review diff
```

Instead of reading a full patch into context:

```bash
hts --commit full-summary
```

### Use staged-only for commit messages

```bash
git add -A
hts --commit full-summary --staged-only
```

This keeps the agent focused on what will actually be committed.

### Use backend check at session start

```bash
hts --which
hts --doctor
```

### Avoid raw huge logs

Prefer:

```bash
hts -- docker logs app
hts -- kubectl logs pod/name
```

### Inspect fallback routing

```bash
hts --explain -- python3 -m pytest
hts --gain -- some-verbose-command
```

Fallback policy:

```text
snip filter -> rtk -> raw-limited -> explicit --no-limit only by request
```

`raw-limited` defaults:

```bash
HTS_RAW_MAX_LINES=200
HTS_RAW_MAX_BYTES=20000
```

---

## Programming workflow examples

### Python

Prefer `hts` for observations:

```bash
hts -- pytest
hts -- python3 -m pytest
hts -- ruff check .
hts -- mypy .
hts -- pip list
```

Use raw terminal for dependency mutation, then summarize:

```bash
pip install -r requirements.txt
hts -- pytest
```

### Node.js / TypeScript

Prefer `hts` for tests, lint, typecheck, and build output:

```bash
hts -- npm test
hts -- pnpm test
hts -- bun test
hts -- vitest
hts -- jest
hts -- eslint .
hts -- tsc --noEmit
hts -- npm run build
```

Use raw terminal for package mutation, then summarize:

```bash
pnpm install
hts -- pnpm test
```

### Go

Prefer `hts` for test/check/build output:

```bash
hts -- go test ./...
hts -- go vet ./...
hts -- golangci-lint run
hts -- go build ./...
```

Use raw terminal for module mutation, then summarize:

```bash
go mod tidy
hts -- go test ./...
```

### Agent decision table

| Intent | Recommended path |
|--------|------------------|
| inspect repo | `hts -- git status`, `hts --review all` |
| summarize diff | `hts --review diff` |
| prepare commit | `hts --commit full-summary --staged-only` |
| run tests for context | `hts -- <test command>` |
| lint/typecheck | `hts -- <lint/typecheck command>` |
| inspect logs | `hts -- docker logs ...`, `hts -- kubectl logs ...` |
| install dependencies | raw terminal, then `hts -- <test command>` |
| deploy/migrate | raw terminal, then inspect logs with `hts` |
| exact stack trace | `hts --no-limit --backend raw -- <command>` or raw terminal |
| unknown filter | `hts --explain -- <command>`, then `hts -- <command>` with raw-limited fallback |

or:
For configured review packets, use:

```bash
hts --review test
```

---
---

## Integration status legend

| Status | Meaning |
|--------|---------|
| supported target | directly designed/tested workflow |
| supported pattern | should work through shell access |
| planned | docs/integration snippets not finished yet |

---

## Roadmap

### Near-term

- Codex CLI usage snippet
- OpenCode usage snippet
- Claude Code usage snippet
- Cursor workflow snippet
- VS Code task examples
- Antigravity IDE notes

### Later

- agent-specific install checks
- project rule templates
- prebuilt `.vscode/tasks.json`
- config-driven default commands from `.hts.json`
