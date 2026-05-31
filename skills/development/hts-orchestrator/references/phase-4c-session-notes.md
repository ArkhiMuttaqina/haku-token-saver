# Phase 4C Session Notes (P1, P2, P3, P4)

## Pitfall: Mode dispatch too late

Symptom:

```
[err] No command provided. Use -- to separate options.
Example: hts -- git status
```

Command used: `./scripts/hts --commit summary` or `./scripts/hts --review diff`.

Root cause:

Script had a generic guard `if [ $# -eq 0 ]` before P3 mode dispatch. After adding `--commit` and `--review` modes, the guard fired first, causing early exit with "no command provided".

Fix:

Move commit/review dispatch before the generic guard. Order:

1. Template mode
2. Commit mode
3. Review mode
4. Compress mode
5. Generic `if [ $# -eq 0 ]` guard

## Truncation limits used

- Commit patch output: 220 lines
- Review lint/test output: 120 lines per section
- Files list in commit summary: first 20 files only
- Long lines in compressor: >180 chars truncated to `...`

## Tricky printf

Leading `--` in format string is parsed as option by `printf`. Use `%s` placeholder:

- Bad: `printf '--- title ---\n'`
- Good: `printf '%s\n' '--- title ---'`

## Config file exclusion

Commit and review diff packets exclude `config/snip-filters.txt` because it is a generated inventory that may change independently of actual code changes. Use git pathspec `':(exclude)config/snip-filters.txt'`.

## Lint/test detection

- Node: `package.json` exists → `npm run -s lint` and `npm test -- --runInBand`
- Python: `pyproject.toml` + command available → `ruff check .` and `pytest`
- Fallback: print `no supported ... target detected`

## Run command twice for `--gain`

`--gain -- <cmd>` executes raw and filtered in sequence, captures both stdout and stderr with `2>&1 || true`. This ensures command errors do not cause `--gain` itself to fail; it always prints byte comparison even if underlying command fails.

## Synced filter inventory

`--sync-snip-filters` writes to `$CONFIG_DIR/snip-filters.txt` (usually `~/.config/haku-token-saver/snip-filters.txt`). File is one filter name per line. Count expected: 127 for current snip reference.

## P4 refinements

### `--filters [pattern]`

Pattern search uses ERE via `grep -E -- "$pattern"`. Do not make this depend on the live snip repo only. Fallback order should be:

1. `$SYNC_SNIP_FROM/filters/*.yaml`
2. `$CONFIG_DIR/snip-filters.txt`
3. `$FILTER_MAP`

Known smoke result: `./scripts/hts --filters '^git-'` returns 12 entries (`git-add` through `git-worktree`).

### `--compress --limit N`

Default limit: `180`. Minimum valid limit: `20`. Validation should happen inside `compress_file()` so both normal and future caller paths are protected:

```bash
if ! [[ "$limit" =~ ^[0-9]+$ ]] || [ "$limit" -lt 20 ]; then
  echo "[err] --limit must be an integer >= 20" >&2
  return 1
fi
```

Dry-run should include the chosen limit:

```text
[dry-run] compress file=README.md limit=120
```

### `--commit --staged-only`

`--staged-only` switches the commit summary scope from working tree diff to staged diff. Expected metadata:

```text
scope=staged
staged_only=true
```

Use `git diff --cached --minimal -- . ':(exclude)config/snip-filters.txt'` for staged patch/stat output, and `repo_staged_files` for the file list.