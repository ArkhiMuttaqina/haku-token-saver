# Terminal Wrapper Templates

`terminal_wrapper` stores preinstalled templates for turning noisy terminal output into compact, structured, human-readable and AI-friendly packets.

Purpose:

> Use `hts` as a universal terminal wrapper for observation-heavy commands.

Use raw terminal for mutations/actions: installs, deploys, migrations, destructive commands, and exact raw output needs.

## Directory structure

```text
terminal_wrapper/
  README.md
  config/
    terminal-wrapper.yaml
  formatters/
    FORMATTER_SPEC.md
  templates/
    docker/
    git/
    kubernetes/
    node/
    python/
    system/
```

## Output policy

Every formatter/template should preserve factual state while reducing token noise.

Required sections:

```text
<Domain> summary
- total: <n>
- warnings: <n>
- failed: <n>

Items
1. name/id
   key: value

Signals
- factual anomaly or notable state

Metadata
- formatter: <name>
- mode: compact|normal|full
- omitted: <n>
- truncated: yes|no
```

## Design rules

1. Deterministic parser first; LLM rewrite never required for known commands.
2. Prefer machine-readable command forms when available.
3. Keep compact, normal, and full modes.
4. Never invent health status beyond visible facts.
5. Always keep raw escape hatch.

## Supported commands

| Command | Template | Modes | Notes |
|---------|----------|-------|-------|
| `docker ps` | docker-ps | compact, normal, full | Detects host-exposed vs internal-only ports |
| `docker images` | docker-images | compact, normal, full | Flags dangling images |
| `git status` | git-status | compact, normal, full | Staged/modified/untracked summary |
| `git log` | git-log | compact, normal, full | Top 20 commits in compact mode |
| `git diff --stat` | git-diff-stat | compact, normal, full | Top 15 changed files by size |
| `kubectl get pods` | kubectl-get-pods | compact, normal, full | Healthy/failed/pending summary |
| `ps aux` | ps-aux | compact, normal, full | Top CPU/memory, high-CPU alerts |
| `ss -tulpn` | ss-listen | compact, normal, full | Public vs localhost binds |
| `systemctl status <unit>` | systemctl-status | compact, normal, full | Active/failed/dead signals |

## Usage

```bash
# Compact mode (default for agents)
python3 terminal_wrapper/render.py docker ps
python3 terminal_wrapper/render.py git status
python3 terminal_wrapper/render.py ps aux

# Normal mode
python3 terminal_wrapper/render.py --mode normal docker ps

# Full mode
python3 terminal_wrapper/render.py --mode full kubectl get pods -A

# Raw mode (passthrough fallback)
python3 terminal_wrapper/render.py --mode raw <any command>
```

## Examples

### Docker ps (compact)

```text
Docker summary
- containers: 6
- running: 6
- host-exposed: 4
- internal-only: 2

Containers
1. chromadb-arkhi25
   image: chromadb/chroma:latest
   status: Up 2 days (healthy)
   ports: 8000/tcp

2. pgsql15-arkhi25
   image: postgres:15-alpine
   status: Up 2 days (healthy)
   ports: 127.0.0.1:6612->5432/tcp

Signals
- 4 containers expose to host
- 2 containers with internal-only ports

Metadata
- formatter: docker/docker-ps
- mode: compact
- omitted: 0
```

### Git status (compact)

```text
Git summary
- branch: main (ahead)
- staged: 3
- modified: 12
- untracked: 5

Staged
- M README.md
- A config/.env
- D old-file.py

Modified
- MM package.json
-  M src/index.ts

Untracked
- temp.log
- .swp

Signals
- Branch has unpushed commits
- Many modified files (12)

Metadata
- formatter: git/git-status
- mode: compact
```

### Process summary (compact)

```text
Process summary
- total: 142
- high CPU (>50%): 2

Top CPU: 98.5%
  pid: 1234
  user: arkhi25
  comm: python3

Top memory: 45.2%
  pid: 5678
  user: postgres
  comm: postgres

Signals
- 2 high-CPU processes detected

Metadata
- formatter: system/ps-aux
- mode: compact
```
