# Haku Token Saver

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Shell](https://img.shields.io/badge/shell-bash-green.svg)
![Python](https://img.shields.io/badge/python-3.9+-blue.svg)
![Status](https://img.shields.io/badge/status-stable-success.svg)

Terminal wrapper that reduces token waste from noisy CLI output.

Designed for AI coding agents: Hermes, OpenClaw, Codex CLI, Claude Code, Cursor, Gemini CLI, VS Code tasks, and any shell-capable agent.

```text
snip > rtk > raw-limited
```

---

## Quick install

### One-line curl (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/ArkhiMuttaqina/haku-token-saver/main/install.sh | bash
```

Default install paths:

- Linux/macOS: `/usr/local/bin` if writable, else `~/.local/bin`, else `~/bin`
- Config: `${XDG_CONFIG_HOME:-$HOME/.config}/haku-token-saver`
- Windows: use Git Bash or WSL only

See [`docs/INSTALL.md`](docs/INSTALL.md) for the full platform matrix and path rules.

### One-line from agent prompt

Paste this into any shell-capable AI agent:

```text
Install HTS. Run: curl -fsSL https://raw.githubusercontent.com/ArkhiMuttaqina/haku-token-saver/main/install.sh | bash. Ensure hts is on PATH. Verify with hts --doctor, hts --which, and hts --self-test. If PATH fails, run hts --fix-env or inspect ./install.sh --json. Use hts as default observation interface for verbose terminal output: git status/log/diff, tests, lint, build, docker logs, kubectl logs. Use raw terminal for mutation, install, deploy, interactive, or exact-output tasks.
```

### Clone install (fallback)

```bash
git clone https://github.com/ArkhiMuttaqina/haku-token-saver.git
cd haku-token-saver
./install.sh --install-deps
hts --doctor
```

---

## Quick use

### Basic routing

```bash
hts -- git status
hts -- git log -20
hts -- pytest
hts -- npm test
hts -- docker ps
```

### Structured formatter (deterministic packets)

```bash
hts --detail compact -- docker ps
hts --detail compact -- docker images
hts --detail compact -- git status
hts --detail compact -- git diff --stat
hts --detail compact -- kubectl get pods -A
hts --detail compact -- ps aux
hts --structured -- ss -tulpn
```

Mode: `compact` (default), `normal`, `full`, `raw`.

### Packet commands

```bash
hts --commit summary
hts --commit full-summary --staged-only
hts --review diff
hts --review test
hts --review lint
hts --review all
```

### Backend control

```bash
hts --which
hts --doctor
hts --backend snip -- git status
hts --backend rtk -- npm test
hts --no-limit --backend raw -- some-command
```

---

## Agent policy

```text
observe / inspect / summarize -> hts
act / mutate / install / deploy -> raw terminal
then summarize with hts again
```

Preferred commands:

- `hts -- git status` / `hts -- git log -20` / `hts -- git diff`
- `hts --review diff` / `hts --review test` / `hts --review lint`
- `hts --commit full-summary --staged-only`
- `hts -- docker ps` / `hts -- docker logs app` / `hts -- kubectl logs pod/name`
- `hts --detail compact -- <command>` for deterministic packets

Use raw terminal for installs, builds, migrations, deploys, or exact-output tasks.

---

## Environment variables

Canonical namespace: `HTS_*`.

- `HTS_BACKEND` — force backend: `snip|rtk|raw`
- `HTS_STRICT` — fail if selected backend unavailable
- `HTS_SNIP_REF` — local snip repo path
- `HTS_RAW_MAX_LINES` — raw fallback line cap
- `HTS_RAW_MAX_BYTES` — raw fallback byte cap

Legacy aliases supported: `HAKU_TOKEN_SAVER_BACKEND`, `HAKU_TOKEN_SAVER_STRICT`.

---

## Uninstall

```bash
./install.sh --uninstall
```

Removes binaries, config, templates, and Hermes skills.

---

## Docs

- [`docs/INSTALL.md`](docs/INSTALL.md) — cross-platform install matrix and path rules
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) — install/runtime fixes and agent repair flow
- [`docs/USAGE.md`](docs/USAGE.md) — full usage guide
- [`docs/AGENTIC_SUPPORT.md`](docs/AGENTIC_SUPPORT.md) — agent/IDE integration
- [`terminal_wrapper/README.md`](terminal_wrapper/README.md) — structured formatter specs