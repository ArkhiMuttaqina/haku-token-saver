---
name: token-saving-cli-workflow
description: Reduce LLM token consumption for CLI commands via filtering (snip, RTK, Caveman) and context optimization (pruning sessions, managing memory, RTK enforcement). Use when working with Hermes/agents and verbose CLI output burns tokens.
version: 1.0.0
---

# Token Saving CLI Workflow

This skill guides token-efficient CLI command execution and Hermes context optimization.

## Scope

- CLI output filtering via snip, RTK, or Caveman
- Hermes session/memory management
- Repo pruning for token-saver-only scope
- Choosing and integrating token-saving backends

## When to Use

- Agent produces verbose CLI output (git log, go test, npm install, docker ps)
- User mentions high token usage or "reduce tokens"
- Refactoring opinionated starter kits into lean scope
- Choosing between token-saving backends (snip vs RTK vs Caveman)
- Maintaining Hermes session and memory hygiene

## Agent terminal policy

For Hermes, OpenClaw, and other shell-capable coding agents, treat token saving as a command-selection policy, not just a backend choice.

Mental model:

```text
observe / inspect / summarize -> hts or filtered backend
act / mutate / install / deploy -> normal terminal
then summarize again -> hts or filtered backend
```

Default to filtered/packetized commands for:

- `git status`, `git log`, `git diff`
- tests and lint output
- docker/kubectl logs
- commit preparation
- repo review packets

Use raw terminal only when:

1. exact unfiltered output is required
2. command mapping/filtering does not exist yet
3. debugging the filtering backend itself
4. execution steps are mutation-heavy and summary should happen afterward

Recommended repo rule snippet:

```markdown
Use `hts` as the default interface for verbose terminal inspection. Before raw `git diff`, `git log`, tests, lint, docker logs, or kubectl logs, prefer `hts`. Use raw terminal for actions/mutations or when exact output is required.
```

## Token-Saving Backends Comparison

### snip (Recommended - General Purpose)

**When to use:**
- Broad CLI filtering across many tools
- Need 127+ built-in filters (git, go, npm, cargo, docker, kubectl, terraform, pip, etc.)
- Want declarative YAML filters (no compiled code required)
- Need tracking reports (`snip gain`)
- Per-project custom filter overrides

**Installation:**
```bash
brew install edouard-claude/tap/snip
# or: go install github.com/edouard-claude/snip/cmd/snip@latest
# or: curl -fsSL https://raw.githubusercontent.com/edouard-claude/snip/master/install.sh | sh
```

**Usage:**
```bash
snip git log -10
snip go test ./...
snip npm install
snip gain                    # savings report
```

**Key features:**
- Filters are YAML data files (declarative DSL)
- Graceful degradation (passthrough if no filter matches)
- Exit codes always preserved
- 19 pipeline actions: keep_lines, remove_lines, head, tail, json_extract, state_machine, etc.
- Custom filters in `~/.config/snip/filters/` or `.snip/` per project
- Startup < 10ms, minimal overhead

**When NOT to use:**
- Command requires raw/full output for debugging
- User explicitly passed format flags (--json, --verbose) that conflict with filter
- Interactive tools (editors, REPLs)

**Integration notes:**
- Do NOT run `snip init` automatically - it patches Claude/Cursor/Codex hooks
- Detect binary existence, then instruct user to install if missing
- Prefer as primary backend for general CLI filtering

### RTK + Caveman (Fallback/Template Mode)

**When to use:**
- Local template-driven output formatting
- Custom output format not covered by snip's filters
- Manual demo/simulation mode
- When snip is unavailable but RTK is installed

**Installation:**
```bash
npm install -g caveman
```

**Usage:**
```bash
caveman template.json data.json    # via wrapper script
rtk <command>                      # Rust Token Kit
```

**Key features:**
- JS templating engine with user-defined templates
- Tighter control over exact output format
- Works with RTK for noise reduction before templating

**Limitations:**
- Requires template per workflow
- No auto-discovery/matching like snip
- More manual setup than snip

### Choosing Backend

**Default:** Prefer snip
- Broadest filter coverage
- Declarative YAML (easier to maintain)
- Built-in tracking

**Fallback:** Use RTK
- snip unavailable
- Generic filtering still useful

**Template mode:** Use Caveman-style wrappers separately
- Custom template requirement
- Stable summaries for repeated workflows (`git-status`, `git-log`, `lint`, `test-results`)
- Demo/educational context

