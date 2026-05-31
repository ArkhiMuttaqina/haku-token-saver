---
name: hts-orchestrator
description: Maintain and extend Haku Token Saver (`hts`), the orchestrator CLI that composes snip > rtk > raw-limited backends plus caveman template workflows to reduce agent token burn from CLI output.
tags:
  - hts
  - snip
  - rtk
  - caveman
  - cli-output-compression
  - token-saving

---

# hts orchestrator

Use this skill when modifying `/home/arkhi25/Repo/agentic/Haku-token-saver/` (Haku Token Saver repo) or adding token-saving CLI workflows.
## Architecture

`hts` is the orchestrator/bootstrapper, not the filter engine.

Backend priority:

1. `snip` — primary filter engine; declarative YAML filters from upstream snip.
2. `rtk` — fallback brevity/compression proxy and broad command coverage.
3. `raw-limited` — bounded direct execution when compression tools are unavailable. Unlimited raw output requires explicit `--no-limit`.

Local upstream references:

- `/home/arkhi25/Repo/references/agentic/snip`
- `/home/arkhi25/Repo/references/agentic/caveman`
- `/home/arkhi25/Repo/references/agentic/rtk`

Main project path:

- `/home/arkhi25/Repo/agentic/Haku-token-saver/`

Compatibility cache path must stay:

- `~/.config/haku-token-saver/`

## Agentic integration policy

`hts` is intended to be the main terminal observation hand for Hermes, OpenClaw, and generic shell-capable coding agents.

Mental model:

```text
observe / inspect / summarize -> hts
act / mutate / install / deploy -> normal terminal
then summarize again -> hts
```

Use `hts` first for:

- repo inspection: `hts -- git status`, `hts --review diff`, `hts --review all`
- commit preparation: `hts --commit summary`, `hts --commit full-summary --staged-only`
- tests/lint: `hts --review test`, `hts --review lint`, or `hts -- <test command>`
- logs: `hts -- docker logs <container>`, `hts -- kubectl logs <target>`
- verbose command families likely to emit more than ~30 lines

Use raw terminal only when:

1. exact unfiltered output is required
2. debugging `hts`, backend selection, or filter behavior
3. executing mutation-heavy actions (install/build/deploy/migration), followed by an `hts` summary if output is large

If a command has no useful `hts` mapping yet, keep `hts` in front and let `raw-limited` cap output by default. Use `hts --no-limit --backend raw -- <command>` only for explicit exact-output needs.

Hermes/OpenClaw project-rule snippet:

```markdown
Use `hts` as the default interface for verbose terminal inspection. Before raw `git diff`, `git log`, tests, lint, docker logs, or kubectl logs, prefer `hts`. Use raw terminal for actions/mutations or when exact output is required.
```

## Command policy matrix by ecosystem

### Python

| Action | Tool | Recommended |
|--------|------|-------------|
| Test | `pytest` | `hts -- pytest` |
| Lint | `ruff` | `hts -- ruff check .` |
| Typecheck | `mypy` | `hts -- mypy .` |
| Install deps | `pip` | Raw: `pip install -r requirements.txt` |
| Sync deps | `uv` | Raw: `uv sync`, then `hts -- pytest` |
| List packages | `pip list` | `hts -- pip list` |

### Node.js / TypeScript

| Action | Tool | Recommended |
|--------|------|-------------|
| Test | `npm test` | `hts -- npm test` |
| Test | `pnpm test` | `hts -- pnpm test` |
| Test | `bun test` | `hts -- bun test` |
| Test | `vitest` | `hts -- vitest` |
| Lint | `eslint` | `hts -- eslint .` |
| Typecheck | `tsc` | `hts -- tsc --noEmit` |
| Install deps | `npm/pnpm/yarn/bun` | Raw install, then `hts -- <test>` |
| Build | `npm run build` | `hts -- npm run build` |

### Go

| Action | Tool | Recommended |
|--------|------|-------------|
| Test | `go test` | `hts -- go test ./...` |
| Vet | `go vet` | `hts -- go vet ./...` |
| Lint | `golangci-lint` | `hts -- golangci-lint run` |
| Build | `go build` | `hts -- go build ./...` |
| Tidy modules | `go mod tidy` | Raw, then `hts -- go test ./...` |

### General logs / infra

| Action | Tool | Recommended |
|--------|------|-------------|
| Container logs | `docker logs` | `hts -- docker logs app` |
| K8s logs | `kubectl logs` | `hts -- kubectl logs pod/name` |
| Service logs | `journalctl` | `hts -- journalctl -u svc -n 50` |
| Diff summary | `git diff` | `hts --review diff` |
| Commit packet | staged changes | `hts --commit full-summary --staged-only` |

Rule: raw for mutation/exact output; `hts` for observation/review/logs.

## Current command surface

Core commands:

