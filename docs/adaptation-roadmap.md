# HTS Adaptation Roadmap

`hts` is the orchestrator/bootstrapper. It should not reimplement `snip`, `caveman`, or `rtk`; it should compose them.

## Source repos

| Repo | Role in hts | Adapt, don't copy |
|---|---|---|
| `snip` | Primary CLI output filter engine | Use filters, hook/init ideas, gain reports, filter registry model |
| `caveman` | Human response compression and templates | Use levels, commit/review/compress workflows, memory compression rules |
| `rtk` | Fallback proxy and mature command coverage | Use command family matrix, Hermes init idea, fallback semantics |

References live at:

```bash
/home/arkhi25/Repo/references/agentic/snip
/home/arkhi25/Repo/references/agentic/caveman
/home/arkhi25/Repo/references/agentic/rtk
```

## What to adapt from snip

Priority: high.

1. **Filter inventory sync**
   - Scan `snip/filters/*.yaml`.
   - Generate/update `config/filter-map.yaml` automatically.
   - Add `hts filters` command to list available filters.

2. **Declarative filter packs**
   - Keep `packs/*.yaml` as hts project-level presets.
   - Packs should reference snip filters by name.
   - `hts --init` enables packs based on project files.

3. **Hook/bootstrap model**
   - Add `hts install-hooks --agent hermes|claude|codex|cursor`.
   - Do not duplicate snip hooks initially; create hts wrapper rules that route shell commands through `hts`.

4. **Gain/report model**
   - Add `hts gain` later.
   - Prefer delegating to `snip gain` or `rtk gain` if available.
   - Fallback to simple local counter only if needed.

## What to adapt from caveman

Priority: medium-high.

1. **Compression levels**
   - `lite`: concise, full sentences.
   - `full`: caveman terse.
   - `ultra`: telegraphic.
   - `normal`: disable.

2. **Special workflows**
   - `hts commit` → compact conventional commit prompt/template.
   - `hts review` → one-line review comments.
   - `hts compress <file>` → compress memory/config docs while preserving code, paths, URLs, identifiers.

3. **Always-on rule files**
   - Generate `CLAUDE.md`, `AGENTS.md`, `.cursorrules` snippets from templates.
   - Let user pick tone level during `hts --init` later.

## What to adapt from rtk

Priority: high for fallback and coverage.

1. **Fallback semantics**
   - Preserve child exit code.
   - If filter fails, run raw command.
   - If selected backend missing and strict=false, degrade: `snip > rtk > raw-limited`.

2. **Command coverage matrix**
   - Use rtk README command groups to enrich pack coverage:
     - files: `ls`, `read`, `find`, `grep`, `diff`
     - git/gh
     - test runners: jest/vitest/pytest/go test/playwright
     - lint: ruff/mypy/eslint/golangci-lint
     - docker/kubectl/aws

3. **Hermes install path**
   - Add explicit Hermes bootstrap docs and optionally installer target.

## Immediate implementation priorities

### P0 — Done/current
- `scripts/hts`
- backend priority: `snip > rtk > raw-limited`
- `--doctor`
- `--init`
- packs: git/node/python/docker
- `config/filter-map.yaml`

### P1 — Next
- `hts filters`
- `hts packs`
- `hts sync-snip-filters --from /home/arkhi25/Repo/references/agentic/snip`
- install docs for `snip`, `caveman`, `rtk`

### P2
- `hts compress <file>` using caveman-preserve rules.
- `hts commit` / `hts review` templates.
- `hts install-hooks --agent hermes`.

### P3
- `hts gain` aggregate report.
- local usage tracking.
- auto benchmark/demo command.

## Non-goals

- Do not vendor the full upstream repos into hts.
- Do not rewrite snip filters in bash.
- Do not replace snip/rtk binaries.
- Do not lose technical identifiers for caveman compression.
