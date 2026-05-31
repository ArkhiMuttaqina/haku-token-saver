## P4 Features — Implemented (Phase 4C-4)

### Commands added to `hts`

| Command | Action | Status |
|---------|--------|--------|
| `hts --filters [pattern]` | List snip filters; optional regex to filter results | ✓ |
| `hts --commit --staged-only` | Generate commit summary from staged changes instead of working-tree | ✓ |
| `hts --compress --limit N` | Set line length limit (default: 180, min: 20) | ✓ |

### Behavior

**--filters [pattern]**

- Falls back to `config/snip-filters.txt` if snip repo not available
- Uses `grep -E` for pattern matching
- Returns empty list if no filters source found

Example:

```bash
hts --filters '^git-'  # Only git-related filters
hts --filters test     # Filters containing 'test'
hts --filters          # List all (no pattern)
```

**--commit --staged-only**

- Adds `scope=staged` flag to commit summary packet
- Uses `git diff --cached` instead of `git diff`
- Adds `staged_only=true` metadata
- Works with both `summary` and `full-summary` modes

Output fields:
- `type=commit-summary`
- `mode=summary|full-summary`
- `scope=staged|working-tree`
- `staged_only=true|false`
- `staged_files=N`
- `dirty_files=N`
- `[stat]`
- `[files]`
- `[patch]` (full-summary only, truncated 220 lines)

**--compress --limit N**

- Default: 180 characters
- Min: 20 characters
- Validates input: non-integer or < 20 → error
- Applied via awk variable `lim`
- Affects line truncation (truncates at `limit-3` + `...`)
- Preserves fenced code blocks

Example:

```bash
hts --compress README.md --limit 120
hts --compress docs/README.md --limit 80
```

### Files modified

- `scripts/hts`:
  - `list_filters()` now accepts optional pattern argument
  - `compress_file()` now accepts limit argument with validation
  - `summarize_commit()` now accepts `staged_only` argument
  - New vars: `FILTERS_PATTERN`, `COMPRESS_LIMIT`, `COMMIT_STAGED_ONLY`
  - Updated `--filters` arg parsing to consume pattern
  - Added `--limit` arg parsing
  - Added `--staged-only` arg parsing
  - Updated help text and examples

### Implementation details

**Filter fallback chain:**

1. `$SYNC_SNIP_FROM/filters/*.yaml` (live snip repo)
2. `$CONFIG_DIR/snip-filters.txt` (synced inventory)
3. `$FILTER_MAP` (fallback mapping)

**Compress validation:**

```bash
if ! [[ "$limit" =~ ^[0-9]+$ ]] || [ "$limit" -lt 20 ]; then
  echo "[err] --limit must be an integer >= 20" >&2
  return 1
fi
```

**Commit scope selection:**

```bash
if [ "$staged_only" = true ]; then
  diff_cmd=(git diff --cached --minimal -- . ':(exclude)config/snip-filters.txt')
  names_cmd='repo_staged_files'
  scope_label='staged'
else
  diff_cmd=(git diff --minimal -- . ':(exclude)config/snip-filters.txt')
  names_cmd='repo_dirty_files'
  scope_label='working-tree'
fi
```

### Testing

All tests passed:

```bash
# Syntax check
bash -n scripts/hts  # ✓ OK

# Filter pattern matching
./scripts/hts --filters '^git-'
# Output: git-add, git-branch, git-commit, git-diff, git-fetch, git-log, git-pull, git-push, git-show, git-stash, git-status, git-worktree

./scripts/hts --filters 'test'
# Output: 6 filters containing 'test'

./scripts/hts --filters
# Output: 127 filters (all)

# Commit staged-only
./scripts/hts --commit summary --staged-only
# Output includes:
#   type=commit-summary
#   mode=summary
#   scope=staged
#   staged_only=true
#   staged_files=0
#   dirty_files=169

# Compress limit
./scripts/hts --dry-run --compress README.md --limit 120
# Output: [dry-run] compress file=README.md limit=120

./scripts/hts --compress README.md --limit 10
# Output: [err] --limit must be an integer >= 20

# Help text
./scripts/hts --help | grep -E -- '--filters|--limit|--staged-only'
# ✓ All three options documented with usage and examples
```

Validation results:
- Pattern matching: ERE works correctly for `^git-` prefix (12 filters)
- Staged-only: scope switches to `staged`, no output when clean (correct)
- Limit validation: rejects `< 20`, accepts `>= 20`, applies correctly in dry-run

### Next feature candidates (future P5)

- `hts --init` generate `.hts.json` with per-project overrides for lint/test commands
- `hts --review lint/test` config override from `.hts.json`
- `hts --commit` auto-generate conventional commit message
- `hts --gain --backend snip|rtk` force benchmark specific backend
- `hts --compress --lines N` limit total output lines (not just line length)
- `hts --help <command>` show command-specific help

### Usage notes

- Pattern matching in `--filters` uses ERE (Extended Regular Expressions)
- `--staged-only` must come before or after `--commit <mode>`; both are flags
- `--limit` applies globally to subsequent `--compress` calls if needed (current: per-invocation)
- For staged commits, ensure files are actually staged (`git add`) before running