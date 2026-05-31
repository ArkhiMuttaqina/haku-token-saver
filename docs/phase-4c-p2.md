## P2 Features — Implemented (Phase 4C-2)

### Commands added to `hts`

| Command | Action | Status |
|---------|--------|--------|
| `hts --gain -- <cmd>` | Compare raw vs filtered output byte count | ✅ |
| `hts --compress <file>` | Basic terse compressor for text files | ✅ |

### Behavior

**hts --gain -- <cmd>**

- Executes command twice: raw (no filter) + filtered (selected backend)
- Captures stdout/stderr both
- Reports:
  - `backend=` (snip/rtk/raw)
  - `filter=` (resolved snip filter or command name)
  - `raw_bytes=`
  - `filtered_bytes=`
  - `bytes_saved=`
  - `percent_saved=`

- Uses helper `run_with_backend_capture()` to honor backend selection
- Does not fail if command returns non-zero; captures output with `2>&1 || true`

**hts --compress <file>**

- Basic tersifier (no LLM call):
  - Trim trailing whitespace
  - Collapse multiple blank lines (max 1 blank)
  - Keep code blocks (` ``` `) untouched
  - Keep comments/headers intact
  - Trim list items (`-`/`*`)
  - Truncate long lines >180 chars to `...`

- Errors:
  - `[err] --compress requires a file path`
  - `[err] file not found: <path>`

### Files touched

**scripts/hts:**

- added flags: `--gain`, `--compress <file>`
- added functions: `compress_file()`, `run_with_backend_capture()`
- updated usage/help text with P2 examples
- added `--dry-run` support for `--compress` (no-op, just echo dry-run message)
- added `--gain` block before `case "$backend" in` exec block

### Test results

✓ `bash -n` ok
✓ `hts --compress README.md` → truncated output, lines trimmed, max 1 blank
✓ `hts --gain -- git log -5` → backend=raw, raw_bytes=1298, filtered_bytes=1298, bytes_saved=0, percent_saved=0%
✓ `hts --dry-run --compress README.md` → `[dry-run] compress file=README.md`
✓ `hts --backend raw --gain -- git log -5` → works as expected (raw=no savings)

### Known limitations

- `compress_file()` is simple awk-based; not LLM-powered semantic compression
- `--gain` runs command twice; may be expensive for heavy commands
- `--compress` truncates at 180 chars; no configurable limit yet