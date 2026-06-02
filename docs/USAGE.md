# How to use `hts`

`hts` is a CLI wrapper for token-saving agentic workflows.

Use it when command output is too verbose for an AI coding agent.


---

## Install and agent setup

### Shell install

```bash
curl -fsSL https://raw.githubusercontent.com/ArkhiMuttaqina/haku-token-saver/main/install.sh | bash
hts --doctor
```

Clone fallback:

```bash
git clone https://github.com/ArkhiMuttaqina/haku-token-saver.git
cd haku-token-saver
./install.sh --install-deps
hts --doctor
```

Install/path rules: see [`docs/INSTALL.md`](docs/INSTALL.md).

The installer installs or verifies `snip`, `rtk`, and `caveman`. If none are available, `hts` falls back to bounded `raw-limited` output.

### Prompt install

Paste into Hermes, OpenClaw, Codex, Claude Code, Antigravity, Gemini CLI, Cursor, or any shell-capable CLI agent:

```text
Install HTS. Clone https://github.com/ArkhiMuttaqina/haku-token-saver.git, run ./install.sh --install-deps, ensure ~/.local/bin is on PATH, verify with hts --doctor and hts --which, then use hts as the default observation interface for verbose CLI output. Use raw terminal for mutation, install, deploy, interactive, or exact-output tasks.
```

### Agent rule

```markdown
Use `hts` as the default interface for verbose terminal inspection. Prefer `hts -- <command>` or hts workflow commands before raw `git diff`, `git log`, tests, lint, build output, docker logs, or kubectl logs. Use raw terminal for mutation, install, deploy, interactive, or exact-output tasks. After mutation, summarize with `hts` when output is large.
```

---

## Mental model

```text
you / agent
   │
   ▼
hts
   │
   ├─ snip  primary filter backend
   ├─ rtk   fallback compression backend
   └─ raw   direct command passthrough
```

Default priority:

```text
snip > rtk > raw-limited
```

---

## Basic syntax

Always separate `hts` flags from the command with `--`:

```bash
hts -- <command> [args...]
```

Examples:

```bash
hts -- git status
hts -- git log -20
hts -- npm test
hts -- pytest
hts -- docker ps
```

Structured formatter mode for deterministic packets:

```bash
hts --detail compact -- docker ps
hts --detail compact -- docker images
hts --detail compact -- git status
hts --detail compact -- git diff --stat
hts --detail compact -- kubectl get pods -A
hts --detail compact -- ps aux
hts --detail compact -- ss -tulpn
hts --detail compact -- systemctl status docker
```

Alias:

```bash
hts --structured -- docker ps
```

---

## Check backend

```bash
hts --which
```

Example output:

```text
Backend: snip
```

Run diagnostics:

```bash
hts --doctor
```

---

## Dry run

Show what `hts` would run:

```bash
hts --dry-run -- git log -20
```

Useful for checking filter selection before sending output to an agent.

---

## Backend override

```bash
hts --backend snip -- git status
hts --backend rtk -- npm test
hts --backend raw -- git diff
```

Use cases:

- `snip`: when you want known filter behavior
- `rtk`: when snip has no good filter
- `raw`: when you want exact output

---

## Filters

List all known filters:

```bash
hts --filters
```

Search filters with regex:

```bash
hts --filters '^git-'
hts --filters 'docker|kubectl'
hts --filters 'test'
```

Sync filter inventory from local/reference snip repo:

```bash
hts --sync-snip-filters
```

Custom source:

```bash
hts --sync-snip-filters --from /path/to/snip
```

---

## Packs

List packs:

```bash
hts --packs
```

Initialize current project:

```bash
hts --init
```

This detects project type and creates `.hts.json`.

Common pack triggers:

| Pack | Trigger examples |
|------|------------------|
| git | `.git` |
| node | `package.json` |
| python | `pyproject.toml`, `requirements.txt` |
| docker | `Dockerfile`, `docker-compose.yml` |

---

## Measure gain

Compare raw output vs filtered output:

```bash
hts --gain -- git log -30
```

Output fields:

```text
backend=snip
filter=git-log
raw_bytes=...
filtered_bytes=...
bytes_saved=...
percent_saved=...
```

If backend is `raw`, gain measures bounded passthrough savings from `raw-limited`, not semantic filter savings.

```text
backend=raw
mode=raw-limited
filter=python3
fallback_reason=snip_and_rtk_missing_fallback_to_raw
exit_code=0
raw_bytes=98432
output_bytes=20000
bytes_saved=78432
percent_saved=79.68
```

