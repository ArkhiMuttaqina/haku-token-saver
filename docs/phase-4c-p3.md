## P3 Features — Implemented (Phase 4C-3)

### Commands added to `hts`

| Command | Action | Status |
|---------|--------|--------|
| `hts --commit summary` | Generate compact commit packet from working-tree diff | ✅ |
| `hts --commit full-summary` | Generate compact commit packet plus truncated patch | ✅ |
| `hts --review diff` | Generate review packet with diff stat only | ✅ |
| `hts --review lint` | Run detected lint target and truncate output | ✅ |
| `hts --review test` | Run detected test target and truncate output | ✅ |
| `hts --review all` | Combine diff + lint + test packet | ✅ |

### Behavior

**hts --commit summary**

Outputs:

- `type=commit-summary`
- `mode=summary`
- `staged_files=`
- `dirty_files=`
- `[stat]` from `git diff --minimal --stat`
- `[files]` first 20 changed files

**hts --commit full-summary**

Adds:

- `[patch]` from `git diff --minimal --unified=0 --no-color`
- truncates patch at 220 lines

**hts --review <mode>**

Modes:

- `diff`: `git diff --stat`
- `lint`: detected lint target
- `test`: detected test target
- `all`: diff + lint + test

Detection:

- Node: `package.json` → `npm run -s lint`, `npm test -- --runInBand`
- Python: `pyproject.toml` + tools → `ruff check .`, `pytest`
- Otherwise: prints `no supported ... target detected`

### Notes

- Commands never commit or mutate files.
- Review lint/test output is capped at 120 lines per section.
- Commit patch output is capped at 220 lines.
- `config/snip-filters.txt` is excluded from commit/review diff packets.
- In the current repo state, unstaged changes are very large because source repo contains many legacy skill deletions; `--commit summary` intentionally surfaces that instead of hiding it.

### Test results

✓ `bash -n scripts/hts`

✓ `./scripts/hts --commit summary`

Observed:

- `type=commit-summary`
- `mode=summary`
- `staged_files=0`
- `dirty_files=169`
- stat/files payload emitted

✓ `./scripts/hts --review diff`

Observed:

- `type=review`
- `mode=diff`
- `[diff]` stat emitted

### Known limitations

- `--commit` summarizes current working-tree diff, not staged-only by default.
- No auto-generated commit message yet.
- `--review lint/test` uses simple detection only.
- No `.hts.json` override for lint/test commands yet.