**Never:** Double-filter
- Avoid `snip -> rtk -> caveman` pipeline on same command
- Over-compression risks losing debugging context

### Wrapper Implementation Pattern

For a lean repo wrapper, keep generic backend routing separate from curated templates:

```text
hts -- <command>          # generic backend: snip > rtk > raw-limited
hts --template git-status # curated template workflow
```

Implementation rules:
- Use direct argv execution (`exec snip "$@"`, `exec rtk "$@"`, `exec "$@"`); avoid shell eval.
- Preserve exit codes from the wrapped command.
- Cache detected backend at `~/.config/haku-token-saver/backend`, but allow env/flag override.
- Add `--which` and `--dry-run` to make backend selection debuggable.
- Installer should create needed template/cache directories and warn for missing optional backends, not fail.
- Caveman wrapper should still run without `rtk`/`caveman` when possible; fallback to compact JSON/text (`jq -c` or `cat`) rather than crashing on missing optional formatter.
- Template routers should normalize short aliases (`status`, `log`, `test`, `scripts`) into canonical workflows and reject unknown names with a clear available-list error.
- If the primary wrapper script is renamed, update installer copies, shell aliases, docs/examples, and verification paths in the same pass. Keep old cache-dir/env names only as an explicit backward-compatibility choice, not by accident.
- For snip backend, pass resolved filter explicitly: `exec snip --filter "$SNIP_FILTER" -- "$@"`.
- Fallback SNIP_FILTER to `$1` (command name) if resolver returns empty; this ensures snip still processes output even when filter mapping is incomplete.
- Dry-run output for snip should show resolved filter: `snip ${SNIP_FILTER:-$1} -- $*`.

#### Pack System (Phase 4A)

Add preset packs for auto-detection and filter organization:

**Structure:**
```
packs/
  git.yaml      # git filters + aliases + detection rules
  node.yaml     # npm/pnpm/yarn filters + detection
  python.yaml   # pytest/ruff/mypy + detection
  docker.yaml   # docker/k8s + detection
config/
  filter-map.yaml  # 128+ alias + command-family mappings
```

**Pack YAML schema:**
```yaml
name: git
description: Enable git-focused templates and snip filters
filters:
  - git-status
  - git-log
  - git-diff
  - ...
aliases:
  - status
  - log
  - diff
  - ...
detect:
  files:
    - .git
  commands:
    - git
```

**filter-map.yaml schema:**
```yaml
aliases:
  status:
    snip: [git-status]
    template: git-status
  log:
    snip: [git-log]
    template: git-log
  test:
    snip: [pytest, vitest, jest, go-test, ...]
    template: test-results
  ...

command_families:
  git: status
  pytest: test
  eslint: lint
  ...
```

#### hts --doctor Mode

Add diagnostics to verify setup:

**What to report:**
- Backend status (snip, rtk available? cached backend?)
- Configuration paths (config dir, packs dir, filter-map.yaml)
- Available packs (iterate `packs/*.yaml`, show name + description)
- Project config (`.hts.json` exists? if not, suggest `hts --init`)

**Output format:**
```
🩺 hts Doctor

Backend:
  ✓ snip available at /usr/local/bin/snip
  ✗ rtk not found
  Current cache: /home/user/.config/haku-token-saver/backend
  Cached backend: snip

Configuration:
  Config dir: /path/to/config
  Packs dir: /path/to/packs
  ✓ filter-map.yaml found

Available packs:
  - git: Enable git-focused templates and snip filters
  - node: Enable Node.js templates and snip filters (npm, pnpm, yarn)
  - python: Enable Python test/lint/typecheck/install filters
  - docker: Enable container and infra-adjacent filters

Project config:
  ✗ .hts.json not found (run 'hts --init' to create)
```

#### hts --init Mode

Auto-detect packs and generate project config:

**Detection rules:**
- File-based: `.git` → git pack, `package.json` → node pack, `pyproject.toml` → python pack, `Dockerfile` → docker pack
- Command-based (optional): `git` command exists → git pack, `npm` exists → node pack, etc.
- Fallback: if nothing detected, enable default `git` pack

**Output:**
```json
{
  "packs": ["git", "node", "python", "docker"],
  "backend": "auto",
  "created": "2026-05-31T12:00:00+07:00"
}
```

