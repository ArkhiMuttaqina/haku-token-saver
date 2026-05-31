---
name: hts-orchestrator
description: Maintain and extend hts, the thin orchestrator for snip, rtk, raw-limited, and caveman-style workflow templates.
tags:
  - hts
  - snip
  - rtk
  - caveman
  - cli-output-compression
  - token-saving
---

# hts orchestrator

Use this skill when modifying the hts repo or extending HTS command routing, install flow, packs, or workflow commands.

## Architecture

`hts` is the orchestrator/bootstrapper, not the filter engine.

Backend priority:

1. `snip` — primary command-aware filter backend.
2. `rtk` — fallback compression backend.
3. `raw-limited` — bounded direct execution when compression tools are unavailable.

Template/workflow layer:

- `caveman` is optional and used for structured template workflows.
- `caveman` is not the primary backend.

Compatibility paths that must remain stable:

- repo: `/home/arkhi25/Repo/agentic/Haku-token-saver/`
- cache/config: `~/.config/haku-token-saver/`

## Operating policy

```text
observe / inspect / summarize -> hts
act / mutate / install / deploy -> raw terminal
then summarize again -> hts
```

Use `hts` first for:

- `git status`, `git log`, `git diff`
- tests, lint, typecheck, build output
- docker/kubectl/service logs
- commit and review packets

Use raw terminal for:

1. exact unfiltered output
2. mutation-heavy actions
3. installs, deploys, migrations
4. interactive commands
5. debugging backend behavior itself

## Supported agent targets

HTS is meant to adapt cleanly to:

- Hermes
- OpenClaw
- Codex
- Claude Code
- Antigravity
- Gemini CLI
- Cursor
- general shell/terminal workflows

Agent rule snippet:

```markdown
Use `hts` as the default interface for verbose terminal inspection. Prefer `hts -- <command>` or hts workflow commands before raw `git diff`, `git log`, tests, lint, build output, docker logs, or kubectl logs. Use raw terminal for mutation, install, deploy, interactive, or exact-output tasks. After mutation, summarize with `hts` when output is large.
```

## Core commands

```bash
hts --which
hts --doctor
hts --init
hts --packs
hts --filters '^git-'
hts --sync-snip-filters
hts --explain -- git status
hts --gain -- git log -30
hts --compress README.md --limit 120
hts --commit summary --staged-only
hts --review diff
hts --review all
hts -- git status
hts -- pytest
hts -- docker logs app
```

## Install expectation

Preferred install flow:

```bash
git clone git@github.com:ArkhiMuttaqina/haku-token-saver.git
cd haku-token-saver
./install.sh --install-deps
hts --doctor
```

Installer requirements:

- install or verify `snip`
- install or verify `rtk`
- install or verify `caveman`
- create caveman shim if package exposes no binary
- sync config/packs into `~/.config/haku-token-saver/`
- keep installed `hts` usable outside the repo checkout

## Safe workflow

1. Inspect `git status --short` before edits.
2. Patch only targeted files.
3. Keep `scripts/hts` shell-compatible Bash.
4. Run syntax checks after edits:

```bash
bash -n scripts/hts scripts/caveman_wrapper.sh install.sh
```

5. Smoke test after changes:

```bash
./scripts/hts --doctor
./scripts/hts --packs
./scripts/hts --filters '^git-'
./scripts/hts --dry-run -- git status
./scripts/hts --review diff
```

## Rules and pitfalls

- Do not reimplement snip inside `hts`; route to installed tooling.
- Use current snip command form: `snip "$@"`.
- Do not emit unbounded raw output by default.
- `raw-limited` must stay the safe fallback.
- Keep docs aligned with actual behavior after any command-surface change.
- Keep repo skills minimal; avoid session-specific references and scratch notes in committed skills.
- Put local development notes under `.hermes/` and keep that directory gitignored.

## Future direction

Good future work:

- better per-project `.hts.json` overrides
- richer `--review lint/test` detection
- stronger install docs per agent family
- pack expansion for more ecosystems
- more template workflows without bloating the core router
