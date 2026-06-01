# Clawhub.ai Submission Pack

## Project Name

Haku Token Saver (HTS)

## Short Description

Token-saving terminal wrapper for AI agents. Turns noisy CLI output into structured, review-ready packets.

## Full Description

Haku Token Saver (HTS) is a unified token-saving observation layer for shell-capable AI agents. It reduces noisy CLI output from commands like `git diff`, `git status`, tests, lint, builds, Docker, Kubernetes, and process listings into concise structured packets.

HTS is designed for Hermes Agent, Codex CLI, Claude Code, OpenCode, Cursor, Gemini CLI, VS Code tasks, OpenClaw-style workflows, and any agent that can run shell commands.

The core rule is simple:

```text
observe / inspect / summarize -> hts
act / mutate / install / deploy -> raw terminal
then summarize again -> hts
```

This keeps agent context focused, reduces token waste, and makes command output easier to review during automated coding workflows.

## Key Features

- Token-saving wrapper for verbose shell output
- Structured review packets for git diffs, tests, lint, and commit summaries
- Deterministic packet rendering with compact, normal, full, and raw modes
- Multi-backend routing: `snip` first, `rtk` fallback, bounded `raw-limited` fallback
- Safe defaults for noisy commands
- Agent-friendly install flow via one-line curl bootstrap
- Hermes skill included: `hts-token-saver`
- Works with Hermes, Codex, Claude Code, OpenCode, Cursor, Gemini CLI, VS Code tasks, and shell agents

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ArkhiMuttaqina/haku-token-saver/main/install.sh | bash
```

## Quick Start

```bash
hts --doctor
hts --which
hts -- git status
hts --detail compact -- docker ps
hts --review diff
hts --commit summary
```

## Hermes Integration

HTS includes a bundled Hermes skill:

```text
skills/hts-token-saver/SKILL.md
```

Users can add this repository as a Hermes skill tap:

```bash
hermes skills tap add ArkhiMuttaqina/haku-token-saver
hermes skills search hts
hermes skills install hts-token-saver
```

The installer also places the skill at:

```text
~/.hermes/skills/development/hts-token-saver
```

## Repository

https://github.com/ArkhiMuttaqina/haku-token-saver

## Documentation

- README: https://github.com/ArkhiMuttaqina/haku-token-saver#readme
- Agent support: docs/AGENTIC_SUPPORT.md
- Ecosystem distribution: docs/ECOSYSTEM_DISTRIBUTION.md
- Terminal wrapper specs: terminal_wrapper/README.md

## Suggested Tags

```text
token-saving, ai-agent, shell, terminal, cli, hermes, codex, claude-code, opencode, cursor, structured-output, cli-compression, review-packets, git, docker, kubernetes
```

## Suggested GitHub Description

```text
Token-saving terminal wrapper for AI agents. Turns noisy CLI output into structured, review-ready packets.
```

## Suggested GitHub Topics

```text
token-saving
shell
hermes
codex
claude-code
opencode
cursor
structured-output
cli-compression
ai-agent
terminal
review-packets
```

## Category

AI Agent Tools / Developer Tools / CLI Utilities

## Compatibility

- Linux
- macOS
- Windows via WSL or Git Bash

## License

MIT