```bash
hts --which
hts --doctor
hts --init
hts --filters
hts --filters '^git-'
hts --packs
hts --sync-snip-filters [--from /path/to/snip]
hts --explain -- <command>
hts --gain -- git log -30
hts --compress README.md
hts --compress README.md --limit 120
hts --commit summary
hts --commit full-summary --staged-only
hts --review diff
hts --review all
hts --dry-run --compress README.md --limit 120
hts --dry-run -- git status
hts --backend snip -- git status
hts --backend rtk -- npm test
hts --no-limit --backend raw -- <command>
hts --max-lines N --max-bytes N -- <command>
hts --template status
```

Backend call shape for snip:

```bash
snip --filter "$SNIP_FILTER" -- "$@"
```

Do not call plain `snip "$@"` after filter routing exists.

## Files to check first

```bash
cd /home/arkhi25/Repo/agentic/Haku-token-saver
```

Read these before edits:

- `scripts/hts` — main orchestrator CLI.
- `scripts/caveman_wrapper.sh` — template workflows.
- `config/filter-map.yaml` — alias and command-family map.
- `config/snip-filters.txt` — synced upstream snip filter inventory.
- `packs/*.yaml` — project preset packs.
- `docs/adaptation-roadmap.md` — planned enrichment from snip/caveman/rtk.
- `docs/phase-4c-p1.md` — implemented P1 feature docs.
- `docs/phase-4c-p2.md` — implemented P2 feature docs (`--gain`, `--compress`).
- `docs/phase-4c-p3.md` — implemented P3 feature docs (`--commit`, `--review`).
- `docs/phase-4c-p4.md` — implemented P4 refinements (`--filters [pattern]`, `--staged-only`, `--limit`).
- `README.md` — user-facing command docs.
- `references/phase-4c-session-notes.md` — compact session-specific notes for P1/P2/P3 implementation details and pitfalls.

## Safe workflow

1. Inspect current `git status --short` before editing. This repo may contain many pre-existing deletions/unrelated changes; do not stage or revert unrelated files.
2. Patch only targeted files. Avoid broad `git add -A`.
3. Keep `hts` as shell-compatible Bash. Run syntax checks after edits:

```bash
bash -n scripts/hts scripts/caveman_wrapper.sh install.sh
```

4. Smoke test core commands:

```bash
./scripts/hts --doctor
./scripts/hts --filters | wc -l
./scripts/hts --packs
./scripts/hts --sync-snip-filters >/tmp/hts_sync.out
./scripts/hts --dry-run --backend snip -- git status
./scripts/hts --dry-run --backend snip -- npm test
./scripts/hts --dry-run --backend snip -- docker ps
./scripts/hts --gain -- git log -5
./scripts/hts --compress README.md
./scripts/hts --compress README.md --limit 120
./scripts/hts --compress README.md --limit 10 2>&1 | grep 'integer >= 20'
./scripts/hts --filters '^git-'
./scripts/hts --commit summary
./scripts/hts --commit summary --staged-only
./scripts/hts --review diff
```

If `--commit` or `--review` unexpectedly prints `[err] No command provided. Use -- to separate options.`, the mode dispatch is too late in the script. Keep commit/review dispatch before the generic `if [ $# -eq 0 ]` guard.

Expected filter count from current snip reference: `127`.

## Adaptation rules

### From snip

Adapt:

- Filter inventory sync.
- Command-to-filter resolver.
- Pack coverage.
- Filter list/report commands.

Do not copy large upstream implementation blindly. Prefer consuming upstream filter names and invoking installed `snip`.

### From rtk

Adapt:

- Fallback semantics.
- Command coverage ideas.
- Brevity/compression defaults.

Keep backend priority `snip > rtk > raw-limited`.

Raw fallback must be bounded by default. Exact passthrough is opt-in via `hts --no-limit --backend raw -- <command>`.

### From caveman

Adapt:

- Template workflows for structured summaries.
- Terse/caveman response style where useful.
- Commands like `commit`, `review`, `compress` as future wrappers.

Do not make caveman the primary backend. It is workflow/template layer.

## Common pitfalls

- `printf '--- title ---\n'` can fail in Bash because leading `--` is parsed as option. Use `printf '%s\n' '--- title ---'`.
- If patching usage/help, update README and docs too.
- `--sync-snip-filters` should write `config/snip-filters.txt`, not only print.
- Commit/review mode dispatch must stay before the generic `if [ $# -eq 0 ]` guard, or `--commit` / `--review` will incorrectly fail with `No command provided`.
- `--filters [pattern]` should fall back through `snip/filters` → `config/snip-filters.txt` → `config/filter-map.yaml`, not depend on live snip repo only.
- `--compress --limit N` must validate integer input and reject values `< 20`.
- Preserve `HTS_SNIP_REF` default path: `/home/arkhi25/Repo/references/agentic/snip`.
- Preserve legacy env vars prefixed `HAKU_TOKEN_SAVER_*` for compatibility.

## Next feature candidates

P5 (future):

- `hts --init` per-project override for lint/test commands in `.hts.json`.
- `hts --review lint/test` config override from `.hts.json`.
- `hts --commit` auto-generated commit message (conventional format).
- `hts --gain --backend snip|rtk` force backend benchmark.
- `hts --compress --lines N` total output line cap.
- `hts --help <command>` command-specific help.
- `hts --packs install <name>` per-project pack enable/disable.

