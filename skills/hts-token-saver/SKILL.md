---
name: hts-token-saver
description: Maintain and use hts as the unified token-saving observation layer for shell-capable agents: snip/rtk/raw-limited routing, Caveman templates, install flow, repo maintenance, and context hygiene.
tags:
  - hts
  - snip
  - rtk
  - caveman
  - cli-output-compression
  - token-saving
  - agent-workflow
---

# hts token saver

Use this skill when modifying `/home/arkhi25/Repo/agentic/Haku-token-saver/`, installing HTS, adding command routing, writing agent rules, or reducing noisy CLI output.

## Canonical paths

- Repo: `/home/arkhi25/Repo/agentic/Haku-token-saver/`
- Installed config/cache: `~/.config/haku-token-saver/`
- Installed CLI default: `~/bin/hts`
- Runtime packs: `~/.config/haku-token-saver/packs/`
- Runtime filter map: `~/.config/haku-token-saver/filter-map.yaml`

Keep compatibility names stable. Do not rename config/cache paths to `~/.config/hts` unless a migration is explicit.

## Mental model

```text
observe / inspect / summarize -> hts
act / mutate / install / deploy -> raw terminal
then summarize again -> hts
```

Use `hts` first for:

- `git status`, `git log`, `git diff`
- tests, lint, typecheck, build output
- docker/kubectl/journal logs
- commit summaries and review packets
- any command likely to emit more than ~30 lines

Use raw terminal for:

1. exact unfiltered output
2. mutation-heavy actions
3. installs, dependency sync, deploys, migrations
4. interactive commands
5. debugging `hts`, backend selection, or filters

After raw mutation, summarize with `hts` if output/state is large.

## Architecture

`hts` is the orchestrator/bootstrapper, not the filter engine.

Backend priority:

1. `snip` — primary command-aware filter backend.
2. `rtk` — fallback compression backend.
3. `raw-limited` — bounded direct execution when compression tools are unavailable.

Template/workflow layer:

- Caveman-style templates are for stable repeated summaries.
- Caveman is not the primary backend and must not replace snip routing.
- Never chain `snip -> rtk -> caveman` for the same command unless explicitly debugging over-compression.

Backend rules:

- Preserve exit codes.
- Use direct argv execution; avoid shell `eval` in new code.
- Keep raw fallback bounded by default.
- Exact passthrough must be opt-in, e.g. `hts --no-limit --backend raw -- <command>`.

Current snip call shape:

```bash
snip "$@"
```

Do not call `snip --filter "$SNIP_FILTER" -- "$@"` with snip v0.17+; it treats `--filter` as the command and fails.

## Agent rule snippet

Paste into Hermes, OpenClaw, Codex, Claude Code, Antigravity, Gemini CLI, Cursor, or any shell-capable agent project instructions:

```markdown
Use `hts` as the default interface for verbose terminal inspection. Prefer `hts -- <command>` or hts workflow commands before raw `git diff`, `git log`, tests, lint, build output, docker logs, or kubectl logs. Use raw terminal for mutation, install, deploy, interactive, or exact-output tasks. After mutation, summarize with `hts` when output is large.
```

## Core commands

```bash
hts --which
hts --doctor
hts --init
hts --packs
hts --filters
hts --filters '^git-'
hts --sync-snip-filters
hts --explain -- git status
hts --gain -- git log -30
hts --compress README.md --limit 120
hts --commit summary
hts --commit full-summary --staged-only
hts --review diff
hts --review all
hts --dry-run -- git status
hts --backend snip -- git status
hts --backend rtk -- npm test
hts --no-limit --backend raw -- <command>
hts --max-lines N --max-bytes N -- <command>
hts --template status
hts --detail compact -- docker ps
hts --detail normal -- git status
hts --structured -- ps aux
```

## Environment variables

Prefer short `HTS_*` names in new docs and scripts:

- `HTS_BACKEND` — force backend: `snip|rtk|raw`
- `HTS_STRICT` — fail if selected backend is unavailable
- `HTS_SNIP_REF` — local snip repo path for filter inventory sync
- `HTS_RAW_MAX_LINES` — raw fallback line cap
- `HTS_RAW_MAX_BYTES` — raw fallback byte cap

Legacy aliases remain supported for compatibility:

- `HAKU_TOKEN_SAVER_BACKEND` → `HTS_BACKEND`
- `HAKU_TOKEN_SAVER_STRICT` → `HTS_STRICT`

Generated `.hts.json` files should include `"schemaVersion": 1`.

## Ecosystem command policy

### Python

```bash
hts -- pytest
hts -- ruff check .
hts -- mypy .
# raw for mutation
uv sync
pip install -r requirements.txt
```

### Node / TypeScript

```bash
hts -- npm test
hts -- pnpm test
hts -- bun test
hts -- vitest
hts -- eslint .
hts -- tsc --noEmit
hts -- npm run build
# raw for mutation
npm install
pnpm install
bun install
```

### Go

```bash
hts -- go test ./...
hts -- go vet ./...
hts -- golangci-lint run
hts -- go build ./...
# raw for mutation
 go mod tidy
```

### Infra/logs

```bash
hts -- docker logs app
hts -- kubectl logs pod/name
hts -- journalctl -u svc -n 50
hts --review diff
hts --commit full-summary --staged-only
```