**After init, suggest:**
```
Next steps:
  hts --doctor      # Verify setup
  hts -- git status # Try a git command
```

#### Command-to-Filter Resolver (normalize_command_for_snip)

Implement resolver function mapping command arguments to snip filters:

**Pattern:**
```bash
normalize_command_for_snip() {
  local cmd="$1"
  local subcmd="${2:-}"
  case "$cmd" in
    git)
      case "$subcmd" in
        status) echo "git-status" ;;
        log) echo "git-log" ;;
        diff) echo "git-diff" ;;
        *) echo "git-$subcmd" ;;
      esac
      ;;
    npm|pnpm|yarn)
      case "$subcmd" in
        test) echo "vitest" ;;
        install|i|add) echo "$cmd-install" ;;
        *) echo "$cmd-$subcmd" ;;
      esac
      ;;
    docker)
      case "$subcmd" in
        ps) echo "docker-ps" ;;
        logs) echo "docker-logs" ;;
        *) echo "docker-$subcmd" ;;
      esac
      ;;
    pytest|vitest|jest|eslint|ruff|mypy|shellcheck)
      echo "$cmd"
      ;;
    *)
      echo "$cmd"
      ;;
  esac
}

SNIP_FILTER="$(normalize_command_for_snip "$@")"
```

**Pitfall:**
- Avoid using `local` keyword inside functions that might be sourced/evaled in different shell contexts; use plain variable assignment for portability.

#### Installer Refinements

**Cache path compatibility:**
- Preserve existing backend cache path: `~/.config/haku-token-saver/backend`
- Do NOT change to new name (e.g., `~/.config/hts/backend`) without explicit migration step; this breaks existing installations.
- Installer should check cache dir path consistently with wrapper script.

**Pre-flight checks:**
- Required: bash, git, jq (fail if missing)
- Optional: snip, rtk (warn but continue if missing)

**Dry-run support:**
- Add `--dry-run` flag to preview install actions without modifying system
- Show planned `mkdir`, `cp`, `chmod`, shell alias injection in dry-run mode

**Example install.sh structure:**
```bash
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/haku-token-saver"
BACKEND_CACHE="$CONFIG_DIR/backend"

detect_backend() {
  # snip > rtk > raw-limited-limited
  if command -v snip >/dev/null 2>&1; then
    echo "snip"
  elif command -v rtk >/dev/null 2>&1; then
    echo "rtk"
  else
    echo "raw"
  fi
}

preflight() {
  need bash
  need git
  need jq
  if ! command -v snip >/dev/null 2>&1; then
    warn "snip not found; install for best results"
  fi
}
```
### Resume Existing Work Before Asking Basics

When the user says to "execute" an existing plan/repo/task, do not restart discovery from zero if prior-session state likely exists.

Preferred recovery order:
1. Recover the prior plan/session context first.
2. Recover the repo path from session history or filesystem clues.
3. Inspect current repo state.
4. Then execute remaining phases.

Pitfall:
- Do not ask the user for repo path or plan details that were already established in prior session history unless recovery actually failed.
- Do not create a fresh plan when the user explicitly wants an earlier plan executed.

## Repo Pruning for Token-Saver-Only Scope

When refactoring opinionated starter kits (e.g., rtk-caveman forks) to lean token-saver scope:

### What to Keep

**Core token-saving components:**
- Wrapper scripts for git status/log, lint, test summaries
- Templates for compact output
- Skills focused on CLI filtering and context optimization

**Example keep-list:**
```
scripts/caveman_wrapper.sh
scripts/demo_token_savings.sh
scripts/verify_caveman_setup.sh
templates/git_status.txt
templates/lint_results.txt
templates/test_results.txt
skills/development/caveman-rtk-integration/
skills/development/context-optimization/
```

### What to Prune

Remove skills/files unrelated to token saving:
- Finance skills (stock picks, market scanning)
- GitHub skills (PR management, repo inspection - LOC counting is noise)
- Productivity skills (Obsidian, Notion, docs maintenance)
- Research skills (arXiv, wiki, academic)
- DevOps skills (MySQL, Syncthing, webhooks)
- Default personality files (overwrites user preferences)

### What to Rewrite

**README.md:**
- Position as lean, non-invasive token-saver fork
- Remove marketing overclaims ("90-99% savings" without context)
- Focus: compact terminal output, optional backends
- Include snip backend option