---

## Explain routing and fallback

Show routing decision without running the command:

```bash
hts --explain -- python3 -m pytest
```

```text
[hts-route]
command=python3
filter=pytest
original_backend=snip
selected_backend=raw
fallback_reason=snip_and_rtk_missing_fallback_to_raw
no_limit=false
raw_max_lines=200
raw_max_bytes=20000
```

Fallback chain:

```text
specific snip filter -> rtk -> raw-limited
```

Raw fallback is bounded by default:

```bash
hts --max-lines 100 --max-bytes 10000 -- some-verbose-command
```

Exact raw output requires explicit opt-in:

```bash
hts --no-limit --backend raw -- some-verbose-command
```

---

## Compress file content

```bash
hts --compress README.md
hts --compress docs/README.md --limit 120
```

Rules:

- trim trailing whitespace
- collapse repeated blank lines
- preserve fenced code blocks
- truncate long lines using `--limit`

Default limit: `180`

Minimum limit: `20`

Invalid:

```bash
hts --compress README.md --limit 10
# [err] --limit must be an integer >= 20
```

---

## Commit packet

Generate compact commit summary:

```bash
hts --commit summary
```

Generate commit summary with patch:

```bash
hts --commit full-summary
```

Only staged changes:

```bash
hts --commit summary --staged-only
hts --commit full-summary --staged-only
```

Output sections:

- metadata
- `[stat]`
- `[files]`
- `[patch]` for `full-summary`

Use this before asking an agent for commit message or review.

---

## Programming workflows

`hts` works well across ecosystems: Python, Node.js, Go, Rust, and more.

### Python

Common workflows:

```bash
hts -- pytest
hts -- python -m pytest
hts -- ruff check .
hts -- mypy .
hts -- pip list
hts -- pip show <package>
```

Action-first, observe-next:

```bash
pip install -r requirements.txt
hts -- ruff check .
hts -- pytest
```

### Node.js / TypeScript

Common workflows:

```bash
hts -- npm test
hts -- pnpm test
hts -- bun test
hts -- vitest
hts -- jest
hts -- eslint .
hts -- tsc --noEmit
hts -- npm run build
hts -- pnpm outdated
```

Action-first, observe-next:

```bash
npm install
hts -- eslint .
hts -- npm test
```

### Go

Common workflows:

```bash
hts -- go test ./...
hts -- go test -v ./...
hts -- go vet ./...
hts -- golangci-lint run
hts -- go build ./...
```

Action-first, observe-next:

```bash
go mod tidy
hts -- go test ./...
hts -- golangci-lint run
```

### Rust

Common workflows:

```bash
hts -- cargo test
hts -- cargo nextest run
hts -- cargo clippy
hts -- cargo build
```

### Observations and logs

```bash
hts -- docker logs app
hts -- kubectl logs pod/name
hts -- journalctl -u myservice -n 50
```

---

## Review packet

```bash
hts --review diff
hts --review lint
hts --review test
hts --review all
```

Modes:

| Mode | Action |
|------|--------|
| `diff` | compact diff packet |
| `lint` | run detected lint command |
| `test` | run detected test command |
| `all` | diff + lint + test |

Current detection:

| Project | Lint | Test |
|---------|------|------|
| Node | `npm run -s lint` | `npm test -- --runInBand` |
| Python | `ruff check .` | `pytest` |

If no supported target exists, output says so instead of failing silently.

---

## Template workflows

```bash
hts --template status
hts --template log
hts --template lint
hts --template test
hts --template scripts
```

These route to `scripts/caveman_wrapper.sh` and produce structured agent-friendly output.

Aliases:

| Template | Workflow |
|----------|----------|
| `status` | `git-status` |
| `log` | `git-log` |
| `test` | `test-results` |
| `scripts` | `npm-scripts` |

---

## Recommended agent workflow

Before sending output to the agent:

```bash
hts --doctor
hts --dry-run -- git diff
hts --commit full-summary
hts --review all
```

For debugging a failing test:

```bash
hts -- pytest tests/foo_test.py
hts --review test
```

For commit preparation:

```bash
git add -A
hts --commit full-summary --staged-only
```

---

## Common mistakes

### Missing `--`

Use:

```bash
hts -- git status
```

Not:

```bash
hts git status
```

### Expecting snip when only raw exists

Check:

```bash
hts --which
command -v snip
```

### `--staged-only` shows clean

Stage files first:

```bash
git add -A
hts --commit summary --staged-only
```
