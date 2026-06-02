# Snip Integration

Snip is the preferred generic backend for CLI output filtering in this repo.

## Role

- primary generic backend when available
- general CLI command output filtering
- fallback only to `rtk`, never chain `snip -> rtk`

## Install

macOS:

```bash
brew install edouard-claude/tap/snip
```

Go:

```bash
go install github.com/edouard-claude/snip/cmd/snip@latest
```

## Usage

Direct usage:

```bash
snip git status
snip npm install
snip pnpm test
```

Via haku-token-saver:

```bash
haku-token-saver --backend snip -- git status
haku-token-saver -- git status  # auto selects snip if present
```

## Auto Detection

Installer writes backend cache:

```text
~/.config/haku-token-saver/backend
```

Priority:

```text
snip > rtk > raw-limited
```

If `snip` is missing, install.sh prints manual instructions but does not fail.

## Comparison

| Backend | Role |
| --- | --- |
| `snip` | preferred generic filter |
| `rtk` | fallback generic filter |
| raw | no filtering |

Do not chain `snip` and `rtk`. Use one backend per invocation.