**install.sh:**
- No automatic personality/CLAUDE.md overwrite
- No bulk skill install outside token-saver scope
- Detect backends (snip, RTK), do not auto-install without consent
- Support dry-run or preview mode
- Safe behavior: backup before overwrite, ask before shell profile changes

**config/CLAUDE.md:**
- Self-contained concise instruction for RTK/Caveman/snip usage
- Do not leave only "@RTK.md" reference
- Include when to prefer which backend

**Skills:**
- Remove domain-specific examples (Zenith, market scanning)
- Keep CLI filtering and context optimization focus

## Hermes Context Optimization

### Prune Old Sessions

```bash
# Cron sessions older than 3 days (safe to delete)
hermes sessions prune --older-than 3 --source cron --yes

# Telegram sessions older than 14 days (if needed)
hermes sessions prune --older-than 14 --source telegram --yes
```

**Why:** Reduces session bloat, speeds up session_search, lowers context noise.

### Auto-Prune Cron

If not exists, create cron job:
```bash
# Daily at 3 AM WIB
hermes cron create --schedule '0 3 * * *' --prompt 'Run hermes sessions prune --older-than 3 --source cron --yes' --name 'session-prune-daily'
```

### RTK Enforcement

Ensure SKILL.md or working agreement contains:
- **Golden Rule:** Prefix CLI commands with `rtk` when applicable
- **MANDATORY** section for execute_code terminal() calls
- Exception list: interactive tools, no-output commands, full-output requests

### Memory Management

- Check memory usage (% of char limit)
- Consolidate redundant entries
- Update RTK mandate entry if workflow changes
- Avoid storing session-specific artifacts (PR numbers, commit SHAs) in memory

### Verify RTK Coverage

```bash
rtk gain                          # Check token savings
hermes insights                   # Usage analytics (last 30 days)
hermes sessions stats             # Session store size
```

**Target:** 100% of eligible terminal() calls filtered.

## Common Issues

### Low RTK Coverage
- Patch CLAUDE.md or working agreement with stricter execute_code rules
- Use `execute_code` preference (see haku-coagent-working-agreement)

### Memory at 100%
- Consolidate or remove entries using memory tool replace action
- Remove transient artifacts (commit SHAs, PR numbers)

### Session Bloat
- Run prune for cron source first (safest to delete)
- Set up auto-prune cron

### Snip Name Collision
- Check `which snip` — should be edouard-claude/snip binary, not Rust Type Kit
- If conflict, use explicit path or rename one

### Double Filtering
- If output over-compressed, check if pipeline chains `snip -> rtk -> caveman`
- Break chain at first backend that produces usable signal

## Key Metrics to Track

| Metric | Target | How to Check |
|--------|--------|--------------|
| RTK coverage | 100% of eligible commands | `rtk gain` vs `hermes insights` tool calls |
| Session count | <100 | `hermes sessions stats` |
| Memory usage | <90% | Memory tool response |
| Auto-prune | Active | `hermes cron list` |
| Snip filters available | 127+ | `snip discover` |

## Examples

### Repo Pruning Checklist
```bash
cd /path/to/opinionated-starter-kit
# Keep only token-saver skills
# Remove: finance, github, productivity, research, devops
# Rewrite: README.md, install.sh, config/CLAUDE.md
# Test: install.sh syntax check, wrapper scripts validation
```

### Choosing Backend
```bash
# General CLI - use snip
snip git log -10
snip go test ./...

# Custom template - use Caveman
caveman custom_template.json output.json

# snip unavailable - fall back to RTK
rtk git status
```

### Session Hygiene
```bash
# Manual prune
hermes sessions prune --older-than 3 --source cron --yes

# Check status
hermes sessions stats
hermes insights

# Set up cron
hermes cron create --schedule '0 3 * * *' --prompt 'hermes sessions prune --older-than 3 --source cron --yes'
```

## References

- See `references/snip-vs-rtk-caveman.md` for detailed comparison
- See `references/hermes-token-saver-lite-wrapper-pattern.md` for session-derived wrapper and installer patterns
- See `references/hts-phase4a-pack-routing.md` for pack presets, `hts --doctor`, `hts --init`, and command-to-filter resolver examples
- See `references/session-recovery-pattern.md` for resuming previously planned multi-phase repo work without re-asking basics