## Structured terminal wrapper

Use `terminal_wrapper/render.py` through `hts` for deterministic observation packets on known command families.

Rules:

1. Observation commands should prefer `hts --detail <mode> -- <command>`.
2. Use `--structured` as shorthand for `--detail compact`.
3. Deterministic parser first; do not require LLM rewrite for known commands.
4. Mutation commands stay on raw terminal.
5. Never invent health or status not visible in command output.

Known useful commands:

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

Mode guidance:

- `compact` — default agent packet
- `normal` — more context
- `full` — richer visible fields
- `raw` — bounded raw fallback

## Caveman/template workflows

Use templates when the same noisy workflow repeats and a stable summary shape is valuable.

Examples:

```bash
hts --template git-status
hts --template git-log 20
hts --template lint src/
hts --template test-results 'npx vitest run'
```

Template guidelines:

1. Keep output 1–20 lines by default.
2. Put structure in templates, not complex logic.
3. Pass only variable data between runs.
4. Show failing/changed/important lines first.
5. Keep full raw output available for debugging.

Caveman syntax reference:

```text
{{d.variable}}
{{- for d.items as item }}{{item}}{{- end }}
{{- if d.condition }}yes{{- end }}
```

## Install and reinstall workflow

Preferred install:

```bash
git clone git@github.com:ArkhiMuttaqina/haku-token-saver.git
cd haku-token-saver
./install.sh --install-deps
hts --doctor
```

When testing installer changes locally, uninstall local installed artifacts first, then reinstall:

```bash
rm -rf ~/.hermes/skills/development/hts-token-saver \
       ~/.hermes/skills/development/hts-orchestrator \
       ~/.hermes/skills/development/hts-cli-workflow \
       ~/.hermes/skills/development/token-saving-cli-workflow \
       ~/.hermes/skills/development/context-optimization \
       ~/.hermes/skills/development/caveman-rtk-integration
rm -f ~/bin/hts ~/bin/caveman_wrapper.sh ~/bin/verify_caveman_setup.sh ~/bin/demo_token_savings.sh
rm -f ~/templates/git_status.txt ~/templates/git_log.txt ~/templates/lint_results.txt ~/templates/test_results.txt
rm -rf ~/.config/haku-token-saver
./install.sh --skip-deps
hts --doctor
```

Installer expectations:

- install or verify `snip`, `rtk`, and `caveman` when `--install-deps` is active
- support `--skip-deps` for fast local reinstall tests
- create Caveman shim if package exposes no binary
- sync config/packs into `~/.config/haku-token-saver/`
- install repo skills under `~/.hermes/skills/development/`
- keep installed `hts` usable outside repo checkout

## Repo maintenance workflow

1. Inspect state first:

```bash
cd /home/arkhi25/Repo/agentic/Haku-token-saver
git status --short
```

2. Read likely files before edits:

- `scripts/hts`
- `scripts/caveman_wrapper.sh`
- `install.sh`
- `config/filter-map.yaml`
- `config/snip-filters.txt`
- `packs/*.yaml`
- `skills/hts-token-saver/SKILL.md`
- `README.md`
- `docs/USAGE.md`
- `docs/AGENTIC_SUPPORT.md`

3. Patch targeted files only. Avoid broad `git add -A`.
4. Keep Bash shell-compatible.
5. Run syntax checks:

```bash
bash -n scripts/hts scripts/caveman_wrapper.sh install.sh
```

6. Smoke test:

```bash
./scripts/hts --doctor
./scripts/hts --packs
./scripts/hts --filters '^git-'
./scripts/hts --dry-run -- git status
./scripts/hts --review diff
./scripts/hts --compress README.md --limit 120
```

## Common pitfalls

- `printf '--- title ---\n'` can fail in Bash because leading `--` is parsed as option. Use `printf '%s\n' '--- title ---'`.
- `--commit` and `--review` dispatch must happen before generic no-command guards.
- `--filters [pattern]` should fall back through synced filters, then repo config.
- `--compress --limit N` must reject non-integers and values `< 20`.
- Installed `hts` must resolve config/packs from `~/.config/haku-token-saver`, not assume repo-relative paths.
- `install.sh` must copy `config/filter-map.yaml` and `packs/*.yaml` into runtime config.
- Preserve legacy `HAKU_TOKEN_SAVER_*` env vars when compatibility matters.
- Keep repo skills minimal and canonical. Do not commit bulky session notes or duplicate near-identical skills.

## Context hygiene

Use compact command flags before filtering when possible:

```bash
git status --porcelain
git log --oneline -20
```

Do not dump full logs unless requested or needed. Use normal detail for security, irreversible actions, migrations, architecture tradeoffs, and ambiguous failures.

For Hermes context bloat:

```bash
hermes sessions prune --older-than 3 --source cron --yes
hermes sessions stats
hermes insights
rtk gain || true
```

Avoid saving transient artifacts in memory. Put stable HTS workflow lessons into this skill or repo docs.

## Future candidates

- `.hts.json` overrides for lint/test/build commands
- richer `hts --review lint/test` detection
- conventional commit message generation
- `hts --gain --backend snip|rtk`
- `hts --compress --lines N`
- command-specific help: `hts --help <command>`
- per-project pack enable/disable
