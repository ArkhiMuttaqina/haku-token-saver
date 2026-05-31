---
name: hts-cli-workflow
description: Use hts as the default token-saving observation layer for shell-capable AI coding agents and terminal workflows.
tags:
  - hts
  - cli
  - agent-workflow
  - token-saving
  - snip
  - rtk
---

# hts CLI workflow

Use this skill when an agent or human needs compact terminal observations without losing the important signal.

## Core rule

```text
observe / inspect / summarize -> hts
act / mutate / install / deploy -> raw terminal
then summarize again -> hts
```

Use `hts` for:

- `git status`, `git log`, `git diff`
- test, lint, typecheck, and build output
- docker/kubectl/service logs
- review packets and commit summaries
- any command likely to emit noisy output

Use raw terminal for:

- package installs and dependency sync
- migrations, deploys, destructive actions
- interactive commands
- exact-output debugging

## Agent rule snippet

Paste this into Hermes, OpenClaw, Codex, Claude Code, Gemini CLI, Cursor, Antigravity, or any CLI agent project instructions:

```markdown
Use `hts` as the default interface for verbose terminal inspection. Prefer `hts -- <command>` or hts workflow commands before raw `git diff`, `git log`, tests, lint, build output, docker logs, or kubectl logs. Use raw terminal for mutation, install, deploy, interactive, or exact-output tasks. After mutation, summarize with `hts` when output is large.
```

## Backend priority

```text
snip > rtk > raw-limited
```

- `snip`: primary command-aware filter backend.
- `rtk`: fallback compression backend.
- `raw-limited`: safe bounded passthrough when backends are unavailable.

## Common commands

```bash
hts --doctor
hts --which
hts --packs
hts --filters '^git-'
hts -- git status
hts -- git log -30
hts --review diff
hts --review all
hts --commit summary --staged-only
hts --gain -- npm test
hts --compress README.md --limit 120
```

## Ecosystem examples

```bash
# Python
hts -- pytest
hts -- ruff check .
hts -- mypy .

# Node/TypeScript
hts -- npm test
hts -- pnpm test
hts -- tsc --noEmit

# Go
hts -- go test ./...
hts -- go vet ./...

# Infra/logs
hts -- docker logs app
hts -- kubectl logs deploy/api
```

## Install expectation

The repo installer should install or verify the required backends automatically:

```bash
git clone git@github.com:ArkhiMuttaqina/haku-token-saver.git
cd haku-token-saver
./install.sh --install-deps
hts --doctor
```

If an agent is asked to install HTS, it should clone the repo, run the installer, verify `hts --doctor`, then add the agent rule snippet to the target project's instruction file when appropriate.
