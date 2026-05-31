# Compact Terminal Output — Hermes Agent Instructions

## Scope

Use these instructions only for this repo:

```text
haku-token-saver
```

Goal: reduce terminal-output token waste without hiding important failures.

## Output Policy

- Prefer compact formatting at the source.
- Prefer `--json`, `--porcelain`, and narrow flags.
- Use `hts` for generic CLI commands.
- Use template mode for stable workflows.
- Keep raw output available when needed.

## Backend Rule

Generic command routing:

```bash
~/bin/hts -- git status
~/bin/hts -- npm test
~/bin/hts --which
```

Backend priority:

```text
snip > rtk > raw-limited
```

Do not chain `snip` and `rtk`.

## Template Workflows

Use template mode for known summaries:

```bash
~/bin/hts --template git-status
~/bin/hts --template git-log 20
~/bin/hts --template lint src/
~/bin/hts --template test-results 'npx vitest run'
~/bin/hts --template npm-scripts
```

Direct wrapper remains available:

```bash
~/bin/caveman_wrapper.sh git-status
~/bin/caveman_wrapper.sh git-log 20
~/bin/caveman_wrapper.sh lint src/
~/bin/caveman_wrapper.sh test-results 'npx vitest run'
~/bin/caveman_wrapper.sh npm-scripts
```

## Caveman Adaptation

Caveman is used here as:

- terse response policy
- curated summary/template style
- memory/config compression inspiration

Caveman is not used as generic CLI fallback.

## Terse Response Policy

Use terse output for:

- status reports
- command summaries
- small bugfix explanations
- validation results

Use normal detail for:

- security warnings
- irreversible actions
- migrations
- architecture tradeoffs
- ambiguous failure analysis

Always preserve:

- code
- paths
- commands
- errors
- URLs
- identifiers

## When Not to Filter

Do not filter when:

- user asks for full logs
- raw traceback context matters
- command is interactive
- exact output matters
- security review needs full evidence

## Verification

```bash
~/bin/verify_caveman_setup.sh
~/bin/hts --which
~/bin/hts --dry-run -- git status
```
